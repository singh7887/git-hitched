class Recommendation < ApplicationRecord
  validates :name, presence: true

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(:sort_order, :name) }
end
