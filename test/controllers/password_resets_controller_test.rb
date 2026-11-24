require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_user(email: "lupa@example.com")
  end

  test "shows the request form" do
    get new_password_reset_url

    assert_response :success
    assert_select "h1", "Lupa password"
  end

  test "requesting a reset emails a known user" do
    assert_enqueued_emails 1 do
      post password_reset_url, params: { email: " LUPA@example.com " }
    end

    assert_redirected_to login_url
  end

  test "unknown email gets the same answer and no email" do
    assert_no_enqueued_emails do
      post password_reset_url, params: { email: "tidak-ada@example.com" }
    end

    assert_redirected_to login_url
    assert_match "Jika email tersebut terdaftar", flash[:notice]
  end

  test "valid token sets a new password" do
    token = @user.generate_token_for(:password_reset)

    get edit_password_reset_url(token: token)
    assert_response :success

    patch password_reset_url(token: token), params: {
      user: { password: "passwordbaru1", password_confirmation: "passwordbaru1" }
    }

    assert_redirected_to login_url
    assert @user.reload.authenticate("passwordbaru1")
  end

  test "token works only once" do
    token = @user.generate_token_for(:password_reset)

    patch password_reset_url(token: token), params: {
      user: { password: "passwordbaru1", password_confirmation: "passwordbaru1" }
    }
    patch password_reset_url(token: token), params: {
      user: { password: "passwordlain2", password_confirmation: "passwordlain2" }
    }

    assert_redirected_to new_password_reset_url
    assert @user.reload.authenticate("passwordbaru1")
  end

  test "expired token is rejected" do
    token = @user.generate_token_for(:password_reset)

    travel User::PASSWORD_RESET_TTL + 1.minute do
      get edit_password_reset_url(token: token)
    end

    assert_redirected_to new_password_reset_url
  end

  test "blank or mismatched password is rejected" do
    token = @user.generate_token_for(:password_reset)

    patch password_reset_url(token: token), params: {
      user: { password: "", password_confirmation: "" }
    }
    assert_response :unprocessable_entity

    patch password_reset_url(token: token), params: {
      user: { password: "passwordbaru1", password_confirmation: "berbeda123" }
    }
    assert_response :unprocessable_entity
    assert @user.reload.authenticate(TestDataHelpers::PASSWORD)
  end
end
