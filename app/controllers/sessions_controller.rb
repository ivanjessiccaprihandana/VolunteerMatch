class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { rate_limited }

  def new
    redirect_to dashboard_path if logged_in?
  end

  def create
    # authenticate_by takes the same time whether or not the email exists.
    user = User.authenticate_by(
      email: session_params[:email].to_s,
      password: session_params[:password].to_s
    )

    if user.nil?
      flash.now[:alert] = "Email atau password salah."
      render :new, status: :unprocessable_entity
    elsif !user.email_confirmed?
      redirect_to new_email_confirmation_path(email: user.email),
                  alert: "Email Anda belum dikonfirmasi. Cek kotak masuk Anda atau kirim ulang tautan konfirmasi."
    else
      log_in(user)
      redirect_to (user.admin? ? admin_root_path : dashboard_path), notice: "Berhasil masuk."
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Anda telah keluar."
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end
end
