json.array!(@usuario_empresas) do |usuario_empresa|
  json.extract! usuario_empresa, :id, :user_id, :empresa_id
  json.url usuario_empresa_url(usuario_empresa, format: :json)
end
