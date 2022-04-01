class CreateXmlTemplates < ActiveRecord::Migration
  def change
    create_table :xml_templates do |t|
      t.string :evento
      t.string :descricao
      t.text :xml
      t.references :user, index: true

      t.timestamps
    end

    add_foreign_key :xml_templates, :users

  end
end
