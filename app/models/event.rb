class Event < ApplicationRecord
  has_many :event_invites, dependent: :destroy
  has_many :invites, through: :event_invites
  has_many :rsvps, dependent: :destroy

  validates :name, presence: true

  def attending_count
    rsvps.where(attending: true).count
  end

  def declined_count
    rsvps.where(attending: false).count
  end

  def pending_count
    rsvps.where(attending: nil).count
  end
end
