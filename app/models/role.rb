class Role < ActiveRecord::Base
  attr_accessible :name
  
  validates :name, :presence => true, :length => { :minimum => 1 }
  
  has_and_belongs_to_many :users
end
