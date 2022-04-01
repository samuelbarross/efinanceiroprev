class AddReferencesToUsuarioEmpresa < ActiveRecord::Migration
	def change
		add_foreign_key :usuario_empresas, :users, column: :user_id
  		add_foreign_key :usuario_empresas, :empresas, column: :empresa_id
  end
end
