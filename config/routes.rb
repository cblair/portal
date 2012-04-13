Portal::Application.routes.draw do
  resources :charts

  root :to => 'home#index'
  devise_for :users
  resources :ifilters

  match '/documents/search_test' => "documents#search_test", :as => :document_search_test
  resources :documents
  match '/documents/manip' => "documents#manip", :as => :document_manip

  resources :collections
  resources :posts
  
  #I did something wrong to have to imply all of these
  match '/DataIO/csv_import'  =>  "DataIO#csv_import", :as => :csv_import
  match '/DataIO/index'  =>  "DataIO#index", :as => :csv_import
  
  match '/visualizations' => 'viz#index', :as => 'visualizations'
  match '/chart/:id' => 'viz#chart', :as => 'chart'
  match '/chart/:id/:share_token' => 'viznoauth#sharechart', :as => 'sharechart'
  match '/chart' => 'viz#chart', :as => 'visualize'
  #Demo stuff
  match '/Movies' => "Movies#index"
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  # root :to => 'welcome#index'
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end


