class User < ApplicationRecord
  GENDERS= [ "Homme", "Femme", "Non-binaire" ]
  has_one_attached :profile_picture
  has_many :victories
  has_many :programs
  has_many :program_meets, through: :programs, source: :meets
  has_many :match_meets,   through: :matches,  source: :meets
  has_many :user_teams
  has_many :teams, through: :user_teams
  has_many :courts, through: :victories
  # validates :gender, inclusion: { in: GENDERS }
  validates :username, presence: true, uniqueness: true

  def total_points
    victory_points = victories.count * 10

    team_ids = teams.pluck(:id)
    matches = Match.where(blue_team_id: team_ids).or(Match.where(red_team_id: team_ids))
    basket_points = matches.sum do |match|
      if team_ids.include?(match.blue_team_id)
        match.blue_team_score.to_i
      else
        match.red_team_score.to_i
      end
    end

    victory_points + basket_points
  end
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
