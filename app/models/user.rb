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
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
