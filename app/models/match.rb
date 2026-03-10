class Match < ApplicationRecord
  belongs_to :user
  belongs_to :blue_team, class_name: "Team"
  belongs_to :red_team, class_name: "Team"
  has_one :meet, as: :meetable
end
