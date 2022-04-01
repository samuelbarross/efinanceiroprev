class UsuarioEmpresa < ActiveRecord::Base
  belongs_to :user
  belongs_to :empresa
end
