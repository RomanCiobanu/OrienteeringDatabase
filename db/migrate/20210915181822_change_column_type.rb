class ChangeColumnType < ActiveRecord::Migration[6.1]
  def change
    change_column :results, :place, :integer
    remove_column :results, :integer
  end
end
