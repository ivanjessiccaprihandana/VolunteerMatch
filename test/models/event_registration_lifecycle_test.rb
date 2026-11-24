require "test_helper"

class EventRegistrationLifecycleTest < ActiveSupport::TestCase
  def setup
    @organization = create_user(role: :organization)
    @volunteer = create_user
    @event = @organization.volunteer_events.create!(default_event_attributes(capacity: 1))
  end

  test "volunteer can register again after cancelling" do
    first = @event.event_registrations.create!(volunteer: @volunteer, motivation: "Pertama")
    first.transition_to(:cancelled)

    again = @event.event_registrations.build(volunteer: @volunteer, motivation: "Kedua")

    assert again.save
  end

  test "database still blocks two active registrations" do
    @event.event_registrations.create!(volunteer: @volunteer, motivation: "Pertama")
    duplicate = @event.event_registrations.build(volunteer: @volunteer, motivation: "Kedua")

    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save(validate: false) }
  end

  test "transition_to refuses to overfill capacity" do
    first = @event.event_registrations.create!(volunteer: @volunteer, motivation: "Ikut")
    second = @event.event_registrations.create!(volunteer: create_user, motivation: "Ikut")

    assert first.transition_to(:accepted)
    assert_not second.transition_to(:accepted)
    assert second.reload.pending?
  end

  test "transition_to locks the event row" do
    registration = @event.event_registrations.create!(volunteer: @volunteer, motivation: "Ikut")
    statements = []
    callback = ->(*, payload) { statements << payload[:sql] }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      registration.transition_to(:accepted)
    end

    assert statements.any? { |sql| sql.include?("FOR UPDATE") }
  end

  test "registration cannot be cancelled after the event started" do
    registration = @event.event_registrations.create!(volunteer: @volunteer, motivation: "Ikut")
    assert registration.cancellable?

    travel_to @event.starts_at + 1.minute do
      assert_not registration.reload.cancellable?
    end
  end

  test "notifications are sent for each step" do
    registration = @event.event_registrations.create!(volunteer: @volunteer, motivation: "Ikut")
    assert_enqueued_email_with RegistrationMailer, :new_registration, params: { registration: registration }

    assert_enqueued_email_with RegistrationMailer, :status_changed, params: { registration: registration } do
      registration.transition_to(:accepted)
    end

    assert_enqueued_email_with RegistrationMailer, :volunteer_cancelled, params: { registration: registration } do
      registration.transition_to(:cancelled)
    end
  end
end
