class AddFieldUrlWebServiceProducao < ActiveRecord::Migration
	def change
  		add_column :xml_templates, :url_web_service_producao, :string
  	end
end
