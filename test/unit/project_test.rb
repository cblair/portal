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

  # test create project
  test "test_project_create" do
    proj1 = Project.new({:name => "Create Project Test", :pdesc => "This is a test of create project."})
    assert proj1.valid?, "Needs a name and a description."
  end

  #test project with bad name field
  test "test_project_create_name_fail" do
    proj = Project.new({:name => "Ab", :pdesc => "Is name valid test?"})
    assert proj.invalid?, "Name field to short."
  end
  
  #test project with bad description field
  test "test_project_create_pdesc_fail" do
    proj = Project.new({:name => "Description fail test.", :pdesc => ""})
    assert proj.invalid?, "Description field to short."
  end
  
  #test destroy project?

  #test edit/update name of project
  test "test_project_edit_name" do
    proj = Project.new({:name => "Edit Project Name", :pdesc => "Edit project name test."})
    proj.update_attributes(:name => "Edited Name")
    assert proj.valid?, "Name may be to short."
  end
  
  #test edit/update pdesc of project
  test "test_project_edit_pdesc" do
    proj = Project.new({:name => "Edit Project Pdesc", :pdesc => "Edit project pdesc."})
    proj.update_attributes(:name => "Edited pdesc")
    assert proj.valid?, "Description may be to short."
  end

end
