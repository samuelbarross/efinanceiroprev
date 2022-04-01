class Empresa < ActiveRecord::Base
	has_many :movimentos
	has_many :usuario_empresas, :dependent => :destroy

	validates :cpf_cnpj, :nome, :caminho_certificado, :senha_certificado, presence: true
	validates :cpf_cnpj, uniqueness: true

	validates :cpf_cnpj, cpf_or_cnpj: true

	UNRANSACKABLE_ATTRIBUTES = ["created_at", "updated_at", "caminho_certificado", "senha_certificado", "pessoa_fisica", "id"]  

	def self.ransackable_attributes auth_object = nil
		(column_names - UNRANSACKABLE_ATTRIBUTES) + _ransackers.keys
	end

end
