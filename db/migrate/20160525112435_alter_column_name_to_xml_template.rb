class AlterColumnNameToXmlTemplate < ActiveRecord::Migration
  def self.up
    rename_column :xml_templates, :url_web_service, :url_web_service_pre_producao
  end
end
