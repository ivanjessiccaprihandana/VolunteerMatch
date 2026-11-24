require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home shows upcoming published events" do
    organization = create_user(role: :organization)
    event = organization.volunteer_events.create!(default_event_attributes(title: "Bersih Pantai"))

    get root_url

    assert_response :success
    assert_select "a[href=?]", volunteer_event_path(event), text: "Bersih Pantai"
  end

  test "privacy and terms pages render" do
    get privacy_url
    assert_response :success
    assert_select "h1", "Kebijakan Privasi"

    get terms_url
    assert_response :success
    assert_select "h1", "Syarat Penggunaan"
  end

  test "health check responds" do
    get rails_health_check_url

    assert_response :success
  end

  test "pages send a content security policy" do
    get root_url

    assert_match "default-src 'self'", response.headers["Content-Security-Policy"]
  end
end
