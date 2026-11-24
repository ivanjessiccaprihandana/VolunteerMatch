require "test_helper"

class Admin::OrganizationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create_user(name: "Admin", role: :admin)
    @organization = create_user(name: "Org Baru", role: :organization, verified: false)
    @organization.create_organization_profile!(organization_name: "Yayasan Baru")
  end

  test "non-admins cannot open the admin area" do
    login_as(create_user)
    get admin_organizations_url
    assert_redirected_to root_url

    login_as(@organization)
    patch admin_organization_url(@organization, verified: true)
    assert_redirected_to root_url
    assert_not @organization.organization_profile.reload.verified?
  end

  test "admin lands on the admin area after login and sees pending organizations" do
    login_as(@admin)
    assert_redirected_to admin_root_url

    get admin_organizations_url

    assert_response :success
    assert_select "h3", "Yayasan Baru"
  end

  test "admin verifies and unverifies an organization" do
    login_as(@admin)

    patch admin_organization_url(@organization, verified: true)
    assert @organization.organization_profile.reload.verified?

    patch admin_organization_url(@organization, verified: false)
    assert_not @organization.organization_profile.reload.verified?
  end

  test "organization without profile cannot be verified" do
    bare = create_user(role: :organization, verified: false)
    login_as(@admin)

    patch admin_organization_url(bare, verified: true)

    assert_redirected_to admin_organizations_url
    assert_nil bare.reload.organization_profile
  end
end
