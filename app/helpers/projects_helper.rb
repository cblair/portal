module ProjectsHelper

  def add_users (project)
  
  end

  def change_owner (project)
    if (params[:user_name][:id] == "")
      @user_id_err = true		#user selected "none" or error
    else
      @target_user = User.find(params[:user_name][:id]) #finds selected user
	    #puts("*** target user = #{@target_user.email}, id #{@target_user.id}") #debug
      # gets an array of documents with the given project ID
      @docs = Document.where("project_id = ?", project.id)
      # changes user ID of documents to target user    
      @docs.each do |d|
        d.update_attributes(:user_id => @target_user.id)
      end
      # TODO: collections code here?
      # changes current project's user ID to target user's ID    	    
	  project.update_attributes(:user_id => @target_user.id)
    end
  end

end
