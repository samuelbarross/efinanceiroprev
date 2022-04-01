class HomeController < ApplicationController
	before_action :authenticate_user!
	def index
		
		@mainTitle = "Bem-Vindo ao Integrador do E-Financeira"
		@mainDesc = "Esta aplicação visa a comunicação com os web services da receita federal, realizando a integração entre o Sistema Público de Escrituração Digital (Sped) e seu sistema."

	end


  def minor
  end

end
