require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
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
  
  # test if couchDB is running?
  
  #Test create new role
  test "test_role_create" do
    role1 = Role.new({:name => "admin"})
    assert role1.valid?, "Needs a name at least 1 character long."
  end
  
  #Test create new role with bad name
  test "test_role_create_name_fail" do
    role1 = Role.new({:name => ""})
    assert role1.invalid?, "Name string to long."
  end
  
  #Test good edit/update of role name
  test "test_edit_good_role_name" do
    role1 = Role.new({:name => "role_edit"})
    role1.update_attributes(:name => "role_update")
    assert role1.valid?, "Role name change failed, maybe to short."
  end
  
  #Test bad edit/update of role name
  test "test_edit_bad_role_name" do
    role1 = Role.new({:name => "role_bad"})
    role1.update_attributes(:name => "")
    assert role1.invalid?, "New role name string to long."
  end
  
  #Test destroy role
  test "test_role_destroy" do
    role = Role.new({:name => "role_del"})
    role.destroy
    assert_nil role.id, "Role deleted successfully."
  end
  
end
