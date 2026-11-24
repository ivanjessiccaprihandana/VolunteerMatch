class UserMailer < ApplicationMailer
  def email_confirmation
    @user = params[:user]
    @url = email_confirmation_url(token: @user.generate_token_for(:email_confirmation))

    mail to: @user.email, subject: "Konfirmasi email akun VolunteerMatch Anda"
  end

  def password_reset
    @user = params[:user]
    @url = edit_password_reset_url(token: @user.generate_token_for(:password_reset))

    mail to: @user.email, subject: "Atur ulang password VolunteerMatch"
  end
end
