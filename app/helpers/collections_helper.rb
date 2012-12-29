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
end
