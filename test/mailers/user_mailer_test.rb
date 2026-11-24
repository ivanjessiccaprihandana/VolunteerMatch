require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "email confirmation contains a working link" do
    user = create_user(email: "baru@example.com", confirmed: false)

    mail = UserMailer.with(user: user).email_confirmation

    assert_equal ["baru@example.com"], mail.to
    assert_match "Konfirmasi", mail.subject
    token = mail.text_part.body.to_s[/token=([^\s"]+)/, 1]
    assert_equal user, User.find_by_token_for(:email_confirmation, CGI.unescape(token))
  end

  test "password reset contains a working link" do
    user = create_user(email: "reset@example.com")

    mail = UserMailer.with(user: user).password_reset

    assert_equal ["reset@example.com"], mail.to
    token = mail.html_part.body.to_s[/token=([^\s"&]+)/, 1]
    assert_equal user, User.find_by_token_for(:password_reset, CGI.unescape(token))
  end
end
