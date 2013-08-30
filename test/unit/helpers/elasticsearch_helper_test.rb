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
  test "es_terms_facet_test_m" do
    qstr = "Superman"
    sfield = "HANDLE"
    flag = "m"
    data = es_terms_facet(qstr, sfield, flag)
    assert data[0][:doc_name] == 'idsArray', "Bad search or error."
  end

  test "es_terms_facet_test_f" do
    qstr = "Superman"
    sfield = "HANDLE"
    flag = "f"
    data = es_terms_facet(qstr, sfield, flag)
    assert data[0][:doc_name] == 'idsArray', "Bad search or error."
  end

  test "es_range_facet_test_m" do
    qfrom = "3.9"
    qto = "4.0"
    sfield = "gpa"
    flag = "m"
    data = es_range_facet(qfrom, qto, sfield, flag)
    assert data[0][:doc_name] == '4', "Bad search or error."
    assert data[1][:doc_name] == '3', "Bad search or error."
  end

  test "es_range_facet_test_f" do
    qfrom = "3.9"
    qto = "4.0"
    sfield = "gpa"
    flag = "f"
    data = es_range_facet(qfrom, qto, sfield, flag)
    assert data[0][:doc_name] == '4', "Bad search or error."
    assert data[1][:doc_name] == '3', "Bad search or error."
  end

  test "es_date_range_facet_test_m" do
    qfrom = "01/16/2000"
    qto = "01/16/2000"
    sfield = "postDate"
    flag = "m"
    data = es_date_range_facet(qfrom, qto, sfield, flag)
    assert data[0][:doc_name] == '2', "Bad search or error."
    assert data[1][:doc_name] == '3', "Bad search or error."
  end

  test "es_date_range_facet_test_f" do
    qfrom = "01/16/2000"
    qto = "01/16/2000"
    sfield = "postDate"
    flag = "f"
    data = es_date_range_facet(qfrom, qto, sfield, flag)
    assert data[0][:doc_name] == '2', "Bad search or error."
    assert data[1][:doc_name] == '3', "Bad search or error."
  end

  test "es_date_histogram_facet_test_m" do
    sfield = "postDate"
    myinterval = "year"
    qfrom = "01/18/2000"
    qto = "01/20/2000"
    flag = "m"
    data = es_date_histogram_facet(sfield, myinterval, qfrom, qto,flag)
    assert data[0][:doc_name] == '5', "Bad search or error."
  end

  test "es_date_histogram_facet_test_f" do
    sfield = "postDate"
    myinterval = "year"
    qfrom = "01/18/2000"
    qto = "01/20/2000"
    flag = "f"
    data = es_date_histogram_facet(sfield, myinterval, qfrom, qto,flag)
    assert data[0][:doc_name] == '5', "Bad search or error."
  end

  #Basic Searches ------------------------------------------------------

  test "es_match_search_test_m" do
    qstr = "clark"
    sfield = "user"
    flag = "m"
    data = es_match_search(qstr, sfield, flag)
    assert data[0][:doc_name] == '1', "Bad search or error."
    assert data[1][:doc_name] == '2', "Bad search or error."
  end

  test "es_match_search_test_f" do
    qstr = "clark"
    sfield = "user"
    flag = "f"
    data = es_match_search(qstr, sfield, flag)
    assert data[0][:doc_name] == '1', "Bad search or error."
    assert data[1][:doc_name] == '2', "Bad search or error."
  end

  test "es_filtered_search_test_m" do
    qstr = "bruce"
    sfield = "user"
    rfield =  "gpa"
    qfrom = 3.9
    qto = 4.00
    flag = "m"
    data = es_filtered_search(qstr, sfield, rfield, qfrom, qto, flag)
    assert data[0][:doc_name] == '4', "Bad search or error."
  end
  
  test "es_filtered_search_test_f" do
    qstr = "bruce"
    sfield = "user"
    rfield =  "gpa"
    qfrom = 3.9
    qto = 4.00
    flag = "f"
    data = es_filtered_search(qstr, sfield, rfield, qfrom, qto, flag)
    assert data[0][:doc_name] == '4', "Bad search or error."
  end

  #Fuzzy like this
  test "es_flt_field_search_test_m" do
    qtext = "lex"
    sfield = "user"
    max = 10
    flag = "m"
    data = es_flt_field_search(qtext, sfield, max, flag)
    assert data[0][:doc_name] == '3', "Bad search or error."
  end

  test "es_prefix_search_test_f" do
    qstr = "diana"
    sfield = "user"
    flag = "f"
    data = es_prefix_search(qstr, sfield, flag)
    assert data[0][:doc_name] == '5', "Bad search or error."
  end

  test "es_query_string_search_test_m" do
    qstr = "Diana"
    flag = "m"
    data = es_query_string_search(qstr, flag)
    assert data[0][:doc_name] == 'users', "Bad search or error."
    assert data[1][:doc_name] == 'idsArray', "Bad search or error."
    assert data[2][:doc_name] == '5', "Bad search or error."
  end
  
  test "es_query_string_search_test_f" do
    qstr = "Diana"
    flag = "f"
    data = es_query_string_search(qstr, flag)
    assert data[0][:doc_name] == 'users', "Bad search or error."
    assert data[1][:doc_name] == 'idsArray', "Bad search or error."
    assert data[2][:doc_name] == '5', "Bad search or error."
  end

  test "es_range_search_test_m" do
    sfield = "gpa"
    qfrom = 3.90
    qto = 4.00
    flag = "m"
    data = es_range_search(sfield, qfrom, qto, flag)
    assert data[0][:doc_name] == '4', "Bad search or error."
    assert data[1][:doc_name] == '3', "Bad search or error."
  end
  
  test "es_range_search_test_f" do
    sfield = "gpa"
    qfrom = 3.90
    qto = 4.00
    flag = "f"
    data = es_range_search(sfield, qfrom, qto, flag)
    assert data[0][:doc_name] == '4', "Bad search or error."
    assert data[1][:doc_name] == '3', "Bad search or error."
  end

  test "es_term_search_test_m" do
    qstr = "bruce"
    sfield = "FIRST_NAME"
    flag = "m"
    data = es_term_search(qstr, sfield, flag)
    assert data[0][:doc_name] == 'idsArray', "Bad search or error."
  end
  
  test "es_term_search_test_f" do
    qstr = "bruce"
    sfield = "FIRST_NAME"
    flag = "f"
    data = es_term_search(qstr, sfield, flag)
    assert data[0][:doc_name] == 'idsArray', "Bad search or error."
  end

  test "es_wildcard_search_test_m" do
    qstr = "dia*a"
    sfield = "FIRST_NAME"
    flag = "m"
    data = es_wildcard_search(qstr, sfield, flag)
    assert data[0][:doc_name] == 'idsArray', "Bad search or error."
  end
  
  test "es_wildcard_search_test_f" do
    qstr = "dia*a"
    sfield = "FIRST_NAME"
    flag = "f"
    data = es_wildcard_search(qstr, sfield, flag)
    assert data[0][:doc_name] == 'idsArray', "Bad search or error."
  end
  
  test "es_search_type_md_test" do
    flag = "m"
    str = search_type(flag)
    assert_equal "\"fields\" : [],", str, "Expecting fields string"
  end
  
  test "es_search_type_f_test" do
    flag = "f"
    str = search_type(flag)
    assert_equal "", str, "Expecting empty string"
  end

end
