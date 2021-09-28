class CreateResults < ActiveRecord::Migration[6.1]
  def change
    create_table :results do |t|
      t.integer :place
      t.references :runner
      t.integer :time, default: 0
      t.references :category
      t.references :competition

      t.timestamps
    end
  end
end
