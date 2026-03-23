module Admin
  class EventsController < BaseController
    before_action :set_event, only: [ :show, :edit, :update, :destroy ]

    def index
      @events = Event.order(:date, :start_time)
    end

    def show
      @attending = @event.rsvps.where(attending: true).includes(guest: :household)
      @declined = @event.rsvps.where(attending: false).includes(guest: :household)
      @pending = @event.rsvps.where(attending: nil).includes(guest: :household)
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
      params.require(:event).permit(:name, :subtitle, :sort_order, :date, :start_time, :time_description, :location, :address, :location_url, :maps_url, :attire, :attire_description, :description, :image)
    end
  end
end
