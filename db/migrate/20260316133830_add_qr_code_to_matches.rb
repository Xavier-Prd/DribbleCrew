class AddQrCodeToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :qr_code, :string
  end
end
