class UpdateResult < ActiveRecord::Migration[6.1]
  def change
    change_column_default :results, :time, 0
    remove_column :results, :integer
  end
end
