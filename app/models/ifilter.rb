class Ifilter < ActiveRecord::Base
  require 'stuffing'
  
  attr_accessible :name, :regex, :stuffing_headers
  
  stuffing
end
