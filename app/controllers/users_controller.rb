class UsersController < ApplicationController
  PUBLIC_ROLES = %w[volunteer organization].freeze

  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { rate_limited }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      UserMailer.with(user: @user).email_confirmation.deliver_later
      redirect_to login_path,
                  notice: "Akun berhasil dibuat. Kami telah mengirim tautan konfirmasi ke #{@user.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user)
          .permit(:name, :email, :password, :password_confirmation)
          .merge(role: public_role)
  end

  # Only volunteer and organization can be chosen at sign-up; anything else
  # (including "admin") falls back to volunteer.
  def public_role
    params.dig(:user, :role).presence_in(PUBLIC_ROLES) || "volunteer"
  end
end
