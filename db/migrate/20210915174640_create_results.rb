class CreateResults < ActiveRecord::Migration[6.1]
  def change
    create_table :results do |t|
      t.integer :place
      t.references :runner
      t.integer :time, default: 0
      t.references :category, default: 0
      t.references :group, default: 0

      t.timestamps
    end
  end
end
