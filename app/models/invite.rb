class Invite < ApplicationRecord
  has_many :guests, dependent: :destroy
  has_many :event_invites, dependent: :destroy
  has_many :events, through: :event_invites
  has_many :hotel_bookings, dependent: :destroy
  accepts_nested_attributes_for :guests, allow_destroy: true

  before_validation :assign_placeholder_email, if: -> { email.blank? }

  validates :name, presence: true

  def no_email?
    email.blank? || email.start_with?("no-email-")
  end

  after_create :assign_all_events

  def self.find_by_email(query)
    where("LOWER(email) = LOWER(?)", query.strip).first
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

  def assign_all_events
    Event.find_each do |event|
      event_invites.find_or_create_by!(event: event)
    end
  end
end
