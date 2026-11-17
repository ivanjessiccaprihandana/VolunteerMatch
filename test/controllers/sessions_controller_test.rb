require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "Session Test",
      email: "session@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "shows the login form" do
    get login_url

    assert_response :success
    assert_select "h1", "Masuk ke VolunteerMatch"
    assert_select "form[action=?][method=?]", login_path, "post"
  end

  test "logs in with valid credentials" do
    post login_url, params: {
      session: {
        email: " SESSION@EXAMPLE.COM ",
        password: "password123"
      }
    }

    assert_redirected_to dashboard_url

    follow_redirect!

    assert_response :success
    assert_select "h1", "Dashboard"
    assert_select "p", text: /Session Test/
  end

  test "rejects invalid credentials" do
    post login_url, params: {
      session: {
        email: @user.email,
        password: "password-salah"
      }
    }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", "Email atau password salah."
  end

  test "requires login to view the dashboard" do
    get dashboard_url

    assert_redirected_to login_url
    assert_equal "Silakan masuk terlebih dahulu.", flash[:alert]
  end

  test "logs out the current user" do
    post login_url, params: {
      session: {
        email: @user.email,
        password: "password123"
      }
    }

    delete logout_url

    assert_redirected_to login_url
    assert_equal "Anda telah keluar.", flash[:notice]

    get dashboard_url
    assert_redirected_to login_url
  end
end
