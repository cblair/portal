require 'test_helper'
include CouchdbHelper
include DocumentsHelper

class MetaformsHelperTest < ActionView::TestCase

  include Devise::TestHelpers
  
	def setup
		@request.env["devise.mapping"] = Devise.mappings[:admin]
		@user = users(:user1)
		sign_in @user
		#@raw_file_text = "fname,lname,gpa
#Clark,Kent,3.5
#Lex,Luther,3.9
#Bruce,Wayne,4.0"
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
		
		Project.all.each do |p|
			p.destroy
		end
		
		Metaform.all.each do |mf|
			mf.destroy
		end

 	end

 	test 'is_json?' do
 		assert is_json?('{ "test" : ["a", 1, "b"] }')
 		assert !is_json?('{ "test" : ["a", 1, "b"] : "c"}')
 		assert !is_json?(nil)
 	end

	test "is_couchdb_running" do
	    #Make sure CouchDB is running; even though it is not in projects_helper.rb
	    result = is_couchdb_running?(
	              host     = Portal::Application.config.couchdb['COUCHDB_HOST'], 
	              port     = Portal::Application.config.couchdb['COUCHDB_PORT'],
	              username = Portal::Application.config.couchdb['COUCHDB_USERNAME'],
	              password = Portal::Application.config.couchdb['COUCHDB_PASSWORD'],
	              https    = Portal::Application.config.couchdb['COUCHDB_HTTPS']
	            )
	    assert result
	end

  #Test adding metadata to document with out metadata
  test "test_metarows_no_md_save" do
    @metaform = metaforms(:metaform1)
    mf_data = {"0" => {"key" => "KeyTest1", "value" => "Value1", "id" => "1"}}
    
    #Save document to Couch
	fname = 'smallv.csv'
	upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/smallv.csv'))
	save_file_to_document(fname, upload.upfile.path, nil, nil, @user)
	
	f = get_ifilter(-1) #internal
	docs = Document.where(:name => fname)
	d = docs.first

    assert metarows_save(mf_data, d) == true, "Metaform not saved."
  end

  #Test saving metaform with 1 metarow to CouchDB
  test "test_metarows_save" do
    @metaform = metaforms(:metaform1)
    mf_data = {"0" => {"key" => "KeyTest1", "value" => "Value1", "id" => "1"}}
    
    #Save and filter document to Couch
	fname = 'smallv.csv'
	upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/smallv.csv'))
	save_file_to_document(fname, upload.upfile.path, nil, nil, @user)
	
	f = get_ifilter(-1) #internal CSV
	docs = Document.where(:name => fname)
	d = docs.first

	data = filter_data_columns_csv(d.stuffing_text) #call filters
	suc_valid = d.validate(f)
    
    assert metarows_save(mf_data, d) == true, "Metaform not saved."
  end

  #Test saving metaform with 2 metarows to CouchDB
  test "test_metarows2_save" do
    @metaform = metaforms(:metaform1)
    mf_data = {"0" => {"key" => "KeyTest 2.1", "value" => "Value 2.1", "id" => "1"},
      "1" => {"key" => "KeyTest 2.2", "value" => "Value 2.2", "id" => "2"}}
    
    #Save and filter document to Couch
	fname = 'smallv.csv'
	upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/smallv.csv'))
	save_file_to_document(fname, upload.upfile.path, nil, nil, @user)
	
	f = get_ifilter(-1) #internal CSV
	docs = Document.where(:name => fname)
	d = docs.first

	data = filter_data_columns_csv(d.stuffing_text) #call filters
	suc_valid = d.validate(f)
    
    assert metarows_save(mf_data, d) == true, "Metaform not saved."
  end

  #Test saving NIL metadata to CouchDB
  test "test_metarows_nil" do
    @metaform = metaforms(:metaform1)
    mf_data = nil
    
    #Save and filter document to Couch
	fname = 'smallv.csv'
	upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/smallv.csv'))
	save_file_to_document(fname, upload.upfile.path, nil, nil, @user)
	
	f = get_ifilter(-1) #internal CSV
	docs = Document.where(:name => fname)
	d = docs.first

	data = filter_data_columns_csv(d.stuffing_text) #call filters
	suc_valid = d.validate(f)
    
    assert metarows_save(mf_data, d) == false, "Metadata not nil."
  end
  
  #Test saving NIL document to CouchDB
  test "test_metarows_doc_nil" do
    mf_data = {"0" => {"key" => "KeyDocNil", "value" => "Doc nil", "id" => "1"}}
    doc = nil
    
    assert metarows_save(mf_data, doc) == false, "Document not nil."
  end
  
  #Test good arguments to "metarows_delete".
  test "test_metarows_delete_good_arg" do
    @metaform = metaforms(:metaform1)
    mf_data = {"0" => {"key" => "KeyTest1", "value" => "Value1", "id" => "1"}}
    
    #Save and filter document to Couch
	fname = 'smallv.csv'
	upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/smallv.csv'))
	save_file_to_document(fname, upload.upfile.path, nil, nil, @user)
	
	f = get_ifilter(-1) #internal CSV
	docs = Document.where(:name => fname)
	d = docs.first

	data = filter_data_columns_csv(d.stuffing_text) #call filters
	suc_valid = d.validate(f)
	
	mf_data2 = {"0" => {"key" => "KeyTest2", "value" => "Value2", "id" => "1"}}
	metarows_save(mf_data2, d)
	metadata = d.stuffing_metadata
	
	assert metarows_delete(d) == true, "Metarows not deleted."
	assert metadata == [{"HatchFilter"=>"CSV (pre-defined)"}, {"Metaform"=>"Metaform1"}, {"KeyTest2"=>"Value2"}], 
	"Metarows don't match"
  end

  #Test nil document to "metarows_delete".
  test "test_metarows_delete_nil_doc" do
    doc = nil
    assert metarows_delete(doc) == false, "Document not nil."
  end

  #Test metarow setup function
  test "test_metarow_setup" do
    @metaform = metaforms(:metaform1)
    assert setup_mrows() == true, "Metarow setup failed."
  end

  #TODO: Make tests for metarow dynamic creation function?
  
  #Test nil name for "add_fields_link"
  test "test_add_fields_name_nil" do
    name = nil
    f = "test"
    association = "test"
    assert add_fields_link(name, f, association) == false, "Name not nil."
  end
  
  #Test nil "f" for "add_fields_link"
  test "test_add_fields_f_nil" do
    name = "test"
    f = nil
    association = "test"
    assert add_fields_link(name, f, association) == false, "f not nil."
  end
  
  #Test nil association for "add_fields_link"
  test "test_add_fields_association_nil" do
    name = "test"
    f = "test"
    association = nil
    assert add_fields_link(name, f, association) == false, "association not nil."
  end

end
