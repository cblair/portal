require 'test_helper'
include CouchdbHelper


class DocumentsHelperTest < ActionView::TestCase
   #Helper tests

	def setup
		@user = users(:user1)
		sign_in @user
	end


	def teardown
		sign_out @user

		Collection.all.each do |c|
			c.destroy
		end

		Document.all.each do |d|
			d.destroy
		end

		Upload.all.each do |u|
			u.destroy
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


	test "save_zip_to_documents - create parent collection" do
		c=Collection.new(:name => "test_save_zip_to_documents")
		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		assert c.name == "test_save_zip_to_documents"

		#There are 2 collections with the same name, due to how OSX zipped this for us
		count = Collection.where(:name => "TUC2").count
		assert count == 2, "TUC2 collection count 2 != #{count}"

		c_names = c.collections.map {|sub_c| sub_c.name}
		assert c_names.include?("TUC2"), "TUC2 not in sub_collections: " + c_names.to_s

		sub_c =  Collection.where(:name => "TUC2").second
		assert sub_c.collection.name == "test_save_zip_to_documents", "TUC2 parent name: #{sub_c.collection.name}"
		assert sub_c.documents.count == 1

		sub_c =  Collection.where(:name => "2011").first
		assert sub_c.collection.name == "TUC2"
		assert sub_c.documents.count == 2

		sub_c =  Collection.where(:name => "2012").first
		assert sub_c.collection.name == "TUC2"
		assert sub_c.documents.count == 2

		Collection.all.each do |sub_c|
			sub_c.documents.each do |sub_d|
				assert sub_d.user == @user, "Document #{sub_d.name} user #{sub_d.user.email} != #{@user.email}"
			end
		end

		c.destroy
	end


	test "save_zip_to_documents - no parent collection" do
		c = nil

		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		c_names = Collection.where(:collection_id => nil).map {|sub_c| sub_c.name}
		assert c_names.include?("TUC2"), "TUC2 not in sub_collections: " + c_names.to_s

		#There are 2 collections with the same name, due to how OSX zipped this for us
		count = Collection.where(:name => "TUC2").count
		assert count == 2, "TUC2 collection count 2 != #{count}"

		c_names = Collection.where(:name => "TUC2").first.collections.map {|sub_c| sub_c.name}
		assert c_names.include?("2011"), "2011 not in sub_collections: " + c_names.to_s
		assert c_names.include?("2012"), "2012 not in sub_collections: " + c_names.to_s
		
		sub_c =  Collection.where(:name => "TUC2").first
		assert sub_c.collection == nil
		assert sub_c.documents.count == 1

		sub_c =  Collection.where(:name => "2011").first
		assert sub_c.collection.name == "TUC2"
		assert sub_c.documents.count == 2

		sub_c =  Collection.where(:name => "2012").first
		assert sub_c.collection.name == "TUC2"
		assert sub_c.documents.count == 2
	end


	test "save_zip_to_documents - nil arguments" do
		c = nil
		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert !save_zip_to_documents(fname, nil, c, nil, @user)
		assert !save_zip_to_documents(nil, upload, c, nil, @user)
		assert !save_zip_to_documents(nil, nil, c, nil, @user)
	end


	test "save_file_to_document - valid upload file, no ifilter" do
		c = nil
		f = nil
		fname = 'TMJ06001.A91_2.txt'
		fp = File.open('test/unit/test_files/TMJ06001.A91_2.txt')
		assert fp.is_a? File

		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload
		assert upload.upfile.path

		assert save_file_to_document(fname, upload.upfile.path, c, f, @user)

		d = Document.first
		assert d.name == fname, "#{d.name} != #{fname}"
		assert d.collection == nil
		assert d.validated == nil, "#{d.validated} != nil"

		assert d.stuffing_data, "Document doesn't have any data: " + d.stuffing_data.to_s
	end


	test "get_data_colnames - all" do
		assert get_data_colnames([])
	end
end
