class AddFieldUrlWebServiceToXmlTemplates < ActiveRecord::Migration
  def change
    add_column :xml_templates, :url_web_service, :string
  end
end
