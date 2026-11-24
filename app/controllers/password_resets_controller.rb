class PasswordResetsController < ApplicationController
  rate_limit to: 5, within: 10.minutes, only: %i[create update], with: -> { rate_limited }

  before_action :set_user_by_token, only: %i[edit update]

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s)
    UserMailer.with(user: user).password_reset.deliver_later if user

    # Same answer either way, so the form cannot be used to probe for accounts.
    redirect_to login_path,
                notice: "Jika email tersebut terdaftar, tautan untuk mengatur ulang password telah dikirim."
  end

  def edit
  end

  def update
    if params.dig(:user, :password).blank?
      @user.errors.add(:password, :blank)
      render :edit, status: :unprocessable_entity
    elsif @user.update(password_params)
      # Receiving the reset email proves ownership of the address.
      @user.confirm_email!
      reset_session
      redirect_to login_path, notice: "Password berhasil diubah. Silakan masuk dengan password baru."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @token = params[:token].to_s
    @user = User.find_by_token_for(:password_reset, @token)
    return if @user

    redirect_to new_password_reset_path,
                alert: "Tautan atur ulang password tidak valid atau sudah kedaluwarsa."
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
