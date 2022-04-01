class AddAnoMesCaixaToMovimento < ActiveRecord::Migration
  def change
    add_column :movimentos, :ano_mes_caixa, :string
  end
end
