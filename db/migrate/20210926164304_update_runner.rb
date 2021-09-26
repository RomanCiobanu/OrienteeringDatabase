class UpdateRunner < ActiveRecord::Migration[6.1]
  def change
    change_column_default :runners, :category_id, 11
    change_column_default :runners, :club_id, 48
  end
end
