namespace :usr do
  get "staff-a-gig", to: "staffing_starts#new", as: :new_staffing_start
  post "staff-a-gig", to: "staffing_starts#create", as: :staffing_start
  resource :onboarding, only: [ :show, :update ], controller: "onboarding"
  resources :recommendation_feedback, only: :index
  resources :reports, only: [ :index, :new, :create ]
  resources :user_blocks, only: [ :create, :destroy ]
  resource :network, only: :show, controller: "networks"
  resources :network_connections, only: [ :new, :create, :destroy ] do
    patch :accept, on: :member
    patch :decline, on: :member
  end
  resources :network_job_shares, only: :show
  resource :settings, only: [ :show, :update ]
  scope "settings", as: :settings do
    resource :billing, only: :show, controller: "billing" do
      post :subscription_checkout
      post :portal
    end
  end
  resources :jobs, only: [ :index, :show ] do
    resource :recommendation_feedback, only: [ :create, :destroy ], controller: "recommendation_feedback"
    resources :network_job_shares, only: [ :new, :create ]
    get :select_company, on: :collection
    get :my_postings, on: :collection
    resource :saved_job, only: [ :create, :destroy ]
    resource :crew, only: :show, controller: "job_crews"
    resource :production, only: [ :show, :update ], controller: "job_productions"
    resource :brief, only: :show, controller: "job_briefs"
    resources :production_days, only: [ :create, :update, :destroy ], shallow: false
    resources :crew_holds, only: [ :create, :destroy ], shallow: false
    resources :crew_positions, only: :create
    resources :job_invitations, only: :create
    resources :contracts, only: [ :create, :destroy ], controller: "job_contracts" do
      get :download, on: :member
    end
  end
  resources :crew_positions, only: :destroy do
    resources :crew_assignments, only: :create
    resources :crew_holds, only: [ :create, :destroy ]
  end
  resources :crew_assignments, only: [ :update, :destroy ]
  resources :saved_jobs, only: [ :index ]
  resources :projects, only: [ :show, :edit, :update, :destroy ] do
    resources :project_shows, except: [ :index, :show ]
    resources :crew_plans, only: [ :new, :create ], controller: "project_crew_plans"
    resource :tour_stops, only: [ :new, :create ], controller: "tour_stops"
    get :select_company, on: :collection
    patch :archive, on: :member
    patch :restore, action: :unarchive, on: :member
  end
  resources :jobs, only: [] do
    resources :job_applications, only: [ :new, :create ]
  end
  resources :job_offers, only: [ :index, :new, :create, :show, :update ] do
    get :calendar, on: :member
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
    patch :read_all, on: :collection
    delete :clear_read, on: :collection
  end

  resources :companies, shallow: true do
    get :next_form, on: :collection, defaults: { format: :turbo_stream }
    get :previous_form, on: :collection, defaults: { format: :turbo_stream }
    get :search, on: :collection, defaults: { format: :json }
    resource :job_placement, only: [ :new, :create ], controller: "job_placements"
    resource :manager, only: :show, controller: "company_managers"
    resource :staffing, only: :show, controller: "company_staffing"
    resources :gig_reuses, only: [ :new, :create ]
    resources :gig_templates, only: [ :index, :create, :destroy ], shallow: false
    resources :venues, except: :show, shallow: false
    resources :crew_members, shallow: false do
      post :invitation, on: :member
    end
    resources :crew_imports, only: [ :new, :create, :show, :update ], shallow: false do
      get :template, on: :collection
    end
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
    post :toggle_occupation_selection, on: :member, defaults: { format: :turbo_stream }
    post :toggle_skill_selection, on: :member, defaults: { format: :turbo_stream }
    post :toggle_equipment_selection, on: :member, defaults: { format: :turbo_stream }
    get :edit_calendar, on: :member
    patch :update_calendar, on: :member, defaults: { format: :turbo_stream }
    resources :reviews, only: [ :new, :create, :edit, :update, :destroy ]
    resources :calendar_events, only: [ :create, :destroy ], param: :date do
      post :toggle_date_selection, on: :collection, defaults: { format: :turbo_stream }
      delete :destroy_all, on: :collection, defaults: { format: :turbo_stream }
      get :previous_month, on: :collection, defaults: { format: :turbo_stream }
      get :next_month, on: :collection, defaults: { format: :turbo_stream }
    end
  end
end
