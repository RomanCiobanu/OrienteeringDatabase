class ChangeColumnName < ActiveRecord::Migration[6.1]
  def change
    rename_column :competitions, :type, :distance_type
  end
end
