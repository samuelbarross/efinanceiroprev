class XmlTemplatesController < ApplicationController
  before_action :set_xml_template, only: [:show, :edit, :update, :destroy]
  respond_to :html, :xml, :js
  before_action :authenticate_user!
  
# DEUS SEJA LOUVADO

# GET /xml_templates
# GET /xml_templates.xml

def index
  @search = XmlTemplate.search(params[:q])

  if params[:q].nil?
    @xml_templates = XmlTemplate.all
    authorize @xml_templates
  else
    @xml_templates = @search.result
    authorize @xml_templates
  end

  @search.build_condition if @search.conditions.empty?
  @search.build_sort if @search.sorts.empty?

  if not params[:Filtro].nil?
    if not params[:Filtro][:id].nil? and params[:Filtro][:id] != ""
      q = SystemControllerQuery.find(params[:Filtro][:id])
      @xml_templates = @xml_templates.where(q.query)
    end
  end

  respond_to do |format|
    format.html
    format.pdf {render pdf: "Relatório de XmlTemplate",
      orientation: "Portrait",
      :disposition => "inline",
      :template => "xml_templates/index.pdf.erb",
      :margin => { :top => 15, :bottom => 15},
      header: {:spacing => 3, html: {template: 'xml_templates/header.pdf.erb'}, :margin => { top: 0, :bottom => 3}},
      footer: {:spacing => 1,html: {template: 'xml_templates/footer.pdf.erb'},:margin => {:top => 3,:bottom => 1}}
    }
  end

end


# GET /xml_templates/1
# GET /xml_templates/1.xml
def show
  @xml_template = XmlTemplate.find(params[:id])
  respond_with  @xml_template
end

# GET /xml_templates/new
# GET /xml_templates/new.xml
# GET COPY/NEW
# GET /xml_templates/new?id=1
def new
  if params[:id]
    @xml_template =  XmlTemplate.find(params[:id]).dup
  else
    @xml_template =  XmlTemplate.new
  end
end

# GET /xml_templates/1/edit
def edit
  @xml_template = XmlTemplate.find(params[:id])
  authorize @xml_template
end

# POST /xml_templates
# POST /xml_templates.xml

def create
  @xml_template = XmlTemplate.new(xml_template_params)
  @xml_template.user_id = current_user.id
    respond_to do |format|
      if @xml_template.save
        format.html { redirect_to @xml_template, notice: 'A configuração foi criado(a) com sucesso.' }
        format.json { render action: 'show', status: :created, location: @xml_template }
      else
        format.html { render action: 'new' }
        format.json { render json: @xml_template.errors, status: :unprocessable_entity }
      end
    end
  end

# PATCH/PUT /xml_templates/1
# PATCH/PUT /xml_templates/1.json
def update
  respond_to do |format|
    if @xml_template.update(xml_template_params)
    format.html { redirect_to @xml_template, notice: 'A configuração foi atualizado(a) com sucesso.' }
    format.json { head :no_content }
  else
    format.html { render action: 'edit' }
    format.json { render json: @xml_template.errors, status: :unprocessable_entity }
  end
end
end

def destroy
  @xml_template.destroy
  redirect_to xml_templates_url, notice: 'A configuração foi apagado(a) com sucesso.'
end

private
def set_xml_template
  @xml_template = XmlTemplate.find(params[:id])
end

def xml_template_params
    params.require(:xml_template).permit(:evento, :descricao, :user_id, :url_web_service_pre_producao, :url_web_service_producao)
  end
end
