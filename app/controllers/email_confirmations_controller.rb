class EmailConfirmationsController < ApplicationController
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { rate_limited }

  # GET /konfirmasi-email?token=...
  def show
    user = User.find_by_token_for(:email_confirmation, params[:token].to_s)

    if user
      user.confirm_email!
      redirect_to login_path, notice: "Email berhasil dikonfirmasi. Silakan masuk."
    else
      redirect_to new_email_confirmation_path,
                  alert: "Tautan konfirmasi tidak valid atau sudah kedaluwarsa."
    end
  end

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s)
    UserMailer.with(user: user).email_confirmation.deliver_later if user && !user.email_confirmed?

    # Same answer either way, so the form cannot be used to probe for accounts.
    redirect_to login_path,
                notice: "Jika email tersebut terdaftar dan belum dikonfirmasi, tautan baru telah dikirim."
  end
end
