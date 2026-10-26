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

ActiveRecord::Schema[8.1].define(version: 2026_10_26_180000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "actor_id", null: false
    t.jsonb "changeset", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "reason", null: false
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_admin_audit_events_on_actor_id"
    t.index ["created_at"], name: "index_admin_audit_events_on_created_at"
    t.index ["subject_type", "subject_id"], name: "index_admin_audit_events_on_subject"
  end

  create_table "assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role_id"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "calendar_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type"
    t.string "external_id"
    t.datetime "from_date"
    t.string "name"
    t.integer "profile_id"
    t.string "provider"
    t.datetime "to_date"
    t.datetime "updated_at", null: false
    t.index ["profile_id", "provider", "external_id"], name: "index_calendar_events_on_profile_provider_and_external_id", unique: true
  end

  create_table "change_log_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.text "summary", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_change_log_entries_on_published_at"
  end

  create_table "companies", force: :cascade do |t|
    t.string "contact_email"
    t.string "contact_phone"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "facebook_url"
    t.text "file_data"
    t.datetime "founded_at"
    t.text "image_data"
    t.string "instagram_handle"
    t.boolean "is_public", default: true
    t.string "linkedin_url"
    t.string "name"
    t.datetime "restricted_at"
    t.string "stripe_customer_id"
    t.string "tiktok_handle"
    t.string "twitter_handle"
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.string "youtube_url"
    t.index ["name"], name: "index_companies_on_name_trigram", opclass: :gin_trgm_ops, using: :gin
    t.index ["restricted_at"], name: "index_companies_on_restricted_at"
    t.index ["stripe_customer_id"], name: "index_companies_on_stripe_customer_id", unique: true, where: "(stripe_customer_id IS NOT NULL)"
  end

  create_table "company_assignments", force: :cascade do |t|
    t.integer "company_id"
    t.datetime "created_at", null: false
    t.integer "profile_id"
    t.string "role"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["company_id", "profile_id"], name: "index_company_assignments_on_company_id_and_profile_id", unique: true
    t.index ["company_id", "user_id"], name: "index_company_assignments_on_company_id_and_user_id", unique: true
  end

  create_table "company_plans", force: :cascade do |t|
    t.string "billing_interval"
    t.boolean "cancel_at_period_end"
    t.integer "company_id"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.integer "plan_id"
    t.string "status", default: "active", null: false
    t.string "stripe_price_id"
    t.string "stripe_subscription_id"
    t.string "stripe_subscription_item_id"
    t.datetime "updated_at", null: false
    t.index ["company_id", "plan_id"], name: "index_company_plans_on_company_id_and_plan_id"
    t.index ["stripe_subscription_id"], name: "index_company_plans_on_stripe_subscription_id", unique: true, where: "(stripe_subscription_id IS NOT NULL)"
    t.index ["stripe_subscription_item_id"], name: "index_company_plans_on_stripe_subscription_item_id", unique: true, where: "(stripe_subscription_item_id IS NOT NULL)"
  end

  create_table "contextual_messages", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "event_key"
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "event_key"], name: "index_contextual_messages_on_conversation_id_and_event_key", unique: true
    t.index ["conversation_id"], name: "index_contextual_messages_on_conversation_id"
    t.index ["sender_id"], name: "index_contextual_messages_on_sender_id"
  end

  create_table "conversation_memberships", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_memberships_on_conversation_id_and_user_id", unique: true
    t.index ["conversation_id"], name: "index_conversation_memberships_on_conversation_id"
    t.index ["user_id"], name: "index_conversation_memberships_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "context_id", null: false
    t.string "context_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["context_type", "context_id"], name: "index_conversations_on_context"
    t.index ["context_type", "context_id"], name: "index_conversations_on_context_type_and_context_id", unique: true
  end

  create_table "credits", force: :cascade do |t|
    t.bigint "company_id"
    t.string "company_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "ends_on"
    t.bigint "job_id"
    t.string "location"
    t.bigint "profile_id", null: false
    t.bigint "project_id"
    t.string "project_name", null: false
    t.string "role", null: false
    t.date "starts_on"
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
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
    t.datetime "created_at", null: false
    t.bigint "crew_position_id", null: false
    t.bigint "job_offer_id"
    t.bigint "profile_id", null: false
    t.datetime "updated_at", null: false
    t.index ["crew_position_id", "profile_id"], name: "index_crew_assignments_on_crew_position_id_and_profile_id", unique: true
    t.index ["crew_position_id"], name: "index_crew_assignments_on_crew_position_id"
    t.index ["job_offer_id"], name: "index_crew_assignments_on_job_offer_id", unique: true
    t.index ["profile_id"], name: "index_crew_assignments_on_profile_id"
  end

  create_table "crew_positions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "headcount", default: 1, null: false
    t.bigint "job_id", null: false
    t.float "pay_max"
    t.float "pay_min"
    t.integer "pay_period"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_crew_positions_on_job_id"
  end

  create_table "crew_shortlist_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "crew_shortlist_id", null: false
    t.bigint "profile_id", null: false
    t.datetime "updated_at", null: false
    t.index ["crew_shortlist_id", "profile_id"], name: "index_crew_shortlist_memberships_on_list_and_profile", unique: true
    t.index ["crew_shortlist_id"], name: "index_crew_shortlist_memberships_on_crew_shortlist_id"
    t.index ["profile_id"], name: "index_crew_shortlist_memberships_on_profile_id"
  end

  create_table "crew_shortlists", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_crew_shortlists_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_crew_shortlists_on_company_id"
    t.index ["created_by_id"], name: "index_crew_shortlists_on_created_by_id"
  end

  create_table "equipment", force: :cascade do |t|
    t.integer "brand_id"
    t.string "category_key"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["category_key"], name: "index_equipment_on_category_key", unique: true
  end

  create_table "equipment_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "equipment_id"
    t.integer "profile_id"
    t.datetime "updated_at", null: false
  end

  create_table "experiences", force: :cascade do |t|
    t.integer "company_id"
    t.string "company_name", null: false
    t.datetime "created_at", null: false
    t.boolean "currently_active", default: false, null: false
    t.string "end_month"
    t.string "end_year"
    t.integer "profile_id", null: false
    t.string "start_month"
    t.string "start_year"
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_id"], name: "index_experiences_on_profile_id"
  end

  create_table "industries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "industry_assignments", force: :cascade do |t|
    t.bigint "assignable_id", null: false
    t.string "assignable_type", null: false
    t.datetime "created_at", null: false
    t.bigint "industry_id", null: false
    t.datetime "updated_at", null: false
    t.index ["assignable_type", "assignable_id"], name: "index_industry_assignments_on_assignable"
    t.index ["industry_id", "assignable_type", "assignable_id"], name: "index_industry_assignments_uniqueness", unique: true
    t.index ["industry_id"], name: "index_industry_assignments_on_industry_id"
  end

  create_table "job_applications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "decision_at"
    t.text "internal_notes"
    t.integer "job_id"
    t.integer "profile_id"
    t.jsonb "question_answers", default: {}
    t.datetime "reviewed_at"
    t.integer "reviewed_by"
    t.integer "status", default: 0
    t.datetime "submitted_at"
    t.datetime "updated_at", null: false
    t.datetime "withdrawn_at"
    t.index ["job_id", "profile_id"], name: "index_job_applications_on_job_id_and_profile_id", unique: true
  end

  create_table "job_contracts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id", null: false
    t.index ["job_id"], name: "index_job_contracts_on_job_id"
    t.index ["uploaded_by_id"], name: "index_job_contracts_on_uploaded_by_id"
  end

  create_table "job_invitations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "invited_by_id", null: false
    t.bigint "job_id", null: false
    t.bigint "profile_id"
    t.datetime "responded_at"
    t.integer "status", default: 0, null: false
    t.string "token"
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_job_invitations_on_invited_by_id"
    t.index ["job_id", "email"], name: "index_job_invitations_on_job_id_and_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["job_id", "profile_id"], name: "index_job_invitations_on_job_id_and_profile_id", unique: true
    t.index ["job_id"], name: "index_job_invitations_on_job_id"
    t.index ["profile_id"], name: "index_job_invitations_on_profile_id"
    t.index ["token"], name: "index_job_invitations_on_token", unique: true
  end

  create_table "job_offers", force: :cascade do |t|
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.bigint "cancelled_by_id"
    t.datetime "created_at", null: false
    t.bigint "crew_position_id"
    t.string "currency", null: false
    t.datetime "ends_at", null: false
    t.datetime "expires_at"
    t.bigint "job_application_id", null: false
    t.string "pay_unit", null: false
    t.bigint "profile_id", null: false
    t.decimal "rate", precision: 12, scale: 2, null: false
    t.datetime "responded_at"
    t.string "role", null: false
    t.bigint "sender_id", null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.text "terms"
    t.datetime "updated_at", null: false
    t.index ["cancelled_by_id"], name: "index_job_offers_on_cancelled_by_id"
    t.index ["crew_position_id"], name: "index_job_offers_on_crew_position_id"
    t.index ["job_application_id"], name: "index_job_offers_on_job_application_id"
    t.index ["job_application_id"], name: "one_pending_offer_per_application", unique: true, where: "(status = 0)"
    t.index ["profile_id"], name: "index_job_offers_on_profile_id"
    t.index ["sender_id"], name: "index_job_offers_on_sender_id"
  end

  create_table "job_requirements", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.integer "importance", null: false
    t.bigint "job_id", null: false
    t.bigint "requirement_id", null: false
    t.string "requirement_type", null: false
    t.integer "source", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "requirement_type", "requirement_id", "importance"], name: "index_job_requirements_on_job_requirement_and_importance", unique: true
    t.index ["job_id"], name: "index_job_requirements_on_job_id"
    t.index ["requirement_type", "requirement_id"], name: "index_job_requirements_on_requirement"
    t.check_constraint "importance = ANY (ARRAY[0, 1])", name: "job_requirements_valid_importance"
    t.check_constraint "requirement_type::text = ANY (ARRAY['Occupation'::character varying::text, 'Skill'::character varying::text, 'Equipment'::character varying::text])", name: "job_requirements_supported_requirement_type"
    t.check_constraint "source = ANY (ARRAY[0, 1])", name: "job_requirements_valid_source"
  end

  create_table "jobs", force: :cascade do |t|
    t.datetime "application_deadline"
    t.datetime "archived_at"
    t.datetime "closed_at"
    t.integer "company_id"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "created_by"
    t.boolean "editable_by_company", default: true
    t.integer "employment_type"
    t.datetime "ends_at"
    t.datetime "filled_at"
    t.boolean "is_active", default: true
    t.boolean "is_visa_sponsorship_available"
    t.float "pay_max"
    t.float "pay_min"
    t.integer "pay_period"
    t.integer "posting_type", default: 0, null: false
    t.string "preferred_capability_keys", default: [], null: false, array: true
    t.string "preferred_equipment_family_keys", default: [], null: false, array: true
    t.text "preferred_equipment_text"
    t.text "preferred_skills_text"
    t.bigint "project_id"
    t.datetime "published_at"
    t.jsonb "questions", default: []
    t.string "required_capability_keys", default: [], null: false, array: true
    t.string "required_equipment_family_keys", default: [], null: false, array: true
    t.text "required_equipment_text"
    t.text "required_skills_text"
    t.boolean "requires_travel"
    t.datetime "restricted_at"
    t.boolean "schedule_has_times", default: true, null: false
    t.datetime "starts_at"
    t.integer "status", default: 1
    t.string "title"
    t.datetime "updated_at", null: false
    t.date "work_dates", default: [], null: false, array: true
    t.integer "workplace_type"
    t.index ["project_id"], name: "index_jobs_on_project_id"
    t.index ["restricted_at"], name: "index_jobs_on_restricted_at"
    t.index ["title"], name: "index_jobs_on_title_trigram", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "location_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "location_id"
    t.integer "locationable_id"
    t.string "locationable_type"
    t.datetime "updated_at", null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.string "zip_code"
  end

  create_table "moderation_decisions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "moderator_id", null: false
    t.text "notes", null: false
    t.string "previous_status", null: false
    t.bigint "safety_report_id", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["moderator_id"], name: "index_moderation_decisions_on_moderator_id"
    t.index ["safety_report_id"], name: "index_moderation_decisions_on_safety_report_id"
  end

  create_table "network_connections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "introduction"
    t.bigint "recipient_id", null: false
    t.datetime "responded_at"
    t.bigint "sender_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index "LEAST(sender_id, recipient_id), GREATEST(sender_id, recipient_id)", name: "network_connections_unique_pair", unique: true
    t.index ["recipient_id"], name: "index_network_connections_on_recipient_id"
    t.index ["sender_id"], name: "index_network_connections_on_sender_id"
    t.check_constraint "sender_id <> recipient_id", name: "network_connections_distinct_users"
  end

  create_table "network_job_shares", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.text "note"
    t.bigint "recipient_id", null: false
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "sender_id", "recipient_id"], name: "network_job_shares_unique_recipient", unique: true
    t.index ["job_id"], name: "index_network_job_shares_on_job_id"
    t.index ["recipient_id"], name: "index_network_job_shares_on_recipient_id"
    t.index ["sender_id"], name: "index_network_job_shares_on_sender_id"
    t.check_constraint "sender_id <> recipient_id", name: "network_job_shares_distinct_users"
  end

  create_table "notification_deliveries", force: :cascade do |t|
    t.datetime "attempted_at"
    t.datetime "created_at", null: false
    t.string "deduplication_key", null: false
    t.string "failure_class"
    t.string "kind", null: false
    t.jsonb "payload", default: {}, null: false
    t.bigint "recipient_id", null: false
    t.datetime "sent_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["deduplication_key"], name: "index_notification_deliveries_on_deduplication_key", unique: true
    t.index ["recipient_id"], name: "index_notification_deliveries_on_recipient_id"
    t.index ["status", "created_at"], name: "index_notification_deliveries_on_status_and_created_at"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "actor_id"
    t.datetime "created_at", null: false
    t.string "kind", null: false
    t.text "message", null: false
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["read_at"], name: "index_notifications_on_read_at_for_retention", where: "(read_at IS NOT NULL)"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "occupation_assignments", force: :cascade do |t|
    t.integer "assignable_id", null: false
    t.string "assignable_type", null: false
    t.datetime "created_at", null: false
    t.integer "occupation_id"
    t.datetime "updated_at", null: false
    t.index ["occupation_id", "assignable_type", "assignable_id"], name: "index_occupation_assignments_uniqueness", unique: true
  end

  create_table "occupations", force: :cascade do |t|
    t.string "category_key"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["category_key"], name: "index_occupations_on_category_key", unique: true
    t.index ["name"], name: "index_occupations_on_name", unique: true
  end

  create_table "plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "annual_price_cents"
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.text "description"
    t.string "key"
    t.integer "monthly_price_cents"
    t.string "name"
    t.integer "position", default: 0, null: false
    t.string "stripe_annual_price_id"
    t.string "stripe_monthly_price_id"
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_plans_on_key", unique: true
    t.index ["stripe_annual_price_id"], name: "index_plans_on_stripe_annual_price_id", unique: true, where: "(stripe_annual_price_id IS NOT NULL)"
    t.index ["stripe_monthly_price_id"], name: "index_plans_on_stripe_monthly_price_id", unique: true, where: "(stripe_monthly_price_id IS NOT NULL)"
  end

  create_table "product_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_key", null: false
    t.bigint "job_id"
    t.string "name", null: false
    t.bigint "subject_id"
    t.string "subject_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_key"], name: "index_product_events_on_event_key", unique: true
    t.index ["job_id"], name: "index_product_events_on_job_id"
    t.index ["name", "created_at"], name: "index_product_events_on_name_and_created_at"
    t.index ["subject_type", "subject_id"], name: "index_product_events_on_subject"
    t.index ["user_id"], name: "index_product_events_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.text "bio"
    t.string "capability_keys", default: [], null: false, array: true
    t.datetime "completed_at"
    t.string "contact_email"
    t.string "contact_phone_number"
    t.datetime "created_at", null: false
    t.string "equipment_family_keys", default: [], null: false, array: true
    t.text "equipment_text"
    t.string "headline"
    t.string "ical_feed_url"
    t.datetime "ical_last_synced_at"
    t.datetime "ical_sync_attempted_at"
    t.text "ical_sync_error"
    t.string "instagram_handle"
    t.string "linkedin_url"
    t.string "profile_type"
    t.boolean "show_credits", default: true, null: false
    t.text "skills_text"
    t.string "spotify_profile_url"
    t.string "twitter_handle"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "website_url"
    t.text "work_examples"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "archived_at"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "ends_on"
    t.string "name", null: false
    t.date "starts_on"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "archived_at"], name: "index_projects_on_company_id_and_archived_at"
    t.index ["company_id", "name"], name: "index_projects_on_company_id_and_name"
    t.index ["company_id"], name: "index_projects_on_company_id"
  end

  create_table "recommendation_feedbacks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.string "reason", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["job_id"], name: "index_recommendation_feedbacks_on_job_id"
    t.index ["user_id", "job_id"], name: "index_recommendation_feedbacks_on_user_id_and_job_id", unique: true
    t.index ["user_id"], name: "index_recommendation_feedbacks_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "hidden_at"
    t.float "overall_rating"
    t.integer "profile_id"
    t.jsonb "rating_data", default: {}
    t.integer "reviewable_id"
    t.string "reviewable_type"
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "pretty_name"
    t.datetime "updated_at", null: false
  end

  create_table "safety_reports", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "details", null: false
    t.bigint "reporter_id", null: false
    t.string "status", default: "open", null: false
    t.bigint "subject_id", null: false
    t.string "subject_label", null: false
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.index ["reporter_id"], name: "index_safety_reports_on_reporter_id"
    t.index ["status", "created_at"], name: "index_safety_reports_on_status_and_created_at"
    t.index ["subject_type", "subject_id"], name: "index_safety_reports_on_subject"
  end

  create_table "saved_jobs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["job_id"], name: "index_saved_jobs_on_job_id"
    t.index ["user_id", "job_id"], name: "index_saved_jobs_on_user_id_and_job_id", unique: true
    t.index ["user_id"], name: "index_saved_jobs_on_user_id"
  end

  create_table "skill_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "profile_id"
    t.integer "skill_id"
    t.datetime "updated_at", null: false
  end

  create_table "skills", force: :cascade do |t|
    t.string "category_key"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["category_key"], name: "index_skills_on_category_key", unique: true
    t.index ["name"], name: "index_skills_on_name", unique: true
  end

  create_table "stripe_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "processed_at"
    t.string "stripe_event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_event_id"], name: "index_stripe_events_on_stripe_event_id", unique: true
  end

  create_table "user_blocks", force: :cascade do |t|
    t.bigint "blocked_user_id", null: false
    t.bigint "blocker_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_user_id"], name: "index_user_blocks_on_blocked_user_id"
    t.index ["blocker_id", "blocked_user_id"], name: "index_user_blocks_on_blocker_id_and_blocked_user_id", unique: true
    t.index ["blocker_id"], name: "index_user_blocks_on_blocker_id"
    t.check_constraint "blocker_id <> blocked_user_id", name: "user_blocks_different_users"
  end

  create_table "user_plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "annual_price_cents", null: false
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.integer "monthly_price_cents", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "stripe_annual_price_id"
    t.string "stripe_monthly_price_id"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_user_plans_on_slug", unique: true
    t.index ["stripe_annual_price_id"], name: "index_user_plans_on_stripe_annual_price_id", unique: true, where: "(stripe_annual_price_id IS NOT NULL)"
    t.index ["stripe_monthly_price_id"], name: "index_user_plans_on_stripe_monthly_price_id", unique: true, where: "(stripe_monthly_price_id IS NOT NULL)"
  end

  create_table "user_subscriptions", force: :cascade do |t|
    t.string "billing_interval"
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.string "status", null: false
    t.string "stripe_customer_id"
    t.string "stripe_price_id"
    t.string "stripe_subscription_id"
    t.string "stripe_subscription_item_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "user_plan_id", null: false
    t.index ["stripe_customer_id"], name: "index_user_subscriptions_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_user_subscriptions_on_stripe_subscription_id", unique: true, where: "(stripe_subscription_id IS NOT NULL)"
    t.index ["stripe_subscription_item_id"], name: "index_user_subscriptions_on_stripe_subscription_item_id", unique: true, where: "(stripe_subscription_item_id IS NOT NULL)"
    t.index ["user_id"], name: "index_user_subscriptions_on_user_id"
    t.index ["user_plan_id"], name: "index_user_subscriptions_on_user_plan_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "dob"
    t.string "email"
    t.boolean "email_notifications_enabled", default: true, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.boolean "job_alert_notifications_enabled", default: true, null: false
    t.string "last_name"
    t.string "middle_name"
    t.datetime "onboarding_completed_at"
    t.string "onboarding_intent"
    t.string "phone"
    t.string "provider"
    t.boolean "recommended_role_notifications_enabled", default: true, null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "restricted_at"
    t.boolean "sms_notifications_enabled", default: false, null: false
    t.string "uid"
    t.boolean "upcoming_job_reminder_notifications_enabled", default: true, null: false
    t.datetime "updated_at", null: false
    t.index "((((COALESCE(first_name, ''::character varying))::text || ' '::text) || (COALESCE(last_name, ''::character varying))::text)) gin_trgm_ops", name: "index_users_on_full_name_trigram", using: :gin
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["restricted_at"], name: "index_users_on_restricted_at"
  end

  create_table "visits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.inet "sign_in_ip"
    t.datetime "signed_out_at"
    t.datetime "updated_at", null: false
    t.integer "user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_audit_events", "users", column: "actor_id"
  add_foreign_key "contextual_messages", "conversations"
  add_foreign_key "contextual_messages", "users", column: "sender_id"
  add_foreign_key "conversation_memberships", "conversations"
  add_foreign_key "conversation_memberships", "users"
  add_foreign_key "credits", "companies"
  add_foreign_key "credits", "jobs"
  add_foreign_key "credits", "profiles"
  add_foreign_key "credits", "projects"
  add_foreign_key "crew_assignments", "crew_positions"
  add_foreign_key "crew_assignments", "job_offers"
  add_foreign_key "crew_assignments", "profiles"
  add_foreign_key "crew_positions", "jobs"
  add_foreign_key "crew_shortlist_memberships", "crew_shortlists"
  add_foreign_key "crew_shortlist_memberships", "profiles"
  add_foreign_key "crew_shortlists", "companies"
  add_foreign_key "crew_shortlists", "users", column: "created_by_id"
  add_foreign_key "industry_assignments", "industries"
  add_foreign_key "job_contracts", "jobs"
  add_foreign_key "job_contracts", "users", column: "uploaded_by_id"
  add_foreign_key "job_invitations", "jobs"
  add_foreign_key "job_invitations", "profiles"
  add_foreign_key "job_invitations", "users", column: "invited_by_id"
  add_foreign_key "job_offers", "crew_positions", on_delete: :nullify
  add_foreign_key "job_offers", "job_applications"
  add_foreign_key "job_offers", "profiles"
  add_foreign_key "job_offers", "users", column: "cancelled_by_id"
  add_foreign_key "job_offers", "users", column: "sender_id"
  add_foreign_key "job_requirements", "jobs"
  add_foreign_key "jobs", "projects"
  add_foreign_key "moderation_decisions", "safety_reports"
  add_foreign_key "moderation_decisions", "users", column: "moderator_id"
  add_foreign_key "network_connections", "users", column: "recipient_id"
  add_foreign_key "network_connections", "users", column: "sender_id"
  add_foreign_key "network_job_shares", "jobs"
  add_foreign_key "network_job_shares", "users", column: "recipient_id"
  add_foreign_key "network_job_shares", "users", column: "sender_id"
  add_foreign_key "notification_deliveries", "users", column: "recipient_id"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "product_events", "jobs"
  add_foreign_key "product_events", "users"
  add_foreign_key "projects", "companies"
  add_foreign_key "recommendation_feedbacks", "jobs"
  add_foreign_key "recommendation_feedbacks", "users"
  add_foreign_key "safety_reports", "users", column: "reporter_id"
  add_foreign_key "saved_jobs", "jobs"
  add_foreign_key "saved_jobs", "users"
  add_foreign_key "user_blocks", "users", column: "blocked_user_id"
  add_foreign_key "user_blocks", "users", column: "blocker_id"
  add_foreign_key "user_subscriptions", "user_plans"
  add_foreign_key "user_subscriptions", "users"
end
