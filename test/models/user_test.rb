require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @attributes = {
      name: "User Test",
      email: "user@example.com",
      password: "password123",
      password_confirmation: "password123"
    }
  end

  test "is valid with valid attributes" do
    user = User.new(@attributes)

    assert user.valid?
  end

  test "normalizes email before validation" do
    user = User.new(
      @attributes.merge(email: " USER@EXAMPLE.COM ")
    )

    user.valid?

    assert_equal "user@example.com", user.email
  end

  test "does not allow duplicate email" do
    User.create!(@attributes)

    duplicate = User.new(
      @attributes.merge(email: "USER@EXAMPLE.COM")
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:email, :taken)
  end

  test "defaults role to volunteer" do
    user = User.new(@attributes)

    assert user.volunteer?
  end

  test "authenticates the correct password" do
    user = User.create!(@attributes)

    assert user.authenticate("password123")
    assert_not user.authenticate("wrong-password")
  end
end