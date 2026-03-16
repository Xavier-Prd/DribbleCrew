class Victory < ApplicationRecord
  belongs_to :user
  belongs_to :court
  validates :user, :court, presence: true
  validates :user_id, uniqueness: { scope: :court_id }
end
