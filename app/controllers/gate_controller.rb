class GateController < ApplicationController
  skip_before_action :require_invite_code

  def new
  end

  def create
    if params[:code].present? && params[:code].strip.casecmp?(ENV.fetch("WEDDING_INVITE_CODE", "SOLSTICE"))
      session[:site_authenticated] = true
      redirect_to root_path
    else
      flash.now[:alert] = "Invalid invite code. Please try again."
      render :new, status: :unprocessable_entity
    end
  end
end
