class StripeWebhooksController < ApplicationController
  skip_before_action :require_invite_code
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret) || ENV["STRIPE_WEBHOOK_SECRET"]

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
    rescue JSON::ParserError
      head :bad_request
      return
    rescue Stripe::SignatureVerificationError
      head :bad_request
      return
    end

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    end

    head :ok
  end

  private

  def handle_checkout_completed(session)
    booking = HotelBooking.find_by(stripe_checkout_session_id: session.id)
    return unless booking
    return if booking.confirmed?

    if session.payment_status == "paid"
      booking.mark_confirmed!(payment_intent_id: session.payment_intent)
      HotelBookingMailer.confirmation(booking).deliver_later
      HotelBookingMailer.admin_notification(booking).deliver_later
    end
  end
end
