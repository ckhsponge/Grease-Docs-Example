ActionController::Routing::Routes.draw do |map|
  map.resources :people

  map.resources :people

  map.resources :exams

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  map.resources :exams do |exam|
    exam.resources :people
  end
  map.exam_edit_people 'exams/:id/edit_people', :controller => 'exams', :action => "edit_people"
  map.exam_cancel_edit_people 'exams/:id/cancel_edit_people', :controller => 'exams', :action => "cancel_edit_people"
  map.exam_save_people 'exams/:id/save_people', :controller => 'exams', :action => "save_people"
  map.exam_save_people_continue 'exams/:id/save_people_continue', :controller => 'exams', :action => "save_people_continue"
  map.exam_revert_people 'exams/:id/revert_people', :controller => 'exams', :action => "revert_people"
  #map.resources :people

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "exams"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
