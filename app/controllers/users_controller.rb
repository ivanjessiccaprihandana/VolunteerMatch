class UsersController < ApplicationController
  PUBLIC_ROLES = %w[volunteer organization].freeze

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to login_path, notice: "Akun berhasil dibuat. Silakan masuk."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    permitted_params = params.require(:user).permit(
      :name,
      :email,
      :password,
      :password_confirmation,
      :role
    )

    permitted_params[:role] = "volunteer" unless PUBLIC_ROLES.include?(permitted_params[:role])
    permitted_params
  end
end
