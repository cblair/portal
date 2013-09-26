class Metarow < ActiveRecord::Base
  attr_accessible :autofill, :key, :metaform_id, :user_id, :value
  
  validates :key, :presence => true, :length => { :minimum => 1 }
  
  belongs_to :metaforms
end
