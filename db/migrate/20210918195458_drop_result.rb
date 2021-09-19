class DropResult < ActiveRecord::Migration[6.1]
  def change
    drop_table :results
  end
end
