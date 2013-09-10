class Collaborator < ActiveRecord::Base
  attr_accessible :project_id, :project_name, :user_email, :user_id, :editor
  
  belongs_to :project
  belongs_to :user
end
