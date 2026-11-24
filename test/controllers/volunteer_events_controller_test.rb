require "test_helper"

class VolunteerEventsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @organization = create_user(
      name: "Organisasi Peduli",
      email: "events-organization@example.com",
      role: :organization
    )
    @other_organization = create_user(
      name: "Organisasi Lain",
      email: "events-other-organization@example.com",
      role: :organization
    )
    @volunteer = create_user(
      name: "Relawan Kegiatan",
      email: "events-volunteer@example.com",
      role: :volunteer
    )
  end

  test "public index displays published upcoming events but not drafts" do
    published = create_event(title: "Bersihkan Pantai", status: :published)
    draft = create_event(title: "Kegiatan Rahasia", status: :draft)

    get volunteer_events_url

    assert_response :success
    assert_select "a[href=?]", volunteer_event_path(published), text: published.title
    assert_select "a[href=?]", volunteer_event_path(draft), count: 0
  end

  test "public can view published event but cannot view draft" do
    published = create_event(status: :published)
    draft = create_event(title: "Masih Dirancang", status: :draft)

    get volunteer_event_url(published)
    assert_response :success

    get volunteer_event_url(draft)
    assert_redirected_to volunteer_events_url
  end

  test "public can search event title and description" do
    matching = create_event(title: "Aksi Bersih Sungai")
    other = create_event(
      title: "Mengajar Bersama",
      description: "Kelas membaca untuk anak-anak."
    )

    get volunteer_events_url, params: { query: "sungai" }

    assert_response :success
    assert_select "a[href=?]", volunteer_event_path(matching), text: matching.title
    assert_select "a[href=?]", volunteer_event_path(other), count: 0
  end

  test "public can combine category and location filters" do
    matching = create_event(
      title: "Kelas Akhir Pekan",
      category: "Pendidikan",
      location: "Jakarta Selatan"
    )
    other = create_event(
      title: "Tanam Pohon Kota",
      category: "Lingkungan",
      location: "Jakarta Selatan"
    )

    get volunteer_events_url, params: {
      category: "Pendidikan",
      location: "jakarta"
    }

    assert_response :success
    assert_select "a[href=?]", volunteer_event_path(matching), text: matching.title
    assert_select "a[href=?]", volunteer_event_path(other), count: 0
  end

  test "public can filter events by start date" do
    target_date = 12.days.from_now.to_date
    target_start = target_date.in_time_zone + 9.hours
    matching = create_event(
      title: "Kegiatan Hari Pilihan",
      starts_at: target_start,
      ends_at: target_start + 3.hours
    )
    other = create_event(title: "Kegiatan Hari Lain")

    get volunteer_events_url, params: { date: target_date.iso8601 }

    assert_response :success
    assert_select "a[href=?]", volunteer_event_path(matching), text: matching.title
    assert_select "a[href=?]", volunteer_event_path(other), count: 0
  end

  test "organization can create an event" do
    login_as(@organization)

    assert_difference("VolunteerEvent.count", 1) do
      post volunteer_events_url, params: { volunteer_event: event_attributes }
    end

    event = VolunteerEvent.order(:created_at).last
    assert_redirected_to volunteer_event_url(event)
    assert_equal @organization, event.organization
  end

  test "volunteer cannot create an event" do
    login_as(@volunteer)

    assert_no_difference("VolunteerEvent.count") do
      post volunteer_events_url, params: { volunteer_event: event_attributes }
    end

    assert_redirected_to dashboard_url
  end

  test "organization can update its own event" do
    event = create_event
    login_as(@organization)

    patch volunteer_event_url(event), params: {
      volunteer_event: { title: "Judul Kegiatan Baru" }
    }

    assert_redirected_to volunteer_event_url(event)
    assert_equal "Judul Kegiatan Baru", event.reload.title
  end

  test "organization cannot edit another organizations event" do
    event = create_event
    login_as(@other_organization)

    assert_raises(ActiveRecord::RecordNotFound) do
      get edit_volunteer_event_url(event)
    end
  end

  test "organization can delete its own event" do
    event = create_event
    login_as(@organization)

    assert_difference("VolunteerEvent.count", -1) do
      delete volunteer_event_url(event)
    end

    assert_redirected_to volunteer_events_url
  end

  private


  def create_event(overrides = {})
    @organization.volunteer_events.create!(event_attributes.merge(overrides))
  end

  def event_attributes
    {
      title: "Penanaman Pohon",
      description: "Menanam pohon bersama warga sekitar.",
      category: "Lingkungan",
      location: "Bandung",
      starts_at: 10.days.from_now.change(usec: 0),
      ends_at: 10.days.from_now.change(usec: 0) + 3.hours,
      registration_deadline: 8.days.from_now.change(usec: 0),
      capacity: 30,
      status: :published
    }
  end

end
