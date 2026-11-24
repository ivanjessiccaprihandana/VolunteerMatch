require "test_helper"

class VolunteerEventLifecycleTest < ActiveSupport::TestCase
  def setup
    @organization = create_user(role: :organization)
  end

  test "unverified organization can save drafts but not publish" do
    unverified = create_user(role: :organization, verified: false)

    draft = unverified.volunteer_events.build(default_event_attributes(status: :draft))
    assert draft.save

    draft.status = :published
    assert_not draft.save
    assert draft.errors.of_kind?(:status, :organization_not_verified)
  end

  test "category must come from the fixed list" do
    event = @organization.volunteer_events.build(default_event_attributes(category: "lingkungan "))

    assert_not event.valid?
    assert event.errors.of_kind?(:category, :inclusion)
  end

  test "new events cannot start in the past" do
    event = @organization.volunteer_events.build(
      default_event_attributes(
        starts_at: 1.day.ago,
        ends_at: 1.day.ago + 2.hours,
        registration_deadline: 2.days.ago
      )
    )

    assert_not event.valid?
    assert event.errors.of_kind?(:starts_at, :must_be_in_future)
  end

  test "capacity cannot drop below accepted volunteers" do
    event = @organization.volunteer_events.create!(default_event_attributes(capacity: 5))
    2.times do
      registration = event.event_registrations.create!(volunteer: create_user, motivation: "Ikut")
      registration.transition_to(:accepted)
    end

    event.capacity = 1
    assert_not event.save
    assert event.errors.of_kind?(:capacity, :below_accepted)

    event.capacity = 2
    assert event.save
  end

  test "cancelling an event emails every active volunteer" do
    event = @organization.volunteer_events.create!(default_event_attributes)
    pending = event.event_registrations.create!(volunteer: create_user, motivation: "Ikut")
    accepted = event.event_registrations.create!(volunteer: create_user, motivation: "Ikut")
    accepted.transition_to(:accepted)
    withdrawn = event.event_registrations.create!(volunteer: create_user, motivation: "Ikut")
    withdrawn.transition_to(:cancelled)
    clear_enqueued_jobs

    assert_enqueued_emails 2 do
      event.update!(status: :cancelled)
    end
    assert pending.reload.pending?
  end

  test "events with registrations are not deletable" do
    event = @organization.volunteer_events.create!(default_event_attributes)
    assert event.deletable?

    event.event_registrations.create!(volunteer: create_user, motivation: "Ikut")
    assert_not event.deletable?
  end

  test "times are interpreted in Jakarta time" do
    assert_equal "Asia/Jakarta", Time.zone.name

    event = @organization.volunteer_events.create!(
      default_event_attributes(
        starts_at: "#{20.days.from_now.to_date.iso8601}T08:00",
        ends_at: "#{20.days.from_now.to_date.iso8601}T12:00",
        registration_deadline: "#{18.days.from_now.to_date.iso8601}T08:00"
      )
    )

    assert_equal 8, event.starts_at.hour
    assert_equal 1, event.starts_at.utc.hour
  end
end
