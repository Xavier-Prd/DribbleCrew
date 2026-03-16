class AddUniqueIndexToUserTeams < ActiveRecord::Migration[8.1]
  def change
    # Supprime les doublons en gardant la ligne avec le plus petit id
    execute <<-SQL
      DELETE FROM user_teams
      WHERE id NOT IN (
        SELECT MIN(id) FROM user_teams GROUP BY user_id, team_id
      )
    SQL
    add_index :user_teams, [:user_id, :team_id], unique: true
  end
end
