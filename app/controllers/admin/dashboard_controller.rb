require "csv"

module Admin
  class DashboardController < BaseController
    def index
      @side = params[:side] if Invite.sides.key?(params[:side])
      invites = @side ? Invite.where(side: @side) : Invite.all
      guests  = @side ? Guest.joins(:invite).where(invites: { side: @side }) : Guest.all

      @total_invites = invites.count
      @responded_invites = invites.where.not(responded_at: nil).count
      @attending_invites = invites.where(attending: true).count
      @declined_invites = invites.where(attending: false).count
      @total_guests = guests.count
      @children_count = guests.where(is_child: true).count
      @childcare_count = guests.where(needs_childcare: true).count

      @events = Event.order(:date, :start_time)
      @event_counts = event_counts_by_side(@side)
    end

    def export
      redirect_to admin_dashboard_path, notice: "Google Sheets export is not yet configured. Set up credentials in config/google_sheets.yml."
    end

    # Feeds the standalone WhatsApp sender script (tools/whatsapp_sender/).
    # Returns one row per invite WITH a phone, including a fresh 1-year signed RSVP link.
    def whatsapp_targets
      verifier = Rails.application.message_verifier(:rsvp_management)
      payload = Invite.where.not(phone: [ nil, "" ]).where(do_not_send: false).order(:name).map do |invite|
        primary = invite.primary_guest
        first_name = (primary&.first_name.presence) || invite.name.to_s.split(/\s+/).first
        {
          id: invite.id,
          name: invite.name,
          first_name: first_name,
          phone: invite.phone,
          rsvp_link: rsvp_manage_url(token: verifier.generate(invite.id, expires_in: 1.year)),
          sent_at: invite.invite_sent_at&.iso8601
        }
      end
      render json: payload
    end

    def export_links
      invites = Invite.includes(:guests).order(:name)
      verifier = Rails.application.message_verifier(:rsvp_management)

      csv_data = CSV.generate(headers: true) do |csv|
        csv << [ "Name", "Email", "Guests", "Responded", "RSVP Link" ]
        invites.each do |invite|
          token = verifier.generate(invite.id, expires_in: 1.year)
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
      invites = Invite.with_real_email
      invites.each { |i| RsvpMailer.invitation(i).deliver_later }
      redirect_to admin_root_path, notice: "Invitations sent to #{invites.count} invites."
    end

    def send_reminders
      invites = Invite.with_real_email.where(responded_at: nil)
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

    private

    # Per-event attending/declined/pending RSVP counts, optionally scoped to one side.
    def event_counts_by_side(side)
      scope = Rsvp.joins(guest: :invite)
      scope = scope.where(invites: { side: side }) if side
      grouped = scope.group(:event_id, :attending).count

      counts = Hash.new { |h, k| h[k] = { attending: 0, declined: 0, pending: 0 } }
      grouped.each do |(event_id, attending), n|
        key = attending == true ? :attending : (attending == false ? :declined : :pending)
        counts[event_id][key] += n
      end
      counts
    end
  end
end
