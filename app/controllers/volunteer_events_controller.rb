class VolunteerEventsController < ApplicationController
  before_action :require_login, except: %i[index show]
  before_action :require_organization, only: %i[new create edit update destroy]
  before_action :set_visible_event, only: :show
  before_action :set_owned_event, only: %i[edit update destroy]

  def index
    upcoming_events = VolunteerEvent.upcoming
    @categories = upcoming_events.reorder(:category).distinct.pluck(:category)
    @filter_date = parsed_filter_date
    @events = upcoming_events
              .matching_text(params[:query])
              .in_category(params[:category])
              .in_location(params[:location])
              .starting_on(@filter_date)
    @owned_events = if logged_in? && current_user.organization?
                      current_user.volunteer_events.order(starts_at: :asc)
                    else
                      VolunteerEvent.none
                    end
  end

  def show
    if logged_in? && current_user.volunteer?
      @event_registration = @event.event_registrations.find_by(
        volunteer: current_user
      ) || @event.event_registrations.build
    elsif logged_in? && @event.organization == current_user
      @event_registrations = @event.event_registrations
                                    .includes(:volunteer)
                                    .order(created_at: :asc)
    end
  end

  def new
    @event = current_user.volunteer_events.build
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
      redirect_to @event, notice: "Kegiatan berhasil diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
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
    return if @event.published?
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
