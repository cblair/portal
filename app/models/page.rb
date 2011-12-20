class Page < ActiveRecord::Base
  validates :header, :presence => true
  validates :footer, :presence => true
end