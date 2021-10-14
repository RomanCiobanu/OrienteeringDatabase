class CreateGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :groups do |t|
      t.string :name
      t.string :clasa
      t.float :rang
      t.references :competition

      t.timestamps
    end
  end
end
