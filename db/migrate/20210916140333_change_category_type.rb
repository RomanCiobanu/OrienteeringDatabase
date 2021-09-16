class ChangeCategoryType < ActiveRecord::Migration[6.1]
  def change
     remove_column :runners, :category

  end
end
