class CreateRunners < ActiveRecord::Migration[6.1]
  def change
    create_table :runners do |t|
      t.string :name
      t.string :surname
      t.date :dob
      t.references :category, default: 10
      t.references :club, default: 0
      t.string :gender￼

      t.timestamps
    end
  end
end
