class Project < ActiveRecord::Base
  attr_accessible :name, :pdesc, :user_id
  
  validates :name,		:presence => true, :length => { :minimum => 3 }
  validates :pdesc,		:presence => true, :length => { :minimum => 1 }
  
  belongs_to :user
  belongs_to :project
  has_many :documents
  has_many :collections
  has_many :projects

end
