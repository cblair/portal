class Document < ActiveRecord::Base
  require 'stuffing'
  attr_accessible :name, :stuffing_data, :stuffing_search
    
  belongs_to :collection
  #TODO: not working, server startup. dump?
  #has_and_belongs_to_many :users  #collaborators
  belongs_to :user                #owner
  has_many :charts, :dependent => :destroy
  stuffing :host => '192.168.1.145', :username => 'cblair3', :password => 'SHIhel7'
    
  #Search for document names
  def self.search(search)
    if search
      where('name LIKE ?', "%#{search}%")
    else
      scoped
    end
  end
end
