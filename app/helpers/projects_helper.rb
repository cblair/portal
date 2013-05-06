module ProjectsHelper
  #creates a list of collaborators for a project collaborators table
  def colab_list_get()
    if (@project == nil)
      return false
    end
    
    #creates a list of collaborators with access to this project
    colab_list = Collaborator.order("user_email").where("project_id = ?", @project.id)
    #colab_list.uniq! #removes extra users from list (so they only appear once)
    return colab_list
  end
=begin  
  #this function may no longer be needed because of new collaboratar table
  #creates a list of collaborators for a project from documents
  def colab_list_get_from_doc(project)
    if project == nil or project == ""
      return false
    end
    
    docs = Document.where("project_id = ?", project.id) #gets all documentss for the project
    user_list = User.all #gets a list of all users
    colab_list = [] #creates empty list of current collaborators
    
    #creates a list of collaborators with access to this project (TODO: better code?)
	docs.each do |doc|
      user_list.each do |user|
        if user.documents.include?(doc)
          colab_list << user
        end
      end
    end
    colab_list.uniq! #removes extra users from list (so they only appear once)
    return colab_list
  end
=end  
  #adds a collaborator to documents (via user documents)
  #def colab_add_to_docs(project, user)
  def colab_add_to_docs(user)
    if (@project == nil or user == nil)
      return false
    end
    docs = Document.where("project_id = ?", @project.id) #gets all docs for the project
    
    #Add collaborator to project documents
    docs.each do |doc|
      if user != nil
        if not user.documents.include?(doc)
          user.documents << doc
          user.save
        end
      else
        return false #user is nil
      end #end if user != nil
    end #end docs.each
    return true  
  end
  
  #adds a collaborator to a project and all its documents
  def colab_add(user)
    if (@project == nil or user == nil)
      return false
    end
    
    if Collaborator.exists?(:user_id => user.id) #avoids duplicate collaborators
      return true
    end
      
    colab = Collaborator.new
    colab.update_attributes(:project_id => @project.id, :project_name => @project.name,
      :user_id => user.id, :user_email => user.email)
    colab_add_to_docs(user)
    return true    
  end
  
  #removes a collaborator from a project
  def colab_remove_project(colab_user_ids)
    if @project == nil or colab_user_ids == nil or colab_user_ids.blank?
      return false
    end
    
    Collaborator.where(:user_id => colab_user_ids).destroy_all
    return true
  end
  
  #removes multiple collaborators from multiple documents (via user documents)
  def colabs_remove_docs(colab_user_ids)
    if (@project == nil or colab_user_ids == nil or colab_user_ids.blank?)
      return false
    end
    docs = Document.where("project_id = ?", @project.id) #gets all documentss for the project

    docs.each do |doc|
      if colab_user_ids
        User.find(colab_user_ids).each do |user|
          user.documents.delete(doc) #Remove collaborator
        end
      end #end if colab_user_ids
    end #end docs.each do |doc|    
    return true
  end

  #removes collaborators from a single document
  def colabs_remove_doc(colab_user_ids, doc)
    if (colab_user_ids == nil or colab_user_ids.blank? or doc == nil)
      return false
    end
    
    User.find(colab_user_ids).each do |user|
      user.documents.delete(doc)
    end
    return true
  end

  #checks document's collaborator state, sets if needed.  Used when adding a doc to a project.
  def colab_check_doc(project, doc)
    if (project == nil or doc == nil)
      return false
    end
    
    colabs = Collaborator.where("project_id = ?", project.id)
      
    colabs.each do |colab|
      user = User.find(colab.user_id)
      if user != nil
        if not user.documents.include?(doc)
          user.documents << doc
          user.save
        end
      else
        return false #user is nil
      end #end if user != nil
    end #colabs.each do |colab|
    return true
  end
  
  #adds a document to a project
  def add_doc(project, doc_id)
    if (project == nil or doc_id == nil or doc_id.blank?)
      @add_doc_err = true
      return false
    end
    
    doc = Document.find(doc_id) #for adding documents
    doc.update_attributes(:project_id => project.id) #adds document to project
    colab_check_doc(project, doc)
    @add_doc_err = false
    return true
  end
  
  #removes documents from a project
  def remove_docs_checked(project, checked)
    if (project == nil or checked == nil or checked.blank?)
      @remove_doc_err = true
      return false
    end
    
    docs = Document.where("project_id = ?", project.id) #list of documents in the project
    #looks for checked documents and removes them
    colab_user_ids = Collaborator.where("project_id = ?", project.id).pluck(:user_id) #for removing collaborators
    
    checked.each do |check_id|  
      if docs.find(check_id)
        doc = docs.find(check_id)
        doc.update_attributes(:project_id => nil)
        colabs_remove_doc(colab_user_ids, doc)
      end
    end
    @remove_doc_err = false
    return true
  end

  #adds a collection to a project
  def add_collection(project, collection_id)
    if (project == nil or collection_id == nil or collection_id.blank?)
      add_col_err = true
      return false
    end
    
    collection = Collection.find(collection_id)
    #collection.update_attributes(:project_id => project.id) #is this code needed?
    
    collection.documents.each do |doc|
      doc_id = doc.id
      add_doc(project, doc_id)
    end
  
    add_col_err = false
    return true
  end

  #checks to see if user is a collaborator
  def is_project_colab(user)
    if Collaborator.exists?(:user_id => user.id)
      return true
    else
      return false
    end
  end

  #changes the owner of a project and all of its documents
  def change_owner(target_user_id)
    if (@project == nil or target_user_id == nil or target_user_id.blank?)
      @user_id_err = true #user selected "none" or error
      return false
    end
    if (target_user_id.blank? or target_user_id == nil)
      @user_id_err = true #user selected "none" or error
      return false
    end
    
    target_user = User.find(target_user_id) #finds selected user
    docs = Document.where("project_id = ?", @project.id) #gets an array of documents with the given project ID

    docs.each do |d|
      d.update_attributes(:user_id => target_user.id) #changes user ID of documents to target user    
    end
    @project.update_attributes(:user_id => target_user.id) #changes current project's user ID to target user's ID
      
    if is_project_colab(target_user) #if target user is a collaborator
      user_ids = Array.new(1, target_user.id)
      colab_remove_project(user_ids)
    end
    
    @user_id_err = false
    return true
  end
  
  #performs cleanup when destroying a project
  def project_clean()
    if @project == nil
      return false
    end
    
    #gets list of collaborators for removal
    colab_user_ids = Collaborator.where("project_id = ?", @project.id).pluck(:user_id)
    colabs_remove_docs(colab_user_ids) 				#removes collaborators from documents
    colab_remove_project(colab_user_ids) 			#removes collaborators from a project
    project_docs_clean()		 					#removes documents from a project
    return true
  end
  
  #removes docs from a project on destroy
  def project_docs_clean()
    if @project == nil
      return false
    end
    
    docs = Document.where("project_id = ?", @project.id) #list of documents in the project
    
    docs.each do |doc|
      doc.update_attributes(:project_id => nil)
    end
    return true
  end
  
end
