Rails.application.routes.draw do
  draw :admin
  draw :usr
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  post "stripe/webhooks", to: "stripe_webhooks#create", as: :stripe_webhook

  root "marketing#show"
  get "meet-the-team", to: "marketing#team", as: :meet_the_team
  get "job-postings/:id", to: "public_job_postings#show", as: :public_job_posting
  get "job-invitations/:token", to: "public_job_invitations#show", as: :public_job_invitation
  patch "job-invitations/:token/accept", to: "public_job_invitations#accept", as: :accept_public_job_invitation
  resources :change_log_entries, only: :index, path: "changelog"

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
