class Guest < ApplicationRecord
  belongs_to :invite
  has_many :rsvps, dependent: :destroy

  enum :meal_choice, { tbd: 0, chicken: 1, fish: 2, vegetarian: 3, vegan: 4 }

  scope :adults, -> { where(is_child: false) }
  scope :children, -> { where(is_child: true) }

  validates :first_name, presence: true

  before_validation :normalize_phone
  after_save :sync_phone_to_invite, if: :should_sync_phone_to_invite?

  def full_name
    [ first_name, last_name ].map(&:presence).compact.join(" ")
  end

  def rsvp_for(event)
    rsvps.find_by(event: event)
  end

  private

  # Strip everything but digits so it's stored consistently regardless of input format.
  def normalize_phone
    return if phone.blank?
    digits = phone.gsub(/\D/, "")
    self.phone = digits.presence
  end

  # Sync the primary guest's phone up to the household invite (so the WhatsApp send
  # and RSVP lookup both stay in sync with whoever the contact person is).
  def should_sync_phone_to_invite?
    is_primary? && phone.present? && (saved_change_to_phone? || saved_change_to_is_primary?)
  end

  def sync_phone_to_invite
    invite.update_column(:phone, phone) if invite.phone != phone
  end
end
