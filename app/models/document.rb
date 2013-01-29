class Document < ActiveRecord::Base
  require 'stuffing'
  attr_accessible :name, :stuffing_data, :stuffing_search, :user_id
    
  belongs_to :collection
  #TODO: not working, server startup. dump?
  #has_and_belongs_to_many :users  #collaborators
  belongs_to :user                #owner
  belongs_to :project
  has_many :charts, :dependent => :destroy
  stuffing
    
  #Search for document names
  def self.search(search)
    if search
      where('name LIKE ?', "%#{search}%")
    else
      scoped
    end
  end
end
