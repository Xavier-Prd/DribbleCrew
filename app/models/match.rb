class Match < ApplicationRecord
  attr_accessor :match_type
  validates :match_type, presence: true, inclusion: { in: [ 1, 2, 3, 4, 5 ] } # Attribut virtuel pour le type de match (1v1, 3v3, 5v5)
  belongs_to :user
  belongs_to :blue_team, class_name: "Team"
  belongs_to :red_team, class_name: "Team"
  validates :blue_team_score, presence: true
  validates :red_team_score, presence: true
  has_one :meet, as: :meetable, dependent: :destroy
  # Permet de créer le Meet en même temps que le Match
  accepts_nested_attributes_for :meet

  def cancelled?
    cancelled
  end

  # Savoir si le match est fini (la date est passée)
  def finished?
    meet.date < Time.current
  end

  # Savoir si le résultat a été confirmé par l'équipe adverse via QR code
  # Logique : qr_code == "confirmed" après scan réussi
  def confirmed?
    qr_code == "confirmed"
  end

  # Savoir si le match est en attente de confirmation (QR code généré, pas encore scanné)
  # Le payload contient "token|blue|red" (distingué de "confirmed")
  def pending_confirmation?
    qr_code.present? && qr_code != "confirmed"
  end

  # Extrait le token de sécurité depuis le payload "token|blue|red|generator_team"
  def qr_token
    qr_code&.split("|")&.first
  end

  # Extrait le score en attente de l'équipe bleue depuis le payload
  def pending_blue_score
    qr_code&.split("|")&.second&.to_i
  end

  # Extrait le score en attente de l'équipe rouge depuis le payload
  def pending_red_score
    qr_code&.split("|")&.third&.to_i
  end

  # Extrait l'équipe du joueur qui a généré le QR code ("blue" ou "red")
  def pending_generator_team
    qr_code&.split("|")&.[](3)
  end
  # Déterminer l'équipe gagnante
  def winner
    return nil unless blue_team_score.present? && red_team_score.present?
    return blue_team if blue_team_score > red_team_score
    return red_team if red_team_score > blue_team_score
    nil # égalité
  end

  # Vérifier l'équipe gagnante
  def winner?(team)
    winner == team
  end
end
