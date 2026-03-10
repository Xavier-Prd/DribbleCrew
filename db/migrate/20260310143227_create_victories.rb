class CreateVictories < ActiveRecord::Migration[8.1]
  def change
    create_table :victories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :court, null: false, foreign_key: true

      t.timestamps
    end
  end
end
