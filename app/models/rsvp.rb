class Rsvp < ApplicationRecord
  belongs_to :guest
  belongs_to :event

  validates :guest_id, uniqueness: { scope: :event_id }
end
