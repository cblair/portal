require 'test_helper'
include CouchdbHelper

#*** IMPORTANT!*** These unit tests are run assuming a pre-configured 
# CouchDB and Elastic Search index. To run these tests properly run the
# scripts; "esCreate.bat" and "esSetup.bat" (may need to run "esDrop.bat"
# to clean things up first).
#***

class ElasticsearchHelperTest < ActionView::TestCase

  include Devise::TestHelpers
  
	def setup
		@request.env["devise.mapping"] = Devise.mappings[:admin]
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
		
		Project.all.each do |p|
			p.destroy
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

  #Facet Searches ------------------------------------------------------
  test "es_terms_facet_test" do
    qstr = "Superman"
    sfield = "HANDLE"
    data = es_terms_facet(qstr, sfield)
    assert data[0][:doc_name] == 'idsArray', "Bad search or error."
  end

  test "es_range_facet_test" do
    qfrom = "3.9"
    qto = "4.0"
    sfield = "gpa"
    data = es_range_facet(qfrom, qto, sfield)
  end

  test "es_date_range_facet_test" do
    qfrom = "3.9"
    qto = "4.0"
    sfield = "gpa"
    data = es_date_range_facet(qfrom, qto, sfield)
  end

  test "es_date_histogram_facet_test" do
    sfield = "postDate"
    myinterval = "year"
    qfrom = "01/18/2000"
    qto = "01/20/2000"
    data = es_date_histogram_facet(sfield, myinterval, qfrom, qto)
    assert data[0][:doc_name] == '5', "Bad search or error."
  end

  #Basic Searches ------------------------------------------------------

  test "es_match_search_test" do
    qstr = "clark"
    sfield = "user"
    data = es_match_search(qstr, sfield)
    assert data[0][:doc_name] == '1', "Bad search or error."
    assert data[1][:doc_name] == '2', "Bad search or error."
  end

  test "es_filtered_search_test" do
    qstr = "bruce"
    sfield = "user"
    rfield =  "gpa"
    qfrom = 3.9
    qto = 4.00
    data = es_filtered_search(qstr, sfield, rfield, qfrom, qto)
    assert data[0][:doc_name] == '4', "Bad search or error."
  end

  #Fuzzy like this
  test "es_flt_field_search_test" do
    qtext = "lex"
    sfield = "user"
    max = 10
    data = es_flt_field_search(qtext, sfield, max)
    assert data[0][:doc_name] == '3', "Bad search or error."
  end

  test "es_prefix_search_test" do
    qstr = "diana"
    sfield = "user"
    data = es_prefix_search(qstr, sfield)
    assert data[0][:doc_name] == '5', "Bad search or error."
  end

  test "es_query_string_search_test" do
    qstr = "Diana"
    data = es_query_string_search(qstr)
    assert data[0][:doc_name] == 'users', "Bad search or error."
    assert data[1][:doc_name] == 'idsArray', "Bad search or error."
    assert data[2][:doc_name] == '5', "Bad search or error."
  end

  test "es_range_search_test" do
    sfield = "gpa"
    qfrom = 3.90
    qto = 4.00
    data = es_range_search(sfield, qfrom, qto)
    assert data[0][:doc_name] == '4', "Bad search or error."
    assert data[1][:doc_name] == '3', "Bad search or error."
  end

  test "es_term_search_test" do
    qstr = "bruce"
    sfield = "FIRST_NAME"
    data = es_term_search(qstr, sfield)
    assert data[0][:doc_name] == 'idsArray', "Bad search or error."
  end

  test "es_wildcard_search_test" do
    qstr = "dia*a"
    sfield = "FIRST_NAME"
    data = es_wildcard_search(qstr, sfield)
    assert data[0][:doc_name] == 'idsArray', "Bad search or error."
  end

end
