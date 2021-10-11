class UpdateResult < ActiveRecord::Migration[6.1]
  def change
    change_column_default :runners, :category_id, from: 11, to: 10
  end
end
