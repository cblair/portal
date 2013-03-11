require 'test_helper'
include CouchdbHelper

class ProjectsHelperTest < ActionView::TestCase

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

  #test change owner
  test "test_change_project_owner" do
    proj = Project.new({:name => "Change Project Owner", :pdesc => "Change project owner test."})
    proj.user = @user #set owner
    #p("***", proj.user)
    puts("------------------------------------------------------------")
    
    col = Collection(:one)
    
    Collection.each do |c|
      puts("#{c.name}")
    end
=begin    
    c=Collection.new(:name => "test_change_project_owner")
	fname = 'ATM_small_test.zip'
	upload = Upload.create(:name => fname, :upfile => File.open('test/unit/test_files/ATM_small_test.zip'))
	
	save_zip_to_documents(fname, upload, c, nil, @user)
	
	puts("------------------------------------------------------------")
	puts("#{c.name}")
	c.documents.each do |d|
	  puts("************************************************************")
	  p("#{c.name}")
	end
=end    
  end
 	
end
