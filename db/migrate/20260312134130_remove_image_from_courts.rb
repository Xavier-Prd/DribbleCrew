class RemoveImageFromCourts < ActiveRecord::Migration[8.1]
  def change
    remove_column :courts, :image, :string
  end
end
