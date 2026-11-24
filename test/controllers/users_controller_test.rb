require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "shows the registration form" do
    get new_user_url

    assert_response :success
    assert_select "h1", "Buat Akun VolunteerMatch"
    assert_select "form[action=?][method=?]", users_path, "post"
  end

  test "creates a volunteer with valid data" do
    assert_enqueued_emails 1 do
      assert_difference("User.count", 1) do
        post users_url, params: {
          user: {
            name: "Relawan Test",
            email: " NEW@EXAMPLE.COM ",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end
    end

    user = User.order(:created_at).last

    assert_redirected_to login_url
    assert_match "tautan konfirmasi", flash[:notice]
    assert_equal "new@example.com", user.email
    assert user.volunteer?
    assert user.authenticate("password123")
    assert_not user.email_confirmed?
  end

  test "creates an organization account" do
    assert_difference("User.count", 1) do
      post users_url, params: {
        user: {
          name: "Pengelola Organisasi",
          email: "organization@example.com",
          role: "organization",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert User.order(:created_at).last.organization?
  end

  test "does not create a user with invalid data" do
    assert_no_difference("User.count") do
      post users_url, params: {
        user: {
          name: "",
          email: "email-salah",
          password: "pendek",
          password_confirmation: "berbeda"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "section li"
  end

  test "does not allow public registration as admin" do
    assert_difference("User.count", 1) do
      post users_url, params: {
        user: {
          name: "Admin Palsu",
          email: "fake-admin@example.com",
          password: "password123",
          password_confirmation: "password123",
          role: "admin"
        }
      }
    end

    assert User.order(:created_at).last.volunteer?
  end
end
