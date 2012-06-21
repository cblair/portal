class Collection < ActiveRecord::Base
  belongs_to :user
  has_many :documents
  
  attr_accessible :name, :collection_id
end
