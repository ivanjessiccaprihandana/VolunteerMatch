class EventRegistration < ApplicationRecord
  belongs_to :volunteer,
             class_name: "User",
             inverse_of: :event_registrations
  belongs_to :volunteer_event

  enum :status, {
    pending: 0,
    accepted: 1,
    rejected: 2,
    cancelled: 3
  }

  scope :active, -> { where(status: %i[pending accepted]) }

  validates :motivation, presence: true, length: { maximum: 1_000 }
  validates :status, presence: true
  validates :volunteer_id,
            uniqueness: {
              scope: :volunteer_event_id,
              conditions: -> { where.not(status: :cancelled) },
              message: :already_registered
            },
            unless: :cancelled?

  validate :volunteer_account_required
  validate :event_must_accept_registrations, on: :create
  validate :capacity_must_be_available, if: :being_accepted?

  after_create_commit :notify_organization_of_registration

  # Changes the status while holding a row lock on the event, so two
  # organizers accepting at the same moment cannot overfill the capacity.
  # Returns true on success, false when validation fails.
  def transition_to(new_status)
    changed = volunteer_event.with_lock do
      update(status: new_status)
    end

    notify_status_change if changed
    changed
  end

  def cancellable?
    (pending? || accepted?) && !volunteer_event.cancelled? && !volunteer_event.started?
  end

  private

  def volunteer_account_required
    return if volunteer.nil? || volunteer.volunteer?

    errors.add(:volunteer, :must_be_volunteer)
  end

  def event_must_accept_registrations
    return if volunteer_event.nil? || volunteer_event.registration_open?

    errors.add(:volunteer_event, :not_accepting_registrations)
  end

  def capacity_must_be_available
    accepted_count = volunteer_event.event_registrations
                                    .accepted
                                    .where.not(id: id)
                                    .count
    return if accepted_count < volunteer_event.capacity

    errors.add(:status, :capacity_full)
  end

  def being_accepted?
    accepted? && will_save_change_to_status?
  end

  def notify_organization_of_registration
    RegistrationMailer.with(registration: self).new_registration.deliver_later
  end

  def notify_status_change
    mailer = RegistrationMailer.with(registration: self)

    case status
    when "accepted", "rejected"
      mailer.status_changed.deliver_later
    when "cancelled"
      mailer.volunteer_cancelled.deliver_later
    end
  end
end
