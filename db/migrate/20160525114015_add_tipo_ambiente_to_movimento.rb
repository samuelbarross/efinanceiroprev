class AddTipoAmbienteToMovimento < ActiveRecord::Migration
  def change
    add_column :movimentos, :tipo_ambiente, :integer
  end
end
