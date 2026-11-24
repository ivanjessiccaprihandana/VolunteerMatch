require "test_helper"

class EventLifecycleTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create_user(name: "Org Lifecycle", role: :organization)
    @volunteer = create_user(name: "Relawan Lifecycle")
    @event = @organization.volunteer_events.create!(default_event_attributes(title: "Aksi Bersih"))
  end

  test "event with registrations is cancelled instead of deleted" do
    @event.event_registrations.create!(volunteer: @volunteer, motivation: "Ikut")
    login_as(@organization)

    assert_no_difference("VolunteerEvent.count") do
      delete volunteer_event_url(@event)
    end
    assert_redirected_to volunteer_event_url(@event)

    patch volunteer_event_url(@event), params: { volunteer_event: { status: "cancelled" } }

    assert @event.reload.cancelled?
    assert_enqueued_email_with RegistrationMailer, :event_cancelled,
                               params: { registration: @event.event_registrations.first }
  end

  test "volunteer can still open a cancelled event they joined" do
    @event.event_registrations.create!(volunteer: @volunteer, motivation: "Ikut")
    @event.update!(status: :cancelled)
    login_as(@volunteer)

    get volunteer_event_url(@event)

    assert_response :success
    assert_select "h3", "Kegiatan dibatalkan"
  end

  test "unverified organization is told to verify before publishing" do
    unverified = create_user(role: :organization, verified: false)
    login_as(unverified)

    assert_no_difference("VolunteerEvent.count") do
      post volunteer_events_url, params: { volunteer_event: default_event_attributes }
    end
    assert_response :unprocessable_entity

    assert_difference("VolunteerEvent.count", 1) do
      post volunteer_events_url, params: { volunteer_event: default_event_attributes(status: "draft") }
    end
  end

  test "volunteer can register again after cancelling" do
    login_as(@volunteer)
    post volunteer_event_event_registrations_url(@event), params: { event_registration: { motivation: "Pertama" } }
    registration = @event.event_registrations.last
    patch cancel_volunteer_event_event_registration_url(@event, registration)

    assert_difference("EventRegistration.count", 1) do
      post volunteer_event_event_registrations_url(@event), params: { event_registration: { motivation: "Kedua" } }
    end

    get volunteer_event_url(@event)
    assert_select "p", text: /Kedua/
  end

  test "index paginates and loads organizations without N+1 queries" do
    (VolunteerEvent::PER_PAGE + 1).times do |i|
      owner = create_user(role: :organization)
      owner.volunteer_events.create!(default_event_attributes(title: "Kegiatan #{i}"))
    end

    queries = 0
    callback = ->(*, payload) { queries += 1 if payload[:sql].include?(%("users")) }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get volunteer_events_url
    end

    assert_response :success
    assert_select ".event-card", VolunteerEvent::PER_PAGE
    assert_select "a[rel=next]"
    assert queries <= 2, "expected organizations to be preloaded, saw #{queries} user queries"

    get volunteer_events_url(page: 2)
    assert_select ".event-card", 2
  end

  test "labels are shown in Indonesian" do
    login_as(@organization)

    get volunteer_event_url(@event)

    assert_select ".badge", text: "Dipublikasikan"
  end
end
