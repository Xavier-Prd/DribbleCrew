class RemoveUniqueIndexFromVictories < ActiveRecord::Migration[8.1]
  def change
    remove_index :victories, [:user_id, :court_id]
  end
end
