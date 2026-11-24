class VolunteerEventsController < ApplicationController
  before_action :require_login, except: %i[index show]
  before_action :require_organization, only: %i[new create edit update destroy]
  before_action :set_visible_event, only: :show
  before_action :set_owned_event, only: %i[edit update destroy]

  def index
    @categories = VolunteerEvent::CATEGORIES
    @filter_date = parsed_filter_date
    events = VolunteerEvent.upcoming
                           .matching_text(params[:query])
                           .in_category(params[:category])
                           .in_location(params[:location])
                           .starting_on(@filter_date)

    @total_count = events.count
    @page = params[:page].to_i.clamp(1, 10_000)
    @total_pages = [(@total_count / VolunteerEvent::PER_PAGE.to_f).ceil, 1].max
    @events = events.includes(:organization).page(@page)

    @owned_events = if logged_in? && current_user.organization?
                      current_user.volunteer_events.order(starts_at: :desc).limit(20)
                    else
                      VolunteerEvent.none
                    end
  end

  def show
    if logged_in? && current_user.volunteer?
      # The newest registration wins, so a volunteer who cancelled and
      # registered again sees the current one.
      @event_registration = @event.event_registrations
                                  .where(volunteer: current_user)
                                  .order(created_at: :desc)
                                  .first
      @event_registration = @event.event_registrations.build if @event_registration.nil? || @event_registration.cancelled?
    elsif logged_in? && @event.organization == current_user
      @event_registrations = @event.event_registrations
                                   .includes(volunteer: :volunteer_profile)
                                   .order(created_at: :asc)
    end
  end

  def new
    @event = current_user.volunteer_events.build(status: :draft)
  end

  def create
    @event = current_user.volunteer_events.build(event_params)

    if @event.save
      redirect_to @event, notice: "Kegiatan berhasil dibuat."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      notice = if @event.saved_change_to_status?(to: "cancelled")
                 "Kegiatan dibatalkan. Relawan yang terdaftar akan diberi tahu lewat email."
               else
                 "Kegiatan berhasil diperbarui."
               end
      redirect_to @event, notice: notice
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @event.deletable?
      redirect_to @event,
                  alert: "Kegiatan yang sudah memiliki pendaftar tidak dapat dihapus. Ubah statusnya menjadi Dibatalkan agar relawan diberi tahu."
      return
    end

    @event.destroy!
    redirect_to volunteer_events_path, notice: "Kegiatan berhasil dihapus."
  end

  private

  def parsed_filter_date
    return if params[:date].blank?

    Date.iso8601(params[:date])
  rescue Date::Error
    nil
  end

  def set_visible_event
    @event = VolunteerEvent.find(params[:id])
    return unless @event.draft?
    return if logged_in? && @event.organization == current_user

    redirect_to volunteer_events_path, alert: "Kegiatan tidak tersedia."
  end

  def set_owned_event
    @event = current_user.volunteer_events.find(params[:id])
  end

  def event_params
    params.require(:volunteer_event).permit(
      :title,
      :description,
      :category,
      :location,
      :starts_at,
      :ends_at,
      :registration_deadline,
      :capacity,
      :status
    )
  end
end
