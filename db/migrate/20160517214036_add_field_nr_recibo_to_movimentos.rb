class AddFieldNrReciboToMovimentos < ActiveRecord::Migration
  def change
    add_column :movimentos, :nr_recibo, :string, limit: 50
  end
end
