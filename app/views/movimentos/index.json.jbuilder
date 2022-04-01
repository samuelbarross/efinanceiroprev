json.array!(@movimentos) do |movimento|
  json.extract! movimento, :id, :arquivo_origem, :arquivo_retorno, :data_arquivo_retorno, :xml_template_id, :user_id
  json.url movimento_url(movimento, format: :json)
end
