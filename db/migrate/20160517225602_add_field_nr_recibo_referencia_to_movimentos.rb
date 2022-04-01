class AddFieldNrReciboReferenciaToMovimentos < ActiveRecord::Migration
  def change
    add_column :movimentos, :nr_recibo_referencia, :string, limit: 50
  end
end
