class ConsultasController < ApplicationController
	before_action :authenticate_user!

   # start
	def cadastro_declarante
      @cnpj = params[:cnpj]
      @nome = params[:nome]
      @endereco = params[:endereco]
      @municipio =  params[:municipio]
      @uf = params[:uf]
      @nr_recibo = params[:nr_recibo]
      @id = params[:id]
      @drop_tp_ambiente = params[:tipo_ambiente]
	end

	def consultar_informacoes_cadastrais      
      dados, msg, status = EFinaceiroPrev.consultas(params[:action], params[:txt_cnpj], params[:drop_tp_ambiente])

      respond_to do |format|
         if status == :success
            format.html { redirect_to cadastro_declarante_path(dados), notice: msg }
         else
            format.html { redirect_to cadastro_declarante_path(dados), flash: { error: msg } }
         end
      end  		
	end

   # start
   def informacoes_movimento
      @cnpj = params[:cnpj]
      @drop_situacao_informacao = params[:situacao_informacao]
      @ano_mes_inicial = params[:ano_mes_inicial]
      @ano_mes_final = params[:ano_mes_final]
      @drop_tp_movimento = params[:tipo_movimento]
      @drop_tp_ni = params[:tipo_ni]
      @ni = params[:ni]
      @drop_tp_ambiente = params[:tipo_ambiente]
      @movimentos = []
      params.each do |key, value|
         if value.is_a?(Hash)
            @movimentos.push(value)
         end
      end
   end

   def consultar_informacoes_movimento
      dados, msg, status = EFinaceiroPrev.consultas(params[:action], params[:txt_cnpj], params[:drop_situacao_informacao], params[:txt_ano_mes_inicial], params[:txt_ano_mes_final], params[:drop_tp_movimento], params[:drop_tp_ni], params[:txt_ni], params[:drop_tp_ambiente])

      respond_to do |format|
         if status == :success
            format.html { redirect_to informacoes_movimento_path(dados), notice: msg }
         else
            format.html { redirect_to informacoes_movimento_path(dados), flash: { error: msg } }
         end
      end         
   end

   # start
   def lista_eFinanceira
      @cnpj = params[:cnpj]
      @drop_situacao_financeira = params[:situacao_financeira]
      @data_inicio = params[:data_inicio]
      @data_fim = params[:data_fim]      
      @drop_tp_ambiente = params[:tipo_ambiente]
      @lista = []
      params.each do |key, value|
         if value.is_a?(Hash)
            @lista.push(value)
         end
      end      
   end

   def consultar_lista_eFinanceira
      dados, msg, status = EFinaceiroPrev.consultas(params[:action], params[:txt_cnpj], params[:drop_situacao_financeira], params[:dt_inicio], params[:dt_fim], params[:drop_tp_ambiente])
      respond_to do |format|
         if status == :success
            format.html { redirect_to lista_eFinanceira_path(dados), notice: msg }
         else
            format.html { redirect_to lista_eFinanceira_path(dados), flash: { error: msg } }
         end
      end  
   end

end
