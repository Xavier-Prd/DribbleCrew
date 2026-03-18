class AddDefaultToMatchesScores < ActiveRecord::Migration[8.1]
  def change
    change_column_default :matches, :blue_team_score, 0
    change_column_null :matches, :blue_team_score, false, 0
    change_column_default :matches, :red_team_score, 0
    change_column_null :matches, :red_team_score, false, 0
  end
end
