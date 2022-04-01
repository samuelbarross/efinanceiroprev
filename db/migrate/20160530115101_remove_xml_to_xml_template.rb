class RemoveXmlToXmlTemplate < ActiveRecord::Migration
	def up
		remove_column :xml_templates, :xml
	end
end
