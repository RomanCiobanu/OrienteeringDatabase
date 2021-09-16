class DropRunners < ActiveRecord::Migration[6.1]
  def change
    drop_table :runners
  end
end
