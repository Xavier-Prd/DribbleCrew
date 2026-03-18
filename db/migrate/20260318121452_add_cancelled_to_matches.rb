class AddCancelledToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :cancelled, :boolean, default: false, null: false
  end
end
