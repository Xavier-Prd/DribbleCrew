class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :red_team, null: false, foreign_key: { to_table: :teams }
      t.references :blue_team, null: false, foreign_key: { to_table: :teams }
      t.integer :blue_team_score
      t.integer :red_team_score

      t.timestamps
    end
  end
end
