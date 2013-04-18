require 'couchrest'
require 'test_helper'
#include CouchdbHelper

class SearchesHelperTest < ActionView::TestCase

    include Devise::TestHelpers

	def setup
		@request.env["devise.mapping"] = Devise.mappings[:admin]
		@user = users(:user1)
		sign_in @user

		Document.all.each do |d|
			d.destroy
		end

		d = Document.new(:name => "test")
		d.stuffing_data = [{"1" => "test"}]
		d.stuffing_primary_keys = ["1"]
		d.save
	end


	def teardown
		sign_out @user

		Document.all.each do |d|
			d.destroy
		end
 	end


 	#just run it, nothing else to test
 	test 'log_and_print' do
		log_and_print "test"
 	end


 	test "couch_search_count_data_in_document - valid data" do
 		#prefix
 		expected_data = [{"key"=>["test"], "value"=>{"Document-1"=>1}}]
 		actual_data = couch_search_count_data_in_document("t")
 		assert expected_data == actual_data, expected_data.to_s + " : " + actual_data.to_s
 		expected_data = [{"key"=>["test"], "value"=>{"Document-1"=>1}}]
 		assert expected_data == couch_search_count_data_in_document("te")
 		expected_data = [{"key"=>["test"], "value"=>{"Document-1"=>1}}]
 		assert expected_data == couch_search_count_data_in_document("tes")

 		#exact
 		expected_data = [{"key"=>["test"], "value"=>{"Document-1"=>1}}]
 		assert expected_data == couch_search_count_data_in_document("test")
 
 		#empty data
 		assert [] == couch_search_count_data_in_document("[test]")
 	end


 	test "couch_search_row_by_doc_and_data - valid data" do
 		expected_data = [{"id"=>"Document-2", "key"=>["Document-2", "test"], "value"=>{"1"=>"test"}}]
 		actual_data = couch_search_row_by_doc_and_data(2, "test")
 		assert expected_data == actual_data, actual_data.to_s
 	end


 	#TODO: test fuller later, not required now since it is in development env only
 	test "elastic_search_all_data - valid data" do
 		expected_data = []
 		actual_data = elastic_search_all_data("id:D*")
 		assert false, actual_data.to_s
 	end


 	#TODO: will be harder to test, Huroku Clodant production only
 	test "cloudant_search_all_data - valid data" do

 	end
end
