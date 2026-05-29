class Invite < ApplicationRecord
  has_many :guests, dependent: :destroy
  has_many :event_invites, dependent: :destroy
  has_many :events, through: :event_invites
  has_many :hotel_bookings, dependent: :destroy
  accepts_nested_attributes_for :guests, allow_destroy: true, reject_if: :all_blank

  before_validation :assign_placeholder_email, if: -> { email.blank? }
  before_validation :normalize_phone

  validates :name, presence: true

  scope :with_real_email, -> { where.not(email: nil).where.not("email LIKE ?", "no-email-%") }

  def no_email?
    email.blank? || email.start_with?("no-email-")
  end

  after_create :assign_all_events

  def self.find_by_email(query)
    where("LOWER(email) = LOWER(?)", query.strip).first
  end

  # Match on the last 10 digits so guests can enter their number in any format.
  def self.find_by_phone(query)
    digits = query.to_s.gsub(/\D/, "")
    return nil if digits.length < 10

    where("phone IS NOT NULL AND phone <> '' AND RIGHT(phone, 10) = ?", digits.last(10)).first
  end

  def responded?
    responded_at.present?
  end

  def primary_guest
    guests.find_by(is_primary: true)
  end

  private

  def assign_placeholder_email
    self.email = "no-email-#{SecureRandom.hex(8)}@placeholder.invalid"
  end

  # Strip everything but digits so phone-lookup matches regardless of input format.
  def normalize_phone
    return if phone.blank?
    digits = phone.gsub(/\D/, "")
    self.phone = digits.presence
  end

  def assign_all_events
    Event.find_each do |event|
      event_invites.find_or_create_by!(event: event)
    end
  end
end
