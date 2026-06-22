class PagesController < ApplicationController
  before_action :check_page_enabled, except: :style_guide

  def home
  end

  def events
    # When the visitor arrived through their personal RSVP/manage link we know which
    # household they are, so show only the events they're invited to. Otherwise the
    # public page shows the full schedule.
    @scoped_invite = current_rsvp_invite
    @events = (@scoped_invite&.events || Event.all).order(:sort_order)
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

  # The invite identified during the RSVP flow, if any (and still present).
  def current_rsvp_invite
    return @current_rsvp_invite if defined?(@current_rsvp_invite)

    id = session[:rsvp_invite_id]
    @current_rsvp_invite = id && Invite.find_by(id: id)
  end
end
