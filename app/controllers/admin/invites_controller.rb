module Admin
  class InvitesController < BaseController
    skip_before_action :verify_authenticity_token, only: [ :mark_sent, :unmark_sent, :mark_skip, :unmark_skip ]
    before_action :set_invite, only: [ :show, :edit, :update, :destroy, :mark_sent, :unmark_sent, :mark_skip, :unmark_skip ]

    def index
      @invites = filtered_invites
      @sent_count = Invite.where.not(invite_sent_at: nil).count
      @skip_count = Invite.where(do_not_send: true).count
      @total_count = Invite.count
    end

    # Add/edit phone numbers for many invites at once (scoped by the active
    # side + sent filters, so you can target e.g. groom-side, not-yet-sent).
    def bulk_phones
      @invites = filtered_invites
    end

    def update_phones
      updated = 0
      (params[:invites] || {}).each do |id, attrs|
        invite = Invite.find_by(id: id)
        next unless invite

        new_phone = attrs[:phone].to_s.strip.presence
        next if invite.phone.to_s == new_phone.to_s

        invite.update(phone: new_phone)
        updated += 1
      end
      redirect_to bulk_phones_admin_invites_path(filter: params[:filter], q: params[:q]),
        notice: "Updated #{updated} phone number(s)."
    end

    def show
      @guests = @invite.guests.order(is_primary: :desc, last_name: :asc, first_name: :asc)
      @events = @invite.events.order(:sort_order, :date)
      @rsvp_for = Rsvp.where(guest_id: @guests.map(&:id)).each_with_object({}) do |rsvp, map|
        map[[ rsvp.guest_id, rsvp.event_id ]] = rsvp
      end
    end

    def new
      @invite = Invite.new
      @invite.guests.build(is_primary: true)
    end

    def create
      @invite = Invite.new(invite_params)
      if @invite.save
        sync_event_assignments
        redirect_to admin_invite_path(@invite), notice: "Household created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @invite.guests.build # one empty slot so admin can add a new guest in-form
    end

    def update
      if @invite.update(invite_params)
        sync_event_assignments
        redirect_to admin_invite_path(@invite), notice: "Household updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @invite.destroy
      redirect_to admin_invites_path, notice: "Household deleted."
    end

    def mark_sent
      @invite.update!(invite_sent_at: Time.current)
      respond_to do |format|
        format.html { redirect_back fallback_location: admin_invites_path, notice: "Marked '#{@invite.name}' as sent." }
        format.json { render json: { id: @invite.id, sent_at: @invite.invite_sent_at.iso8601 } }
      end
    end

    def unmark_sent
      @invite.update!(invite_sent_at: nil)
      respond_to do |format|
        format.html { redirect_back fallback_location: admin_invites_path, notice: "Marked '#{@invite.name}' as not sent." }
        format.json { render json: { id: @invite.id, sent_at: nil } }
      end
    end

    def mark_skip
      @invite.update!(do_not_send: true)
      respond_to do |format|
        format.html { redirect_back fallback_location: admin_invites_path, notice: "'#{@invite.name}' will be skipped by the WhatsApp send." }
        format.json { render json: { id: @invite.id, do_not_send: true } }
      end
    end

    def unmark_skip
      @invite.update!(do_not_send: false)
      respond_to do |format|
        format.html { redirect_back fallback_location: admin_invites_path, notice: "'#{@invite.name}' is back in the send list." }
        format.json { render json: { id: @invite.id, do_not_send: false } }
      end
    end

    private

    # Shared list scoping for the invites index and bulk-phones page: search (q),
    # sent/unsent/skipped filter, and the sticky bride/groom side (@admin_side).
    def filtered_invites
      scope = Invite.includes(:guests).order(:name)
      scope = scope.where("name ILIKE ? OR email ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
      scope = scope.where.not(invite_sent_at: nil)                if params[:filter] == "sent"
      scope = scope.where(invite_sent_at: nil, do_not_send: false) if params[:filter] == "unsent"
      scope = scope.where(do_not_send: true)                     if params[:filter] == "skipped"
      scope = scope.where(side: @admin_side)                     if @admin_side

      case params[:status]
      when "attending" then scope = scope.where(attending: true)
      when "declined"  then scope = scope.where(attending: false)
      when "responded" then scope = scope.where.not(responded_at: nil)
      when "pending"   then scope = scope.where(responded_at: nil)
      end
      scope
    end

    def set_invite
      @invite = Invite.find(params[:id])
    end

    # The form submits event_ids[] checkboxes (plus a blank hidden field so the key is
    # always present). Replace this invite's event assignments to match the selection.
    # When the param is absent entirely (e.g. API/import), the model's default-event
    # assignment is left untouched.
    def sync_event_assignments
      return unless params.key?(:event_ids)

      selected = Array(params[:event_ids]).reject(&:blank?).map(&:to_i)
      @invite.event_ids = Event.where(id: selected).pluck(:id)
    end

    def invite_params
      params.require(:invite).permit(:name, :email, :phone, :party_size, :notes, :side,
        guests_attributes: [ :id, :first_name, :last_name, :phone, :is_primary, :is_child, :age, :meal_choice, :dietary_notes, :_destroy ])
    end
  end
end
