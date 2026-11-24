class ApplicationController < ActionController::Base
  helper_method :current_user, :logged_in?

  private

  def current_user
    return unless session[:user_id]

    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def log_in(user)
    reset_session
    session[:user_id] = user.id
  end

  def require_login
    return if logged_in?

    redirect_to login_path, alert: "Silakan masuk terlebih dahulu."
  end

  def require_organization
    return if current_user&.organization?

    redirect_to dashboard_path, alert: "Fitur ini hanya tersedia untuk organisasi."
  end

  def require_volunteer
    return if current_user&.volunteer?

    redirect_to dashboard_path, alert: "Fitur ini hanya tersedia untuk relawan."
  end

  def require_admin
    return if current_user&.admin?

    redirect_to root_path, alert: "Halaman ini hanya untuk admin."
  end

  def rate_limited
    redirect_back fallback_location: root_path,
                  alert: "Terlalu banyak percobaan. Silakan coba lagi beberapa menit lagi."
  end
end
