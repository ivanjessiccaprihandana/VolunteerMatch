require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "volunteer deletes their account with the right password" do
    volunteer = create_user
    login_as(volunteer)

    assert_difference("User.count", -1) do
      delete account_url, params: { password: TestDataHelpers::PASSWORD }
    end

    assert_redirected_to root_url
    get dashboard_url
    assert_redirected_to login_url
  end

  test "wrong password keeps the account" do
    volunteer = create_user
    login_as(volunteer)

    assert_no_difference("User.count") do
      delete account_url, params: { password: "salah-sekali" }
    end

    assert_response :unprocessable_entity
  end

  test "organization with active volunteers on upcoming events cannot delete" do
    organization = create_user(role: :organization)
    event = organization.volunteer_events.create!(default_event_attributes)
    event.event_registrations.create!(volunteer: create_user, motivation: "Ikut")
    login_as(organization)

    assert_no_difference("User.count") do
      delete account_url, params: { password: TestDataHelpers::PASSWORD }
    end

    assert_response :unprocessable_entity
  end

  test "guest is sent to login" do
    get edit_account_url

    assert_redirected_to login_url
  end
end
