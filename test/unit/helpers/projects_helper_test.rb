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

  #---------------------------------------------------------------------
  #Test setting public project to private
  test "test_set_project_public" do
    project = projects(:proj1)
    is_public = proj_public_set(project)
    assert is_public == true, "Project should be set to private."
  end

  #Test setting private project to public
  test "test_set_project_private" do
    project = projects(:proj2)
    is_public = proj_public_set(project)
    assert is_public == false, "Project should be set to public."
  end

  #Test for bad (nil) public field in a project
  test "test_nil_public_project" do
    project = projects(:proj1)
    project.public = nil
    is_public = proj_public_set(project)
    assert is_public == nil, "Project public field not nil."
  end

  #---------------------------------------------------------------------
  ### Test adding collaborators to user documents ###
  #test adding a collaborator to a project (via user docs)
  test "test_add_collaborator_project" do
    user1 = users(:user1)
    doc1 = documents(:doc1)
    user1.documents << doc1
    user1.save
    assert user1.documents.include?(doc1) == true, "Collaborator not added."
  end
  
  #test adding multiple collaborators to a project (via user docs)
  test "test_add_multiple_collaborators_project" do
    user1 = users(:user1)
    doc1 = documents(:doc1)
    doc2 = documents(:doc2)
    user1.documents << doc1
    user1.documents << doc2
    user1.save
    assert user1.documents.include?(doc1) == true, "Collaborator 1 not added."
    assert user1.documents.include?(doc2) == true, "Collaborator 2 not added."
  end
  
  #test failure to add a collaborator to a project (via user docs)
  test "test_add_collaborator_project_fail" do
    user1 = users(:user1)
    doc1 = documents(:doc1)
    assert user1.documents.include?(doc1) == false, "Collaborator added."
  end
  
  #test failure to add multiple collaborators to a project (via user docs)
  test "test_add_multiple_collaborators_project_fail" do
    user1 = users(:user1)
    doc1 = documents(:doc1)
    doc2 = documents(:doc2)
    assert user1.documents.include?(doc1) == false, "Collaborator 1 added."
    assert user1.documents.include?(doc2) == false, "Collaborator 2 added."
  end
  
  #test remove a collaborator from a project (via user docs)
  test "test_remove_collaborator_project" do
    user1 = users(:user1)
    doc1 = documents(:doc1)
    user1.documents << doc1
    user1.save
    user1.documents.delete(doc1)
    assert user1.documents.include?(doc1) == false, "Collaborator 1 not removed."
  end
  
  #test remove multiple collaborators from a project (via user docs)
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
  
  #test failure to remove a collaborator from a project (via user docs)
  test "test_remove_collaborator_project_fail" do
    user1 =  users(:user1)
    doc1 = documents(:doc1)
    user1.documents << doc1
    user1.save
    assert user1.documents.include?(doc1) == true, "Collaborator 1 removed."
  end
  
  #test failure to remove multiple collaborators from a project (via user docs)
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

  #---------------------------------------------------------------------
  #test good project argument to "colab_list_get"
  test "test_colab_list_get_project_good_arg" do
    @project = projects(:proj1)
    #list = colab_list_get(proj)
    list = colab_list_get()
    assert_instance_of Collaborator, list[0], "1: Should be a collaborator object."
    assert_instance_of Collaborator, list[1], "2: Should be a collaborator object."
  end

  #test nil project argument to "colab_list_get"
  test "test_colab_list_get_nil_project_arg" do
    @project = nil
    assert colab_list_get() == false, "Project is not nil."
  end

  #---------------------------------------------------------------------
  ### Test "colab_add_to_docs" method ###
  #test good arguments to "colab_add_to_docs"
  test "test_colab_add_to_docs_good_args" do
    user1 = users(:user1)
    #proj1 = projects(:proj1)
    @project = projects(:proj1)
    assert colab_add_to_docs(user1) == true, "Project or user not nil."
  end

  #test nil project argument to "colab_add_to_docs"
  test "test_colab_add_to_docs_nil_proj_arg" do
    user1 = users(:user1)
    #proj_bad = nil
    @project = nil
    assert colab_add_to_docs(user1) == false, "Project not nil."
  end

  #test nil user argument to "colab_add_to_docs"
  test "test_colab_add_to_docs_nil_user_arg" do
    user_bad =  nil
    #proj = projects(:proj1)
    @project = projects(:proj1)
    assert colab_add_to_docs(user_bad) == false, "Project not nil."
  end

  #---------------------------------------------------------------------
  ### Test "colab_add" method ###
  #test good arguments to "colab_add"
  test "test_colab_add_good_args" do
    user1 = users(:user1)
    #proj1 = projects(:proj1)
    @project = projects(:proj1)
    assert colab_add(user1) == true, "Project or user is nil."
  end

  #test nil project argument, good user for "colab_add"
  test "test_colab_add_nil_project_arg" do
    user1 = users(:user1)
    @project = nil
    assert colab_add(user1) == false, "Project not nil."
  end

  #test good project, nil user argument for "colab_add"
  test "test_colab_add_nil_user_arg" do
    user_bad =  nil
    #proj = projects(:proj1)
    @project = nil
    assert colab_add(user_bad) == false, "User not nil."
  end

  #test nil arguments for "colab_add"
  test "test_colab_add_nil_args" do
    user_bad = nil
    @project = nil
    assert colab_add(user_bad) == false, "Project or user not nil."
  end

  #---------------------------------------------------------------------
  ### Test "colab_remove_project" method
  #test good arguments to "colab_remove_project"
  test "test_colab_remove_project_good_args" do
    #proj = projects(:proj1)
    @project = projects(:proj1)
    colab_user_ids = [2,3]
    assert colab_remove_project(colab_user_ids) == true, "Project or collaborator id list nil/empty."
  end

  #test nil project argument, good user id list to "colab_remove_project"
  test "test_colab_remove_project_nil_proj_arg" do
    @project = nil
    colab_user_ids = [2,3]
    assert colab_remove_project(colab_user_ids) == false, "Project not nil."
  end

  #test good project, nil user id list to "colab_remove_project"
  test "test_colab_remove_project_nil_user_arg" do
    #proj = projects(:proj1)
    @project = projects(:proj1)
    colab_user_ids = nil
    assert colab_remove_project(colab_user_ids) == false, "User/collaborator list not nil."
  end

  #test good project, empty user id list to "colab_remove_project"
  test "test_colab_remove_project_empty_user_arg" do
    #proj = projects(:proj1)
    @project = projects(:proj1)
    colab_user_ids = []
    assert colab_remove_project(colab_user_ids) == false, "User/collaborator list not nil."
  end

  #---------------------------------------------------------------------
  ## Test "colabs_remove_docs" method ###
  #test good arguments to "colabs_remove_docs" (for multiple docs)
  test "test_colabs_remove_docs_good_args" do
    #proj = projects(:proj1)
    @project = projects(:proj1)
    colab_user_ids = [2,3]
    assert colabs_remove_docs(colab_user_ids) == true, "Project or id list nil/empty."
  end

  #test nil project argument, good user ids to "colabs_remove_docs"
  test "test_colabs_remove_docs_nil_proj_args" do
    #proj = nil
    @project = nil
    colab_user_ids = [2,3]
    assert colabs_remove_docs(colab_user_ids) == false, "Project not nil."
  end

  #test good project argument, nil user ids to "colabs_remove_docs"
  test "test_colabs_remove_docs_nil_colabs_args" do
    #proj = projects(:proj1)
    @project = projects(:proj1)
    colab_user_ids = nil
    assert colabs_remove_docs(colab_user_ids) == false, "Collaborators not nil."
  end

  #test good project argument, blank user ids to "colabs_remove_docs"
  test "test_colabs_remove_docs_empty_colabs_args" do
    #proj = projects(:proj1)
    @project = projects(:proj1)
    colab_user_ids = []
    assert colabs_remove_docs(colab_user_ids) == false, "Collaborators not empty."
  end

  #---------------------------------------------------------------------
  ### Test "colabs_remove_doc" method ###
  #Test good arguemnts to "colabs_remove_doc" (for single doc)
  test "test_colabs_remove_doc_good_args" do
    colab_user_ids = [2,3]
    doc = documents(:doc1) 
    assert colabs_remove_doc(colab_user_ids, doc) == true, "User ids or doc is likely nil."
  end
  
  #Test nil user id arguments, good doc to "colabs_remove_doc" (for single doc)
  test "test_colabs_remove_doc_nil_users_arg" do
    colab_user_ids = nil
    doc = documents(:doc1)
    assert colabs_remove_doc(colab_user_ids, doc) == false, "User ids not nil."
  end
  
  #Test empty user id arguments, good doc to "colabs_remove_doc" (for single doc)
  test "test_colabs_remove_doc_empty_users_arg" do
    colab_user_ids = []
    doc = documents(:doc1)
    assert colabs_remove_doc(colab_user_ids, doc) == false, "User ids not empty."
  end
  
  #Test good user ids, nil doc arguemnt to "colabs_remove_doc" (for single doc)
  test "test_colabs_remove_doc_nil_proj_arg" do
    colab_user_ids = [2,3]
    doc = nil
    assert colabs_remove_doc(colab_user_ids, doc) == false, "Document not nil."
  end

  #---------------------------------------------------------------------
  ### Test "colab_check_doc" ###
  #Test good arguments to "colab_check_doc"
  test "test_colab_check_doc_good_args" do
    proj = projects(:proj1)
    doc = documents(:doc1)
    assert colab_check_doc(proj, doc) == true, "Project or document is nil."
  end

  #Test nil project argument, good doc to "colab_check_doc"
  test "test_colab_check_doc_nil_proj_arg" do
    proj = nil
    doc = documents(:doc1)
    assert colab_check_doc(proj, doc) == false, "Project is not nil."
  end
  
  #Test good project, nil doc argument to "colab_check_doc"
  test "test_colab_check_doc_nil_doc_arg" do
    proj = projects(:proj1)
    doc = nil
    assert colab_check_doc(proj, doc) == false, "Document is not nil."
  end
  
  #---------------------------------------------------------------------
  ### Test "is_project_colab" method ###
  #Test user is a collaborator for "is_project_colab"
  test "test_is_project_colab_user_is_colab" do
    user2 = users(:user2)
    assert is_project_colab(user2) == true, "User not a collaborator."
  end

  #Test user is not a collaborator for "is_project_colab"
  test "test_is_project_colab_user_not_colab" do
    user1 = users(:user1)
    assert is_project_colab(user1) == false, "User is a collaborator."
  end
  
  #---------------------------------------------------------------------
  ### Test "add_doc" method ###
  #Test good arguments to "add_doc"
  test "test_add_doc_good_arg" do
    proj = projects(:proj1)
    doc_id = 5
    assert add_doc(proj, doc_id) == true, "Project is nil."
  end

  #Test nil project arguments to "add_doc"
  test "test_add_doc_nil_proj_arg" do
    proj = nil
    doc_id = 2
    assert add_doc(proj, doc_id) == false, "Project is not nil."
  end

  #Test good project argument, nil doc id to "add_doc"
  test "test_add_doc_nil_doc_id_arg" do
    proj = projects(:proj1)
    doc_id = nil
    assert add_doc(proj, doc_id) == false, "Document id is not nil."
  end
  
  #Test good project argument, empty doc id to "add_doc"
  test "test_add_doc_empty_doc_id_arg" do
    proj = projects(:proj1)
    doc_id = []
    assert add_doc(proj, doc_id) == false, "Document id is not empty."
  end
  #---------------------------------------------------------------------
  ### Test "remove_docs_checked" method ###
  #Test good arguments to "remove_docs_checked"
  test "test_remove_docs_checked_good_args" do
    proj = projects(:proj1)
    checked = [1,2] #ids of docs to be removed from project
    assert remove_docs_checked(proj, checked) == true, "Project is nil."
  end

  #Test nil project argument, good checked docs to "remove_docs_checked"
  test "test_remove_docs_checked_nil_proj_arg" do
    proj = nil
    checked = [1,2]
    assert remove_docs_checked(proj, checked) == false, "Project is not nil."
  end
  
  #Test good project, nil checked docs argument to "remove_docs_checked"
  test "test_remove_docs_checked_nil_check_arg" do
    proj = projects(:proj1)
    checked = nil
    assert remove_docs_checked(proj, checked) == false, "checked is not nil."
  end
  
  #---------------------------------------------------------------------
  ### Test "add_collection" method ###
  #Test good arguments to "add_collection"
  test "test_add_collection_good_args" do
    proj = projects(:proj1)
    collection_id = 3
    assert add_collection(proj, collection_id) == true, "Project or collection id is nil."
  end

  #Test nil project argument, good collection id to "add_collection"
  test "test_add_collection_nil_proj_arg" do
    proj = nil
    collection_id = 3
    assert add_collection(proj, collection_id) == false, "Project is not nil."
  end
  
  #Test good project, nil collection id to "add_collection"
  test "test_add_collection_nil_col_id_arg" do
    proj = projects(:proj1)
    collection_id = nil
    assert add_collection(proj, collection_id) == false, "Collection is not nil."
  end
  
  #Test good project, blank collection id to "add_collection"
  test "test_add_collection_blank_col_id_arg" do
    proj = projects(:proj1)
    collection_id = ""
    assert add_collection(proj, collection_id) == false, "Collection is not blank."
  end

  #---------------------------------------------------------------------
  ### Test "remove_project_collections" method
  #Test good arguments to "remove_project_collections"
  test "test_remove_collection_checked_good_args" do
    proj = projects(:proj1)
    checked = [3,4] #ids of collections to be removed from project
    assert remove_collection_checked(proj, checked) == true, "Collection or ids is bad."
  end
  
  #Test nil project argument, good checked to "remove_project_collections"
  test "test_remove_collection_checked_nil_proj_arg" do
    proj = nil
    checked = [3,4] #ids of collections to be removed from project
    assert remove_collection_checked(proj, checked) == false, "Project is not nil."
  end
  
  #Test good project, nil checked arguments to "remove_project_collections"
  test "test_remove_collection_checked_nil_checked_arg" do
    proj = projects(:proj1)
    checked = nil #ids of collections to be removed from project
    assert remove_collection_checked(proj, checked) == false, "Collection id list is not nil."
  end
  
  #Test good project, empty checked arguments to "remove_project_collections"
  test "test_remove_collection_checked_empty_checked_arg" do
    proj = projects(:proj1)
    checked = [] #ids of collections to be removed from project
    assert remove_collection_checked(proj, checked) == false, "Collection id list is not empty."
  end

  #---------------------------------------------------------------------
  ### Test change owner methods ###
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
    #proj = projects(:proj1)
    @project = projects(:proj1)
    assert change_owner(user_id) == true, "Project is nil."
  end
  
  #test nil project argument, good user to "change_owner"
  test "test_change_owner_nil_project_arg" do
    user1 = users(:user1)
    user_id = user1.id
    #proj_bad = nil
    @project = nil
    assert change_owner(user_id) == false, "Project is not nil."
  end
    
  #test good project, nil user argument for "change_owner"
  test "test_change_owner_nil_user_arg" do
    user_bad = nil
    #proj = projects(:proj1)
    @project = projects(:proj1)
    assert change_owner(user_bad) == false, "User is not nil."
  end
  
  #test empty string user id for "change_owner"
  test "test_change_owner_empty_user_str_arg" do
    user_bad = ""
    #proj = projects(:proj1)
    @project = projects(:proj1)
    assert change_owner(user_bad) == false, "User sting is not empty."
  end

  #---------------------------------------------------------------------
  ### Test project destroy and cleanup methods
  #Test good aruments to "project_clean"
  test "test_project_clean_good_arg" do
    #proj = projects(:proj1)
    @project = projects(:proj1)
    assert project_clean() == true, "Project is nil."
  end

  #Test nil arguments to "project_clean"
  test "test_project_clean_nil_proj_arg" do
    #proj = nil
    @project = nil
    assert project_clean() == false, "Project is not nil."
  end
  
  #Test successful "project_docs_clean"
  test "test_project_docs_clean_good" do
    #proj = projects(:proj1)
    @project = projects(:proj1)
    assert project_docs_clean() == true, "Project is nil."
  end
  
  #Test nil project arguemnt to "project_docs_clean"
  test "test_project_docs_clean_nil_proj" do
    #proj = nil
    @project = nil
    assert project_docs_clean() == false, "Project is not nil."
  end
  
  #Test successful "project_collections_clean"
  test "test_project_collections_clean_good" do
    #proj = projects(:proj1)
    @project = projects(:proj1)
    assert project_docs_clean() == true, "Project is nil."
  end
  
  #Test fail "project_collections_clean"
  test "test_project_collections_clean_bad" do
    #proj = projects(:proj1)
    @project = nil
    assert project_docs_clean() == false, "Project is not nil."
  end

end
