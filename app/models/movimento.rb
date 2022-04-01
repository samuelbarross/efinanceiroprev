class Movimento < ActiveRecord::Base
	before_save :checar_retorno
	before_destroy :checar_retorno

	belongs_to :xml_template
  	belongs_to :user
	belongs_to :empresa
	
	enum tipo_ambiente: { producao: 1, homologacao: 2 }

	UNRANSACKABLE_ATTRIBUTES = ["user_id", "updated_at", "xml", "arquivo_origem", "arquivo_retorno", "xml_template_id", "empresa_id"]

	def self.ransackable_attributes auth_object = nil
		(column_names - UNRANSACKABLE_ATTRIBUTES) + _ransackers.keys
	end

	def validade_certificado
		emp = Empresa.where(cpf_cnpj: self.empresa.cpf_cnpj).first
		certificado = OpenSSL::X509::Certificate.new(File.read("#{emp.caminho_certificado}/cert.pem"))
		"Validade do certificado: #{certificado.not_after.strftime("%d/%m/%Y")}".upcase
	end

	def id_declarante
		self.arquivo_origem.split(";")[2]
	end

	def checar_retorno
		if self.arquivo_retorno
			self.errors.add(:base, "Arquivo já enviado, não é mais possivel alterar ou remover!")
			false
		end
	end

end
