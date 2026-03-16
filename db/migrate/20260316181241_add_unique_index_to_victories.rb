class AddUniqueIndexToVictories < ActiveRecord::Migration[8.1]
  def change
    execute <<-SQL
      DELETE FROM victories
      WHERE id NOT IN (
        SELECT MIN(id) FROM victories GROUP BY user_id, court_id
      )
    SQL
    add_index :victories, [:user_id, :court_id], unique: true
  end
end
