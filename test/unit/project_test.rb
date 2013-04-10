require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
=begin
   test "the truth" do
     assert true
   end
=end
=begin
  include Devise::TestHelpers

	def setup
		@request.env["devise.mapping"] = Devise.mappings[:admin]
		@user = users(:user1)
		sign_in @user
	end
=end
#=begin
	def teardown
		#sign_out @user

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
#=end
  # test if couchDB is running?

  #test create project
  test "test_project_create" do
    proj1 = Project.new({:name => "Create Project Test", :pdesc => "This is a test of create project."})
    assert proj1.valid?, "Needs a name and a description."
  end

  #test create project with bad name field
  test "test_project_create_name_fail" do
    proj = Project.new({:name => "Ab", :pdesc => "Is name valid test?"})
    assert proj.invalid?, "Name field too short."
  end
  
  #test create project with bad description field
  test "test_project_create_pdesc_fail" do
    proj = Project.new({:name => "Description fail test.", :pdesc => ""})
    assert proj.invalid?, "Description field too short."
  end

  #test good edit/update name of project
  test "test_good_project_edit_name" do
    proj = Project.new({:name => "Edit Project Name", :pdesc => "Edit project name test."})
    proj.update_attributes(:name => "Edited Name")
    assert proj.valid?, "Name may be too short."
  end
  
  #test good edit/update pdesc of project
  test "test_good_project_edit_pdesc" do
    proj = Project.new({:name => "Edit Project", :pdesc => "Edit project pdesc."})
    proj.update_attributes(:name => "Edited pdesc")
    assert proj.valid?, "Description may be too short."
  end
  
  #test bad edit/update name of project
  test "test_bad_project_edit_name" do
    proj = Project.new({:name => "Edit Project Name", :pdesc => "Edit project name test."})
    proj.update_attributes(:name => "E")
    assert proj.invalid?, "Name may be too short."
  end
  
  #test bad edit/update pdesc of project
  test "test_bad_project_edit_pdesc" do
    proj = Project.new({:name => "Edit Project", :pdesc => "Edit project pdesc."})
    proj.update_attributes(:name => "")
    assert proj.invalid?, "Description may be too short."
  end
  
  #test destroy project
  test "test_project_destroy" do
    proj = Project.new({:name => "Destroy Project", :pdesc => "Destroy project pdesc."})
    proj.destroy
    assert_nil proj.id, "Project deleted successfully."
  end

end
