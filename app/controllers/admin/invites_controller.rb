module Admin
  class InvitesController < BaseController
    skip_before_action :verify_authenticity_token, only: [ :mark_sent, :unmark_sent, :mark_skip, :unmark_skip ]
    before_action :set_invite, only: [ :show, :edit, :update, :destroy, :mark_sent, :unmark_sent, :mark_skip, :unmark_skip ]

    def index
      @invites = Invite.includes(:guests).order(:name)
      @invites = @invites.where("name ILIKE ? OR email ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
      @invites = @invites.where.not(invite_sent_at: nil)               if params[:filter] == "sent"
      @invites = @invites.where(invite_sent_at: nil, do_not_send: false) if params[:filter] == "unsent"
      @invites = @invites.where(do_not_send: true)                     if params[:filter] == "skipped"
      @sent_count = Invite.where.not(invite_sent_at: nil).count
      @skip_count = Invite.where(do_not_send: true).count
      @total_count = Invite.count
    end

    def show
      @guests = @invite.guests.order(:last_name, :first_name)
      @events = @invite.events.order(:date)
    end

    def new
      @invite = Invite.new
      @invite.guests.build(is_primary: true)
    end

    def create
      @invite = Invite.new(invite_params)
      if @invite.save
        redirect_to admin_invite_path(@invite), notice: "Invite created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @invite.guests.build # one empty slot so admin can add a new guest in-form
    end

    def update
      if @invite.update(invite_params)
        redirect_to admin_invite_path(@invite), notice: "Invite updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @invite.destroy
      redirect_to admin_invites_path, notice: "Invite deleted."
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

    def set_invite
      @invite = Invite.find(params[:id])
    end

    def invite_params
      params.require(:invite).permit(:name, :email, :phone, :party_size, :notes,
        guests_attributes: [ :id, :first_name, :last_name, :phone, :is_primary, :is_child, :age, :meal_choice, :dietary_notes, :_destroy ])
    end
  end
end
