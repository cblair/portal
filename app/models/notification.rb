class Notification < ActiveRecord::Base
  attr_accessible :body, :emailed, :title
end
