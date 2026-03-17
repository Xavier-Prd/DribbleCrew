class Program < ApplicationRecord
  LEVELS = [ "Débutant", "Intermédiaire", "Confirmé", "Expert" ]
  belongs_to :user
  belongs_to :team, optional: true # l'équipe qui contient les participants
  has_many :meets, as: :meetable
  validates :level, inclusion: { in: LEVELS }
  validates :goal, presence: true

  # Si pas d'équipe, on est créer une
  before_validation :ensure_team_exists, on: :create

  private
  def ensure_team_exists
    self.team ||= Team.create(number_player: 99)
  end
end
