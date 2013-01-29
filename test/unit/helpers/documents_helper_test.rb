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
		fp.close

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
		#empty tests
		assert get_data_colnames(nil)
		assert get_data_colnames([])

		#valid test
		d = [
				{'a' => 1, 'b' => 2, 'c' => 3},
				{'a' => 4, 'b' => 5, 'c' => 6}
			]
		colnames = get_data_colnames(d)
		assert colnames == ['a','b','c'], "Data col names ['a','b','c'] != #{colnames.to_s}"

		#valid, ignores any goofs in colnames after the first row
		d = [
				{'a' => 1, 'b' => 2, 'c' => 3},
				{'d' => 4, 'e' => 5, 'f' => 6}
			]
		colnames = get_data_colnames(d)
		assert colnames == ['a','b','c'], "Data col names == #{colnames.to_s}"
	end


	test "filter_metadata_columns - nil args" do
		fp = File.open('test/unit/test_files/TMJ06001.A91_2.txt')
		f = ifilters(:ifilter1)
		assert filter_metadata_columns(nil, fp) == []
		assert filter_metadata_columns(f, nil) == []

		fp.close
	end


	test "filter_metadata_columns - valid args, but bad file iterator" do
		fp = File.open('test/unit/test_files/TMJ06001.A91_2.txt')
		assert fp.is_a? File
		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9:]+)"}
								]
		f.save

		md = filter_metadata_columns(f, fp) #can't feed it a file like this
		assert md == [], "#{md.to_s} != []"

		fp.close
	end


	test "filter_metadata_columns - valid args" do
		fp = File.open('test/unit/test_files/TMJ06001.A91_2.txt')
		assert fp.is_a? File
		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9:]+)"}
								]
		f.save

		md = filter_metadata_columns(f, fp.each_line.each.map {|l| l})
		md_expected = 	[
							{1=>"FILE TYPE", 2=>"INTERROGATION"}, 
							{1=>"FILE TITLE", 2=>"TMJ06001.A91"}, 
							{1=>"FILE CREATED", 2=>"01"}
						]
		assert md == md_expected, "#{md.to_s} != #{md_expected.to_s}"

		fp.close
	end


	test "filter_data_columns - nil args" do
		fp = File.open('test/unit/test_files/TMJ06001.A91_2.txt')
		assert fp.is_a? File
		f = ifilters(:ifilter1)
		f.save

		#if the iterator (i.e. File object) is nil, we better get back and empty Array
		assert filter_data_columns(f, nil) == []
		assert filter_data_columns(nil, nil) == []

		#if the iterator arg is valid, but the filter arg is nil, we should get back
		# unfiltered data
		data = filter_data_columns(nil, fp)
		expected_data = [
			{1=>"    FILE TYPE                      : INTERROGATION\n"}, 
			{1=>"    FILE TITLE                     : TMJ06001.A91\n"}, 
			{1=>"    FILE CREATED                   : 01 JANUARY 2006 AT 00:00\n"}, 
			{1=>"\n"}, 
			{1=>"! This file contains all detections for 2006 from the juvenile bypass outfall.\n"}, 
			{1=>"! The tags were detected using an FS-2001F portable transceiver and flat-plate\n"}, 
			{1=>"! antenna.  These data were compiled from the original files by Dave Marvin,\n"}, 
			{1=>"! PTAGIS.  The original data files are listed in the data stream below, \n"}, 
			{1=>"! followed by their contents.\n"}, {1=>"\n"}, {1=>"! TMJ06032.A1\n"}, 
			{1=>"| 01 02/16/06 18:34:51 ::q\n"}, {1=>":q.t. XX 91\n"}, 
			{1=>"\n"}, 
			{1=>"1a 2a\n"}, 
			{1=>"| 01 02/16/06 19:08:15 3D9.1BF1E7919A XX 91\n"}, 
			{1=>"| 01 02/16/06 19:18:36 3D9.1BF1A998FA XX 91\n"}, 
			{1=>"| 01 02/17/06 18:21:03 3D9.1BF20E8FE2 XX 91\n"}, 
			{1=>"| 01 02/20/06 18:27:01 3D9.1BF11BFFF5 XX 91\n"}, 
			{1=>"| 01 02/22/06 01:56:38 3D9.1BF23F62D4 XX 91\n"}, 
			{1=>"| 01 02/22/06 03:56:10 3D9.1BF234346C XX 91\n"}, 
			{1=>"| 01 02/22/06 17:59:11 3D9.1BF2342E83 XX 91\n"}, 
			{1=>"| 01 02/22/06 19:03:37 3D9.1BF23435A4 XX 91\n"}, 
			{1=>"| 01 02/22/06 19:03:37 3D9.1BF23435A4 XX 91\n"}, 
			{1=>"| 01 02/22/06 19:03:37 3D9.1BF23435A4 XX 91\n"}, 
			{1=>"\n"}, 
			{1=>"    FILE CLOSED                    : 28 JUNE 2006 AT 08:13\n"}
		]
		assert data != [], "#{data} == []"
		assert data == expected_data, "data != unfiltered data"
		fp.close

		fp = File.open('test/unit/test_files/TMJ06001.A91_2.txt')
		assert filter_data_columns(f, fp) != []
		fp.close
	end

	test "filter_data_columns - valid data" do
		fp = File.open('test/unit/test_files/TMJ06001.A91_2.txt')
		assert fp.is_a? File
		f = ifilters(:ifilter1)
		f.save
		#iterator = fp.each_line.each.map {|l| l}
		iterator = 	[
						"| 01 02/16/06 19:08:15 3D9.1BF1E7919A XX 91", 
						"| 01 02/16/06 19:18:36 3D9.1BF1A998FA XX 91", 
						"| 01 02/17/06 18:21:03 3D9.1BF20E8FE2 XX 91", 
						"| 01 02/20/06 18:27:01 3D9.1BF11BFFF5 XX 91"
					]
		data = filter_data_columns(f, iterator)
		expected_data = [
							{1=>"02/16/06 19:08:15", 2=>"3D9.1BF1E7919A"}, 
							{1=>"02/16/06 19:18:36", 2=>"3D9.1BF1A998FA"}, 
							{1=>"02/17/06 18:21:03", 2=>"3D9.1BF20E8FE2"}, 
							{1=>"02/20/06 18:27:01", 2=>"3D9.1BF11BFFF5"}
						]
		assert data != [], "#{data} == []"
		assert data == expected_data, "#{data} != #{expected_data}"

		data = filter_data_columns(f, fp)
		expected_data = [
							{1=>"02/16/06 19:08:15", 2=>"3D9.1BF1E7919A"}, 
							{1=>"02/16/06 19:18:36", 2=>"3D9.1BF1A998FA"}, 
							{1=>"02/17/06 18:21:03", 2=>"3D9.1BF20E8FE2"}, 
							{1=>"02/20/06 18:27:01", 2=>"3D9.1BF11BFFF5"}, 
							{1=>"02/22/06 01:56:38", 2=>"3D9.1BF23F62D4"}, 
							{1=>"02/22/06 03:56:10", 2=>"3D9.1BF234346C"}, 
							{1=>"02/22/06 17:59:11", 2=>"3D9.1BF2342E83"}, 
							{1=>"02/22/06 19:03:37", 2=>"3D9.1BF23435A4"}, 
							{1=>"02/22/06 19:03:37", 2=>"3D9.1BF23435A4"}, 
							{1=>"02/22/06 19:03:37", 2=>"3D9.1BF23435A4"}
						]
		assert data != [], "#{data} == []"
		assert data == expected_data, "#{data} != #{expected_data}"

		fp.close

		#Hash check - data is array of hashes, not some file pointer
		data =	[
					{1=>"| 01 02/16/06 19:08:15 3D9.1BF1E7919A XX 91\n"}, 
					{1=>"| 01 02/16/06 19:18:36 3D9.1BF1A998FA XX 91\n"}, 
					{1=>"| 01 02/17/06 18:21:03 3D9.1BF20E8FE2 XX 91\n"}, 
					{1=>"| 01 02/20/06 18:27:01 3D9.1BF11BFFF5 XX 91\n"},
				]
		expected_data = 	
				[
					{1=>"02/16/06 19:08:15", 2=>"3D9.1BF1E7919A"}, 
					{1=>"02/16/06 19:18:36", 2=>"3D9.1BF1A998FA"}, 
					{1=>"02/17/06 18:21:03", 2=>"3D9.1BF20E8FE2"}, 
					{1=>"02/20/06 18:27:01", 2=>"3D9.1BF11BFFF5"}
				]
		result_data = filter_data_columns(f, data)
		assert result_data != []
		assert result_data == expected_data
	end


	test "get_data_column - valid" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		d = Document.where(:name => fname).first

		expected_data = [
			"    FILE TYPE                      : INTERROGATION\n", 
			"    FILE TITLE                     : TMJ06001.A91\n", 
			"    FILE CREATED                   : 01 JANUARY 2006 AT 00:00\n", 
			"\n", 
			"! This file contains all detections for 2006 from the juvenile bypass outfall.\n", 
			"! The tags were detected using an FS-2001F portable transceiver and flat-plate\n", 
			"! antenna.  These data were compiled from the original files by Dave Marvin,\n", 
			"! PTAGIS.  The original data files are listed in the data stream below, \n", 
			"! followed by their contents.\n", 
			"\n", 
			"! TMJ06032.A1\n", 
			"| 01 02/16/06 18:34:51 ::q\n", 
			":q.t. XX 91\n", 
			"\n", 
			"1a 2a\n", 
			"| 01 02/16/06 19:08:15 3D9.1BF1E7919A XX 91\n", 
			"| 01 02/16/06 19:18:36 3D9.1BF1A998FA XX 91\n", 
			"| 01 02/17/06 18:21:03 3D9.1BF20E8FE2 XX 91\n", 
			"| 01 02/20/06 18:27:01 3D9.1BF11BFFF5 XX 91\n", 
			"| 01 02/22/06 01:56:38 3D9.1BF23F62D4 XX 91\n", 
			"| 01 02/22/06 03:56:10 3D9.1BF234346C XX 91\n", 
			"| 01 02/22/06 17:59:11 3D9.1BF2342E83 XX 91\n", 
			"| 01 02/22/06 19:03:37 3D9.1BF23435A4 XX 91\n", 
			"| 01 02/22/06 19:03:37 3D9.1BF23435A4 XX 91\n", 
			"| 01 02/22/06 19:03:37 3D9.1BF23435A4 XX 91\n", 
			"\n", 
			"    FILE CLOSED                    : 28 JUNE 2006 AT 08:13\n"
		]
		data = get_data_column(d, '1') 
		assert data != []
		assert data == expected_data

		#empty data back
		data = get_data_column(d, '2') 
		assert data == [], "#{data} != []"
	end


	test "get_data_column - nil args" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		d = Document.where(:name => fname).first

		assert get_data_column(d, nil) == []
		assert get_data_column(nil, '1') == []
		d.stuffing_data = nil
		assert get_data_column(d, '1') == []

		assert get_data_column(nil, nil) == []
	end
end