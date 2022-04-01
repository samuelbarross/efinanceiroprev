class EmpresasController < ApplicationController
  before_action :set_empresa, only: [:show, :edit, :update, :destroy]
  respond_to :html, :xml, :js
  before_action :authenticate_user!
  
# DEUS SEJA LOUVADO

# GET /empresas
# GET /empresas.xml

def index
  @search = Empresa.search(params[:q])
  
  if params[:q].nil?
    @empresas = Empresa.all
    authorize @empresas
  else
    @empresas = @search.result
    authorize @empresas
  end

  @search.build_condition if @search.conditions.empty?
  @search.build_sort if @search.sorts.empty?
  
  if not params[:Filtro].nil?
    if not params[:Filtro][:id].nil? and params[:Filtro][:id] != ""
      q = SystemControllerQuery.find(params[:Filtro][:id])
      @empresas = @empresas.where(q.query)
    end
  end

  respond_to do |format|
    format.html
    format.pdf {render pdf: "Relatório de Empresa",
      orientation: "Portrait",
      :disposition => "inline",
      :template => "empresas/index.pdf.erb",
      :margin => { :top => 15, :bottom => 15},
      header: {:spacing => 3, html: {template: 'empresas/header.pdf.erb'}, :margin => { top: 0, :bottom => 3}},
      footer: {:spacing => 1,html: {template: 'empresas/footer.pdf.erb'},:margin => {:top => 3,:bottom => 1}}
    }
  end
end


# GET /empresas/1
# GET /empresas/1.xml
def show
  @empresa = Empresa.find(params[:id])
  respond_with  @empresa
end

# GET /empresas/new
# GET /empresas/new.xml
# GET COPY/NEW
# GET /empresas/new?id=1
def new
  if params[:id]
    @empresa =  Empresa.find(params[:id]).dup
  else
    @empresa =  Empresa.new
  end
end

# GET /empresas/1/edit
def edit
  @empresa = Empresa.find(params[:id])
  authorize @empresa
end

# POST /empresas
# POST /empresas.xml

def create
  @empresa = Empresa.new(empresa_params)
    #@empresa.user_id = current_user.id
    respond_to do |format|
      if @empresa.save
        format.html { redirect_to @empresa, notice: 'Empresa foi criado(a) com sucesso.' }
        format.json { render action: 'show', status: :created, location: @empresa }
      else
        format.html { render action: 'new' }
        format.json { render json: @empresa.errors, status: :unprocessable_entity }
      end
    end
  end

# PATCH/PUT /empresas/1
# PATCH/PUT /empresas/1.json
def update
  respond_to do |format|
    if @empresa.update(empresa_params)
    format.html { redirect_to @empresa, notice: 'Empresa foi atualizado(a) com sucesso.' }
    format.json { head :no_content }
  else
    format.html { render action: 'edit' }
    format.json { render json: @empresa.errors, status: :unprocessable_entity }
  end
end
end

def destroy
  @empresa.destroy
  redirect_to empresas_url, notice: 'Empresa foi apagado(a) com sucesso.'
end

private
def set_empresa
  @empresa = Empresa.find(params[:id])
end

def empresa_params
    valores = params.require(:empresa).permit(:cpf_cnpj, :pessoa_fisica, :nome, :caminho_certificado, :senha_certificado)
    valores[:cpf_cnpj].gsub!(".","") if valores[:cpf_cnpj].present?
    valores[:cpf_cnpj].gsub!("-","") if valores[:cpf_cnpj].present?
    valores[:cpf_cnpj].gsub!("/","") if valores[:cpf_cnpj].present?    
    valores
  end
end
