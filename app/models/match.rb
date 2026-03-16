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
  # Logique : scores présents ET qr_code effacé (nil) = confirmation faite
  def confirmed?
    blue_team_score.present? && red_team_score.present? && qr_code.nil?
  end

  # Savoir si le match est en attente de confirmation (scores soumis, QR code pas encore scanné)
  def pending_confirmation?
    blue_team_score.present? && red_team_score.present? && qr_code.present?
  end
  # Déterminer l'équipe gagnante
  def winner
  end

  # Vérifier l'équipe gagnante
  def winner?(team)
    winner == team
  end
end
