class VolunteerEvent < ApplicationRecord
  CATEGORIES = %w[Lingkungan Pendidikan Kesehatan Sosial Bencana Hewan Lainnya].freeze
  PER_PAGE = 12

  belongs_to :organization, class_name: "User", inverse_of: :volunteer_events
  has_many :event_registrations, dependent: :destroy
  has_many :registered_volunteers,
           through: :event_registrations,
           source: :volunteer

  enum :status, {
    draft: 0,
    published: 1,
    closed: 2,
    cancelled: 3
  }

  normalizes :title, :location, with: ->(value) { value.to_s.squish }

  scope :upcoming, -> {
    published.where("starts_at >= ?", Time.current).order(:starts_at)
  }

  def self.matching_text(query)
    return all if query.blank?

    pattern = "%#{sanitize_sql_like(query.strip)}%"
    where(
      "title ILIKE :pattern OR description ILIKE :pattern",
      pattern: pattern
    )
  end

  def self.in_category(category)
    category.present? ? where(category: category) : all
  end

  def self.in_location(location)
    return all if location.blank?

    pattern = "%#{sanitize_sql_like(location.strip)}%"
    where("location ILIKE ?", pattern)
  end

  def self.starting_on(date)
    date.present? ? where(starts_at: date.all_day) : all
  end

  def self.page(number)
    number = number.to_i.clamp(1, 10_000)
    limit(PER_PAGE).offset((number - 1) * PER_PAGE)
  end

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, presence: true, length: { maximum: 10_000 }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :location, presence: true, length: { maximum: 255 }
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :registration_deadline, presence: true
  validates :status, presence: true
  validates :capacity,
            numericality: {
              only_integer: true,
              greater_than: 0,
              less_than_or_equal_to: 10_000
            }

  validate :organization_account_required
  validate :organization_verified_to_publish
  validate :starts_in_future, if: -> { new_record? || will_save_change_to_starts_at? }
  validate :ends_after_start
  validate :registration_closes_before_start
  validate :capacity_covers_accepted_volunteers, if: -> { persisted? && will_save_change_to_capacity? }

  after_update_commit :notify_volunteers_of_cancellation,
                      if: -> { saved_change_to_status?(to: "cancelled") }

  def registration_open?
    published? &&
      registration_deadline.present? &&
      registration_deadline.future? &&
      starts_at.present? &&
      starts_at.future? &&
      capacity.present? &&
      accepted_count < capacity
  end

  def remaining_capacity
    [capacity - accepted_count, 0].max
  end

  def accepted_count
    event_registrations.accepted.count
  end

  def started?
    starts_at.present? && starts_at <= Time.current
  end

  # Events that real volunteers signed up for are cancelled instead of
  # deleted, so everyone keeps a record and gets notified.
  def deletable?
    event_registrations.none?
  end

  private

  def organization_account_required
    return if organization.nil? || organization.organization?

    errors.add(:organization, :must_be_organization)
  end

  def organization_verified_to_publish
    return unless published? && will_save_change_to_status?
    return if organization.nil? || organization.verified_organization?

    errors.add(:status, :organization_not_verified)
  end

  def starts_in_future
    return if starts_at.blank? || starts_at.future?

    errors.add(:starts_at, :must_be_in_future)
  end

  def ends_after_start
    return if starts_at.blank? || ends_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, :must_be_after_start)
  end

  def registration_closes_before_start
    return if registration_deadline.blank? || starts_at.blank?
    return if registration_deadline < starts_at

    errors.add(:registration_deadline, :must_be_before_start)
  end

  def capacity_covers_accepted_volunteers
    return if capacity.blank? || capacity >= accepted_count

    errors.add(:capacity, :below_accepted, count: accepted_count)
  end

  def notify_volunteers_of_cancellation
    event_registrations.active.includes(:volunteer).find_each do |registration|
      RegistrationMailer.with(registration: registration).event_cancelled.deliver_later
    end
  end
end
