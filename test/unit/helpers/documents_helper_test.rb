require 'test_helper'
include CouchdbHelper


class DocumentsHelperTest < ActionView::TestCase
   #Helper tests

	def setup

	end


	def teardown
		Collection.all.each do |c|
			c.destroy
		end

		Document.all.each do |d|
			d.destroy
		end
 	end


 	test 'is_json?' do
 		assert is_json?('{ "test" : ["a", 1, "b"] }')
 		assert !is_json?('{ "test" : ["a", 1, "b"] : "c"}')
 	end


	test "is_couchdb_running" do
	    #Make sure CouchDB is running; even though it is not in documents_helper.rb
	    result = is_couchdb_running?(
	              host     = Portal::Application.config.couchdb['COUCHDB_HOST'], 
	              port     = Portal::Application.config.couchdb['COUCHDB_PORT'],
	              username = Portal::Application.config.couchdb['COUCHDB_USERNAME'],
	              password = Portal::Application.config.couchdb['COUCHDB_PASSWORD'],
	              https    = Portal::Application.config.couchdb['COUCHDB_HTTPS']
	            )
	    assert result
 	end


	test "save_zip_to_documents - basic" do
		@user = users(:user1)
		sign_in @user

		c=Collection.new(:name => "test_save_zip_to_documents")
		c.save
		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		assert c.name == "test_save_zip_to_documents"

		c_names = c.collections.map {|sub_c| sub_c.name}
		assert c_names.include?("TUC2"), "TUC2 not in sub_collections: " + c_names.to_s

		c.destroy
	end
end
