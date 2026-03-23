class DevController < ApplicationController
  skip_before_action :require_invite_code

  def toggle_pages
    session[:dev_show_all_pages] = !session[:dev_show_all_pages]
    redirect_back fallback_location: root_path
  end
end
