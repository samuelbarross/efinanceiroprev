class UsuarioEmpresasController < ApplicationController
  before_action :set_usuario_empresa, only: [:show, :edit, :update, :destroy]
  respond_to :html, :xml, :js
  
# DEUS SEJA LOUVADO

# GET /usuario_empresas
# GET /usuario_empresas.xml

# Início da index-------------------------------------------------------------------------------------------
def index
  @search = UsuarioEmpresa.search(params[:q])
  @search.build_condition
  @search.build_condition
  if params[:q].nil?
    @usuario_empresas = UsuarioEmpresa.all
  else
    @usuario_empresas = @search.result
  end

  if not params[:Filtro].nil?
    if not params[:Filtro][:id].nil? and params[:Filtro][:id] != ""
      q = SystemControllerQuery.find(params[:Filtro][:id])
      @usuario_empresas = @usuario_empresas.where(q.query)
    end
  end

  respond_to do |format|
    format.html
    format.pdf {render pdf: "Relatório de UsuarioEmpresa",
      orientation: "Portrait",
      :disposition => "inline",
      :template => "usuario_empresas/index.pdf.erb",
      :margin => { :top => 15, :bottom => 15},
      header: {:spacing => 3, html: {template: 'usuario_empresas/header.pdf.erb'}, :margin => { top: 0, :bottom => 3}},
      footer: {:spacing => 1,html: {template: 'usuario_empresas/footer.pdf.erb'},:margin => {:top => 3,:bottom => 1}}
    }
  end
# --------------------------------------------------------------------------------------------------------
end
# Fim do index  --------------------------------------------------------------------------------------------

# GET /usuario_empresas/1
# GET /usuario_empresas/1.xml
def show
  @usuario_empresa = UsuarioEmpresa.find(params[:id])
  respond_with  @usuario_empresa
end

# GET /usuario_empresas/new
# GET /usuario_empresas/new.xml
# GET COPY/NEW
# GET /usuario_empresas/new?id=1
def new
  if params[:id]
    @usuario_empresa =  UsuarioEmpresa.find(params[:id]).dup
  else
    @usuario_empresa =  UsuarioEmpresa.new
  end
end

# GET /usuario_empresas/1/edit
def edit
  @usuario_empresa = UsuarioEmpresa.find(params[:id])
end

# POST /usuario_empresas
# POST /usuario_empresas.xml

def create
  @usuario_empresa = UsuarioEmpresa.new(usuario_empresa_params)
    #@usuario_empresa.user_id = current_user.id
    respond_to do |format|
      if @usuario_empresa.save
        format.html { redirect_to @usuario_empresa, notice: 'Usuario Empresa foi criado(a) com sucesso.' }
        format.json { render action: 'show', status: :created, location: @usuario_empresa }
      else
        format.html { render action: 'new' }
        format.json { render json: @usuario_empresa.errors, status: :unprocessable_entity }
      end
    end
  end

# PATCH/PUT /usuario_empresas/1
# PATCH/PUT /usuario_empresas/1.json
def update
  respond_to do |format|
    if @usuario_empresa.update(usuario_empresa_params)
    format.html { redirect_to @usuario_empresa, notice: 'Usuario Empresa foi atualizado(a) com sucesso.' }
    format.json { head :no_content }
  else
    format.html { render action: 'edit' }
    format.json { render json: @usuario_empresa.errors, status: :unprocessable_entity }
  end
end
end

def destroy
  @usuario_empresa.destroy
  redirect_to usuario_empresas_url, notice: 'Usuario Empresa foi apagado(a) com sucesso.'
end

private
def set_usuario_empresa
  @usuario_empresa = UsuarioEmpresa.find(params[:id])
end

def usuario_empresa_params
    params.require(:usuario_empresa).permit(:user_id, :empresa_id)
  end
end
