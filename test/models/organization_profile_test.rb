require "test_helper"

class OrganizationProfileTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      name: "Pengelola Organisasi",
      email: "organization-profile@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: :organization
    )
  end

  test "requires an organization name" do
    profile = OrganizationProfile.new(user: @user)

    assert_not profile.valid?
    assert profile.errors.of_kind?(:organization_name, :blank)
  end

  test "is unverified by default" do
    profile = OrganizationProfile.create!(
      user: @user,
      organization_name: "Organisasi Test"
    )

    assert_not profile.verified?
  end
end
