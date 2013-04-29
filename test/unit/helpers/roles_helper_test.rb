require 'test_helper'
include CouchdbHelper

class RolesHelperTest < ActionView::TestCase
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
  
  #Test good arguments to "update_user_roles"
  test "test_update_user_roles_good_args" do
    role1 = roles(:role1)
    role2 = roles(:role2)
    role_list =[]
    role_list << role1
    role_list << role2
    user1 = users(:user1)
    assert update_user_roles(role_list, user1) == true, "Role ids or user is bad."
  end
  
  #Test nil roles argument, good user for "update_user_roles"
  test "test_update_user_roles_nil_roles_arg" do
    role_list = nil
    user1 = users(:user1)
    assert update_user_roles(role_list, user1) == false, "Role ids not nil."
  end

end
