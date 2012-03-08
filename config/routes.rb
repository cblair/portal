Portal::Application.routes.draw do
  resources :posts

  resources :data_columns

  resources :tests

  resources :data_column_ints

  resources :metadata

  resources :data

  get "home/index"
  root :to => 'Home#index'
  match '/home'     =>  "Home#index"

  resource :metadatum
  
  #I did something wrong to have to imply all of these
  match '/DataIO'  =>  "DataIO#index"
  match '/DataIO/csv_import'  =>  "DataIO#csv_import"
  match '/metadata/:id/data' => 'Metadata#showassociated'
  match '/Metadata' => "Metadata#index"
  match '/Metadata/show' => "Metadata#show"
  match 'Metadata/testjson' => 'Metadata#testjson'
  match 'Metadata/:id' => 'Metadata#show'
  
  match '/Data' => "Data#index"
  
  match 'DataColumns/get_data_column_json' => 'DataColumns#get_data_column_json'
  match 'DataColumns/:id' => 'DataColumns#show'
  
  match 'DataColumnInts/:id' => 'DataColumnInts#show'
  
  match '/Viz' => "Viz#index"
  match '/Viz' => "Viz#show"
  match '/viz/:id/:chart_type/:y/:x' => 'viz#chart'
  
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


