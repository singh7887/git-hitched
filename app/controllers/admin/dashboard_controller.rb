require "csv"

module Admin
  class DashboardController < BaseController
    def index
      @total_invites = Invite.count
      @responded_invites = Invite.where.not(responded_at: nil).count
      @total_guests = Guest.count
      @events = Event.order(:date, :start_time)
      @meal_counts = Guest.where.not(meal_choice: :tbd).group(:meal_choice).count
      @attending_invites = Invite.where(attending: true).count
      @declined_invites = Invite.where(attending: false).count
      @children_count = Guest.children.count
      @childcare_count = Guest.where(needs_childcare: true).count
    end

    def export
      redirect_to admin_dashboard_path, notice: "Google Sheets export is not yet configured. Set up credentials in config/google_sheets.yml."
    end

    def export_links
      invites = Invite.includes(:guests).order(:name)
      verifier = Rails.application.message_verifier(:rsvp_management)

      csv_data = CSV.generate(headers: true) do |csv|
        csv << [ "Name", "Email", "Guests", "Responded", "RSVP Link" ]
        invites.each do |invite|
          token = verifier.generate(invite.id, expires_in: 30.days)
          csv << [
            invite.name,
            invite.no_email? ? "" : invite.email,
            invite.guests.size,
            invite.responded? ? "Yes" : "No",
            rsvp_manage_url(token: token)
          ]
        end
      end

      send_data csv_data, filename: "rsvp-links-#{Date.today}.csv", type: "text/csv", disposition: "attachment"
    end

    def send_invitations
      invites = Invite.where.not(email: nil)
      invites.each { |i| RsvpMailer.invitation(i).deliver_later }
      redirect_to admin_root_path, notice: "Invitations sent to #{invites.count} invites."
    end

    def send_reminders
      invites = Invite.where(responded_at: nil).where.not(email: nil)
      invites.each { |i| RsvpMailer.reminder(i).deliver_later }
      redirect_to admin_root_path, notice: "Reminders sent to #{invites.count} invites."
    end

    def send_test_email
      test_address = "benensonmacfadyen@gmail.com"
      invite = Invite.joins(:event_invites).distinct.first

      unless invite
        redirect_to admin_root_path, alert: "No invite with events found to use as test data."
        return
      end

      email_type = params[:email_type]
      mail = case email_type
      when "invitation"          then RsvpMailer.invitation(invite)
      when "confirmation"        then RsvpMailer.confirmation(invite)
      when "update_notification" then RsvpMailer.update_notification(invite)
      when "reminder"            then RsvpMailer.reminder(invite)
      else
               redirect_to admin_root_path, alert: "Unknown email type: #{email_type}"
               return
      end

      mail.to = [ test_address ]
      mail.deliver_now

      redirect_to admin_root_path, notice: "Test #{email_type.humanize} email sent to #{test_address}."
    end
  end
end
