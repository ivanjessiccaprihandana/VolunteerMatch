require "test_helper"

class EventRegistrationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create_user(
      name: "Organisasi Kegiatan",
      email: "controller-registration-organization@example.com",
      role: :organization
    )
    @other_organization = create_user(
      name: "Organisasi Lain",
      email: "controller-registration-other-org@example.com",
      role: :organization
    )
    @volunteer = create_user(
      name: "Relawan Utama",
      email: "controller-registration-volunteer@example.com",
      role: :volunteer
    )
    @other_volunteer = create_user(
      name: "Relawan Lain",
      email: "controller-registration-other-volunteer@example.com",
      role: :volunteer
    )
    @event = @organization.volunteer_events.create!(event_attributes)
  end

  test "guest must log in before registering" do
    assert_no_difference("EventRegistration.count") do
      post volunteer_event_event_registrations_url(@event), params: {
        event_registration: { motivation: "Saya ingin membantu." }
      }
    end

    assert_redirected_to login_url
  end

  test "volunteer can register for an event" do
    login_as(@volunteer)

    assert_difference("EventRegistration.count", 1) do
      post volunteer_event_event_registrations_url(@event), params: {
        event_registration: {
          motivation: "Saya memiliki pengalaman mengajar anak-anak."
        }
      }
    end

    registration = EventRegistration.order(:created_at).last
    assert_redirected_to volunteer_event_url(@event)
    assert_equal @volunteer, registration.volunteer
    assert registration.pending?
  end

  test "organization cannot register as a volunteer" do
    login_as(@organization)

    assert_no_difference("EventRegistration.count") do
      post volunteer_event_event_registrations_url(@event), params: {
        event_registration: { motivation: "Tidak boleh diterima." }
      }
    end

    assert_redirected_to dashboard_url
  end

  test "volunteer cannot register twice" do
    create_registration(@volunteer)
    login_as(@volunteer)

    assert_no_difference("EventRegistration.count") do
      post volunteer_event_event_registrations_url(@event), params: {
        event_registration: { motivation: "Pendaftaran kedua." }
      }
    end

    assert_redirected_to volunteer_event_url(@event)
  end

  test "event owner can accept and reject registrations" do
    first = create_registration(@volunteer)
    second = create_registration(@other_volunteer)
    login_as(@organization)

    patch accept_volunteer_event_event_registration_url(@event, first)
    assert first.reload.accepted?

    patch reject_volunteer_event_event_registration_url(@event, second)
    assert second.reload.rejected?
  end

  test "another organization cannot manage registrations" do
    registration = create_registration(@volunteer)
    login_as(@other_organization)

    patch accept_volunteer_event_event_registration_url(@event, registration)

    assert_redirected_to volunteer_event_url(@event)
    assert registration.reload.pending?
  end

  test "volunteer can cancel their own registration" do
    registration = create_registration(@volunteer)
    login_as(@volunteer)

    patch cancel_volunteer_event_event_registration_url(@event, registration)

    assert_redirected_to volunteer_event_url(@event)
    assert registration.reload.cancelled?
  end

  test "volunteer cannot cancel another volunteers registration" do
    registration = create_registration(@other_volunteer)
    login_as(@volunteer)

    patch cancel_volunteer_event_event_registration_url(@event, registration)

    assert_redirected_to volunteer_event_url(@event)
    assert registration.reload.pending?
  end

  test "event owner can see the applicants" do
    registration = create_registration(@volunteer)
    login_as(@organization)

    get volunteer_event_url(@event)

    assert_response :success
    assert_select "h2", "Daftar Pendaftar"
    assert_select "h3", registration.volunteer.name
    assert_select "p", text: /#{registration.volunteer.email}/
  end

  test "volunteer can see registration status on dashboard" do
    registration = create_registration(@volunteer)
    registration.update!(status: :accepted)
    login_as(@volunteer)

    get dashboard_url

    assert_response :success
    assert_select "h2", "Pendaftaran Saya"
    assert_select "a[href=?]", volunteer_event_path(@event), text: @event.title
    assert_select "li", text: /Accepted/
  end

  private

  def create_registration(volunteer)
    @event.event_registrations.create!(
      volunteer: volunteer,
      motivation: "Saya ingin memberikan kontribusi terbaik."
    )
  end

  def create_user(name:, email:, role:)
    User.create!(
      name: name,
      email: email,
      password: "password123",
      password_confirmation: "password123",
      role: role
    )
  end

  def event_attributes
    {
      title: "Mengajar Bersama",
      description: "Kegiatan mengajar anak-anak selama sehari.",
      category: "Pendidikan",
      location: "Bandung",
      starts_at: 10.days.from_now.change(usec: 0),
      ends_at: 10.days.from_now.change(usec: 0) + 3.hours,
      registration_deadline: 8.days.from_now.change(usec: 0),
      capacity: 20,
      status: :published
    }
  end

  def login_as(user)
    post login_url, params: {
      session: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
