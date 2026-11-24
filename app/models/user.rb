class User < ApplicationRecord
  EMAIL_CONFIRMATION_TTL = 2.days
  PASSWORD_RESET_TTL = 30.minutes

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

  enum :role, {
    volunteer: 0,
    organization: 1,
    admin: 2
  }

  # Tokens are signed and self-expiring, so nothing is stored in the database.
  # Changing the email invalidates a confirmation link; changing the password
  # invalidates every outstanding reset link.
  generates_token_for :email_confirmation, expires_in: EMAIL_CONFIRMATION_TTL do
    email
  end

  generates_token_for :password_reset, expires_in: PASSWORD_RESET_TTL do
    password_salt.last(10)
  end

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }
  normalizes :name, with: ->(name) { name.to_s.squish }

  validates :name, presence: true, length: { maximum: 100 }
  validates :role, presence: true

  validates :email,
            presence: true,
            length: { maximum: 255 },
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password,
            length: { minimum: 8, maximum: 72 },
            if: -> { password.present? }

  def email_confirmed?
    email_confirmed_at.present?
  end

  def confirm_email!
    update!(email_confirmed_at: Time.current) unless email_confirmed?
  end

  # Organizations may only publish events once an admin verified them.
  def verified_organization?
    organization? && organization_profile&.verified?
  end

  # Upcoming published events that still have people waiting on them.
  def events_with_active_volunteers
    volunteer_events.published
                    .where("starts_at > ?", Time.current)
                    .joins(:event_registrations)
                    .merge(EventRegistration.active)
                    .distinct
  end

  def deletable?
    !organization? || events_with_active_volunteers.none?
  end
end
