namespace :admin do
  root "dashboards#show"
  resources :users, only: :index
  resources :companies, only: :index
  resources :jobs, only: :index
  resources :change_log_entries, except: :show
end
