module Admin
  class InvitesController < BaseController
    before_action :set_invite, only: [ :show, :edit, :update, :destroy ]

    def index
      @invites = Invite.includes(:guests).order(:name)
      @invites = @invites.where("name ILIKE ? OR email ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
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

    private

    def set_invite
      @invite = Invite.find(params[:id])
    end

    def invite_params
      params.require(:invite).permit(:name, :email,
        guests_attributes: [ :id, :first_name, :last_name, :is_primary, :meal_choice, :dietary_notes, :_destroy ])
    end
  end
end
