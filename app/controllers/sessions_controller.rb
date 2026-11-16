class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if logged_in?
  end

  def create
    user = User.find_by(email: session_params[:email].to_s.strip.downcase)

    if user&.authenticate(session_params[:password])
      reset_session
      session[:user_id] = user.id

      redirect_to dashboard_path, notice: "Berhasil masuk."
    else
      flash.now[:alert] = "Email atau password salah."
      render :new, status: :unprocessable_entity
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
