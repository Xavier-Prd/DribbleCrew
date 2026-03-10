class Court < ApplicationRecord
  has_many :meets
  has_many :victories
  validates :name, :address, :long, :lat, presence: true
end
