class EventRegistrationsController < ApplicationController
  before_action :require_login
  before_action :set_event
  before_action :require_volunteer, only: %i[create cancel]
  before_action :require_event_owner, only: %i[accept reject]
  before_action :set_registration, only: %i[accept reject cancel]
  before_action :require_registration_owner, only: :cancel

  def create
    registration = @event.event_registrations.build(registration_params)
    registration.volunteer = current_user

    if registration.save
      redirect_to @event, notice: "Pendaftaran berhasil dikirim."
    else
      redirect_to @event,
                  alert: registration.errors.full_messages.to_sentence
    end
  end

  def accept
    decide(:accepted, "Pendaftar berhasil diterima.")
  end

  def reject
    decide(:rejected, "Pendaftar berhasil ditolak.")
  end

  def cancel
    unless @registration.pending? || @registration.accepted?
      redirect_to @event, alert: "Pendaftaran ini tidak dapat dibatalkan."
      return
    end

    update_status(:cancelled, "Pendaftaran berhasil dibatalkan.")
  end

  private

  def set_event
    @event = VolunteerEvent.find(params[:volunteer_event_id])
  end

  def set_registration
    @registration = @event.event_registrations.find(params[:id])
  end

  def require_event_owner
    return if @event.organization == current_user

    redirect_to @event, alert: "Anda tidak berhak mengelola pendaftar kegiatan ini."
  end

  def require_registration_owner
    return if @registration.volunteer == current_user

    redirect_to @event, alert: "Anda tidak berhak membatalkan pendaftaran ini."
  end

  def registration_params
    params.require(:event_registration).permit(:motivation)
  end

  def decide(status, success_message)
    unless @registration.pending?
      redirect_to @event, alert: "Pendaftaran ini sudah diproses."
      return
    end

    update_status(status, success_message)
  end

  def update_status(status, success_message)
    if @registration.update(status: status)
      redirect_to @event, notice: success_message
    else
      redirect_to @event,
                  alert: @registration.errors.full_messages.to_sentence
    end
  end
end
