class Collection < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection
  belongs_to :project
  has_many :documents
  has_many :collections
  
  attr_accessible :name, :collection, :collection_id
end
