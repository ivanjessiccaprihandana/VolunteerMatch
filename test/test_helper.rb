ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module TestDataHelpers
  PASSWORD = "password123".freeze

  # Confirmed by default, and organizations are verified by default, because
  # most tests are about what happens after onboarding.
  def create_user(name: "Pengguna Uji", email: nil, role: :volunteer, confirmed: true, verified: true)
    user = User.create!(
      name: name,
      email: email || "user-#{SecureRandom.hex(4)}@example.com",
      password: PASSWORD,
      password_confirmation: PASSWORD,
      role: role,
      email_confirmed_at: (Time.current if confirmed)
    )

    if user.organization? && verified
      user.create_organization_profile!(organization_name: name, verified: true)
    end

    user
  end

  def default_event_attributes(overrides = {})
    starts_at = 10.days.from_now.change(usec: 0)

    {
      title: "Penanaman Pohon",
      description: "Menanam pohon bersama warga sekitar.",
      category: "Lingkungan",
      location: "Bandung",
      starts_at: starts_at,
      ends_at: starts_at + 3.hours,
      registration_deadline: starts_at - 2.days,
      capacity: 30,
      status: :published
    }.merge(overrides)
  end
end

class ActiveSupport::TestCase
  include TestDataHelpers
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  # Keep fixtures sequential on Windows. Parallel fixture loading can cause
  # PostgreSQL connection and transaction errors once the suite exceeds the
  # Rails parallelization threshold.

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all
end

class ActionDispatch::IntegrationTest
  def login_as(user, password: TestDataHelpers::PASSWORD)
    post login_url, params: { session: { email: user.email, password: password } }
  end
end
