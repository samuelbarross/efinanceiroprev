class AddReferencesToMovimento < ActiveRecord::Migration
	def change
   	add_reference :movimentos, :empresa, index: true
  	end
end
