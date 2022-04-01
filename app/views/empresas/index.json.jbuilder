json.array!(@empresas) do |empresa|
  json.extract! empresa, :id, :cpf_cnpj, :pessoa_fisica, :nome, :caminho_certificado, :senha_certificado
  json.url empresa_url(empresa, format: :json)
end
