class CreateMovimentos < ActiveRecord::Migration
  def change
    create_table :movimentos do |t|
      t.text :arquivo_origem
      t.text :arquivo_retorno
      t.datetime :data_arquivo_retorno
      t.references :xml_template, index: true
      t.references :user, index: true

      t.timestamps
    end
    add_foreign_key :movimentos, :xml_templates
    add_foreign_key :movimentos, :users
  end
end
