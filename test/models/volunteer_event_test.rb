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
    assert_includes event.errors[:organization], "must use an organization account"
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
end
