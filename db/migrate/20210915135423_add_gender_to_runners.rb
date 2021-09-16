class AddGenderToRunners < ActiveRecord::Migration[6.1]
  def change
    add_column :runners, :gender, :string
  end
end
