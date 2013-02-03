module CollectionsHelper
  include DocumentsHelper
  
  #Deletes all ancestor collections
  def collection_recursive_destroy(c)
    c.collections.each do |child_c|
      collection_recursive_destroy(child_c)
    end
    
    #destroy all child documents
    c.documents.each do |d|
      d.destroy
    end
    
    c.destroy
  end
  
  
  def validate_collection_helper(collection, ifilter=nil)
    suc_valid = true
    
    collection.collections.each do |sub_collection|
      suc_valid = suc_valid & (validate_collection_helper(sub_collection, ifilter) == true)
    end
    
    collection.documents.each do |document|
      suc_valid = suc_valid & validate_document_helper(document, ifilter)
    end
    
    suc_valid = suc_valid & collection.save
    
    return suc_valid
  end
  
  
  def collection_is_validated(collection)
    suc_valid = true
    
    collection.collections.each do |sub_collection|
      suc_valid = suc_valid & (collection_is_validated(sub_collection) == true)
    end
    
    collection.documents.each do |doc|
      suc_valid = suc_valid & (doc.validated == true)
    end
    
    return suc_valid
  end
    
  #recursively sets all (sub) documents 
  def set_pub_priv_collection_helper(collection, public)
    collection.documents.each do |doc|
      doc.public = public
      doc.save
    end
    
    collection.collections.each do |sub_collection|
      set_pub_priv_collection_helper(sub_collection, public)
    end
  end
  
  #Get all category options, with indentation  
  def get_all_collection_select_options()
    o = []
    
    collections = Collection.where(:collection_id => nil)
    
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
    
    #TODO: will have to pass in user instead of using current_user
    if not collection_is_viewable(c, current_user)
      return retval
    end
    
    retval << [('-' * level) + c.name, c.id]
    c.collections.each do |child_c|
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
    
    if collection.collection == potential_parent_collection
      retval = true
    end
    
    retval = (retval or collection_is_parent(potential_parent_collection, collection.collection))
    
    puts "TS" + collection.name
    puts retval
    
    return retval
  end
end
