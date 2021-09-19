class CreateResult < ActiveRecord::Migration[6.1]
  def change
    create_table :results do |t|
      t.string :place
      t.string :integer
      t.references :runner
      t.time :time
      t.references :category
      t.references :competition

      t.timestamps
    end
  end
end