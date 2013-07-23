class Project < ActiveRecord::Base
  attr_accessible :name, :pdesc, :user_id
  
  validates :name,		:presence => true, :length => { :minimum => 3 }
  validates :pdesc,		:presence => true, :length => { :minimum => 1 }
  
  #belongs_to :user
  has_many :collaborators
  has_many :users, :through => :collaborators
  belongs_to :project
  has_many :documents
  has_and_belongs_to_many :collections

end
