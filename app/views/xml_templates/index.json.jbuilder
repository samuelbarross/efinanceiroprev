json.array!(@xml_templates) do |xml_template|
  json.extract! xml_template, :id, :evento, :descricao, :xml, :user_id
  json.url xml_template_url(xml_template, format: :json)
end
