class Program < ApplicationRecord
  LEVELS = [ "Debutant", "Intermediate", "Confirmed", "Expert" ]
  belongs_to :user
  has_one :team
  has_many :meets, as: :meetable
  validates :level, inclusion: { in: LEVELS }
  validates :goal, presence: true
end
