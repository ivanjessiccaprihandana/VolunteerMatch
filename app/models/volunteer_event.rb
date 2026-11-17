class VolunteerEvent < ApplicationRecord
  belongs_to :organization, class_name: "User", inverse_of: :volunteer_events

  enum status: {
    draft: 0,
    published: 1,
    closed: 2,
    cancelled: 3
  }

  scope :upcoming, -> {
    published.where("starts_at >= ?", Time.current).order(:starts_at)
  }

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
