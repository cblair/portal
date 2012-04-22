class Document < ActiveRecord::Base
  require 'stuffing'
  attr_accessible :name, :stuffing_data, :stuffing_search
    
  belongs_to :collection
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