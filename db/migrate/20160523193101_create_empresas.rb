class CreateEmpresas < ActiveRecord::Migration
  def change
    create_table :empresas do |t|
      t.string :cpf_cnpj, limit: 18
      t.boolean :pessoa_fisica
      t.string :nome, limit: 100
      t.string :caminho_certificado
      t.string :senha_certificado

      t.timestamps
    end
  end
end
