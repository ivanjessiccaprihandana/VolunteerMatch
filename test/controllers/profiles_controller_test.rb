require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @volunteer = User.create!(
      name: "Relawan Profil",
      email: "profile-volunteer@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    @organization = User.create!(
      name: "Pengelola Organisasi",
      email: "profile-organization@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :organization
    )
  end

  test "redirects guests to login" do
    get profile_url

    assert_redirected_to login_url
  end

  test "creates and updates a volunteer profile" do
    login_as(@volunteer)

    assert_difference("VolunteerProfile.count", 1) do
      patch profile_url, params: {
        volunteer_profile: {
          phone: "081234567890",
          city: "Jakarta",
          skills: "Desain, fotografi",
          availability: "Akhir pekan",
          bio: "Relawan lingkungan"
        }
      }
    end

    assert_redirected_to profile_url
    assert_equal "Jakarta", @volunteer.reload.volunteer_profile.city

    get profile_url

    assert_response :success
    assert_select "h1", "Profil Relawan"
  end

  test "creates an organization profile without allowing self verification" do
    login_as(@organization)

    assert_difference("OrganizationProfile.count", 1) do
      patch profile_url, params: {
        organization_profile: {
          organization_name: "Peduli Lingkungan",
          phone: "0211234567",
          city: "Bandung",
          website: "https://example.com",
          description: "Komunitas lingkungan",
          verified: true
        }
      }
    end

    profile = @organization.reload.organization_profile

    assert_redirected_to profile_url
    assert_equal "Peduli Lingkungan", profile.organization_name
    assert_not profile.verified?
  end

  test "renders errors for an invalid organization profile" do
    login_as(@organization)

    assert_no_difference("OrganizationProfile.count") do
      patch profile_url, params: {
        organization_profile: {
          organization_name: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "section li"
  end

  private

  def login_as(user)
    post login_url, params: {
      session: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
