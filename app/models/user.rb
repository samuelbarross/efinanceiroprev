class User < ActiveRecord::Base
	enum role: [:normal_user, :admin]  		

	# Include default devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
	         :recoverable, :rememberable, :trackable, :validatable, :lockable

	has_many :xml_templates #, :dependent => :destroy
	has_many :movimentos #, :dependent => :destroy
	has_many :usuario_empresas, :dependent => :destroy
	
	accepts_nested_attributes_for :usuario_empresas, :allow_destroy => true
	
	# after_create :lock_access! 
end
