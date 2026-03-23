class Guest < ApplicationRecord
  belongs_to :invite
  has_many :rsvps, dependent: :destroy

  enum :meal_choice, { tbd: 0, chicken: 1, fish: 2, vegetarian: 3, vegan: 4 }

  scope :adults, -> { where(is_child: false) }
  scope :children, -> { where(is_child: true) }

  validates :first_name, presence: true

  def full_name
    [ first_name, last_name ].map(&:presence).compact.join(" ")
  end

  def rsvp_for(event)
    rsvps.find_by(event: event)
  end
end
