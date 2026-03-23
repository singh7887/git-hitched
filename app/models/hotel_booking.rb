class HotelBooking < ApplicationRecord
  belongs_to :invite

  validates :guest_name, :email, :check_in, :check_out, :rooms, :amount_cents, :phone, presence: true
  validates :email, confirmation: true
  validates :rooms, numericality: { greater_than: 0, less_than_or_equal_to: 5 }
  validates :stripe_checkout_session_id, uniqueness: true, allow_nil: true
  validates :phone, format: { with: /\A\+?[\d\s\-().]{7,20}\z/, message: "must be a valid phone number" }
  validate :check_out_after_check_in

  scope :confirmed, -> { where(status: "confirmed") }
  scope :pending, -> { where(status: "pending") }
  scope :refunded, -> { where(status: "refunded") }
  scope :active_pending, -> { pending.where("created_at > ?", 30.minutes.ago) }

  NIGHTLY_RATE_CENTS = 220_00
  TOTAL_ROOMS = 30
  PENDING_TIMEOUT = 30.minutes

  def self.rooms_reserved
    confirmed.sum(:rooms) + active_pending.sum(:rooms)
  end

  def self.rooms_available
    TOTAL_ROOMS - rooms_reserved
  end

  def nights
    return 0 unless check_in && check_out
    (check_out - check_in).to_i
  end

  def confirmation_number
    "WED-#{id.to_s.rjust(4, '0')}"
  end

  def amount_display
    format("$%.2f", amount_cents / 100.0)
  end

  def confirmed?
    status == "confirmed"
  end

  def refunded?
    status == "refunded"
  end

  def mark_confirmed!(payment_intent_id: nil)
    update!(
      status: "confirmed",
      stripe_payment_intent_id: payment_intent_id,
      confirmed_at: Time.current
    )
  end

  def mark_refunded!
    update!(
      status: "refunded",
      refunded_at: Time.current
    )
  end

  private

  def check_out_after_check_in
    return unless check_in && check_out
    errors.add(:check_out, "must be after check-in date") unless check_out > check_in
  end
end
