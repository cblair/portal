class HomeController < ApplicationController
  def index
  end
  
  def dashboard
    current_user_id = nil
    if current_user
      current_user_id = current_user.id
    end
    
    @root_collections = Collection.where( :collection_id => nil, 
                                          :user_id => current_user_id)
    if current_user_id != nil
      @root_collections += Collection.where( :collection_id => nil, 
                                            :user_id => nil)
    end
    
    @owned_docs = Document.where(:user_id => current_user.id).limit(5)
    
    @colab_docs = current_user.documents
    
    respond_to do |format|
      format.html 
      #format.json { render json: {} }
    end
  end

end
