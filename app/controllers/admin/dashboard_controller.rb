require "csv"

module Admin
  class DashboardController < BaseController
    def index
      @side = @admin_side
      invites = @side ? Invite.where(side: @side) : Invite.all
      active  = invites.active

      # Per-stage overview: households, people invited (party size), and named guests.
      @stage_rows = StageHelper::ACTIVE_STAGES.map { |stage| stage_summary(stage, invites) }
      @excluded = stage_summary(:skipped, invites)

      @total_households = active.count
      @total_people = active.sum(:party_size).to_i
      @total_named_guests = guests_for(active).count
      @responded_households = active.where.not(responded_at: nil).count

      active_guests = guests_for(active)
      @children_count = active_guests.where(is_child: true).count
      @childcare_count = active_guests.where(needs_childcare: true).count

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
      scope = Invite.where.not(phone: [ nil, "" ]).where(do_not_send: false).order(:name)
      scope = scope_by_side_and_sent(scope)
      payload = scope.map do |invite|
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
      invites = scope_by_side_and_sent(Invite.includes(:guests).order(:name))
      verifier = Rails.application.message_verifier(:rsvp_management)

      csv_data = CSV.generate(headers: true) do |csv|
        csv << [ "Name", "Side", "Stage",
                 "Sent?", "Responded?", "Attending?", "Has Phone?", "Skipped?",
                 "Party Size", "Guests", "Phone", "Email", "Sent Date", "RSVP Link" ]
        invites.each do |invite|
          token = verifier.generate(invite.id, expires_in: 1.year)
          csv << [
            invite.name,
            invite.side,
            StageHelper::STAGE_META.dig(invite.crm_stage, :label),
            invite.invite_sent_at.present? ? "Yes" : "No",
            invite.responded? ? "Yes" : "No",
            invite.responded? ? (invite.attending? ? "Yes" : "No") : nil,
            invite.phone.present? ? "Yes" : "No",
            invite.do_not_send? ? "Yes" : "No",
            invite.party_size,
            invite.guests.size,
            invite.phone,
            invite.no_email? ? "" : invite.email,
            invite.invite_sent_at&.to_date,
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

    def guests_for(invite_relation)
      Guest.where(invite_id: invite_relation.select(:id))
    end

    # Households / people-invited / named-guest counts for one stage.
    def stage_summary(stage, invites)
      rel = invites.for_stage(stage)
      {
        stage: stage,
        households: rel.count,
        people: rel.sum(:party_size).to_i,
        guests: guests_for(rel).count
      }
    end

    # Scope an invite relation by the sticky side (@admin_side) and the sent filter,
    # so exports and the WhatsApp targets can be limited to e.g. groom-side unsent.
    def scope_by_side_and_sent(relation)
      relation = relation.where.not(invite_sent_at: nil)                if params[:filter] == "sent"
      relation = relation.where(invite_sent_at: nil, do_not_send: false) if params[:filter] == "unsent"
      relation = relation.where(do_not_send: true)                     if params[:filter] == "skipped"
      relation = relation.where(side: @admin_side)                     if @admin_side
      relation = relation.merge(Invite.for_stage(params[:stage]))      if params[:stage].present?

      case params[:status]
      when "attending" then relation = relation.where(attending: true)
      when "declined"  then relation = relation.where(attending: false)
      when "responded" then relation = relation.where.not(responded_at: nil)
      when "pending"   then relation = relation.where(responded_at: nil)
      end
      relation
    end

    # Per-event attending/declined/pending RSVP counts, optionally scoped to one side.
    def event_counts_by_side(side)
      scope = Rsvp.joins(guest: :invite).where(invites: { do_not_send: false })
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
