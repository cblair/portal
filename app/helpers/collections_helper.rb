module CollectionsHelper
  include DocumentsHelper

  
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
      job = Job.new(
        :description => "Document #{document.name} " + 
        "validation from collection #{collection.name}"
      )
      job.save
      #TODO: submit_job will likely die if Portal::Application.config.job_type == "threads",
      # because the jobs lock up the PG pool
      job.submit_job(current_user, document, {:ifilter_id => ifilter.id})
    end
  end
  
  #Adds collection to selected project (from collections -> edit -> _form)
  def add_project_col(project, collection)
    #Add this collection to the project
    if !project.collections.collect {|pc| pc.id}.include?(collection.id)
      project.collections << collection
    end

    #Add this collection's descendants to the project
    collection.descendants.each do |c|
      if !project.collections.collect {|pc| pc.id}.include?(c.id)
        project.collections << c
      end
    end

    project.save
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
    
    return o
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
