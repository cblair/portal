=begin
class CouchdbDocument < CouchRest::Model::Base

	design do
		view :all_data_values 
	end

end
=end