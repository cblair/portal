module ProjectsHelper
  # creates a list of collaborators for a project
  def colab_list_get (project)
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
  
  #adds a collaborator to a project and all its documents
  def colab_add (project, user)
    if (project != nil and user != nil)
      docs = Document.where("project_id = ?", project.id) #gets all docs for the project
      
      #Add collaborator to project
      docs.each do |doc|
        if user != nil
          if not user.documents.include?(doc)
            user.documents << doc
            user.save
          end
        else
          return false #user is nil
        end
      end
    else
      return false #project is nil
    end
    return true
  end
  
  # removes a collaborator from a project and all its documents
  def colab_remove (project)
     if project != nil
      docs = Document.where("project_id = ?", project.id) #gets all documentss for the project
      #TODO: more error checking?
      #Remove collaborators
      docs.each do |doc|
        if params[:colab_user_ids]
          User.find(params[:colab_user_ids]).each do |user|
            user.documents.delete(doc)
          end
        end
      end
    else
      return false #project is nil
    end
    return true
  end
  
  def add_users (project)
    #TODO: Add documents through projects?
  end

  #changes the owner of a project and all of its documents
  def change_owner (project, target_user_id)
    if project == nil or project == ""
      return false
    end
    
    if (target_user_id != "" and target_user_id != nil)
      target_user = User.find(target_user_id) #finds selected user
		# gets an array of documents with the given project ID
      docs = Document.where("project_id = ?", project.id) #TODO: also check for users ID?
		# changes user ID of documents to target user    
      docs.each do |d|
        d.update_attributes(:user_id => target_user.id)
      end
		# TODO: collections code here?
		# changes current project's user ID to target user's ID    	    
	  project.update_attributes(:user_id => target_user.id)
	  @user_id_err = false
	  return true
    else
      @user_id_err = true		#user selected "none" or error
      return false
    end
  end

end
