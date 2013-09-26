class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  has_many :collaborators
  has_many :projects, :through => :collaborators #user owns projects
  has_many :collections
  has_many :documents                 #as owner
  has_many :uploads
  has_and_belongs_to_many :documents  #as collaborators
  has_many :jobs
  has_and_belongs_to_many :roles
  has_many :metaforms
end
