class ChangeColumnTypeTimeTimeToInteger < ActiveRecord::Migration[6.1]
  def change
    change_column :results, :time, :integer
  end
end
