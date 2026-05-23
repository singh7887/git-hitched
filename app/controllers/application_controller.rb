class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  helper_method :page_enabled?

  def page_enabled?(page)
    return true if Rails.env.development? && session[:dev_show_all_pages]
    pages_config.fetch(page.to_s, true)
  end

  def pages_config
    PAGES_CONFIG
  end

  private

  def require_page_enabled!(page)
    redirect_to root_path unless page_enabled?(page)
  end
end
