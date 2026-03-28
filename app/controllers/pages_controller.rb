class PagesController < ApplicationController
  before_action :check_page_enabled, except: :style_guide

  def home
  end

  def events
    @events = Event.order(:sort_order)
  end

  def travel
  end

  def stay
  end

  def explore
  end

  def attire
  end

  def faq
  end

  def our_story
  end

  def gallery
  end

  def style_guide
    render layout: "style_guide"
  end

  private

  def check_page_enabled
    require_page_enabled!(action_name)
  end
end
