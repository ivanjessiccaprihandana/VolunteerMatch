require "test_helper"

class RegistrationMailerTest < ActionMailer::TestCase
  def setup
    @organization = create_user(name: "Yayasan", email: "org@example.com", role: :organization)
    @volunteer = create_user(name: "Sari", email: "sari@example.com")
    @event = @organization.volunteer_events.create!(default_event_attributes(title: "Bersih Pantai"))
    @registration = @event.event_registrations.create!(volunteer: @volunteer, motivation: "Saya suka pantai")
  end

  test "new registration goes to the organization" do
    mail = RegistrationMailer.with(registration: @registration).new_registration

    assert_equal ["org@example.com"], mail.to
    assert_match "Bersih Pantai", mail.subject
    assert_match "Saya suka pantai", mail.text_part.body.to_s
  end

  test "status change goes to the volunteer" do
    @registration.update!(status: :accepted)

    mail = RegistrationMailer.with(registration: @registration).status_changed

    assert_equal ["sari@example.com"], mail.to
    assert_match "DITERIMA", mail.text_part.body.to_s
  end

  test "event cancellation goes to the volunteer" do
    mail = RegistrationMailer.with(registration: @registration).event_cancelled

    assert_equal ["sari@example.com"], mail.to
    assert_match "dibatalkan", mail.subject.downcase
  end

  test "volunteer cancellation goes to the organization" do
    mail = RegistrationMailer.with(registration: @registration).volunteer_cancelled

    assert_equal ["org@example.com"], mail.to
  end
end
