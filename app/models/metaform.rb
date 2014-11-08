class Metaform < ActiveRecord::Base
  attr_accessible :mddesc, :name, :user_id, :metarows_attributes
  
  validates :name, :presence => true, :length => { :minimum => 1 }
  validates :mddesc, :presence => true, :length => { :minimum => 1 }
  
  belongs_to :users
  has_many :metarows, :dependent => :destroy
  accepts_nested_attributes_for :metarows, :allow_destroy => true,
    :reject_if => proc { |row| row['key'].blank? }
  
  default_scope :order => 'metaforms.name ASC'  #Always sorts by name?
end
