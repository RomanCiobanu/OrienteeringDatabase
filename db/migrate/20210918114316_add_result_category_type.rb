class AddResultCategoryType < ActiveRecord::Migration[6.1]
  def change
     add_column :results, :category, :references
  end
end
