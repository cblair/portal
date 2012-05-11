class Feed < ActiveRecord::Base
  attr_accessible :name, :feed_url, :interval_val, :interval_unit, :document_id
end
