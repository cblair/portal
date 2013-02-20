class Upload < ActiveRecord::Base
  attr_accessible :name, :upfile
  has_attached_file :upfile
  belongs_to :user
  
  include Rails.application.routes.url_helpers

  def to_jq_upload
    {
      "name" => read_attribute(:upfile_file_name),
      "size" => read_attribute(:upfile_file_size),
      "url" => upfile.url(:original),
      "delete_url" => upload_path(self),
      "delete_type" => "DELETE" 
    }
  end
end
