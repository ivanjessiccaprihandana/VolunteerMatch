class VolunteerEvent < ApplicationRecord
  belongs_to :organization, class_name: "User", inverse_of: :volunteer_events
  has_many :event_registrations, dependent: :destroy
  has_many :registered_volunteers,
           through: :event_registrations,
           source: :volunteer

  enum status: {
    draft: 0,
    published: 1,
    closed: 2,
    cancelled: 3
  }

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

  validates :title, presence: true
  validates :description, presence: true
  validates :category, presence: true
  validates :location, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :registration_deadline, presence: true
  validates :status, presence: true
  validates :capacity,
            numericality: { only_integer: true, greater_than: 0 }

  validate :organization_account_required
  validate :ends_after_start
  validate :registration_closes_before_start

  def registration_open?
    published? &&
      registration_deadline.present? &&
      registration_deadline.future? &&
      starts_at.present? &&
      starts_at.future? &&
      capacity.present? &&
      event_registrations.accepted.count < capacity
  end

  def remaining_capacity
    [capacity - event_registrations.accepted.count, 0].max
  end

  private

  def organization_account_required
    return if organization.nil? || organization.organization?

    errors.add(:organization, "must use an organization account")
  end

  def ends_after_start
    return if starts_at.blank? || ends_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, "must be after the start time")
  end

  def registration_closes_before_start
    return if registration_deadline.blank? || starts_at.blank?
    return if registration_deadline < starts_at

    errors.add(:registration_deadline, "must be before the start time")
  end
end
