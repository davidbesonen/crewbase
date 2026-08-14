namespace :usr do
  resource :settings, only: [ :show, :update ]
  scope "settings", as: :settings do
    resource :billing, only: :show, controller: "billing" do
      post :subscription_checkout
      post :portal
    end
  end
  resources :jobs, only: [ :index, :show ] do
    get :select_company, on: :collection
    get :my_postings, on: :collection
    resource :saved_job, only: [ :create, :destroy ]
    resource :crew, only: :show, controller: "job_crews"
    resources :crew_positions, only: :create
    resources :job_invitations, only: :create
  end
  resources :crew_positions, only: :destroy do
    resources :crew_assignments, only: :create
  end
  resources :crew_assignments, only: [ :update, :destroy ]
  resources :saved_jobs, only: [ :index ]
  resources :projects, only: [ :show, :edit, :update, :destroy ] do
    get :select_company, on: :collection
    patch :archive, on: :member
    patch :restore, action: :unarchive, on: :member
  end
  resources :jobs, only: [] do
    resources :job_applications, only: [ :new, :create ]
  end
  resources :job_applications, only: [ :index, :show ] do
    patch :update_status, on: :member
    post :add_credit, on: :member
    resources :contextual_messages, only: :create
  end
  resources :job_invitations, only: [ :index ] do
    patch :accept, on: :member
    patch :decline, on: :member
    resources :contextual_messages, only: :create
  end
  resources :conversations, only: [ :index, :show ] do
    resources :contextual_messages, only: :create
  end
  resources :notifications, only: [ :index ] do
    patch :read, on: :member
    delete :clear_read, on: :collection
  end

  resources :companies, shallow: true do
    get :next_form, on: :collection, defaults: { format: :turbo_stream }
    get :previous_form, on: :collection, defaults: { format: :turbo_stream }
    get :search, on: :collection, defaults: { format: :json }
    resource :manager, only: :show, controller: "company_managers"
    resource :plan, only: :show, controller: "company_plans"
    resource :billing_checkout, only: :create, controller: "company_billing_checkouts"
    resource :billing_portal, only: :create, controller: "company_billing_portals"
    resources :reviews, only: [ :new, :create, :edit, :update, :destroy ]
    resources :crew_shortlists, only: [ :index, :create ]
    resources :projects, only: [ :index, :new, :create ]
    scope module: :companies do
      resources :applications, only: [ :index ]
      resources :jobs, except: [ :show ], shallow: false
    end
  end

  resources :crew_shortlists, only: [ :show, :destroy ] do
    resources :memberships,
      controller: "crew_shortlist_memberships",
      only: [ :create, :destroy ],
      param: :profile_id
  end

  resources :dashboards, only: [ :index ] do
    get :quick_search, on: :collection, defaults: { format: :json }
  end
  resources :profiles, only: [ :index ]

  resources :profiles, only: [ :show, :edit, :update ] do
    resources :credits, except: [ :index, :show ]
    resources :job_invitations, only: [ :create ]
    get :next_page, on: :member, defaults: { format: :turbo_stream }
    get :previous_page, on: :member, defaults: { format: :turbo_stream }
    get :toggle_occupation_selection, on: :member, defaults: { format: :turbo_stream }
    get :toggle_skill_selection, on: :member, defaults: { format: :turbo_stream }
    get :toggle_equipment_selection, on: :member, defaults: { format: :turbo_stream }
    get :edit_calendar, on: :member
    patch :update_calendar, on: :member, defaults: { format: :turbo_stream }
    resources :reviews, only: [ :new, :create, :edit, :update, :destroy ]
    resources :calendar_events, only: [ :create, :destroy ], param: :date do
      get :toggle_date_selection, on: :collection, defaults: { format: :turbo_stream }
      get :destroy_all, on: :collection, defaults: { format: :turbo_stream }
      get :previous_month, on: :collection, defaults: { format: :turbo_stream }
      get :next_month, on: :collection, defaults: { format: :turbo_stream }
    end
  end
end
