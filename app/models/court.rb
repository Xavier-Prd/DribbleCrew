class Court < ApplicationRecord
  has_many :meets
  has_many :victories
  has_one_attached :image
  validates :name, :address, presence: true
end
