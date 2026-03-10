class Team < ApplicationRecord
  has_many :programs
  has_many :user_teams
  has_many :users, through: :user_teams
  validates :number_player, presence: true
end
