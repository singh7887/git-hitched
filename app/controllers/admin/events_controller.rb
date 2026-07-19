module Admin
  class EventsController < BaseController
    before_action :set_event, only: [ :show, :edit, :update, :destroy ]

    def index
      @events = Event.order(:date, :start_time)
    end

    def show
      # Exclude households that are no longer invited.
      rsvps = @event.rsvps.includes(guest: :invite)
                    .where(guests: { invite_id: Invite.active.select(:id) })
                    .references(:guests).to_a
      @attending_count = rsvps.count { |r| r.attending == true }
      @declined_count  = rsvps.count { |r| r.attending == false }
      @pending_count   = rsvps.count { |r| r.attending.nil? }

      # Group RSVPs by family (invite) for the expandable per-family view.
      @families = rsvps.group_by { |r| r.guest.invite_id }.map do |_invite_id, group|
        invite = group.first.guest.invite
        {
          invite: invite,
          guests: group.sort_by { |r| [ r.guest.is_primary? ? 0 : 1, r.guest.first_name.to_s.downcase ] },
          attending: group.count { |r| r.attending == true },
          declined:  group.count { |r| r.attending == false },
          pending:   group.count { |r| r.attending.nil? }
        }
      end.sort_by { |f| [ -f[:attending], f[:invite].name.to_s.downcase ] }
    end

    def new
      @event = Event.new
    end

    def create
      @event = Event.new(event_params)
      if @event.save
        redirect_to admin_event_path(@event), notice: "Event created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @event.update(event_params)
        redirect_to admin_event_path(@event), notice: "Event updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @event.destroy
      redirect_to admin_events_path, notice: "Event deleted."
    end

    private

    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:name, :subtitle, :sort_order, :default_invited, :date, :start_time, :time_description, :location, :address, :location_url, :maps_url, :attire, :attire_description, :description, :image)
    end
  end
end
