class Collection < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection
  has_many :documents
  has_many :collections
  
  attr_accessible :name, :collection, :collection_id
end
