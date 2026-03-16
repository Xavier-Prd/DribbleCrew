class Team < ApplicationRecord
  has_many :programs
  has_many :user_teams
  has_many :users, through: :user_teams
  validates :number_player, presence: true, numericality: { greater_than_or_equal_to: 1, message: "doit être au minimum 1 (1v1)" }
end
