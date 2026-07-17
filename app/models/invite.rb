class Invite < ApplicationRecord
  has_many :guests, dependent: :destroy
  has_many :event_invites, dependent: :destroy
  has_many :events, through: :event_invites
  has_many :hotel_bookings, dependent: :destroy
  accepts_nested_attributes_for :guests, allow_destroy: true, reject_if: :all_blank

  before_validation :assign_placeholder_email, if: -> { email.blank? }
  before_validation :normalize_phone

  enum :side, { groom: "groom", bride: "bride" }, default: :groom

  validates :name, presence: true

  scope :with_real_email, -> { where.not(email: nil).where.not("email LIKE ?", "no-email-%") }

  def no_email?
    email.blank? || email.start_with?("no-email-")
  end

  after_create :assign_default_events

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

  # Single CRM "stage" for a household (mutually exclusive, priority order).
  def crm_stage
    return :skipped   if do_not_send?
    return :not_sent  if invite_sent_at.nil?
    return :awaiting  if responded_at.nil?

    attending? ? :attending : :declined
  end

  # Relation matching a given stage — same definition as #crm_stage, kept here so
  # the list filter, pipeline counts, and CSV export share one source of truth.
  def self.for_stage(stage)
    case stage.to_s
    when "not_sent"  then where(do_not_send: false, invite_sent_at: nil)
    when "awaiting"  then where(do_not_send: false).where.not(invite_sent_at: nil).where(responded_at: nil)
    when "attending" then where(do_not_send: false, attending: true).where.not(responded_at: nil)
    when "declined"  then where(do_not_send: false, attending: false).where.not(responded_at: nil)
    when "skipped"   then where(do_not_send: true)
    else all
    end
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

  # New invites are attached to the "default" events only (the shared celebrations).
  # Side-specific events such as the bride-side Maiyaan/Haldi are flagged
  # default_invited: false and must be opted into per invite (admin event checkboxes).
  def assign_default_events
    Event.where(default_invited: true).find_each do |event|
      event_invites.find_or_create_by!(event: event)
    end
  end
end
