class DevController < ApplicationController
  def toggle_pages
    session[:dev_show_all_pages] = !session[:dev_show_all_pages]
    redirect_back fallback_location: root_path
  end
end
