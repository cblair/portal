class Document < ActiveRecord::Base
  attr_accessible :name, :stuffing_data
    
  belongs_to :collection
  stuffing
  
  def self.search(search)
    if search
      where('name LIKE ?', "%#{search}%")
    else
      scoped
    end
  end
end