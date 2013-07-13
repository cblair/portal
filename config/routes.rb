Portal::Application.routes.draw do
  match '/jobs/clear_jobs' => "jobs#clear_jobs", :as => :clear_jobs
  resources :jobs

  match "/delayed_job" => DelayedJobWeb, :anchor => false

  resources :searches

  resources :notifications
  match '/notifications/send_notification/:id' => "notifications#send_notification", :as => :send_notification

  resources :uploads

  resources :charts
  resources :feeds

  root :to => 'home#index'
  match '/home/dashboard' => "home#dashboard", :as => :home_dashboard
  match '/home/search' => "home#search", :as => :home_search
  match '/home/analyze' => "home#analyze", :as => :home_analyze
  
  #Devise / Users
  devise_for :users

  #Custom displaying of Devise users. Do each of these maunally, because we want to
  # be especially careful what we route to
  match '/users' => "users#index"
  match '/users/:id(.:format)', :to => 'users#index', :as => :user
  match '/users/:id/edit(.:format)', :to => 'users#edit', :as => :edit_user
  
  resources :ifilters

  post '/documents/:id(.:format)', :to => 'documents#show'
  post '/documents(.:format)', :to => 'documents#index'
  match '/documents_manip' => "documents#manip", :as => :document_manip
  match '/documents/search_test' => "documents#search_test", :as => :document_search_test
  resources :documents

  resources :collections
  
  resources :searches
  match '/search/search_all' => "searches#search_all", :as => :search_all
  match '/search/new' => "searches#new", :as => :new_search

  resources :projects
  match '/projects/owner/:id' => "projects#owner", :as => :owner
  match '/projects/add_project_collection/:id' => "projects#add_project_collection", :as => :add_project_collection
  match '/projects/remove_project_collections/:id' => "projects#remove_project_collections", :as => :remove_project_collections
  match '/projects/add_project_doc' => "projects#add_project_doc", :as => :add_project_doc
  match '/projects/remove_project_docs' => "projects#remove_project_docs", :as => :remove_project_docs
  
  resources :roles
  match '/roles/edit_each_user_role/:id' => "roles#edit_each_user_role", :as => :edit_each_user_role
  match '/roles/update_each_user_role/:id' => "roles#update_each_user_role", :as => :update_each_user_role
  
  resources :posts
  
  #I did something wrong to have to imply all of these
  match '/DataIO/csv_import'  =>  "DataIO#csv_import", :as => :csv_import
  match '/DataIO/csv_export/:id'  =>  "DataIO#csv_export", :as => :csv_export, :formats => 'zip'
  match '/DataIO/index'  =>  "DataIO#index", :as => :csv_import
  match '/DataIO/js_upload'  =>  "DataIO#js_upload", :as => :js_upload
  match '/DataIO/jsu_index'  =>  "DataIO#jsu_index", :as => :jsu_csv_import
  
  match '/visualizations' => 'viz#index', :as => 'visualizations'
  match '/chart/:id' => 'viz#chart', :as => 'chart'
  match '/chart/:id/:share_token' => 'viznoauth#sharechart', :as => 'sharechart'
  match '/chart' => 'viz#chart', :as => 'visualize'
  match '/DataIO/index'  =>  "DataIO#index", :as => :data_io_index
  
  #TODO: to document_controller
  match '/collections/validate_doc/:id' =>  "Collections#validate_doc", :as => :validate_doc
  match '/collections/validate_collection/:id' =>  "Collections#validate_collection", :as => :validate_collection
  
  match '/documents/pub_priv_doc/:id' =>  "Documents#pub_priv_doc", :as => :pub_priv_doc
  match '/collections/pub_priv_collection/:id' =>  "Collections#pub_priv_collection", :as => :pub_priv_collection
  
  match '/visualize' => 'viz#chart', :as => 'visualize'

  match '/charts/:id/:last_id' => 'charts#showjson', :as => :chart_update

  #Demo stuff
  match '/tests' => "tests#index"
  match '/tests/index' => "tests#index"
  
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


