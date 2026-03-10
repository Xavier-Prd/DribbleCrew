class Meet < ApplicationRecord
  DURATIONS = [ 15, 30, 45, 60, 90, 120 ]
  belongs_to :court
  belongs_to :meetable, polymorphic: true
  validates :date, :duration, :meetable, presence: true
  validates :duration, inclusion: { in: DURATIONS }
end
