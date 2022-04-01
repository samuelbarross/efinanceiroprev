class CreateUsuarioEmpresas < ActiveRecord::Migration
  def change
    create_table :usuario_empresas do |t|
      t.references :user, index: true
      t.references :empresa, index: true

      t.timestamps
    end
  end
end
