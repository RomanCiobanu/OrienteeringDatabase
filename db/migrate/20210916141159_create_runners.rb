class CreateRunners < ActiveRecord::Migration[6.1]
  def change
    create_table :runners do |t|
      t.string :name
      t.string :surname
      t.date :dob
      t.references :category
      t.references :club
      t.string :gender

      t.timestamps
    end
  end
end
