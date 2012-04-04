class Document < ActiveRecord::Base
  require 'stuffing'
  attr_accessible :name, :stuffing_data
    
  belongs_to :collection
  has_many :charts, :dependent => :destroy
  stuffing
  
  def self.search(search)
    if search
      where('name LIKE ?', "%#{search}%")
    else
      scoped
    end
  end
end
