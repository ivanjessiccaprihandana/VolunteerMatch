require "test_helper"

class VolunteerEventTest < ActiveSupport::TestCase
  def setup
    @organization = User.create!(
      name: "Pengelola Kegiatan",
      email: "event-organization@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :organization
    )
    @organization.create_organization_profile!(organization_name: "Pengelola", verified: true)

    @attributes = {
      organization: @organization,
      title: "Bersih Pantai",
      description: "Kegiatan membersihkan pantai bersama.",
      category: "Lingkungan",
      location: "Pantai Ancol",
      starts_at: 2.weeks.from_now,
      ends_at: 2.weeks.from_now + 4.hours,
      registration_deadline: 1.week.from_now,
      capacity: 30,
      status: :published
    }
  end

  test "is valid with complete attributes" do
    event = VolunteerEvent.new(@attributes)

    assert event.valid?
  end

  test "requires an organization account" do
    volunteer = User.create!(
      name: "Relawan",
      email: "event-volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    event = VolunteerEvent.new(@attributes.merge(organization: volunteer))

    assert_not event.valid?
    assert event.errors.of_kind?(:organization, :must_be_organization)
  end

  test "requires valid dates and capacity" do
    event = VolunteerEvent.new(
      @attributes.merge(
        ends_at: @attributes[:starts_at] - 1.hour,
        registration_deadline: @attributes[:starts_at] + 1.hour,
        capacity: 0
      )
    )

    assert_not event.valid?
    assert event.errors[:ends_at].any?
    assert event.errors[:registration_deadline].any?
    assert event.errors[:capacity].any?
  end

  test "searches title and description case insensitively" do
    river_event = VolunteerEvent.create!(
      @attributes.merge(title: "Aksi Bersih Sungai")
    )
    reading_event = VolunteerEvent.create!(
      @attributes.merge(
        title: "Berbagi Buku",
        description: "Mengadakan kelas membaca untuk anak."
      )
    )

    assert_includes VolunteerEvent.matching_text("SUNGAI"), river_event
    assert_includes VolunteerEvent.matching_text("membaca"), reading_event
    assert_not_includes VolunteerEvent.matching_text("sungai"), reading_event
  end

  test "treats search wildcard characters as ordinary text" do
    percentage_event = VolunteerEvent.create!(
      @attributes.merge(title: "100% Peduli Lingkungan")
    )
    ordinary_event = VolunteerEvent.create!(
      @attributes.merge(title: "1000 Pohon")
    )

    results = VolunteerEvent.matching_text("100%")

    assert_includes results, percentage_event
    assert_not_includes results, ordinary_event
  end

  test "filters category location and start date" do
    target_date = 3.weeks.from_now.to_date
    target_start = target_date.in_time_zone + 9.hours
    target_event = VolunteerEvent.create!(
      @attributes.merge(
        category: "Pendidikan",
        location: "Jakarta Selatan",
        starts_at: target_start,
        ends_at: target_start + 3.hours
      )
    )

    results = VolunteerEvent
              .in_category("Pendidikan")
              .in_location("jakarta")
              .starting_on(target_date)

    assert_equal [target_event], results.to_a
  end
end
