class DashboardController < ApplicationController
  before_action :require_login

  def show
    return unless current_user.volunteer?

    @event_registrations = current_user.event_registrations
                                       .includes(:volunteer_event)
                                       .order(created_at: :desc)
  end
end
