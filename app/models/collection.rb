class Collection < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection
  belongs_to :project
  has_many :documents
  has_many :collections
  has_and_belongs_to_many :projects
  has_and_belongs_to_many :uploads
  has_ancestry
  
  attr_accessible :name, :collection, :parent_id, :collection_id, :user_id, :project_id
end
