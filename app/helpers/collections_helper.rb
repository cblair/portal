module CollectionsHelper
  include DocumentsHelper
  include MetaformsHelper

  #Deletes all ancestor collections
  def collection_recursive_destroy(c)
    c.children.each do |child_c|
      collection_recursive_destroy(child_c)
    end
    
    #destroy all child documents
    c.documents.each do |d|
      d.destroy
    end
    
    c.destroy
  end
  
  
  def validate_collection_helper(collection, ifilter=nil)
    collection.children.each do |sub_collection|
      validate_collection_helper(sub_collection, ifilter)
    end

    #just build up jobs for now
    collection.documents.each do |document|
      #Let's only submit jobs for documents that haven't already
      # been validated AND are filterable...
      if (document.stuffing_raw_file_url != nil)
        puts "INFO: File is raw, not submitting job. ###"  #Skip file, do nothing.
      elsif !document.validated
        job = Job.new(
          :description => "Document #{document.name} " + 
          "validation from collection #{collection.name}"
        )
        job.save
        #TODO: submit_job will likely die if Portal::Application.config.job_type == "threads",
        # because the jobs lock up the PG pool
        job.submit_job(current_user, document, {:ifilter_id => ifilter.id})
      else
        puts "INFO: Document '#{document.name}' already validated, not submitting job."
      end
    end
  end
  
=begin
  #Adds owner of a project as a collaborator
  #NOTE: Not finished
  def add_owner(project, collection)
    if (project == nil or collection == nil)
      return false
    end
    
    if (collection.user_id != project.user_id)
      puts "user is not the project owner, updating... ****************"
      
    end
  end
=end

  #Adds collection to selected project (from collections -> edit -> _form)
  def add_project_col(project, collection)
    #Add this collection to the project
    if !project.collections.collect {|pc| pc.id}.include?(collection.id)
      project.collections << collection
      #add_owner(project, collection) #not finished
    end

    #Add this collection's descendants to the project
    collection.descendants.each do |c|
      if !project.collections.collect {|pc| pc.id}.include?(c.id)
        project.collections << c
      end
    end

    project.save
  end

  #collection inherits project and permissions of parent collection by default
  def inherit_collection(parent_collection)
    #collection is a sub-collection, parent has a project
    if (!parent_collection.projects.empty?)
      add_project_col(parent_collection.projects.first, @collection)
    #collection is a sub-collection, parent dose not have a project
    elsif (parent_collection.projects.empty?)
      @collection.projects.each do |project|
        @collection.projects.delete project
        
        @collection.descendants.each do |c|
          if !c.projects.empty?
            c.projects.delete project
          end
        end
      end
    end
  end
  
  def collection_is_validated(collection)
    suc_valid = true
    
    collection.children.each do |sub_collection|
      suc_valid = suc_valid & (collection_is_validated(sub_collection) == true)
    end
    
    collection.documents.each do |doc|
      suc_valid = suc_valid & (doc.validated == true)
    end
    
    return suc_valid
  end

#-----------------------------------------------------------------------
  #Get all category options, with indentation  
  def get_all_collection_select_options()
    o = []
    
    collections = Collection.roots
    
    if collections == nil
      return o
    end
    
    collections.each do |c|
      get_collection_select_options(c).each do |c_option|
        o << c_option
      end
    end
    o.sort!
    
    return o
  end

  #Makes a list of user's note uploads
  def upload_note_select_for_collection
    retval = Upload.where("user_id = ? AND upload_type = ?",
      @collection.user_id, "note").order("upfile_file_name").collect { |u| [u.upfile_file_name, u.id] }
  end

  #Adds (links) the current collection to the given note file (upload)
  def add_note_collection(upload_id)
    upload = Upload.find(upload_id.to_i)
    
    if not @collection.uploads.include?(upload)
      @collection.uploads << upload
    end
  end

  #Creates a list of checkboxes for removing notes.
  def remove_note_list()
    remove_upload_ids = []
    @collection.uploads.each do |upload|
      remove_upload_ids << upload
    end
    
    return remove_upload_ids
  end

  #Removes the link(s) to notes from this document (just the link(s)).
  def remove_notes_collection(remove_list)
    
    remove_list.each do |upload_id|
      upload = Upload.find(upload_id)
      if ( @collection.uploads.include?(upload) )
        @collection.uploads.delete(upload)
      end
    end
  end


  #Makes form select_options, indenting the children
  def get_collection_select_options(c, level=0)
    retval = []
#=begin
    #TODO: will have to pass in user instead of using current_user
    if not collection_is_viewable(c, current_user)
      return retval
    end
#=end
    retval << [('-' * level) + c.name, c.id]
    c.children.each do |child_c|
      get_collection_select_options(child_c, level + 1).each do |child_c|
        retval << child_c
      end
    end
    
    return retval
  end
  
#----------------------------------------------------------------------
  #checks to see if 
  def collection_is_parent(potential_parent_collection, collection)
    retval = false
    
    if (potential_parent_collection == nil or collection == nil)
      return false
    end
    
    #TODO: ancestry
    if collection.collection == potential_parent_collection
      retval = true
    end
    
    retval = (retval or collection_is_parent(potential_parent_collection, collection.collection))
    
    return retval
  end
end
