class AddClasaToCompetition < ActiveRecord::Migration[6.1]
  def change
    add_column :competitions, :clasa, :string
  end
end
