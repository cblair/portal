module CollectionsHelper
  #Deletes all ancestor collections
  def collection_recursive_destroy(c)
    c.collections.each do |child_c|
      collection_recursive_destroy(child_c)
    end
    
    #destroy all child documents
    @collection.documents.each do |d|
      d.destroy
    end
    
    c.destroy
  end
end
