class Match < ApplicationRecord
  belongs_to :user
  belongs_to :blue_team, class_name: "Team"
  belongs_to :red_team, class_name: "Team"
  has_one :meet, as: :meetable
  # Permet de créer le Meet en même temps que le Match
  accepts_nested_attributes_for :meet

  # Savoir si le match est fini (la date est passée)
  def finished?
    meet.date < Time.current
  end

  # Savoir si le résultat a été confirmé par l'équipe adverse via QR code
  # Logique : scores réels présents ET qr_code effacé (nil) = confirmation faite
  def confirmed?
    blue_team_score.present? && red_team_score.present? && qr_code.nil?
  end

  # Savoir si le match est en attente de confirmation (QR code généré, pas encore scanné)
  # Les scores ne sont pas encore dans blue_team_score/red_team_score à ce stade
  def pending_confirmation?
    qr_code.present?
  end

  # Extrait le token de sécurité depuis le payload "token|blue|red"
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
