class Court < ApplicationRecord
  has_many :meets
  has_many :victories
  validates :name, :address, presence: true
end
