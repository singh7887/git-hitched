class RsvpMailer < ApplicationMailer
  def invitation(invite)
    @invite = invite
    @events = invite.events.order(:date, :start_time)
    @manage_url = rsvp_manage_url(token: signed_token(invite))
    mail(to: invite.email, subject: "You're Invited — #{WEDDING[:couple_names_possessive]} Wedding")
  end

  def confirmation(invite)
    @invite = invite
    @guests = invite.guests.order(is_primary: :desc, first_name: :asc)
    @events = invite.events.order(:date, :start_time)
    @manage_url = rsvp_manage_url(token: signed_token(invite))
    mail(to: invite.email, subject: "RSVP Confirmation — #{WEDDING[:couple_names_possessive]} Wedding")
  end

  def update_notification(invite)
    @invite = invite
    @guests = invite.guests.order(is_primary: :desc, first_name: :asc)
    @events = invite.events.order(:date, :start_time)
    @manage_url = rsvp_manage_url(token: signed_token(invite))
    mail(to: invite.email, subject: "RSVP Updated — #{WEDDING[:couple_names_possessive]} Wedding")
  end

  def reminder(invite)
    @invite = invite
    @events = invite.events.order(:date, :start_time)
    @manage_url = rsvp_manage_url(token: signed_token(invite))
    mail(to: invite.email, subject: "We'd love to hear from you — #{WEDDING[:couple_names_possessive]} Wedding")
  end

  private

  def signed_token(invite)
    Rails.application.message_verifier(:rsvp_management).generate(
      invite.id, expires_in: 30.days
    )
  end
end
