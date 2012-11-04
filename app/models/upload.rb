class Upload < ActiveRecord::Base
  attr_accessible :name, :upfile
  has_attached_file :upfile
end
