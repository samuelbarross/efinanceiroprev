class MovimentosController < ApplicationController
    before_action :set_movimento, only: [:show, :edit, :update, :destroy]
    respond_to :html, :xml, :js
    before_action :authenticate_user!

    def index
        empresas = Empresa.where(id: UsuarioEmpresa.includes(:empresa).where(user_id: current_user.id).map{|f| "#{f.empresa_id}"}).map{|f| "#{f.id}"}

        # Bizu: esse order é fundamental para o datatable agrupar corretamente
        # --------------------------------------------------------------------
        movimentos = Movimento.where(empresa_id: empresas).where("datediff(Now(), created_at) <= 60").limit(500).order("empresa_id, id")
        # movimentos = Movimento.where(empresa_id: empresas).limit(500).order("empresa_id, id")

        # No search tem que pesquisar em todos
        # -------------------------------------
        buscar_movimentos = Movimento.where(empresa_id: empresas).order("empresa_id, id") if params[:q].presence

        @search = params[:q].presence ? buscar_movimentos.search(params[:q]) : movimentos.search(params[:q])

        if params[:q].nil?
            @movimentos = movimentos
        else
            @movimentos = @search.result
        end

        @search.build_condition if @search.conditions.empty?
        @search.build_sort if @search.sorts.empty?
    end

    # Importa somente as empresas que o usuário tem acesso.
    def importar_txt
        msg, salvo = EFinaceiroPrev.importar_txt(params[:arquivo_origem].tempfile, current_user.id, params[:arquivo_origem].original_filename)

        respond_to do |format|
            if salvo == :success
                format.html { redirect_to movimentos_path, notice: msg }
            else
                format.html { redirect_to movimentos_path, flash: { error: msg } }
            end
        end
    end

    def processar_evento
        @movimento = Movimento.find(params[:id])

        # Array
        dados = @movimento.arquivo_origem.split(';')

        # Posição fixa no array  que sempre estará qual o nome do evento que será utilizado
        case dados[1]
        when 'evtCadDeclarante'
            @msg, @status = EFinaceiroPrev.cadastro_declarante(dados, @movimento)
        when 'evtAberturaeFinanceira'
            @msg, @status = EFinaceiroPrev.abertura_efinanceira(dados, @movimento)
        when 'evtMovOpFin'
            @msg, @status = EFinaceiroPrev.movimento_operacao_financeira(dados, @movimento)
        when 'evtExclusao'
            @msg, @status = EFinaceiroPrev.exlcusao(dados, @movimento)
        when 'evtFechamentoeFinanceira'
            # Para esse evento em especial se for colocar novos campo "PADRÕES" tem que por depois da posição 10 do array dados.
            # Informações referente a fechamento_mes por no final do array dados.

            # Removendo sujeira do enter "\r\n"
            remove_enter = dados[dados.length - 1]

            if remove_enter.eql?("\r\n") or remove_enter.eql?("\n")
                dados.delete(remove_enter)
            end

            aux = dados[11..dados.length - 1]

            # Quebrando o array em grupos
            numero_de_grupos = aux.count / 2
            fechamento_meses = aux.in_groups(numero_de_grupos)

            @msg, @status = EFinaceiroPrev.fechamento_financeira(dados, @movimento, fechamento_meses)
        when 'evtExclusaoeFinanceira'
            @msg, @status = EFinaceiroPrev.exlcusao_financeira(dados, @movimento)
        else
            @msg = 'Evento não localizado, comunique ao Administrador.'
            @status = :error
        end

        @movimento.reload

        respond_to do |format|
            format.js
            if @status == :success
                @enviado = true
            else
                @enviado = false
            end
        end
    end

    def download_xml
        @movimento = Movimento.find(params[:id])
        respond_to do |format|
            format.js
        end
    end

    def download_xml_envio
        xml_envio, evento = EFinaceiroPrev.xml_envio(params[:id])
        send_data xml_envio, disposition: 'attachment', filename: "#{evento}.xml"
    end

    def xml
        movimento = Movimento.find(params[:id])
        send_data movimento.arquivo_retorno, disposition: 'attachment', filename: "#{movimento.xml_template.evento}-#{movimento.data_arquivo_retorno.strftime("%d/%m/%Y")}.xml"
    end

    def download_txt
        empresas = Empresa.where(id: UsuarioEmpresa.includes(:empresa).where(user_id: current_user.id).map{|f| "#{f.empresa_id}"}).map{|f| "#{f.id}"}
        movimentos = Movimento.where(empresa_id: empresas).where.not(arquivo_retorno: nil)

        data = ""
        data_envio = ""

        movimentos.each_index do |x|
            if movimentos[x].data_arquivo_retorno.to_s.blank?
                data_envio = movimentos[x].data_arquivo_retorno.to_s
            else
                data_envio = movimentos[x].data_arquivo_retorno.strftime("%Y-%m-%d")
            end

            data << movimentos[x].arquivo_origem.split(";")[2] << ";" << movimentos[x].xml_template.evento << ";" << data_envio << ";" << movimentos[x].nr_recibo.to_s << ";" << movimentos[x].empresa.cpf_cnpj << ";\r\n"
        end
        send_data data, filename: "movimentos-#{Time.new.strftime("%Y-%m-%d")}.txt", type: "text/plain", disposition: 'attachment'
    end

    def enviar_marcados
        Movimento.transaction do
            unless params[:flag_envio].nil? then
                params[:flag_envio].each do |check|
                    movimento = Movimento.find(check)
                    dados = movimento.arquivo_origem.split(";")
                    case dados[1]
                    when "evtMovOpFin"
                        @msg, @status  = EFinaceiroPrev.movimento_operacao_financeira(dados, movimento)
                        if @status == :error
                            @msg << ", PAROU NO Id: #{check}"
                        end
                        @msg, status = check, :success
                    end
                end
            else
                @msg = "Selecione algum movimento na página abaixo."
                @status = :error
            end
        end

        respond_to do |format|
            if @status == :success
                format.html { redirect_to movimentos_path, notice: @msg }
            else
                format.html { redirect_to movimentos_path, flash: { error: @msg } }
            end
        end
    end

    def deleta_selecionados
        raise
    end

    def print_tela
        empresas = Empresa.where(id: UsuarioEmpresa.includes(:empresa).where(user_id: current_user.id).map{|f| "#{f.empresa_id}"}).map{|f| "#{f.id}"}
        movimentos = Movimento.where(empresa_id: empresas).order("empresa_id, id") # Bizu: esse order é fundamental para o datatable agrupar corretamente

        @search = movimentos.search(params[:q])

        if params[:q].nil?
            @movimentos = movimentos
        else
            @movimentos = @search.result
        end

        respond_to do |format|
            format.pdf {
                render pdf: "Impressão dos Movimentos",
                :show_as_html => false,
                :page_size => "A4",
                :orientation => "Landscape",
                :disposition => "inline",
                :template => "movimentos/print_tela.pdf.erb",
                :margin => {:top => 30, :bottom => 30},
                header: { html: { template: 'movimentos/header.pdf.erb'}, :spacing => 5},
                footer: { html: { template: 'movimentos/footer.pdf.erb'}}
            }
        end
    end

    def show
        @movimento = Movimento.find(params[:id])
        respond_with  @movimento
    end

    def new
        if params[:id]
            @movimento =  Movimento.find(params[:id]).dup
        else
            @movimento =  Movimento.new
        end
    end

    def edit
        @movimento = Movimento.find(params[:id])
    end

    def create
        @movimento = Movimento.new(movimento_params)
        # @movimento.user_id = current_user.id
        respond_to do |format|
            if @movimento.save
                format.html { redirect_to @movimento, notice: 'Movimento foi criado(a) com sucesso.' }
                format.json { render action: 'show', status: :created, location: @movimento }
            else
                format.html { render action: 'new' }
                format.json { render json: @movimento.errors, status: :unprocessable_entity }
            end
        end
    end

    def update
        respond_to do |format|
            if @movimento.update(movimento_params)
                format.html { redirect_to @movimento, notice: 'Movimento foi atualizado(a) com sucesso.' }
                format.json { head :no_content }
            else
                format.html { render action: 'edit' }
                format.json { render json: @movimento.errors, status: :unprocessable_entity }
            end
        end
    end

    def destroy
        if @movimento.destroy
            redirect_to movimentos_url, notice: 'Movimento foi apagado(a) com sucesso.'
        else
            redirect_to movimentos_url, flash: { error: @movimento.errors.full_messages.join(", ") }
        end
    end

    private
    def set_movimento
        @movimento = Movimento.find(params[:id])
    end

    def movimento_params
        valores = params.require(:movimento).permit(:arquivo_origem, :arquivo_retorno, :data_arquivo_retorno, :xml_template_id, :user_id)
    end
end
