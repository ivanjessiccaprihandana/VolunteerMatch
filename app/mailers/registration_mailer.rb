class RegistrationMailer < ApplicationMailer
  before_action :set_registration

  # To the organization: a volunteer applied.
  def new_registration
    mail to: @event.organization.email,
         subject: "Pendaftar baru: #{@event.title}"
  end

  # To the volunteer: accepted or rejected.
  def status_changed
    mail to: @volunteer.email,
         subject: "Status pendaftaran Anda: #{@event.title}"
  end

  # To the organization: a volunteer withdrew.
  def volunteer_cancelled
    mail to: @event.organization.email,
         subject: "Pendaftar membatalkan: #{@event.title}"
  end

  # To the volunteer: the organization cancelled the event.
  def event_cancelled
    mail to: @volunteer.email,
         subject: "Kegiatan dibatalkan: #{@event.title}"
  end

  private

  def set_registration
    @registration = params[:registration]
    @event = @registration.volunteer_event
    @volunteer = @registration.volunteer
    @event_url = volunteer_event_url(@event)
  end
end
