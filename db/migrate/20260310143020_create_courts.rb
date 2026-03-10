class CreateCourts < ActiveRecord::Migration[8.1]
  def change
    create_table :courts do |t|
      t.string :name
      t.string :image
      t.string :address
      t.float :long
      t.float :lat

      t.timestamps
    end
  end
end
