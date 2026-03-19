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
    victory_points = victories.count * 25

    team_ids = teams.pluck(:id)
    return victory_points if team_ids.empty?

    # Calcul SQL : additionne uniquement le score de l'équipe de l'utilisateur
    # via CASE plutôt que de charger tous les matchs en mémoire Ruby
    team_ids_str = team_ids.map(&:to_i).join(",")
    basket_points = Match.where("blue_team_id IN (?) OR red_team_id IN (?)", team_ids, team_ids)
                         .sum("LEAST(CASE WHEN blue_team_id IN (#{team_ids_str}) THEN COALESCE(blue_team_score, 0) ELSE COALESCE(red_team_score, 0) END * 0.25, 10.0)")

    (victory_points + basket_points).round
  end
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
