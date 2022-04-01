class AlterCpfCnpjToEmpresa < ActiveRecord::Migration
def up
    change_table :empresas do |t|
	   t.change :cpf_cnpj, :string, limit: 14
    end	
  end
end