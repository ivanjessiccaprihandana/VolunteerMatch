class PagesController < ApplicationController
  def home
    @upcoming_events = VolunteerEvent.upcoming.includes(:organization).limit(3)
  end

  def privacy
  end

  def terms
  end
end
