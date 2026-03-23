class PagesController < ApplicationController
  before_action :check_page_enabled, except: :style_guide

  def home
  end

  def events
    @events = Event.order(:sort_order)
    @welcome = @events.find { |e| e.id == 1 }
    @ceremony = @events.find { |e| e.id == 2 }
    @reception = @events.find { |e| e.id == 3 }
    @recovery = @events.find { |e| e.id == 4 }
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
