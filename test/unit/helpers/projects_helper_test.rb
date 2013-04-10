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

  #test good project argument to "colab_list_get"
  test "test_colab_list_get_project_good_arg" do
    proj = projects(:proj1)
    temp = colab_list_get(proj)
    assert_instance_of Array, temp, "Should return an array."
  end
  
  #test nil project argument to "colab_list_get"
  test "test_colab_list_get_nil_project_arg" do
    proj_bad = nil
    assert colab_list_get(proj_bad) == false, "Project is not nil."
  end

  #test adding a collaborator to a project
  test "test_add_collaborator_project" do
    user1 =  users(:user1)
    doc1 = documents(:doc1)
    user1.documents << doc1
    user1.save
    assert user1.documents.include?(doc1) == true, "Collaborator not added."
  end
  
  #test adding multiple collaborators to a project
  test "test_add_multiple_collaborators_project" do
    user1 =  users(:user1)
    doc1 = documents(:doc1)
    doc2 = documents(:doc2)
    user1.documents << doc1
    user1.documents << doc2
    user1.save
    assert user1.documents.include?(doc1) == true, "Collaborator 1 not added."
    assert user1.documents.include?(doc2) == true, "Collaborator 2 not added."
  end
  
  #test failure to add a collaborator to a project
  test "test_add_collaborator_project_fail" do
    user1 =  users(:user1)
    doc1 = documents(:doc1)
    assert user1.documents.include?(doc1) == false, "Collaborator added."
  end
  
  #test failure to add multiple collaborators to a project
  test "test_add_multiple_collaborators_project_fail" do
    user1 =  users(:user1)
    doc1 = documents(:doc1)
    doc2 = documents(:doc2)
    assert user1.documents.include?(doc1) == false, "Collaborator 1 added."
    assert user1.documents.include?(doc2) == false, "Collaborator 2 added."
  end
  
  #test remove a collaborator from a project
  test "test_remove_collaborator_project" do
    user1 =  users(:user1)
    doc1 = documents(:doc1)
    user1.documents << doc1
    user1.save
    user1.documents.delete(doc1)
    assert user1.documents.include?(doc1) == false, "Collaborator 1 not removed."
  end
  
  #test remove multiple collaborators from a project
  test "test_remove_multiple_collaborators_project" do
    user1 =  users(:user1)
    doc1 = documents(:doc1)
    doc2 = documents(:doc2)
    user1.documents << doc1
    user1.documents << doc2
    user1.save
    user1.documents.delete(doc1)
    user1.documents.delete(doc2)
    assert user1.documents.include?(doc1) == false, "Collaborator 1 not removed."
    assert user1.documents.include?(doc2) == false, "Collaborator 2 not removed."
  end
  
  #test failure to remove a collaborator from a project
  test "test_remove_collaborator_project_fail" do
    user1 =  users(:user1)
    doc1 = documents(:doc1)
    user1.documents << doc1
    user1.save
    assert user1.documents.include?(doc1) == true, "Collaborator 1 removed."
  end
  
  #test failure to remove multiple collaborators from a project
  test "test_remove_multiple_collaborators_project_fail" do
    user1 =  users(:user1)
    doc1 = documents(:doc1)
    doc2 = documents(:doc2)
    user1.documents << doc1
    user1.documents << doc2
    user1.save
    assert user1.documents.include?(doc1) == true, "Collaborator 1 removed."
    assert user1.documents.include?(doc2) == true, "Collaborator 2 removed."
  end
  
  #test good arguments to "colab_add"
  test "test_colab_add_good_args" do
    user1 = users(:user1)
    proj1 = projects(:proj1)
    assert colab_add(proj1, user1) == true, "Project or user is nil."
  end
  
  #test good arguments to "colab_remove"
  test "test_colab_remove_good_args" do
    proj1 = projects(:proj1)
    assert colab_remove(proj1) == true, "Project is nil."
  end
  
  #test nil project argument, good user for "colab_add"
  test "test_colab_add_nil_project_arg" do
    user1 = users(:user1)
    proj_bad = nil
    assert colab_add(proj_bad, user1) == false, "Project not nil."
  end
  
  #test good project, nil user argument for "colab_add"
  test "test_colab_add_nil_user_arg" do
    user_bad =  nil
    proj = projects(:proj1)
    assert colab_add(proj, user_bad) == false, "User not nil."
  end
  
  #test nil arguments for "colab_add"
  test "test_colab_add_nil_args" do
    user_bad = nil
    proj_bad = nil
    assert colab_add(proj_bad, user_bad) == false, "Project or user not nil."
  end
  
  #test nil arguments to "colab_remove"
  test "test_colab_remove_nil_args" do
    proj = nil
    assert colab_remove(proj) == false, "Project is not nil."
  end
  
  #test change owner, change project's user id
  test "test_change_project_owner" do
    proj1 = projects(:proj1)
    proj1.user_id = 2    
    assert proj1.user_id == 2, "Owner change was successful."
  end
  
  #test change project documents owner
  test "test_change_project_documents_owner" do
    doc1 = documents(:doc1)
    doc2 = documents(:doc2)
    doc1.project_id = 2
    doc2.project_id = 2
    assert doc1.project_id == 2, "Document owner successfully changed."
    assert doc2.project_id == 2, "Document owner successfully changed."
  end
  
  #test good arguments to "change_owner"
  test "test_change_owner_good_args" do
    user1 = users(:user1)
    user_id = user1.id
    proj = projects(:proj1)
    assert change_owner(proj, user_id) == true, "Project is nil."
  end
  
  #test nil project argument, good user to "change_owner"
  test "test_change_owner_nil_project_arg" do
    user1 = users(:user1)
    user_id = user1.id
    proj_bad = nil
    assert change_owner(proj_bad, user_id) == false, "Project is not nil."
  end
    
  #test good project, nil user argument for "change_owner"
  test "test_change_owner_nil_user_arg" do
    user_bad = nil
    proj = projects(:proj1)
    assert change_owner(proj, user_bad) == false, "User is not nil."
  end
  
  #test empty string project for "change_owner"
  test "test_change_owner_empty_project_str_arg" do
    user1 = users(:user1)
    user_id = user1.id
    proj_bad = ""
    assert change_owner(proj_bad, user_id) == false, "Project sting is not empty."
  end
  
  #test empty string user id for "change_owner"
  test "test_change_owner_empty_user_str_arg" do
    user_bad = ""
    proj = projects(:proj1)
    assert change_owner(proj, user_bad) == false, "User sting is not empty."
  end
  
end
