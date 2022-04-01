class AddForeingKeyToMovimento < ActiveRecord::Migration
	def change
  		add_foreign_key :movimentos, :empresas, column: :empresa_id
  	end
end
