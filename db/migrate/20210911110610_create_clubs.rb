class CreateClubs < ActiveRecord::Migration[6.1]
  def change
    create_table :clubs do |t|
      t.string :name
      t.string :territory
      t.string :representative
      t.string :email
      t.string :phone

      t.timestamps
    end
  end
end
