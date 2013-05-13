require 'test_helper'
include CouchdbHelper

class DocumentsHelperTest < ActionView::TestCase
   #Helper tests

    include Devise::TestHelpers

	def setup
		@request.env["devise.mapping"] = Devise.mappings[:admin]
		@user = users(:user1)
		sign_in @user

		@raw_file_text = "    FILE TYPE                      : INTERROGATION
    FILE TITLE                     : TMJ06001.A91
    FILE CREATED                   : 01 JANUARY 2006 AT 00:00

! This file contains all detections for 2006 from the juvenile bypass outfall.
! The tags were detected using an FS-2001F portable transceiver and flat-plate
! antenna.  These data were compiled from the original files by Dave Marvin,
! PTAGIS.  The original data files are listed in the data stream below, 
! followed by their contents.

! TMJ06032.A1
| 01 02/16/06 18:34:51 ::q
:q.t. XX 91

1a 2a
| 01 02/16/06 19:08:15 3D9.1BF1E7919A XX 91
| 01 02/16/06 19:18:36 3D9.1BF1A998FA XX 91
| 01 02/17/06 18:21:03 3D9.1BF20E8FE2 XX 91
| 01 02/20/06 18:27:01 3D9.1BF11BFFF5 XX 91
| 01 02/22/06 01:56:38 3D9.1BF23F62D4 XX 91
| 01 02/22/06 03:56:10 3D9.1BF234346C XX 91
| 01 02/22/06 17:59:11 3D9.1BF2342E83 XX 91
| 01 02/22/06 19:03:37 3D9.1BF23435A4 XX 91
| 01 02/22/06 19:03:37 3D9.1BF23435A4 XX 91
| 01 02/22/06 19:03:37 3D9.1BF23435A4 XX 91

    FILE CLOSED                    : 28 JUNE 2006 AT 08:13
