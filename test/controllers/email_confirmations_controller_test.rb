require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_user(email: "unconfirmed@example.com", confirmed: false)
  end

  test "unconfirmed user cannot log in and is offered a new link" do
    login_as(@user)

    assert_redirected_to new_email_confirmation_url(email: @user.email)

    get dashboard_url
    assert_redirected_to login_url
  end

  test "valid token confirms the email" do
    token = @user.generate_token_for(:email_confirmation)

    get email_confirmation_url(token: token)

    assert_redirected_to login_url
    assert @user.reload.email_confirmed?

    login_as(@user)
    assert_redirected_to dashboard_url
  end

  test "invalid token is rejected" do
    get email_confirmation_url(token: "bukan-token")

    assert_redirected_to new_email_confirmation_url
    assert_not @user.reload.email_confirmed?
  end

  test "token expires" do
    token = @user.generate_token_for(:email_confirmation)

    travel User::EMAIL_CONFIRMATION_TTL + 1.minute do
      get email_confirmation_url(token: token)
    end

    assert_not @user.reload.email_confirmed?
  end

  test "resending sends an email only to unconfirmed accounts" do
    confirmed = create_user(email: "confirmed@example.com")

    assert_enqueued_emails 1 do
      post new_email_confirmation_url, params: { email: @user.email }
    end

    assert_no_enqueued_emails do
      post new_email_confirmation_url, params: { email: confirmed.email }
      post new_email_confirmation_url, params: { email: "tidak-ada@example.com" }
    end

    assert_redirected_to login_url
  end
end
