class Ifilter < ActiveRecord::Base
  require 'stuffing'
  
  attr_accessible :name, :regex, :stuffing_headers
  
  stuffing# :host => '192.168.1.145', :username => 'cblair', :password => 'Aba-Gal#'
end
