# Lets a user permanently delete their own account and personal data.
class AccountsController < ApplicationController
  before_action :require_login

  def edit
  end

  def destroy
    unless current_user.authenticate(params[:password].to_s)
      flash.now[:alert] = "Password salah. Akun tidak dihapus."
      return render :edit, status: :unprocessable_entity
    end

    unless current_user.deletable?
      flash.now[:alert] = "Batalkan dulu kegiatan mendatang yang masih memiliki relawan aktif."
      return render :edit, status: :unprocessable_entity
    end

    current_user.destroy!
    reset_session
    redirect_to root_path, notice: "Akun dan data Anda telah dihapus."
  end
end
