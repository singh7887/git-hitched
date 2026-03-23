class EventInvite < ApplicationRecord
  belongs_to :invite
  belongs_to :event

  validates :invite_id, uniqueness: { scope: :event_id }
end
