class Court < ApplicationRecord
  has_many :meets
  has_many :victories
  has_one_attached :image
  validates :name, :address, presence: true

  def short_address
    parts = address.to_s.split(", ")
    [ parts[0], parts[1] ].compact.join(", ")
  end
end
