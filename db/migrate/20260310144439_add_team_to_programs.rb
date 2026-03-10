class AddTeamToPrograms < ActiveRecord::Migration[8.1]
  def change
    add_reference :programs, :team, null: false, foreign_key: true
  end
end
