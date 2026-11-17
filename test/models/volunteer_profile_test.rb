require "test_helper"

class VolunteerProfileTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      name: "Relawan Test",
      email: "volunteer-profile@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "belongs to one user" do
    profile = VolunteerProfile.new(user: @user, city: "Jakarta")

    assert profile.valid?

    profile.save!

    duplicate = VolunteerProfile.new(user: @user)

    assert_not duplicate.valid?
  end
end
