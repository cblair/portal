class Document < ActiveRecord::Base
  attr_accessible :name, :stuffing_data
    
  belongs_to :collection
  stuffing
end
