require 'test_helper'

class MetaformTest < ActiveSupport::TestCase
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
		
		Metaform.all.each do |mf|
			mf.destroy
		end
 	end

  #test create metaform
  test "test_metaform_create" do
    mf = Metaform.new({:name => "Create Metaform Test", :mddesc => "Test of create metaform."})
    assert mf.valid?, "Needs a name and a description."
  end
  
  #test create metaform with bad name field
  test "test_metaform_create_name_fail" do
    mf = Metaform.new({:name => "", :mddesc => "Is name valid test?"})
    assert mf.invalid?, "Name field too short."
  end
  
  #test create metaform with bad description field
  test "test_metaform_create_pmdesc_fail" do
    mf = Metaform.new({:name => "Description fail test.", :mddesc => ""})
    assert mf.invalid?, "Description field too short."
  end
  
  #test good edit/update name of metaform
  test "test_good_metaform_edit_name" do
    mf = Metaform.new({:name => "Edit Metaform Name", :mddesc => "Edit metaform name test."})
    mf.update_attributes(:name => "Edited Name")
    assert mf.valid?, "Name may be too short."
  end
  
  #test good edit/update mddesc of metaform
  test "test_good_metaform_edit_mddesc" do
    mf = Metaform.new({:name => "Edit Metaform", :mddesc => "Edit metaform mddesc."})
    mf.update_attributes(:name => "Edited mddesc")
    assert mf.valid?, "Description may be too short."
  end
  
  #test bad edit/update name of metaform
  test "test_bad_metaform_edit_name" do
    mf = Metaform.new({:name => "Edit Metaform Name", :mddesc => "Edit metaform name test."})
    mf.update_attributes(:name => "")
    assert mf.invalid?, "Name may be too short."
  end
  
  #test bad edit/update mddesc of metaform
  test "test_bad_metaform_edit_mddesc" do
    mf = Metaform.new({:name => "Edit Metaform", :mddesc => "Edit metaform mddesc."})
    mf.update_attributes(:mddesc => "")
    assert mf.invalid?, "Description may be too short."
  end
  
  #test destroy metaform
  test "test_metaform_destroy" do
    mf = Metaform.new({:name => "Destroy Metaform", :pdesc => "Destroy metaform mddesc."})
    mf.destroy
    assert_nil mf.id, "Metaform deleted successfully."
  end
end
