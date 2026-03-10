class CreateMeets < ActiveRecord::Migration[8.1]
  def change
    create_table :meets do |t|
      t.references :court, null: false, foreign_key: true
      t.references :meetable, polymorphic: true, null: false
      t.date :date
      t.integer :duration

      t.timestamps
    end
  end
end
