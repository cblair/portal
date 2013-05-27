class Collection < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection
  has_many :documents
  has_many :collections
  has_ancestry
  
  attr_accessible :name, :collection, :parent_id
end
