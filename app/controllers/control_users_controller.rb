class ControlUsersController < ApplicationController
	before_action :set_control_user, only: [:show, :edit, :update, :destroy]
	before_action :authenticate_user!

	def index
		@control_users = User.all
		authorize @control_users
	end	

	def edit	
		authorize @control_user
	end

	def show
		@usuario_empresas = Empresa.where(id: UsuarioEmpresa.includes(:empresa).where(user_id: params[:id]).map{|f| "#{f.empresa_id}"})
	end

	def update
		respond_to do |format|
		  if @control_user.update(control_user_params)
		    format.html { redirect_to @control_user, notice: 'Usuário was successfully updated.' }
		    format.json { head :no_content }
		  else
		    format.html { render action: 'edit' }
		    format.json { render json: @control_user.errors, status: :unprocessable_entity }
		  end
		end
	end  	

	def destroy
		@control_user.destroy
		respond_to do |format|
		format.html { redirect_to users_url }
		format.json { head :no_content }
		end
	end

	private

		# Use callbacks to share common setup or constraints between actions.
		def set_control_user
		  @control_user = User.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def control_user_params
		  params.require(:user).permit(:id, :role, :email, usuario_empresas_attributes: [:id, :user_id, :empresa_id, :_destroy])
		end

end
