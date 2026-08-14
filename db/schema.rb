# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_08_13_130100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assignments", force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "brands", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "calendar_events", force: :cascade do |t|
    t.string "event_type"
    t.integer "profile_id"
    t.string "name"
    t.datetime "from_date"
    t.datetime "to_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "external_id"
    t.index ["profile_id", "provider", "external_id"], name: "index_calendar_events_on_profile_provider_and_external_id", unique: true
  end

  create_table "change_log_entries", force: :cascade do |t|
    t.string "title", null: false
    t.text "summary", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_change_log_entries_on_published_at"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.text "file_data"
    t.string "website_url"
    t.string "contact_email"
    t.string "contact_phone"
    t.string "linkedin_url"
    t.string "twitter_handle"
    t.string "instagram_handle"
    t.string "facebook_url"
    t.string "youtube_url"
    t.string "tiktok_handle"
    t.datetime "founded_at"
    t.boolean "is_public", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "image_data"
    t.string "stripe_customer_id"
    t.index ["name"], name: "index_companies_on_name_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["stripe_customer_id"], name: "index_companies_on_stripe_customer_id", unique: true, where: "(stripe_customer_id IS NOT NULL)"
  end

  create_table "company_assignments", force: :cascade do |t|
    t.string "role"
    t.integer "user_id"
    t.integer "profile_id"
    t.integer "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "profile_id"], name: "index_company_assignments_on_company_id_and_profile_id", unique: true
    t.index ["company_id", "user_id"], name: "index_company_assignments_on_company_id_and_user_id", unique: true
  end

  create_table "company_plans", force: :cascade do |t|
    t.integer "company_id"
    t.integer "plan_id"
    t.string "status", default: "active", null: false
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.boolean "cancel_at_period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "billing_interval"
    t.string "stripe_subscription_id"
    t.string "stripe_subscription_item_id"
    t.string "stripe_price_id"
    t.index ["company_id", "plan_id"], name: "index_company_plans_on_company_id_and_plan_id"
    t.index ["stripe_subscription_id"], name: "index_company_plans_on_stripe_subscription_id", unique: true, where: "(stripe_subscription_id IS NOT NULL)"
    t.index ["stripe_subscription_item_id"], name: "index_company_plans_on_stripe_subscription_item_id", unique: true, where: "(stripe_subscription_item_id IS NOT NULL)"
  end

  create_table "contextual_messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "sender_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_contextual_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_contextual_messages_on_sender_id"
  end

  create_table "conversation_memberships", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.bigint "user_id", null: false
    t.datetime "last_read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_memberships_on_conversation_id_and_user_id", unique: true
    t.index ["conversation_id"], name: "index_conversation_memberships_on_conversation_id"
    t.index ["user_id"], name: "index_conversation_memberships_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.string "context_type", null: false
    t.bigint "context_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["context_type", "context_id"], name: "index_conversations_on_context"
    t.index ["context_type", "context_id"], name: "index_conversations_on_context_type_and_context_id", unique: true
  end

  create_table "credits", force: :cascade do |t|
    t.bigint "profile_id", null: false
    t.bigint "job_id"
    t.bigint "project_id"
    t.bigint "company_id"
    t.string "role", null: false
    t.string "project_name", null: false
    t.string "company_name"
    t.date "starts_on"
    t.date "ends_on"
    t.string "location"
    t.text "description"
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["company_id"], name: "index_credits_on_company_id"
    t.index ["job_id"], name: "index_credits_on_job_id"
    t.index ["profile_id", "job_id"], name: "index_credits_on_profile_id_and_job_id", unique: true, where: "(job_id IS NOT NULL)"
    t.index ["profile_id", "starts_on"], name: "index_credits_on_profile_id_and_starts_on"
    t.index ["profile_id", "visible"], name: "index_credits_on_profile_id_and_visible"
    t.index ["profile_id"], name: "index_credits_on_profile_id"
    t.index ["project_id"], name: "index_credits_on_project_id"
  end

  create_table "crew_assignments", force: :cascade do |t|
    t.bigint "crew_position_id", null: false
    t.bigint "profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crew_position_id", "profile_id"], name: "index_crew_assignments_on_crew_position_id_and_profile_id", unique: true
    t.index ["crew_position_id"], name: "index_crew_assignments_on_crew_position_id"
    t.index ["profile_id"], name: "index_crew_assignments_on_profile_id"
  end

  create_table "crew_positions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "title", null: false
    t.integer "headcount", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.float "pay_min"
    t.float "pay_max"
    t.integer "pay_period"
    t.index ["job_id"], name: "index_crew_positions_on_job_id"
  end

  create_table "crew_shortlist_memberships", force: :cascade do |t|
    t.bigint "crew_shortlist_id", null: false
    t.bigint "profile_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crew_shortlist_id", "profile_id"], name: "index_crew_shortlist_memberships_on_list_and_profile", unique: true
    t.index ["crew_shortlist_id"], name: "index_crew_shortlist_memberships_on_crew_shortlist_id"
    t.index ["profile_id"], name: "index_crew_shortlist_memberships_on_profile_id"
  end

  create_table "crew_shortlists", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "created_by_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_crew_shortlists_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_crew_shortlists_on_company_id"
    t.index ["created_by_id"], name: "index_crew_shortlists_on_created_by_id"
  end

  create_table "equipment", force: :cascade do |t|
    t.string "name"
    t.integer "brand_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "equipment_assignments", force: :cascade do |t|
    t.integer "equipment_id"
    t.integer "profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "experiences", force: :cascade do |t|
    t.integer "profile_id", null: false
    t.string "title", null: false
    t.string "company_name", null: false
    t.integer "company_id"
    t.string "start_month"
    t.string "start_year"
    t.string "end_month"
    t.string "end_year"
    t.boolean "currently_active", default: false, null: false
    t.text "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_experiences_on_profile_id"
  end

  create_table "industries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "industry_assignments", force: :cascade do |t|
    t.bigint "industry_id", null: false
    t.string "assignable_type", null: false
    t.bigint "assignable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignable_type", "assignable_id"], name: "index_industry_assignments_on_assignable"
    t.index ["industry_id", "assignable_type", "assignable_id"], name: "index_industry_assignments_uniqueness", unique: true
    t.index ["industry_id"], name: "index_industry_assignments_on_industry_id"
  end

  create_table "job_applications", force: :cascade do |t|
    t.integer "job_id"
    t.integer "profile_id"
    t.integer "status", default: 0
    t.jsonb "question_answers", default: {}
    t.datetime "submitted_at"
    t.datetime "reviewed_at"
    t.datetime "withdrawn_at"
    t.datetime "decision_at"
    t.text "internal_notes"
    t.integer "reviewed_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "profile_id"], name: "index_job_applications_on_job_id_and_profile_id", unique: true
  end

  create_table "job_invitations", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "profile_id"
    t.bigint "invited_by_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "token"
    t.index ["invited_by_id"], name: "index_job_invitations_on_invited_by_id"
    t.index ["job_id", "email"], name: "index_job_invitations_on_job_id_and_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["job_id", "profile_id"], name: "index_job_invitations_on_job_id_and_profile_id", unique: true
    t.index ["job_id"], name: "index_job_invitations_on_job_id"
    t.index ["profile_id"], name: "index_job_invitations_on_profile_id"
    t.index ["token"], name: "index_job_invitations_on_token", unique: true
  end

  create_table "job_requirements", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "requirement_type", null: false
    t.bigint "requirement_id", null: false
    t.integer "importance", null: false
    t.integer "source", default: 0, null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "requirement_type", "requirement_id", "importance"], name: "index_job_requirements_on_job_requirement_and_importance", unique: true
    t.index ["job_id"], name: "index_job_requirements_on_job_id"
    t.index ["requirement_type", "requirement_id"], name: "index_job_requirements_on_requirement"
    t.check_constraint "importance = ANY (ARRAY[0, 1])", name: "job_requirements_valid_importance"
    t.check_constraint "requirement_type::text = ANY (ARRAY['Occupation'::character varying, 'Skill'::character varying, 'Equipment'::character varying]::text[])", name: "job_requirements_supported_requirement_type"
    t.check_constraint "source = ANY (ARRAY[0, 1])", name: "job_requirements_valid_source"
  end

  create_table "jobs", force: :cascade do |t|
    t.integer "company_id"
    t.string "title"
    t.integer "workplace_type"
    t.integer "employment_type"
    t.boolean "requires_travel"
    t.boolean "is_visa_sponsorship_available"
    t.float "pay_min"
    t.float "pay_max"
    t.integer "pay_period"
    t.boolean "is_active", default: true
    t.integer "status", default: 1
    t.datetime "published_at"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "archived_at"
    t.datetime "closed_at"
    t.datetime "filled_at"
    t.datetime "application_deadline"
    t.integer "created_by"
    t.boolean "editable_by_company", default: true
    t.jsonb "questions", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "project_id"
    t.date "work_dates", default: [], null: false, array: true
    t.datetime "completed_at"
    t.integer "posting_type", default: 0, null: false
    t.index ["project_id"], name: "index_jobs_on_project_id"
    t.index ["title"], name: "index_jobs_on_title_trigram", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "location_assignments", force: :cascade do |t|
    t.integer "location_id"
    t.integer "locationable_id"
    t.string "locationable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.string "state"
    t.string "country"
    t.string "zip_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "recipient_id", null: false
    t.bigint "actor_id"
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.string "kind", null: false
    t.text "message", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["read_at"], name: "index_notifications_on_read_at_for_retention", where: "(read_at IS NOT NULL)"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "occupation_assignments", force: :cascade do |t|
    t.integer "occupation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "assignable_type", null: false
    t.integer "assignable_id", null: false
    t.index ["occupation_id", "assignable_type", "assignable_id"], name: "index_occupation_assignments_uniqueness", unique: true
  end

  create_table "occupations", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_occupations_on_name", unique: true
  end

  create_table "plans", force: :cascade do |t|
    t.string "name"
    t.integer "monthly_price_cents"
    t.integer "annual_price_cents"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "key"
    t.text "description"
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.string "stripe_monthly_price_id"
    t.string "stripe_annual_price_id"
    t.index ["key"], name: "index_plans_on_key", unique: true
    t.index ["stripe_annual_price_id"], name: "index_plans_on_stripe_annual_price_id", unique: true, where: "(stripe_annual_price_id IS NOT NULL)"
    t.index ["stripe_monthly_price_id"], name: "index_plans_on_stripe_monthly_price_id", unique: true, where: "(stripe_monthly_price_id IS NOT NULL)"
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "user_id"
    t.string "headline"
    t.text "bio"
    t.string "contact_email"
    t.string "contact_phone_number"
    t.string "website_url"
    t.string "linkedin_url"
    t.string "twitter_handle"
    t.string "instagram_handle"
    t.string "spotify_profile_url"
    t.string "profile_type"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ical_feed_url"
    t.datetime "ical_last_synced_at"
    t.datetime "ical_sync_attempted_at"
    t.text "ical_sync_error"
    t.boolean "show_credits", default: true, null: false
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.date "starts_on"
    t.date "ends_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "archived_at"
    t.index ["company_id", "archived_at"], name: "index_projects_on_company_id_and_archived_at"
    t.index ["company_id", "name"], name: "index_projects_on_company_id_and_name"
    t.index ["company_id"], name: "index_projects_on_company_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "profile_id"
    t.integer "reviewable_id"
    t.string "reviewable_type"
    t.text "body"
    t.jsonb "rating_data", default: {}
    t.float "overall_rating"
    t.datetime "hidden_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "pretty_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "saved_jobs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "job_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_saved_jobs_on_job_id"
    t.index ["user_id", "job_id"], name: "index_saved_jobs_on_user_id_and_job_id", unique: true
    t.index ["user_id"], name: "index_saved_jobs_on_user_id"
  end

  create_table "skill_assignments", force: :cascade do |t|
    t.integer "skill_id"
    t.integer "profile_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "skills", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_skills_on_name", unique: true
  end

  create_table "stripe_events", force: :cascade do |t|
    t.string "stripe_event_id", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_event_id"], name: "index_stripe_events_on_stripe_event_id", unique: true
  end

  create_table "user_plans", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "monthly_price_cents", null: false
    t.integer "annual_price_cents", null: false
    t.boolean "active", default: true, null: false
    t.jsonb "data", default: {}, null: false
    t.string "stripe_monthly_price_id"
    t.string "stripe_annual_price_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_user_plans_on_slug", unique: true
    t.index ["stripe_annual_price_id"], name: "index_user_plans_on_stripe_annual_price_id", unique: true, where: "(stripe_annual_price_id IS NOT NULL)"
    t.index ["stripe_monthly_price_id"], name: "index_user_plans_on_stripe_monthly_price_id", unique: true, where: "(stripe_monthly_price_id IS NOT NULL)"
  end

  create_table "user_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "user_plan_id", null: false
    t.string "status", null: false
    t.string "billing_interval"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "stripe_subscription_item_id"
    t.string "stripe_price_id"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_customer_id"], name: "index_user_subscriptions_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_user_subscriptions_on_stripe_subscription_id", unique: true, where: "(stripe_subscription_id IS NOT NULL)"
    t.index ["stripe_subscription_item_id"], name: "index_user_subscriptions_on_stripe_subscription_item_id", unique: true, where: "(stripe_subscription_item_id IS NOT NULL)"
    t.index ["user_id"], name: "index_user_subscriptions_on_user_id"
    t.index ["user_plan_id"], name: "index_user_subscriptions_on_user_plan_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.datetime "dob"
    t.string "middle_name"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "provider"
    t.string "uid"
    t.boolean "email_notifications_enabled", default: true, null: false
    t.boolean "sms_notifications_enabled", default: false, null: false
    t.boolean "job_alert_notifications_enabled", default: true, null: false
    t.boolean "recommended_role_notifications_enabled", default: true, null: false
    t.boolean "upcoming_job_reminder_notifications_enabled", default: true, null: false
    t.index "((((COALESCE(first_name, ''::character varying))::text || ' '::text) || (COALESCE(last_name, ''::character varying))::text)) gin_trgm_ops", name: "index_users_on_full_name_trigram", using: :gin
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "visits", force: :cascade do |t|
    t.inet "sign_in_ip"
    t.datetime "signed_out_at"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "contextual_messages", "conversations"
  add_foreign_key "contextual_messages", "users", column: "sender_id"
  add_foreign_key "conversation_memberships", "conversations"
  add_foreign_key "conversation_memberships", "users"
  add_foreign_key "credits", "companies"
  add_foreign_key "credits", "jobs"
  add_foreign_key "credits", "profiles"
  add_foreign_key "credits", "projects"
  add_foreign_key "crew_assignments", "crew_positions"
  add_foreign_key "crew_assignments", "profiles"
  add_foreign_key "crew_positions", "jobs"
  add_foreign_key "crew_shortlist_memberships", "crew_shortlists"
  add_foreign_key "crew_shortlist_memberships", "profiles"
  add_foreign_key "crew_shortlists", "companies"
  add_foreign_key "crew_shortlists", "users", column: "created_by_id"
  add_foreign_key "industry_assignments", "industries"
  add_foreign_key "job_invitations", "jobs"
  add_foreign_key "job_invitations", "profiles"
  add_foreign_key "job_invitations", "users", column: "invited_by_id"
  add_foreign_key "job_requirements", "jobs"
  add_foreign_key "jobs", "projects"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "projects", "companies"
  add_foreign_key "saved_jobs", "jobs"
  add_foreign_key "saved_jobs", "users"
  add_foreign_key "user_subscriptions", "user_plans"
  add_foreign_key "user_subscriptions", "users"
end