"
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
 		assert !is_json?(nil)
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

		assert d.stuffing_data == nil
		assert d.stuffing_text != nil
	end

	test "save_file_to_document - valid upload file, ifilter" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		assert save_file_to_document(fname, upload.upfile.path, nil, f, @user)

		docs = Document.where(:name => fname)
		assert docs.count == 1
		d = docs.first

		md = get_document_metadata(d)
		#TODO: save_file_to_document doesn't parse metadata, but isn't used in Hatch yet
		#      to do so. Filed Task Manager task to fix
		#assert md != [], md.to_s + " should not == []"
	end


	test "save_file_to_document - 409 error" do
		d = Document.new(:name => "fakey")
		d.save

		host     = Portal::Application.config.couchdb['COUCHDB_HOST']
		port     = Portal::Application.config.couchdb['COUCHDB_PORT']
		username = Portal::Application.config.couchdb['COUCHDB_USERNAME']
		password = Portal::Application.config.couchdb['COUCHDB_PASSWORD']
		https    = Portal::Application.config.couchdb['COUCHDB_HTTPS']

		#This name will have to change if the project name ever does
		db_name = "portal_test"

		if https
        	conn_str = "https://"
    	else
        	conn_str = "http://"
      	end
      
      	if username != nil and password != nil
        	conn_str += "#{username}:#{password}@"
      	end
      
      	conn_str += "#{host}:#{port}/#{db_name}"
      
      	assert host == "127.0.0.1", host.to_s

      	db = CouchRest.database(conn_str)

      	#jump ahead of stuffing and our ActiveRecord ids...
      	puts "TS216"
      	response = db.save_doc({"_id" => "Document-#{d.id + 1}"})
      	assert response["ok"] == true
      	puts "TS219"

		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		assert !save_file_to_document(fname, upload.upfile.path, nil, f, @user)

     	response = db.delete_doc(
     								{
     									"_id" => "Document-#{d.id + 1}", 
     									"_rev" => response['rev']
     								}
     							)
	end


	test "save_file_to_document -  nil arguments" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		#assert save_file_to_document(fname, upload.upfile.path, nil, f, @user)
		assert !save_file_to_document(nil, upload.upfile.path, nil, f, @user)
		assert !save_file_to_document(fname, nil, nil, f, @user)
		assert !save_file_to_document(nil, nil, nil, f, @user)
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


	test "filter_data_columns_csv - valid data" do
		fname = 'test.csv'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/test.csv'))
		assert upload

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		f = get_ifilter(-1) #internal CSV

		docs = Document.where(:name => fname)
		assert docs.count == 1, Document.all.to_s
		d = docs.first

		data = filter_data_columns_csv(d.stuffing_text)
		expected_data =	[{"site"=>"AAA", "Fish"=>"3d9.xxx", "time"=>"2"}, {"site"=>"AAA", "Fish"=>"3d9.xxx", "time"=>"4"}, {"site"=>"AAA", "Fish"=>"3d9.xxx", "time"=>"5"}]
		assert data == expected_data, data.to_s + " != " + expected_data.to_s		

		data = filter_data_columns(f, d.stuffing_text)
		assert data == expected_data

		#should generate already parsed error
		d.stuffing_data = data
		d.save
		data = filter_data_columns(f, d.stuffing_text)
		assert data == expected_data
	end


	test "filter_data_columns_csv - invalid data" do
		fname = 'test.csv'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/test.csv'))
		assert upload

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		f = get_ifilter(-1) #internal CSV

		docs = Document.where(:name => fname)
		assert docs.count == 1, Document.all.to_s
		d = docs.first

		data = filter_data_columns_csv(nil)
		assert data == []

		#this file has some quotes errors in it. hits 
		#TODO: Added task to Task Manager to make these user-fixable things more visable
		fname = 'sys_Protocol.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/sys_Protocol.txt'))
		assert upload

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		f = get_ifilter(-1) #internal CSV

		docs = Document.where(:name => fname)
		assert docs.count == 1, Document.all.to_s
		d = docs.first

		data = filter_data_columns_csv(nil)
		assert data == []		

		#TODO: this file is toxic, has something that translates badly into JSON 
		#      (unterminated quotes. This is a bug that we should
		#      fix.
		fname = 'lkp_Species.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/lkp_Species.txt'))
		assert upload

		assert !save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		f = get_ifilter(-1) #internal CSV

		docs = Document.where(:name => fname)
		assert docs.count == 0, docs.count.to_s
	end


	test "filter_data_columns_xml - valid data" do
		fname = 'tbl_WaterQuality.xml'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/tbl_WaterQuality.xml'))
		assert upload

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		f = get_ifilter(-2) #internal XML

		docs = Document.where(:name => fname)
		assert docs.count == 1, Document.all.to_s
		d = docs.first

		data = filter_data_columns_xml(d.stuffing_text)
		expected_data =	[
						{"WaterQualityID"=>"4", "WaterQualityName"=>"TR1-A-L-dce-20080527-1345-Ammonia-20080527-1345", "DceName"=>"TR1-A-L-dce-20080527-1345", "MethodName"=>"Ammonia", "SampleDate"=>"2008-05-27T13:45:00", "SampleDateTime"=>"2008-05-27T13:45:00", "WaterQualityValue"=>"-999", "WaterQualityUnits"=>"micrograms/Liter", "DataQualityRank"=>"not assigned", "WaterQualityMeasurementNotes"=>"-999 indicates that sample ammonia level was below the assay detection limit of 10 micrograms/Liter", "DateCreated"=>"2012-05-31T10:59:03", "CreatedBy"=>"Torre Stockard", "LastUpdated"=>"2012-05-31T10:59:03", "UpdatedBy"=>"Torre Stockard", "WaterQualityAttribute"=>"NH4"}, 
						{"WaterQualityID"=>"5", "WaterQualityName"=>"TR1-A-R-dce-20080527-1345-Ammonia-20080527-1345", "DceName"=>"TR1-A-R-dce-20080527-1345", "MethodName"=>"Ammonia", "SampleDate"=>"2008-05-27T13:45:00", "SampleDateTime"=>"2008-05-27T13:45:00", "WaterQualityValue"=>"-999", "WaterQualityUnits"=>"micrograms/Liter", "DataQualityRank"=>"not assigned", "WaterQualityMeasurementNotes"=>"-999 indicates that sample ammonia level was below the assay detection limit of 10 micrograms/Liter", "DateCreated"=>"2012-05-31T10:59:03", "CreatedBy"=>"Torre Stockard", "LastUpdated"=>"2012-05-31T10:59:03", "UpdatedBy"=>"Torre Stockard", "WaterQualityAttribute"=>"NH4"}, 
						{"WaterQualityID"=>"6", "WaterQualityName"=>"TR2-A-L-dce-20080527-1300-Ammonia-20080527-1300", "DceName"=>"TR2-A-L-dce-20080527-1300", "MethodName"=>"Ammonia", "SampleDate"=>"2008-05-27T13:00:00", "SampleDateTime"=>"2008-05-27T13:00:00", "WaterQualityValue"=>"11.6497330942593", "WaterQualityUnits"=>"micrograms/Liter", "DataQualityRank"=>"not assigned", "DateCreated"=>"2012-05-31T10:59:03", "CreatedBy"=>"Torre Stockard", "LastUpdated"=>"2012-05-31T10:59:03", "UpdatedBy"=>"Torre Stockard", "WaterQualityAttribute"=>"NH4"}
						]
		assert data == expected_data, data.to_s
	end

	test "filter_data_columns_xml - invalid data" do
		fname = 'tbl_WaterQuality_bad1.xml'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/tbl_WaterQuality_bad1.xml'))
		assert upload

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		f = get_ifilter(-2) #internal XML

		docs = Document.where(:name => fname)
		assert docs.count == 1, Document.all.to_s
		d = docs.first

		data = filter_data_columns_xml(d.stuffing_data)
		assert data == [], data.to_s
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
		iterator = 	"| 01 02/16/06 19:08:15 3D9.1BF1E7919A XX 91 
					 | 01 02/16/06 19:18:36 3D9.1BF1A998FA XX 91
					 | 01 02/17/06 18:21:03 3D9.1BF20E8FE2 XX 91 
					 | 01 02/20/06 18:27:01 3D9.1BF11BFFF5 XX 91"
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

		#String check
		data =	"| 01 02/16/06 19:08:15 3D9.1BF1E7919A XX 91
					| 01 02/16/06 19:18:36 3D9.1BF1A998FA XX 91
					| 01 02/17/06 18:21:03 3D9.1BF20E8FE2 XX 91
					| 01 02/20/06 18:27:01 3D9.1BF11BFFF5 XX 91"
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

		#XML tests
		iterator = 	'<?xml version="1.0" encoding="UTF-8"?>
						<dataroot xmlns:od="urn:schemas-microsoft-com:officedata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  xsi:noNamespaceSchemaLocation="tbl_WaterQuality.xsd" generated="2013-03-05T10:43:17">
						<tbl_WaterQuality>
						<WaterQualityID>4</WaterQualityID>
						<WaterQualityName>TR1-A-L-dce-20080527-1345-Ammonia-20080527-1345</WaterQualityName>
						<DceName>TR1-A-L-dce-20080527-1345</DceName>
						<MethodName>Ammonia</MethodName>
						<SampleDate>2008-05-27T13:45:00</SampleDate>
						<SampleDateTime>2008-05-27T13:45:00</SampleDateTime>
						<WaterQualityValue>-999</WaterQualityValue>
						<WaterQualityUnits>micrograms/Liter</WaterQualityUnits>
						<DataQualityRank>not assigned</DataQualityRank>
						<WaterQualityMeasurementNotes>-999 indicates that sample ammonia level was below the assay detection limit of 10 micrograms/Liter</WaterQualityMeasurementNotes>
						<DateCreated>2012-05-31T10:59:03</DateCreated>
						<CreatedBy>Torre Stockard</CreatedBy>
						<LastUpdated>2012-05-31T10:59:03</LastUpdated>
						<UpdatedBy>Torre Stockard</UpdatedBy>
						<WaterQualityAttribute>NH4</WaterQualityAttribute>
						</tbl_WaterQuality>
						<tbl_WaterQuality>
						<WaterQualityID>5</WaterQualityID>
						<WaterQualityName>TR1-A-R-dce-20080527-1345-Ammonia-20080527-1345</WaterQualityName>
						<DceName>TR1-A-R-dce-20080527-1345</DceName>
						<MethodName>Ammonia</MethodName>
						<SampleDate>2008-05-27T13:45:00</SampleDate>
						<SampleDateTime>2008-05-27T13:45:00</SampleDateTime>
						<WaterQualityValue>-999</WaterQualityValue>
						<WaterQualityUnits>micrograms/Liter</WaterQualityUnits>
						<DataQualityRank>not assigned</DataQualityRank>
						<WaterQualityMeasurementNotes>-999 indicates that sample ammonia level was below the assay detection limit of 10 micrograms/Liter</WaterQualityMeasurementNotes>
						<DateCreated>2012-05-31T10:59:03</DateCreated>
						<CreatedBy>Torre Stockard</CreatedBy>
						<LastUpdated>2012-05-31T10:59:03</LastUpdated>
						<UpdatedBy>Torre Stockard</UpdatedBy>
						<WaterQualityAttribute>NH4</WaterQualityAttribute>
						</tbl_WaterQuality>
						<tbl_WaterQuality>
						<WaterQualityID>6</WaterQualityID>
						<WaterQualityName>TR2-A-L-dce-20080527-1300-Ammonia-20080527-1300</WaterQualityName>
						<DceName>TR2-A-L-dce-20080527-1300</DceName>
						<MethodName>Ammonia</MethodName>
						<SampleDate>2008-05-27T13:00:00</SampleDate>
						<SampleDateTime>2008-05-27T13:00:00</SampleDateTime>
						<WaterQualityValue>11.6497330942593</WaterQualityValue>
						<WaterQualityUnits>micrograms/Liter</WaterQualityUnits>
						<DataQualityRank>not assigned</DataQualityRank>
						<DateCreated>2012-05-31T10:59:03</DateCreated>
						<CreatedBy>Torre Stockard</CreatedBy>
						<LastUpdated>2012-05-31T10:59:03</LastUpdated>
						<UpdatedBy>Torre Stockard</UpdatedBy>
						<WaterQualityAttribute>NH4</WaterQualityAttribute>
						</tbl_WaterQuality>
						<tbl_WaterQuality>
						<WaterQualityID>7</WaterQualityID>
						<WaterQualityName>TR2-A-R-dce-20080527-1300-Ammonia-20080527-1300</WaterQualityName>
						<DceName>TR2-A-R-dce-20080527-1300</DceName>
						<MethodName>Ammonia</MethodName>
						<SampleDate>2008-05-27T13:00:00</SampleDate>
						<SampleDateTime>2008-05-27T13:00:00</SampleDateTime>
						<WaterQualityValue>19.9847280999598</WaterQualityValue>
						<WaterQualityUnits>micrograms/Liter</WaterQualityUnits>
						<DataQualityRank>not assigned</DataQualityRank>
						<DateCreated>2012-05-31T10:59:03</DateCreated>
						<CreatedBy>Torre Stockard</CreatedBy>
						<LastUpdated>2012-05-31T10:59:03</LastUpdated>
						<UpdatedBy>Torre Stockard</UpdatedBy>
						<WaterQualityAttribute>NH4</WaterQualityAttribute>
						</tbl_WaterQuality>
						</dataroot>'

		f = get_ifilter(-2) #internal XML
		data = filter_data_columns(f, iterator)
		expected_data = [
							{"WaterQualityID"=>"4", "WaterQualityName"=>"TR1-A-L-dce-20080527-1345-Ammonia-20080527-1345", "DceName"=>"TR1-A-L-dce-20080527-1345", "MethodName"=>"Ammonia", "SampleDate"=>"2008-05-27T13:45:00", "SampleDateTime"=>"2008-05-27T13:45:00", "WaterQualityValue"=>"-999", "WaterQualityUnits"=>"micrograms/Liter", "DataQualityRank"=>"not assigned", "WaterQualityMeasurementNotes"=>"-999 indicates that sample ammonia level was below the assay detection limit of 10 micrograms/Liter", "DateCreated"=>"2012-05-31T10:59:03", "CreatedBy"=>"Torre Stockard", "LastUpdated"=>"2012-05-31T10:59:03", "UpdatedBy"=>"Torre Stockard", "WaterQualityAttribute"=>"NH4"}, 
							{"WaterQualityID"=>"5", "WaterQualityName"=>"TR1-A-R-dce-20080527-1345-Ammonia-20080527-1345", "DceName"=>"TR1-A-R-dce-20080527-1345", "MethodName"=>"Ammonia", "SampleDate"=>"2008-05-27T13:45:00", "SampleDateTime"=>"2008-05-27T13:45:00", "WaterQualityValue"=>"-999", "WaterQualityUnits"=>"micrograms/Liter", "DataQualityRank"=>"not assigned", "WaterQualityMeasurementNotes"=>"-999 indicates that sample ammonia level was below the assay detection limit of 10 micrograms/Liter", "DateCreated"=>"2012-05-31T10:59:03", "CreatedBy"=>"Torre Stockard", "LastUpdated"=>"2012-05-31T10:59:03", "UpdatedBy"=>"Torre Stockard", "WaterQualityAttribute"=>"NH4"}, 
							{"WaterQualityID"=>"6", "WaterQualityName"=>"TR2-A-L-dce-20080527-1300-Ammonia-20080527-1300", "DceName"=>"TR2-A-L-dce-20080527-1300", "MethodName"=>"Ammonia", "SampleDate"=>"2008-05-27T13:00:00", "SampleDateTime"=>"2008-05-27T13:00:00", "WaterQualityValue"=>"11.6497330942593", "WaterQualityUnits"=>"micrograms/Liter", "DataQualityRank"=>"not assigned", "DateCreated"=>"2012-05-31T10:59:03", "CreatedBy"=>"Torre Stockard", "LastUpdated"=>"2012-05-31T10:59:03", "UpdatedBy"=>"Torre Stockard", "WaterQualityAttribute"=>"NH4"}, 
							{"WaterQualityID"=>"7", "WaterQualityName"=>"TR2-A-R-dce-20080527-1300-Ammonia-20080527-1300", "DceName"=>"TR2-A-R-dce-20080527-1300", "MethodName"=>"Ammonia", "SampleDate"=>"2008-05-27T13:00:00", "SampleDateTime"=>"2008-05-27T13:00:00", "WaterQualityValue"=>"19.9847280999598", "WaterQualityUnits"=>"micrograms/Liter", "DataQualityRank"=>"not assigned", "DateCreated"=>"2012-05-31T10:59:03", "CreatedBy"=>"Torre Stockard", "LastUpdated"=>"2012-05-31T10:59:03", "UpdatedBy"=>"Torre Stockard", "WaterQualityAttribute"=>"NH4"}
						]
		assert data != [], "#{data} == []"
		assert data == expected_data
	end


	test "get_data_column - valid" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		d = Document.where(:name => fname).first

		expected_data = ["row1", "row2"]
		d.stuffing_data = [{"1" => "row1"}, {"1" => "row2"}]
		data = get_data_column(d, '1') 
		assert data != []
		assert data == expected_data, data.to_s + " != " + expected_data.to_s

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


	test "get_document_metadata - valid data" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)
		assert validate_document_helper(@document, f)

		docs = Document.where(:name => fname)
		assert docs.count == 1
		d = docs.first

		md = get_document_metadata(d)
		assert md != [], md.to_s + " should not == []"
		assert md == 	[
						{"1"=>"FILE TYPE", "2"=>"INTERROGATION"}, 
						{"1"=>"FILE TITLE", "2"=>"TMJ06001.A91"}, 
						{"1"=>"FILE CREATED", "2"=>"01 JANUARY 2006 AT 00:00"}
						], md.to_s
	end


	test "get_document_metadata - invalid data" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		docs = Document.where(:name => fname)
		assert docs.count == 1, "doc count should == 1, but == #{docs.count}"
		d = docs.first

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)
		assert validate_document_helper(@document, nil)

		#no filter, get nothing
		md = get_document_metadata(d)
		assert md == [], md.to_s + " should == []"

		#if its empty, get empty
		d.stuffing_metadata = []
		md = get_document_metadata(d)
		assert md == [], md.to_s + " should == []"
		d.stuffing_metadata = nil
		md = get_document_metadata(d)
		assert md == [], md.to_s + " should == []"

		#cause rescue
		d = nil
		md = get_document_metadata(d)
		assert md == [], md.to_s + " should == []"		
	end


	test "get_document_data - valid data" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		d = Document.where(:name => fname).first

		assert validate_document_helper(d, f)

		data = get_document_data(d)
		assert data != [], data.to_s + " should not == []"
		assert data == 	[
						{"1"=>"02/16/06 19:08:15", "2"=>"3D9.1BF1E7919A"}, 
						{"1"=>"02/16/06 19:18:36", "2"=>"3D9.1BF1A998FA"}, 
						{"1"=>"02/17/06 18:21:03", "2"=>"3D9.1BF20E8FE2"}, 
						{"1"=>"02/20/06 18:27:01", "2"=>"3D9.1BF11BFFF5"}, 
						{"1"=>"02/22/06 01:56:38", "2"=>"3D9.1BF23F62D4"}, 
						{"1"=>"02/22/06 03:56:10", "2"=>"3D9.1BF234346C"}, 
						{"1"=>"02/22/06 17:59:11", "2"=>"3D9.1BF2342E83"}, 
						{"1"=>"02/22/06 19:03:37", "2"=>"3D9.1BF23435A4"}, 
						{"1"=>"02/22/06 19:03:37", "2"=>"3D9.1BF23435A4"}, 
						{"1"=>"02/22/06 19:03:37", "2"=>"3D9.1BF23435A4"}
						]
	end


	test "get_document_data - invalid data" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		docs = Document.where(:name => fname)
		assert docs.count == 1
		d = docs.first

		#no filter, get unfiltered doc data
		data = get_document_data(d)
		assert data == nil
		assert d.stuffing_text != nil

		#if its empty, get empty
		d.stuffing_data = []
		data = get_document_data(d)
		assert data == [], data.to_s + " should == []"

		#cause rescue
		d = nil
		data = get_document_data(d)
		assert data == [], data.to_s + " should == []"		
	end


	test "get_last_n_above_id - valid data" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		d = Document.where(:name => fname).first

		d.stuffing_data = 	[
								{"id" => 1, "x" => 1, "y" => 2},
								{"id" => 2, "x" => 2, "y" => 4},
								{"id" => 3, "x" => 3, "y" => 8}
							]
		d.save

		data = get_last_n_above_id(d, "x", "y", 1, 3)
		assert data == {"lastpt"=>3, "points"=>[[2, 4], [3, 8]]}

		data = get_last_n_above_id(d, "x", "y", 2, 3)
		assert data == {"lastpt"=>3, "points"=>[[3,8]]}

		#id is passed whats in data
		data = get_last_n_above_id(d, "x", "y", 3, 3)
		assert data == {"lastpt"=>3, "points"=>[]}	

		#small maxes
		data = get_last_n_above_id(d, "x", "y", 1, 0)
		assert data == {"lastpt"=>3, "points"=>[]}, data.to_s + " != []"
		data = get_last_n_above_id(d, "x", "y", 1, -1)
		assert data == {"lastpt"=>-1, "points"=>[]}

		#weird ids
		data = get_last_n_above_id(d, "x", "y", 0, 3)
		assert data == {"lastpt"=>3, "points"=>[[1, 2], [2, 4], [3, 8]]}
		data = get_last_n_above_id(d, "x", "y", -1, 3)
		assert data == {"lastpt"=>3, "points"=>[[1, 2], [2, 4], [3, 8]]}

		#empty stuffing data
		d.stuffing_data = []
		d.save
		data = get_last_n_above_id(d, "x", "y", 0, 3)
		assert data == []
	end


	test "get_last_n_above_id - invalid data" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		d = Document.where(:name => fname).first

		d.stuffing_data = 	[
								{"id" => 1, "x" => 1, "y" => 2},
								{"id" => 2, "x" => 2, "y" => 4},
								{"id" => 3, "x" => 3, "y" => 8}
							]
		d.save

		data = get_last_n_above_id(nil, nil, nil, nil, nil)
		assert data == [], data.to_s + " != []"

		data = get_last_n_above_id(nil, "x", "y", 1, 3)
		assert data == [], data.to_s + " != []"

		data = get_last_n_above_id(d, nil, "y", 1, 3)
		assert data == [], data.to_s + " != []"

		data = get_last_n_above_id(d, "x", nil, 1, 3)
		assert data == [], data.to_s + " != []"

		data = get_last_n_above_id(d, "x", "y", nil, 3)
		assert data == {"lastpt"=>3, "points"=>[[1, 2], [2, 4], [3, 8]]}

		data = get_last_n_above_id(d, "x", "y", 1, nil)
		assert data == {"lastpt"=>-1, "points"=>[]}
	end


	test "get_data_map - valid data" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		d = Document.where(:name => fname).first

		d.stuffing_data = 	[
								{"id" => 1, "x" => 1, "y" => 2},
								{"id" => 2, "x" => 1, "y" => 4},
								{"id" => 3, "x" => 1, "y" => 5},
								{"id" => 4, "x" => 2, "y" => 1},
								{"id" => 5, "x" => 2, "y" => 4},
								{"id" => 6, "x" => 3, "y" => 8},
								{"id" => 7, "x" => 3, "y" => 5},
								{"id" => 8, "x" => 3, "y" => 8}
							]
		d.save

		data = get_data_map(d, "x")
		assert data ==	[
							{"value"=>"1", "map"=>3}, 
							{"value"=>"2", "map"=>2}, 
							{"value"=>"3", "map"=>3}
						], data.to_s

		data = get_data_map(d, "y")
		assert data ==	[
							{"value"=>"2", "map"=>1}, 
							{"value"=>"4", "map"=>2}, 
							{"value"=>"5", "map"=>2}, 
							{"value"=>"1", "map"=>1}, 
							{"value"=>"8", "map"=>2}
						], data.to_s

		d.stuffing_data = []
		d.save
		data = get_data_map(d, "x")
		assert data == []
	end


	test "get_data_map - invalid data" do
		fname = 'TMJ06001.A91_2.txt'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		assert save_file_to_document(fname, upload.upfile.path, nil, nil, @user)

		d = Document.where(:name => fname).first

		d.stuffing_data = 	[
								{"id" => 1, "x" => 1, "y" => 2},
								{"id" => 2, "x" => 1, "y" => 4},
								{"id" => 3, "x" => 1, "y" => 5},
								{"id" => 4, "x" => 2, "y" => 1},
								{"id" => 5, "x" => 2, "y" => 4},
								{"id" => 6, "x" => 3, "y" => 8},
								{"id" => 7, "x" => 3, "y" => 5},
								{"id" => 8, "x" => 3, "y" => 8}
							]
		d.save

		data = get_data_map(nil, nil)
		assert data == []

		data = get_data_map(d, nil)
		assert data == []

		data = get_data_map(nil, "x")
		assert data == []
	end


	test "collection_is_viewable - valid data" do
		c_name = "viewable_test"
		c = Collection.new(:name => c_name)
		c.save

		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		#this user uploaded the file, s the collection should be viewable
		assert collection_is_viewable(c, @user)

		#test zip file collections
		c = Collection.where(:name => "TUC2").first
		assert c
		assert collection_is_viewable(c, @user)

		c = Collection.where(:name => "2011").first
		assert c
		assert collection_is_viewable(c, @user)

		c = Collection.where(:name => "2012").first
		assert c
		assert collection_is_viewable(c, @user)

		user2 = User.new(:email => "test@test.com")
		c = Collection.where(:name => "2012").first
		assert !collection_is_viewable(c, user2)
		
		#set one of the documents of the collection to public, and the collection will then
		# be public
		d = Document.where(:name => "TMJ06001.B02.txt").first
		assert d
		d.public = true
		d.save
		assert doc_is_viewable(d, user2)
		c = Collection.where(:name => "TUC2").first
		assert c != nil
		assert collection_is_viewable(c, user2)
		c = Collection.where(:name => "2011").first
		assert c != nil
		assert collection_is_viewable(c, user2)
		c = Collection.where(:name => "2012").first
		assert c != nil
		assert !collection_is_viewable(c, user2)

		#set private, and user to user2
		d.public = false
		d.user = user2
		d.save
		assert doc_is_viewable(d, user2)
		c = Collection.where(:name => "TUC2").first
		assert c != nil
		assert collection_is_viewable(c, user2)
		c = Collection.where(:name => "2011").first
		assert c != nil
		assert collection_is_viewable(c, user2)
		c = Collection.where(:name => "2012").first
		assert c != nil
		assert !collection_is_viewable(c, user2)		
	end


	test "collection_is_viewable - nil data" do
		c_name = "viewable_test"
		c = Collection.new(:name => c_name)
		c.save

		user2 = User.new(:email => "test@test.com")

		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		cols = Collection.where(:name => "TUC2")
		assert cols.count == 2 #counting the weird hidden OSX zipped stuff
		c = cols[1]
		assert c != nil

		#no collection
		assert !collection_is_viewable(nil, nil)
		assert !collection_is_viewable(nil, @user)

		Document.all do |doc|
			assert doc.user == @user, doc.name + " user == " + doc.user.email
			assert !doc.public, "#{doc.name} should not == public"
			assert !doc_is_viewable(doc, nil)
		end

		#no user
		assert !(c.collections.empty? and c.documents.empty?)
		c.documents.each do |doc|
			assert !doc_is_viewable(doc, nil)
		end

		assert c!= nil
		assert !collection_is_viewable(c, nil)
	end


	test "doc_is_viewable - valid data" do
		c_name = "viewable_test"
		c = Collection.new(:name => c_name)
		c.save

		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		user2 = User.new(:email => "test@test.com")

		d = Document.where(:name => "TMJ06001.C02.txt").first

		#this user uploaded the file, s the document should be viewable
		assert doc_is_viewable(d, @user)
		assert !doc_is_viewable(d, user2)

		#public doc
		d.public = true
		d.save
		assert doc_is_viewable(d, user2)

		d.public = false
		d.save
		assert !doc_is_viewable(d, user2)

		#add user2 as a collaborator
		# TODO: seems like a user could hack around this; adding Task Manager task to test
		# in User controller
		user2.documents << d
		user2.save

		assert doc_is_viewable(d, user2), "#{user2.email} docs == #{user2.documents}, has no doc '#{d.name}'"
	end


	test "doc_is_viewable - invalid data" do
		c_name = "viewable_test"
		c = Collection.new(:name => c_name)
		c.save

		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		d = Document.where(:name => "TMJ06001.C02.txt").first

		assert !doc_is_viewable(nil, nil)
		assert !doc_is_viewable(nil, @user)
		assert !doc_is_viewable(d, nil)

		#pass it something else besides a Document
		assert !doc_is_viewable(c, @user)
	end


	test "pop_temp_docs_list - valid data" do
		c_name = "viewable_test"
		c = Collection.new(:name => c_name)
		c.save

		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		f = ifilters(:ifilter1)
		f.stuffing_headers = 	[
									{"val" => "[ ]*(FILE[ ]+TYPE)[ ]*:[ ]*([A-Z]+)"},
									{"val" => "[ ]*(FILE[ ]+TITLE)[ ]*:[ ]*([A-Z0-9.]+)"},
									{"val" => "[ ]*(FILE[ ]+CREATED)[ ]*:[ ]*([A-Z0-9: ]+)"}
								]
		f.save

		doc_list = {}
		Document.all.each do |key|
			assert validate_document_helper(key, f)
      		doc_list[key] = nil
    	end

		pop_temp_docs_list(doc_list).each do |doc, temp_doc|
			assert doc.kind_of?(Document)
			assert temp_doc.kind_of?(Tempfile), "#{temp_doc.class} != Tempfile"
		end
	end


	test "pop_temp_docs_list - invalid data" do
		assert pop_temp_docs_list(nil) == {}
	end


	test "zip_doc_list - valid data" do
		c_name = "viewable_test"
		c = Collection.new(:name => c_name)
		c.save

		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		doc_list = {}
		Document.all.each do |key|
      		doc_list[key] = nil
    	end

		doc_list = pop_temp_docs_list(doc_list)

		#Create zip
	    zip_fname = "hatch_data_io"
	    temp_zip = Tempfile.new(zip_fname)
	    
	    Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert zip_doc_list(['tmp', 'sub_tmp'], zipfile, doc_list)
		end

		entries = 	[
						"tmp/sub_tmp/TMJ06001.B01.txt",
						"tmp/sub_tmp/TMJ06001.B02.txt",
						"tmp/sub_tmp/TMJ06001.C01.txt",
						"tmp/sub_tmp/TMJ06001.C02.txt",
						"tmp/sub_tmp/TMJ06001.A01.txt"
					]
		zipfile = Zip::ZipFile.open(temp_zip.path)
		zipfile.each do |file|
			assert entries.include?(file.to_s), file.to_s + " not in entries: #{entries}"
		end
	end


	test "zip_doc_list - invalid data" do
		c_name = "viewable_test"
		c = Collection.new(:name => c_name)
		c.save

		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		doc_list = {}
		Document.all.each do |key|
      		doc_list[key] = nil
    	end

		doc_list = pop_temp_docs_list(doc_list)

		#Create zip
	    zip_fname = "hatch_data_io"
	    temp_zip = Tempfile.new(zip_fname)
	    
	    Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert !zip_doc_list(nil, nil, nil)
		end

		Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert !zip_doc_list(nil, zipfile, doc_list)
		end

		Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert !zip_doc_list(['tmp', 'sub_tmp'], nil, doc_list)
		end

		Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert !zip_doc_list(['tmp', 'sub_tmp'], zipfile, nil)
		end
	end


	test "recursive_collection_zip - valid data" do
		c_name = "viewable_test"
		c = Collection.new(:name => c_name)
		c.save

		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		doc_list = {}
		Document.all.each do |key|
      		doc_list[key] = nil
    	end

		doc_list = pop_temp_docs_list(doc_list)

		#Create zip
	    zip_fname = "hatch_data_io"
	    temp_zip = Tempfile.new(zip_fname)
	    
	    Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert recursive_collection_zip(['tmp'], zipfile, c)
		end

		entries =	[
						"tmp/viewable_test/TUC2/TMJ06001.A01.txt",
						"tmp/viewable_test/TUC2/2011/TMJ06001.B01.txt",
						"tmp/viewable_test/TUC2/2011/TMJ06001.B02.txt",
						"tmp/viewable_test/TUC2/2012/TMJ06001.C01.txt",
						"tmp/viewable_test/TUC2/2012/TMJ06001.C02.txt"
					]
		zipfile = Zip::ZipFile.open(temp_zip.path)
		zipfile.each do |file|
			assert entries.include?(file.to_s), file.to_s + " not in entries: #{entries}"
		end

		#make 'blank' named dir
		c.name = ""
		c.save
		Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert recursive_collection_zip(['tmp'], zipfile, c)
		end

		entries =	[
						"tmp/(blank)/TUC2/TMJ06001.A01.txt",
						"tmp/(blank)/TUC2/2011/TMJ06001.B01.txt",
						"tmp/(blank)/TUC2/2011/TMJ06001.B02.txt",
						"tmp/(blank)/TUC2/2012/TMJ06001.C01.txt",
						"tmp/(blank)/TUC2/2012/TMJ06001.C02.txt"
					]
		zipfile = Zip::ZipFile.open(temp_zip.path)
		zipfile.each do |file|
			assert entries.include?(file.to_s), file.to_s + " not in entries: #{entries}"
		end
	end


	test "recursive_collection_zip - invalid data" do
		c_name = "viewable_test"
		c = Collection.new(:name => c_name)
		c.save

		fname = 'TUC2.zip'
		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TUC2.zip'))
		assert upload

		assert save_zip_to_documents(fname, upload, c, nil, @user)

		doc_list = {}
		Document.all.each do |key|
      		doc_list[key] = nil
    	end

		doc_list = pop_temp_docs_list(doc_list)

		#Create zip
	    zip_fname = "hatch_data_io"
	    temp_zip = Tempfile.new(zip_fname)
	    
	    Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert !recursive_collection_zip(nil, nil, nil)
		end

		Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert !recursive_collection_zip(nil, zipfile, c)
		end

		Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert !recursive_collection_zip(['tmp'], nil, c)
		end

		Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
			assert !recursive_collection_zip(['tmp'], zipfile, nil)
		end
	end


	test "validate_document_helper - valid data, no ifilter" do
		c = nil
		f = nil
		fname = 'TMJ06001.A91_2.txt'
		fp = File.open('test/unit/test_files/TMJ06001.A91_2.txt')
		assert fp.is_a? File
		fp.close

		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload
		assert upload.upfile.path

		assert save_file_to_document(fname, upload.upfile.path, c, nil, @user)

		d = Document.first

		validate_document_helper(d, nil)

		md = get_document_metadata(d)

		#should have found the right one
		assert md != [], md.to_s + " should not == []"
		assert md == 	[
						{"1"=>"FILE TYPE", "2"=>"INTERROGATION"}, 
						{"1"=>"FILE TITLE", "2"=>"TMJ06001.A91"}, 
						{"1"=>"FILE CREATED", "2"=>"01 JANUARY 2006 AT 00:00"}
						], md.to_s

		data = get_document_data(d)
		assert data != [], data.to_s + " should not == []"
		assert data == 	[
						{"1"=>"02/16/06 19:08:15", "2"=>"3D9.1BF1E7919A"}, 
						{"1"=>"02/16/06 19:18:36", "2"=>"3D9.1BF1A998FA"}, 
						{"1"=>"02/17/06 18:21:03", "2"=>"3D9.1BF20E8FE2"}, 
						{"1"=>"02/20/06 18:27:01", "2"=>"3D9.1BF11BFFF5"}, 
						{"1"=>"02/22/06 01:56:38", "2"=>"3D9.1BF23F62D4"}, 
						{"1"=>"02/22/06 03:56:10", "2"=>"3D9.1BF234346C"}, 
						{"1"=>"02/22/06 17:59:11", "2"=>"3D9.1BF2342E83"}, 
						{"1"=>"02/22/06 19:03:37", "2"=>"3D9.1BF23435A4"}, 
						{"1"=>"02/22/06 19:03:37", "2"=>"3D9.1BF23435A4"}, 
						{"1"=>"02/22/06 19:03:37", "2"=>"3D9.1BF23435A4"}
						]
	end

	
	test "validate_document_helper - valid data, correct ifilter" do
		c = nil
		f = ifilters(:ifilter1)
		fname = 'TMJ06001.A91_2.txt'
		fp = File.open('test/unit/test_files/TMJ06001.A91_2.txt')
		assert fp.is_a? File
		fp.close

		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload
		assert upload.upfile.path

		assert save_file_to_document(fname, upload.upfile.path, c, nil, @user)

		d = Document.first

		validate_document_helper(d, f)

		md = get_document_metadata(d)

		#should have found the right one
		assert md != [], md.to_s + " should not == []"
		assert md == 	[
						{"1"=>"FILE TYPE", "2"=>"INTERROGATION"}, 
						{"1"=>"FILE TITLE", "2"=>"TMJ06001.A91"}, 
						{"1"=>"FILE CREATED", "2"=>"01 JANUARY 2006 AT 00:00"}
						], md.to_s

		data = get_document_data(d)
		assert data != [], data.to_s + " should not == []"
		assert data == 	[
						{"1"=>"02/16/06 19:08:15", "2"=>"3D9.1BF1E7919A"}, 
						{"1"=>"02/16/06 19:18:36", "2"=>"3D9.1BF1A998FA"}, 
						{"1"=>"02/17/06 18:21:03", "2"=>"3D9.1BF20E8FE2"}, 
						{"1"=>"02/20/06 18:27:01", "2"=>"3D9.1BF11BFFF5"}, 
						{"1"=>"02/22/06 01:56:38", "2"=>"3D9.1BF23F62D4"}, 
						{"1"=>"02/22/06 03:56:10", "2"=>"3D9.1BF234346C"}, 
						{"1"=>"02/22/06 17:59:11", "2"=>"3D9.1BF2342E83"}, 
						{"1"=>"02/22/06 19:03:37", "2"=>"3D9.1BF23435A4"}, 
						{"1"=>"02/22/06 19:03:37", "2"=>"3D9.1BF23435A4"}, 
						{"1"=>"02/22/06 19:03:37", "2"=>"3D9.1BF23435A4"}
						]
	end


	test "validate_document_helper - valid data, incorrect ifilter" do
		c = nil
		f = ifilters(:ifilter_bad)
		fname = 'TMJ06001.A91_2.txt'
		fp = File.open('test/unit/test_files/TMJ06001.A91_2.txt')
		assert fp.is_a? File
		fp.close

		upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/TMJ06001.A91_2.txt'))
		assert upload
		assert upload.upfile.path

		assert save_file_to_document(fname, upload.upfile.path, c, nil, @user)

		d = Document.first

		validate_document_helper(d, f)

		md = get_document_metadata(d)

		#should have found the right one
		assert md == [], md.to_s + " should == []"

		expected_data = @raw_file_text

		data = d.stuffing_text
		assert data == expected_data, data.to_s
	end
end