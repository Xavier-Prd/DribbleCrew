class Meet < ApplicationRecord
  DURATIONS = [ 15, 30, 45, 60, 90, 120 ]
  belongs_to :court
  belongs_to :meetable, polymorphic: true
  validates :date, :duration, :meetable, presence: true
  validates :duration, inclusion: { in: DURATIONS }
  # Empêche de créer un meet avec une date déjà passée
  validates :date, comparison: { greater_than: -> { Time.current }, message: "doit être dans le futur" }
end
