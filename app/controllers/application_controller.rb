class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?

    redirect_to login_path, alert: "Silakan masuk terlebih dahulu."
  end

  def require_organization
    return if current_user&.organization?

    redirect_to dashboard_path, alert: "Fitur ini hanya tersedia untuk organisasi."
  end
end
