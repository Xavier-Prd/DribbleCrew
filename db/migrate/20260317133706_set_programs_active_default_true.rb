class SetProgramsActiveDefaultTrue < ActiveRecord::Migration[8.1]
  def change
    change_column_default :programs, :active, from: nil, to: true
    Program.where(active: nil).update_all(active: true)
  end
end
