namespace :admin do
  resource :operations, only: :show
  resource :product_metrics, only: :show
  resources :reports, only: [ :index, :show, :update ]
  root "dashboards#show"
  resources :audit_events, only: :index
  resource :billing, only: :show, controller: "billing"
  resources :users, only: [ :index, :show, :update ]
  resources :companies, only: [ :index, :show, :update ]
  resources :jobs, only: [ :index, :show, :update ]
  resources :change_log_entries, except: :show
end
