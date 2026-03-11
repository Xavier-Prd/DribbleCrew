class ChangeDateColumnInMeets < ActiveRecord::Migration[8.1]
  def change
    change_column :meets, :date, :datetime
  end
end
