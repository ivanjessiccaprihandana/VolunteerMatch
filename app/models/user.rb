class User < ApplicationRecord
  has_secure_password

  has_one :volunteer_profile, dependent: :destroy
  has_one :organization_profile, dependent: :destroy
  has_many :volunteer_events,
           foreign_key: :organization_id,
           inverse_of: :organization,
           dependent: :destroy
  has_many :event_registrations,
           foreign_key: :volunteer_id,
           inverse_of: :volunteer,
           dependent: :destroy
  has_many :registered_volunteer_events,
           through: :event_registrations,
           source: :volunteer_event

  enum role: {
    volunteer: 0,
    organization: 1,
    admin: 2
  }

  before_validation :normalize_email

  validates :name, presence: true
  validates :role, presence: true

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: /\A[^@\s]+@[^@\s]+\z/ }

  validates :password,
            length: { minimum: 8 },
            if: -> { password.present? }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
