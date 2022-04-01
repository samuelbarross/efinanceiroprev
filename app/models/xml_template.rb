class XmlTemplate < ActiveRecord::Base
	belongs_to :user
	has_many :xml_templates

	validates :evento, :descricao, :user_id, :url_web_service_pre_producao, :url_web_service_producao, presence: true
	validates :evento, uniqueness: true

	UNRANSACKABLE_ATTRIBUTES = ["user_id", "updated_at", "id", "descricao", "url_web_service_pre_producao", "url_web_service_producao"]  

	def self.ransackable_attributes auth_object = nil
		(column_names - UNRANSACKABLE_ATTRIBUTES) + _ransackers.keys
	end
end
