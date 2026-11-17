class ProfilesController < ApplicationController
  before_action :require_login
  before_action :require_profile_role

  def show
    @profile = current_profile
  end

  def edit
    @profile = current_profile
  end

  def update
    @profile = current_profile

    if @profile.update(profile_params)
      redirect_to profile_path, notice: "Profil berhasil diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def current_profile
    if current_user.volunteer?
      current_user.volunteer_profile || current_user.build_volunteer_profile
    else
      current_user.organization_profile || current_user.build_organization_profile
    end
  end

  def profile_params
    if current_user.volunteer?
      params.require(:volunteer_profile).permit(
        :phone,
        :city,
        :bio,
        :skills,
        :availability
      )
    else
      params.require(:organization_profile).permit(
        :organization_name,
        :phone,
        :city,
        :description,
        :website
      )
    end
  end

  def require_profile_role
    return if current_user&.volunteer? || current_user&.organization?

    redirect_to dashboard_path, alert: "Role ini tidak memiliki profil publik."
  end
end
