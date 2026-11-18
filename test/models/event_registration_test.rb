require "test_helper"

class EventRegistrationTest < ActiveSupport::TestCase
  def setup
    @organization = create_user(
      name: "Organisasi Pendaftaran",
      email: "registration-organization@example.com",
      role: :organization
    )
    @volunteer = create_user(
      name: "Relawan Pendaftar",
      email: "registration-volunteer@example.com",
      role: :volunteer
    )
    @other_volunteer = create_user(
      name: "Relawan Kedua",
      email: "registration-volunteer-two@example.com",
      role: :volunteer
    )
    @event = @organization.volunteer_events.create!(event_attributes)
  end

  test "is valid for a volunteer and an open event" do
    registration = @event.event_registrations.build(
      volunteer: @volunteer,
      motivation: "Saya ingin membantu masyarakat sekitar."
    )

    assert registration.valid?
  end

  test "prevents duplicate registration" do
    create_registration(@volunteer)
    duplicate = @event.event_registrations.build(
      volunteer: @volunteer,
      motivation: "Mencoba mendaftar kembali."
    )

    assert_not duplicate.valid?
    assert duplicate.errors[:volunteer_id].any?
  end

  test "requires a volunteer account" do
    registration = @event.event_registrations.build(
      volunteer: @organization,
      motivation: "Akun organisasi tidak boleh mendaftar."
    )

    assert_not registration.valid?
    assert registration.errors[:volunteer].any?
  end

  test "rejects registration after the deadline" do
    @event.update!(registration_deadline: 1.hour.ago)
    registration = @event.event_registrations.build(
      volunteer: @volunteer,
      motivation: "Pendaftaran sudah terlambat."
    )

    assert_not registration.valid?
    assert registration.errors[:volunteer_event].any?
  end

  test "prevents accepting more volunteers than capacity" do
    @event.update!(capacity: 1)
    first = create_registration(@volunteer)
    second = create_registration(@other_volunteer)

    assert first.update(status: :accepted)
    assert_not second.update(status: :accepted)
    assert second.errors[:status].any?
  end

  private

  def create_registration(volunteer)
    @event.event_registrations.create!(
      volunteer: volunteer,
      motivation: "Saya siap berkontribusi dalam kegiatan ini."
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
      title: "Donasi Buku",
      description: "Mengumpulkan buku untuk taman baca.",
      category: "Pendidikan",
      location: "Jakarta",
      starts_at: 10.days.from_now,
      ends_at: 10.days.from_now + 3.hours,
      registration_deadline: 8.days.from_now,
      capacity: 10,
      status: :published
    }
  end
end
