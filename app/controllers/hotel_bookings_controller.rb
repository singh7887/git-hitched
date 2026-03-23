class HotelBookingsController < ApplicationController
  def new
    @booking = HotelBooking.new(
      check_in: Date.new(2026, 6, 20),
      check_out: Date.new(2026, 6, 22),
      rooms: 1
    )
    @rooms_available = HotelBooking.rooms_available
  end

  def create
    @rooms_available = HotelBooking.rooms_available
    @booking = HotelBooking.new(booking_params)
    @booking.check_in = Date.new(2026, 6, 20)
    @booking.check_out = Date.new(2026, 6, 22)
    @booking.amount_cents = calculate_amount(@booking)

    if @booking.rooms > @rooms_available
      flash.now[:alert] = @rooms_available > 0 ? "Only #{@rooms_available} room(s) available." : "Sorry, all rooms are booked!"
      render :new, status: :unprocessable_entity
      return
    end

    invite = Invite.find_by_email(@booking.email)
    if invite
      @booking.invite = invite
    else
      invite = Invite.create!(name: @booking.guest_name, email: @booking.email)
      @booking.invite = invite
    end

    unless @booking.valid?
      render :new, status: :unprocessable_entity
      return
    end

    @booking.save!

    session = Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      customer_email: @booking.email,
      line_items: [ {
        price_data: {
          currency: @booking.currency,
          unit_amount: @booking.amount_cents,
          product_data: {
            name: "Hotel Room — #{WEDDING[:couple_names_possessive]} Wedding",
            description: "#{@booking.rooms} room(s), #{@booking.nights} night(s): #{@booking.check_in.strftime('%b %d')} – #{@booking.check_out.strftime('%b %d, %Y')}"
          }
        },
        quantity: 1
      } ],
      mode: "payment",
      expires_at: 30.minutes.from_now.to_i,
      success_url: success_hotel_booking_url(@booking) + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cancel_hotel_booking_url(@booking),
      metadata: { hotel_booking_id: @booking.id.to_s }
    )

    @booking.update!(stripe_checkout_session_id: session.id)
    redirect_to session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    @booking&.destroy if @booking&.persisted?
    flash.now[:alert] = "Payment setup failed: #{e.message}"
    @booking = HotelBooking.new(booking_params.merge(check_in: Date.new(2026, 6, 20), check_out: Date.new(2026, 6, 22)))
    render :new, status: :unprocessable_entity
  end

  def success
    @booking = HotelBooking.find(params[:id])

    unless @booking.confirmed?
      checkout_session = Stripe::Checkout::Session.retrieve(params[:session_id]) if params[:session_id].present?

      if checkout_session&.payment_status == "paid"
        @booking.mark_confirmed!(payment_intent_id: checkout_session.payment_intent)
        HotelBookingMailer.confirmation(@booking).deliver_later
        HotelBookingMailer.admin_notification(@booking).deliver_later
      end
    end
  end

  def cancel
    @booking = HotelBooking.find(params[:id])
    @booking.destroy if @booking.status == "pending"
    redirect_to new_hotel_booking_path, notice: "Booking cancelled. You can try again anytime."
  end

  private

  def booking_params
    params.require(:hotel_booking).permit(:guest_name, :email, :email_confirmation, :phone, :rooms, :notes)
  end

  def calculate_amount(booking)
    booking.nights * booking.rooms * HotelBooking::NIGHTLY_RATE_CENTS
  end
end
