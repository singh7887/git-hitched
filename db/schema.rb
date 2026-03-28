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

ActiveRecord::Schema[8.1].define(version: 2026_03_23_155929) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "audit_action", ["create", "update", "delete", "state_change", "escalate", "assign", "holly_reply"]
  create_enum "integration_type", ["slack", "teams", "whatsapp", "llm", "discord"]
  create_enum "severity", ["low", "medium", "high", "critical"]
  create_enum "ticket_state", ["new", "open", "in_progress", "pending", "resolved", "closed", "cancelled", "acknowledged", "committed", "overdue", "escalated"]

  create_table "agent_actions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "approved_by"
    t.jsonb "arguments", null: false
    t.uuid "conversation_id"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "executed_at"
    t.integer "iteration", default: 0, null: false
    t.jsonb "previous_state"
    t.text "reasoning"
    t.text "requested_by"
    t.jsonb "result"
    t.text "risk_level", null: false
    t.timestamptz "rolled_back_at"
    t.uuid "rolled_back_by"
    t.uuid "run_id", null: false
    t.text "status", default: "pending", null: false
    t.uuid "tenant_id", null: false
    t.integer "tokens_used", default: 0
    t.text "tool_name", null: false
    t.index ["run_id"], name: "idx_agent_actions_run_id"
    t.index ["status"], name: "idx_agent_actions_status"
    t.index ["tenant_id", "created_at"], name: "idx_agent_actions_tenant_created", order: { created_at: :desc }
    t.index ["tenant_id"], name: "idx_agent_actions_tenant"
  end

  create_table "agent_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.string "level", limit: 15, default: "operational", null: false
    t.jsonb "payload", default: {}, null: false
    t.integer "payload_size_bytes", default: 0, null: false
    t.uuid "tenant_id", null: false
    t.uuid "turn_id", null: false
    t.string "type", limit: 30, null: false
    t.index ["tenant_id", "created_at"], name: "idx_agent_events_tenant_date", order: { created_at: :desc }
    t.index ["turn_id", "created_at"], name: "idx_agent_events_turn"
    t.check_constraint "level::text = ANY (ARRAY['operational'::character varying::text, 'debug'::character varying::text])", name: "agent_events_level_check"
  end

  create_table "agent_memory", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "category", null: false
    t.float "confidence", limit: 24, default: 0.5
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.jsonb "examples", default: []
    t.text "key", null: false
    t.uuid "tenant_id", null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.text "value", null: false
    t.index ["tenant_id", "category"], name: "idx_agent_memory_tenant_category"
    t.index ["tenant_id"], name: "idx_agent_memory_tenant"
    t.unique_constraint ["tenant_id", "category", "key"], name: "agent_memory_tenant_id_category_key_key"
  end

  create_table "agent_token_usage", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "date", default: -> { "CURRENT_DATE" }, null: false
    t.integer "runs", default: 0, null: false
    t.uuid "tenant_id", null: false
    t.bigint "tokens_in", default: 0, null: false
    t.bigint "tokens_out", default: 0, null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["tenant_id", "date"], name: "idx_agent_token_usage_date"
    t.index ["tenant_id"], name: "idx_agent_token_usage_tenant"
    t.unique_constraint ["tenant_id", "date"], name: "agent_token_usage_tenant_id_date_key"
  end

  create_table "ai_conversation_summaries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "channel_id", limit: 50
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "first_message_at"
    t.timestamptz "last_message_at"
    t.integer "message_count", default: 0, null: false
    t.text "summary", null: false
    t.uuid "tenant_id", null: false
    t.string "thread_ts", limit: 50
    t.index ["tenant_id", "created_at"], name: "idx_convo_summaries_tenant", order: { created_at: :desc }
  end

  create_table "ai_conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "channel_id", null: false
    t.jsonb "context_json"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "question", null: false
    t.text "response", null: false
    t.tsvector "search_vector"
    t.uuid "tenant_id"
    t.text "thread_ts"
    t.text "user_id", null: false
    t.index ["search_vector"], name: "idx_ai_conversations_search", where: "(search_vector IS NOT NULL)", using: :gin
    t.index ["tenant_id"], name: "idx_ai_conversations_tenant"
  end

  create_table "ai_feedback", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "conversation_id", null: false
    t.text "correction"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "sentiment", null: false
    t.text "user_id", null: false
    t.check_constraint "sentiment = ANY (ARRAY['positive'::text, 'negative'::text])", name: "ai_feedback_sentiment_check"
  end

  create_table "ai_memory", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "category", null: false
    t.jsonb "examples"
    t.text "key", null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.text "value", null: false

    t.unique_constraint ["category", "key"], name: "ai_memory_category_key_key"
  end

  create_table "ai_suggestions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "category", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.jsonb "data_context"
    t.uuid "property_id"
    t.text "status", default: "pending", null: false
    t.text "suggestion", null: false
    t.uuid "tenant_id"
    t.index ["tenant_id"], name: "idx_ai_suggestions_tenant"
    t.check_constraint "status = ANY (ARRAY['pending'::text, 'accepted'::text, 'dismissed'::text])", name: "ai_suggestions_status_check"
  end

  create_table "api_keys", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.uuid "created_by"
    t.timestamptz "expires_at"
    t.text "key_hash", null: false
    t.string "key_prefix", limit: 12, null: false
    t.timestamptz "last_used_at"
    t.string "name", limit: 200, null: false
    t.jsonb "permissions", default: ["read"], null: false
    t.uuid "tenant_id", null: false
    t.index ["key_hash"], name: "idx_api_keys_hash"
    t.index ["tenant_id"], name: "idx_api_keys_tenant"
    t.unique_constraint ["key_hash"], name: "api_keys_key_hash_key"
  end

  create_table "api_request_log", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.integer "duration_ms"
    t.text "error_msg"
    t.string "message_id", limit: 512
    t.string "method", limit: 16, null: false
    t.string "path", limit: 512, null: false
    t.text "req_headers"
    t.integer "req_size"
    t.text "req_snippet"
    t.text "res_snippet"
    t.integer "status"
    t.uuid "tenant_id"
    t.index ["created_at"], name: "ix_api_request_log_created", order: :desc
    t.index ["message_id"], name: "ix_api_request_log_message_id", where: "(message_id IS NOT NULL)"
    t.index ["path"], name: "ix_api_request_log_path"
  end

  create_table "attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "caption"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.uuid "entity_id", null: false
    t.text "entity_type", null: false
    t.text "file_key", null: false
    t.text "file_name", null: false
    t.text "file_url", null: false
    t.text "mime_type", null: false
    t.integer "size_bytes"
    t.jsonb "tags", default: []
    t.uuid "tenant_id"
    t.text "uploaded_by", default: "dashboard", null: false
    t.index ["entity_type", "entity_id"], name: "idx_attachments_entity"
    t.index ["tenant_id"], name: "idx_attachments_tenant"
  end

  create_table "audit_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.enum "action", null: false, enum_type: "audit_action"
    t.string "actor", limit: 255
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.uuid "entity_id", null: false
    t.string "entity_type", limit: 100, null: false
    t.jsonb "new_values"
    t.jsonb "old_values"
    t.uuid "property_id"
    t.uuid "tenant_id"
    t.index ["created_at"], name: "ix_audit_logs_created_at", order: :desc
    t.index ["entity_type", "entity_id", "created_at"], name: "ix_audit_logs_entity_created", order: { created_at: :desc }
    t.index ["entity_type", "entity_id"], name: "ix_audit_logs_entity"
    t.index ["property_id", "created_at"], name: "ix_audit_logs_property_created", order: { created_at: :desc }, where: "(property_id IS NOT NULL)"
    t.index ["property_id"], name: "ix_audit_logs_property_id", where: "(property_id IS NOT NULL)"
    t.index ["tenant_id"], name: "idx_audit_logs_tenant"
  end

  create_table "calendar_connections", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "access_token"
    t.boolean "active", default: true, null: false
    t.text "calendar_id"
    t.jsonb "config", default: {}, null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "provider", null: false
    t.text "refresh_token"
    t.uuid "tenant_id", null: false
    t.timestamptz "token_expires_at"
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["tenant_id"], name: "idx_calendar_connections_tenant"
    t.unique_constraint ["tenant_id", "provider"], name: "calendar_connections_tenant_id_provider_key"
  end

  create_table "detected_exceptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "context", default: {}, null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "due_at", null: false
    t.uuid "property_id", null: false
    t.string "room_number", limit: 100
    t.string "rule_id", limit: 50, null: false
    t.enum "severity", default: "medium", null: false, enum_type: "severity"
    t.string "status", limit: 50, default: "OPEN", null: false
    t.uuid "tenant_id"
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index "rule_id, property_id, COALESCE(room_number, ''::character varying)", name: "ix_detected_exceptions_lookup", where: "((status)::text = ANY (ARRAY[('OPEN'::character varying)::text, ('ACKNOWLEDGED'::character varying)::text]))"
    t.index ["created_at"], name: "ix_detected_exceptions_created_at", order: :desc
    t.index ["property_id"], name: "ix_detected_exceptions_property_id"
    t.index ["tenant_id"], name: "idx_detected_exceptions_tenant"
  end

  create_table "escalation_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "after_minutes", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", limit: 255, null: false
    t.uuid "property_id"
    t.enum "severity", enum_type: "severity"
    t.uuid "sla_rule_id"
    t.string "target_type", limit: 50, null: false
    t.string "target_value", limit: 500
    t.uuid "tenant_id"
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["created_at"], name: "ix_escalation_rules_created_at", order: :desc
    t.index ["property_id"], name: "ix_escalation_rules_property_id", where: "(property_id IS NOT NULL)"
    t.index ["sla_rule_id"], name: "ix_escalation_rules_sla_rule_id", where: "(sla_rule_id IS NOT NULL)"
    t.index ["tenant_id"], name: "idx_escalation_rules_tenant"
    t.check_constraint "after_minutes >= 0", name: "chk_escalation_minutes"
  end

  create_table "event_invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "invite_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_invites_on_event_id"
    t.index ["invite_id", "event_id"], name: "index_event_invites_on_invite_id_and_event_id", unique: true
    t.index ["invite_id"], name: "index_event_invites_on_invite_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "address"
    t.string "attire"
    t.text "attire_description"
    t.datetime "created_at", null: false
    t.date "date"
    t.text "description"
    t.string "image"
    t.string "location"
    t.string "location_url"
    t.string "maps_url"
    t.string "name"
    t.integer "sort_order"
    t.time "start_time"
    t.string "subtitle"
    t.string "time_description"
    t.datetime "updated_at", null: false
  end

  create_table "exceptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "detection_window_start", null: false, comment: "Start of the detection window (e.g. date_trunc('hour', observed_at)) to dedupe within window"
    t.string "exception_type", limit: 255, null: false
    t.text "message"
    t.jsonb "metadata"
    t.uuid "property_id", null: false
    t.enum "severity", default: "medium", null: false, enum_type: "severity"
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["created_at"], name: "ix_exceptions_created_at", order: :desc
    t.index ["property_id", "created_at"], name: "ix_exceptions_property_created", order: { created_at: :desc }
    t.index ["property_id"], name: "ix_exceptions_property_id"
    t.index ["severity"], name: "ix_exceptions_severity", where: "(severity = ANY (ARRAY['high'::severity, 'critical'::severity]))"
    t.unique_constraint ["property_id", "detection_window_start", "exception_type"], name: "uq_exceptions_detection_window"
  end

  create_table "guests", force: :cascade do |t|
    t.integer "age"
    t.datetime "created_at", null: false
    t.text "dietary_notes"
    t.string "first_name", null: false
    t.bigint "invite_id", null: false
    t.boolean "is_child", default: false, null: false
    t.boolean "is_primary", default: false, null: false
    t.string "last_name"
    t.integer "meal_choice", default: 0
    t.boolean "needs_childcare", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["invite_id"], name: "index_guests_on_invite_id"
  end

  create_table "holly_knowledge", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.float "embedding", limit: 24, array: true
    t.text "embedding_model"
    t.uuid "property_id", null: false
    t.uuid "source_snapshot_log_id"
    t.uuid "tenant_id"
    t.index ["created_at"], name: "idx_holly_knowledge_created", order: :desc
    t.index ["property_id"], name: "idx_holly_knowledge_property"
    t.index ["tenant_id"], name: "idx_holly_knowledge_tenant"
  end

  create_table "holly_skill_metrics", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "avg_tokens", precision: 10, scale: 1, default: "0.0"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.integer "invocations", default: 0, null: false
    t.timestamptz "last_used_at"
    t.integer "negative_outcomes", default: 0, null: false
    t.integer "positive_outcomes", default: 0, null: false
    t.string "skill_name", limit: 100, null: false
    t.uuid "tenant_id", null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false

    t.unique_constraint ["tenant_id", "skill_name"], name: "holly_skill_metrics_tenant_id_skill_name_key"
  end

  create_table "holly_typed_memory", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "confidence", precision: 3, scale: 2, default: "0.5", null: false
    t.text "content", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "expires_at"
    t.string "injection_mode", limit: 20, default: "prompt", null: false
    t.timestamptz "last_accessed_at"
    t.integer "priority", default: 0
    t.uuid "property_id"
    t.text "relevance_tags", default: [], null: false, array: true
    t.string "scope", limit: 20, null: false
    t.string "source", limit: 20, null: false
    t.string "status", limit: 20, default: "active", null: false
    t.uuid "supersedes_memory_id"
    t.uuid "tenant_id", null: false
    t.string "type", limit: 20, null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.uuid "user_id"
    t.index ["expires_at"], name: "idx_typed_memory_expires", where: "(expires_at IS NOT NULL)"
    t.index ["property_id"], name: "idx_typed_memory_property", where: "(property_id IS NOT NULL)"
    t.index ["tenant_id", "scope", "type"], name: "idx_typed_memory_tenant_scope"
    t.index ["tenant_id", "status"], name: "idx_typed_memory_tenant_status", where: "((status)::text = 'active'::text)"
    t.check_constraint "confidence >= 0::numeric AND confidence <= 1::numeric", name: "holly_typed_memory_confidence_check"
    t.check_constraint "injection_mode::text = ANY (ARRAY['prompt'::character varying::text, 'retrieval_only'::character varying::text])", name: "holly_typed_memory_injection_mode_check"
    t.check_constraint "scope::text = ANY (ARRAY['tenant'::character varying::text, 'property'::character varying::text, 'user'::character varying::text, 'session'::character varying::text])", name: "holly_typed_memory_scope_check"
    t.check_constraint "source::text = ANY (ARRAY['explicit'::character varying::text, 'inferred'::character varying::text, 'system'::character varying::text])", name: "holly_typed_memory_source_check"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying::text, 'archived'::character varying::text, 'superseded'::character varying::text])", name: "holly_typed_memory_status_check"
    t.check_constraint "type::text = ANY (ARRAY['preference'::character varying::text, 'identity'::character varying::text, 'workflow'::character varying::text, 'project'::character varying::text, 'constraint'::character varying::text, 'fact'::character varying::text, 'warning'::character varying::text])", name: "holly_typed_memory_type_check"
  end

  create_table "hotel_bookings", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.date "check_in", null: false
    t.date "check_out", null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "currency", default: "usd", null: false
    t.string "email", null: false
    t.string "guest_name", null: false
    t.bigint "invite_id", null: false
    t.text "notes"
    t.string "phone"
    t.datetime "refunded_at"
    t.integer "rooms", default: 1, null: false
    t.string "status", default: "pending", null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.datetime "updated_at", null: false
    t.index ["invite_id"], name: "index_hotel_bookings_on_invite_id"
    t.index ["status"], name: "index_hotel_bookings_on_status"
    t.index ["stripe_checkout_session_id"], name: "index_hotel_bookings_on_stripe_checkout_session_id", unique: true
  end

  create_table "imported_prompts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "category", limit: 100, default: "Imported", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "description", default: ""
    t.text "prompt_text", null: false
    t.text "source_url", null: false
    t.uuid "tenant_id", null: false
    t.string "title", limit: 200, null: false
    t.index ["tenant_id"], name: "idx_imported_prompts_tenant"
  end

  create_table "integration_channels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "channel_ref", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.string "department", limit: 50
    t.uuid "integration_id", null: false
    t.uuid "property_id"
    t.index "integration_id, COALESCE((property_id)::text, '*'::text), COALESCE(department, '*'::character varying)", name: "uq_integration_channels", unique: true
  end

  create_table "integrations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.jsonb "config", default: {}, null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.boolean "is_default", default: false, null: false
    t.string "name", limit: 100, null: false
    t.uuid "tenant_id"
    t.enum "type", null: false, enum_type: "integration_type"
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["tenant_id"], name: "idx_integrations_tenant"
    t.index ["type"], name: "uq_integrations_default_type", unique: true, where: "(is_default = true)"
  end

  create_table "invites", force: :cascade do |t|
    t.boolean "attending"
    t.boolean "children_attending", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.text "notes"
    t.datetime "responded_at"
    t.datetime "updated_at", null: false
  end

  create_table "notification_suppressions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.string "created_by", limit: 255
    t.timestamptz "expires_at"
    t.uuid "property_id"
    t.text "reason"
    t.string "scope", limit: 20, null: false
    t.text "scope_key"
    t.uuid "tenant_id", null: false
    t.string "ticket_qid", limit: 64
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["expires_at"], name: "idx_notification_suppressions_expires"
    t.index ["tenant_id", "property_id", "scope", "scope_key"], name: "uq_notification_suppressions_account_active", unique: true, where: "((scope)::text = 'account'::text)"
    t.index ["tenant_id", "property_id", "scope"], name: "idx_notification_suppressions_tenant_property_scope"
    t.index ["tenant_id", "property_id", "scope_key"], name: "idx_notification_suppressions_scope_key", where: "((scope)::text = 'account'::text)"
    t.index ["tenant_id", "ticket_qid"], name: "idx_notification_suppressions_ticket_qid", where: "((scope)::text = 'ticket'::text)"
    t.index ["tenant_id", "ticket_qid"], name: "uq_notification_suppressions_ticket_active", unique: true, where: "((scope)::text = 'ticket'::text)"
    t.index ["tenant_id"], name: "idx_notification_suppressions_tenant"
    t.check_constraint "scope::text = 'ticket'::text AND ticket_qid IS NOT NULL AND scope_key IS NULL OR scope::text = 'account'::text AND scope_key IS NOT NULL", name: "chk_notification_suppressions_scope_target"
    t.check_constraint "scope::text = ANY (ARRAY['ticket'::character varying::text, 'account'::character varying::text])", name: "notification_suppressions_scope_check"
  end

  create_table "plan_steps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "completed", default: false, null: false
    t.timestamptz "completed_at"
    t.date "date", null: false
    t.text "google_event_id"
    t.text "google_task_id"
    t.text "notes"
    t.integer "step_index", null: false
    t.text "sync_fingerprint"
    t.uuid "task_id", null: false
    t.text "title", null: false
    t.index ["date"], name: "idx_plan_steps_due", where: "(completed = false)"
    t.index ["task_id"], name: "idx_plan_steps_task"
    t.unique_constraint ["task_id", "step_index"], name: "plan_steps_task_id_step_index_key"
  end

  create_table "planned_task_assignees", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "email"
    t.text "name", null: false
    t.text "role", default: "assignee", null: false
    t.uuid "task_id", null: false
    t.uuid "user_id"
    t.index ["task_id"], name: "idx_task_assignees_task"
    t.index ["user_id"], name: "idx_task_assignees_user"
    t.unique_constraint ["task_id", "user_id"], name: "planned_task_assignees_task_id_user_id_key"
  end

  create_table "planned_task_chunks", force: :cascade do |t|
    t.integer "chunk_index", null: false
    t.text "content", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.float "embedding", limit: 24, array: true
    t.uuid "task_id", null: false
    t.uuid "tenant_id", null: false
    t.index ["tenant_id"], name: "idx_task_chunks_tenant"
    t.unique_constraint ["task_id", "chunk_index"], name: "planned_task_chunks_task_id_chunk_index_key"
  end

  create_table "planned_tasks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.uuid "created_by"
    t.text "description", null: false
    t.date "due_date", null: false
    t.time "due_time"
    t.float "embedding", limit: 24, array: true
    t.text "embedding_model", default: "text-embedding-004", null: false
    t.text "file_url"
    t.text "google_event_id"
    t.text "google_task_id"
    t.jsonb "metadata", default: {}, null: false
    t.jsonb "plan"
    t.integer "points"
    t.integer "priority"
    t.text "status", default: "open", null: false
    t.text "sync_fingerprint"
    t.text "task_type"
    t.uuid "template_id"
    t.uuid "tenant_id", null: false
    t.text "title", null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.text "urgency", default: "medium", null: false
    t.index ["tenant_id", "status"], name: "idx_planned_tasks_status"
    t.index ["tenant_id"], name: "idx_planned_tasks_tenant"
  end

  create_table "properties", primary_key: "property_id", id: :uuid, default: nil, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "balance_warning_minutes", default: 120, null: false, comment: "Minutes since midnight (local time) when the FIN warning window opens. Default 900 (3 PM). Replaces the old \"minutes before cutoff\" interpretation."
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.integer "default_cooldown_minutes"
    t.time "end_of_day_cutoff_local", default: "2000-01-01 15:00:00"
    t.string "escalation_contact", limit: 100
    t.integer "escalation_minutes_critical", default: 15, null: false
    t.integer "escalation_minutes_high", default: 30, null: false
    t.integer "extended_stay_high_urgency_days"
    t.integer "followup_minutes_critical", default: 30, null: false
    t.integer "followup_minutes_high", default: 60, null: false
    t.integer "followup_minutes_low", default: 240, null: false
    t.integer "followup_minutes_medium", default: 120, null: false
    t.integer "followup_tier2_after", default: 3, null: false
    t.integer "followup_tier3_after", default: 3, null: false
    t.boolean "has_extended_stay", default: false
    t.string "manager_slack_channel_id", limit: 50
    t.string "manager_slack_id", limit: 50
    t.integer "max_followups", default: 10
    t.string "property_code", limit: 50, null: false
    t.string "property_name", limit: 100
    t.time "quiet_hours_end", default: "2000-01-01 06:00:00", null: false
    t.time "quiet_hours_start", default: "2000-01-01 22:00:00", null: false
    t.integer "reminder_lead_minutes"
    t.string "slack_channel_id", limit: 50
    t.uuid "tenant_id"
    t.string "timezone", limit: 50, default: "America/Chicago"
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index "lower((property_name)::text)", name: "ix_properties_name"
    t.index ["active"], name: "ix_properties_active", where: "active"
    t.index ["property_code"], name: "ix_properties_property_code"
    t.index ["tenant_id"], name: "idx_properties_tenant"
    t.unique_constraint ["property_code"], name: "properties_property_code_key"
  end

  create_table "property_department_channels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "channel_id", limit: 50, null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.string "department", limit: 50, null: false
    t.uuid "property_id", null: false
    t.index ["channel_id"], name: "ix_dept_channels_channel"
    t.index ["property_id"], name: "ix_dept_channels_property"
    t.unique_constraint ["property_id", "department"], name: "property_department_channels_property_id_department_key"
  end

  create_table "property_latest_stats", primary_key: "property_id", id: :uuid, default: nil, force: :cascade do |t|
    t.decimal "adr", precision: 10, scale: 2
    t.integer "arrivals"
    t.integer "available"
    t.integer "down_rooms"
    t.integer "due_outs"
    t.date "fin004_early_notified_date"
    t.decimal "occupancy_rate", precision: 5, scale: 4
    t.integer "occupied"
    t.integer "pickup"
    t.decimal "revenue", precision: 14, scale: 2
    t.decimal "revpar", precision: 10, scale: 2
    t.integer "stay_overs"
    t.integer "total_rooms"
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
  end

  create_table "property_stats_forecast", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "confidence_high", precision: 14, scale: 4
    t.decimal "confidence_low", precision: 14, scale: 4
    t.date "forecast_date", null: false
    t.timestamptz "generated_at", default: -> { "now()" }
    t.string "metric", limit: 50, null: false
    t.string "model", limit: 50
    t.decimal "predicted_value", precision: 14, scale: 4
    t.uuid "property_id", null: false
    t.text "reason"
    t.string "status", limit: 30, default: "ready"
    t.index ["property_id", "forecast_date"], name: "idx_stats_forecast_property_date"
    t.unique_constraint ["property_id", "forecast_date", "metric"], name: "property_stats_forecast_property_id_forecast_date_metric_key"
  end

  create_table "property_stats_history", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.decimal "adr", precision: 10, scale: 2
    t.integer "arrivals"
    t.integer "available"
    t.timestamptz "created_at", default: -> { "now()" }
    t.integer "down_rooms"
    t.integer "due_outs"
    t.decimal "occupancy_rate", precision: 6, scale: 4
    t.integer "occupied"
    t.integer "pickup"
    t.uuid "property_id", null: false
    t.decimal "revenue", precision: 14, scale: 2
    t.decimal "revpar", precision: 10, scale: 2
    t.date "stat_date", null: false
    t.integer "stay_overs"
    t.integer "total_rooms"
    t.index ["property_id", "stat_date"], name: "idx_stats_history_property_date", order: { stat_date: :desc }
    t.unique_constraint ["property_id", "stat_date"], name: "property_stats_history_property_id_stat_date_key"
  end

  create_table "push_subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "auth", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "endpoint", null: false
    t.text "p256dh", null: false
    t.uuid "tenant_id"
    t.text "user_agent"
    t.index ["tenant_id"], name: "idx_push_subscriptions_tenant"
    t.unique_constraint ["endpoint"], name: "push_subscriptions_endpoint_key"
  end

  create_table "qid_counters", primary_key: ["property_code", "date"], force: :cascade do |t|
    t.integer "counter", default: 0, null: false
    t.date "date", null: false
    t.string "property_code", limit: 50, null: false
  end

  create_table "raw_ingestion_log", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.string "ingestion_type", limit: 20, default: "single"
    t.string "message_id", limit: 512, null: false
    t.text "raw_email", null: false
    t.uuid "tenant_id"
    t.index ["created_at"], name: "ix_raw_ingestion_log_created_at", order: :desc
    t.index ["message_id"], name: "ix_raw_ingestion_log_message_id"
    t.index ["tenant_id"], name: "ix_raw_ingestion_log_tenant"
    t.unique_constraint ["message_id"], name: "uq_raw_ingestion_log_message_id"
  end

  create_table "responses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.string "created_by", limit: 255
    t.boolean "is_internal", default: false, null: false
    t.uuid "property_id", null: false
    t.uuid "ticket_id", null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["created_at"], name: "ix_responses_created_at", order: :desc
    t.index ["property_id", "created_at"], name: "ix_responses_property_created", order: { created_at: :desc }
    t.index ["property_id"], name: "ix_responses_property_id"
    t.index ["ticket_id"], name: "ix_responses_ticket_id"
  end

  create_table "rsvps", force: :cascade do |t|
    t.boolean "attending"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "guest_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_rsvps_on_event_id"
    t.index ["guest_id", "event_id"], name: "index_rsvps_on_guest_id_and_event_id", unique: true
    t.index ["guest_id"], name: "index_rsvps_on_guest_id"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.timestamptz "expires_at", null: false
    t.uuid "tenant_id", null: false
    t.text "token_hash", null: false
    t.uuid "user_id", null: false
    t.index ["expires_at"], name: "idx_sessions_expires"
    t.index ["token_hash"], name: "idx_sessions_token"
    t.unique_constraint ["token_hash"], name: "sessions_token_hash_key"
  end

  create_table "sla_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", limit: 255, null: false
    t.uuid "property_id"
    t.integer "resolution_minutes", null: false
    t.integer "response_minutes", null: false
    t.enum "severity", null: false, enum_type: "severity"
    t.uuid "tenant_id"
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["created_at"], name: "ix_sla_rules_created_at", order: :desc
    t.index ["property_id", "severity"], name: "ix_sla_rules_property_severity", where: "is_active"
    t.index ["property_id"], name: "ix_sla_rules_property_id", where: "(property_id IS NOT NULL)"
    t.index ["tenant_id"], name: "idx_sla_rules_tenant"
    t.check_constraint "response_minutes > 0 AND resolution_minutes > 0", name: "chk_sla_positive"
  end

  create_table "snapshot_analysis_log", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "agreed"
    t.jsonb "comparison_json"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.integer "engine_only"
    t.integer "holly_count"
    t.jsonb "holly_json"
    t.integer "holly_only"
    t.uuid "property_id", null: false
    t.integer "rule_engine_count"
    t.jsonb "rule_engine_json"
    t.timestamptz "snapshot_at", null: false
    t.uuid "tenant_id"
    t.index ["created_at"], name: "idx_snapshot_analysis_log_created_at", order: :desc
    t.index ["property_id"], name: "idx_snapshot_analysis_log_property_id"
  end

  create_table "system_scheduled_jobs", primary_key: "job_key", id: :text, force: :cascade do |t|
    t.integer "attempt_count", default: 0, null: false
    t.text "cron_expr"
    t.integer "interval_seconds"
    t.text "last_error"
    t.timestamptz "last_run_at"
    t.timestamptz "last_success_at"
    t.timestamptz "locked_at"
    t.timestamptz "next_run_at", null: false
    t.text "schedule_kind", null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["next_run_at"], name: "idx_system_scheduled_jobs_next_run"
    t.check_constraint "schedule_kind = ANY (ARRAY['interval'::text, 'cron'::text])", name: "system_scheduled_jobs_schedule_kind_check"
  end

  create_table "task_chat_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "role", null: false
    t.uuid "task_id", null: false
    t.uuid "tenant_id", null: false
    t.uuid "user_id"
    t.index ["task_id", "created_at"], name: "idx_task_chat_messages_task_created"
    t.index ["task_id"], name: "idx_task_chat_messages_task"
    t.index ["tenant_id"], name: "idx_task_chat_messages_tenant"
    t.check_constraint "role = ANY (ARRAY['user'::text, 'assistant'::text])", name: "task_chat_messages_role_check"
  end

  create_table "task_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.uuid "assignee_ids", array: true
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "description", null: false
    t.timestamptz "last_run_at"
    t.jsonb "metadata", default: {}, null: false
    t.timestamptz "next_run_at"
    t.text "rrule"
    t.uuid "tenant_id", null: false
    t.text "title", null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.text "urgency", default: "medium", null: false
    t.index ["next_run_at"], name: "idx_task_templates_next_run", where: "(active = true)"
    t.index ["tenant_id"], name: "idx_task_templates_tenant"
  end

  create_table "tenant_cron_jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.jsonb "channel_target", default: {}, null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.string "cron_expr", limit: 100, null: false
    t.timestamptz "last_run_at"
    t.string "name", limit: 200, null: false
    t.text "prompt_template", null: false
    t.uuid "tenant_id", null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.index ["active"], name: "idx_tenant_cron_jobs_active", where: "(active = true)"
    t.index ["tenant_id"], name: "idx_tenant_cron_jobs_tenant"
  end

  create_table "tenants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.string "domain_pack", limit: 50, default: "hospitality", null: false
    t.string "name", limit: 200, null: false
    t.string "plan", limit: 50, default: "free", null: false
    t.jsonb "settings", default: {}, null: false
    t.string "slug", limit: 100, null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false

    t.unique_constraint ["slug"], name: "tenants_slug_key"
  end

  create_table "ticket_notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "author", default: "dashboard", null: false
    t.text "body", null: false
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "qid", null: false
    t.uuid "ticket_id", null: false
    t.index ["qid"], name: "idx_ticket_notes_qid"
    t.index ["ticket_id"], name: "idx_ticket_notes_ticket_id"
  end

  create_table "ticket_state_transitions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "comment"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.string "created_by", limit: 255
    t.enum "from_state", enum_type: "ticket_state"
    t.uuid "ticket_id", null: false
    t.enum "to_state", null: false, enum_type: "ticket_state"
    t.index ["created_at"], name: "ix_ticket_state_transitions_created_at", order: :desc
    t.index ["ticket_id", "created_at"], name: "ix_ticket_state_transitions_ticket_created", order: { created_at: :desc }
    t.index ["ticket_id"], name: "ix_ticket_state_transitions_ticket_id"
    t.check_constraint "from_state IS DISTINCT FROM to_state", name: "chk_state_change"
  end

  create_table "tickets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "assigned_to", limit: 255
    t.timestamptz "closed_at"
    t.timestamptz "committed_eta"
    t.timestamptz "contacted_at"
    t.string "contacted_by", limit: 100
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.text "description"
    t.uuid "detected_exception_id"
    t.timestamptz "eta_at"
    t.uuid "exception_id"
    t.integer "followup_count", default: 0, null: false
    t.text "guest_impact_label"
    t.integer "guest_impact_score", default: 0
    t.text "holly_followup_question"
    t.timestamptz "holly_followup_sent_at"
    t.timestamptz "last_followup_at"
    t.timestamptz "last_notified_at"
    t.integer "manager_followup_count", default: 0, null: false
    t.jsonb "metadata"
    t.uuid "property_id", null: false
    t.string "qid", limit: 50
    t.enum "severity", default: "medium", null: false, enum_type: "severity"
    t.timestamptz "sla_breached_at"
    t.timestamptz "sla_starts_at", comment: "When set, Slack post is delayed until this time (UTC). Used with tenants.settings.rule_time_windows (active_after)."
    t.timestamptz "sla_warning_sent_at"
    t.string "slack_channel_id", limit: 50
    t.string "slack_message_ts", limit: 50
    t.string "slack_thread_ts", limit: 50
    t.enum "state", default: "new", null: false, enum_type: "ticket_state"
    t.uuid "tenant_id"
    t.string "title", limit: 500, null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.string "work_order_number", limit: 100
    t.index ["assigned_to"], name: "ix_tickets_assigned_to", where: "(assigned_to IS NOT NULL)"
    t.index ["created_at"], name: "ix_tickets_created_at", order: :desc
    t.index ["detected_exception_id"], name: "ix_tickets_detected_exception_id", where: "(detected_exception_id IS NOT NULL)"
    t.index ["exception_id"], name: "ix_tickets_exception_id", where: "(exception_id IS NOT NULL)"
    t.index ["property_id", "created_at"], name: "ix_tickets_property_created", order: { created_at: :desc }
    t.index ["property_id"], name: "ix_tickets_property_id"
    t.index ["qid"], name: "ix_tickets_qid", unique: true, where: "(qid IS NOT NULL)"
    t.index ["slack_channel_id", "slack_message_ts"], name: "ix_tickets_slack", where: "((slack_channel_id IS NOT NULL) AND (slack_message_ts IS NOT NULL))"
    t.index ["state", "eta_at"], name: "ix_tickets_eta_followup", where: "((eta_at IS NOT NULL) AND (state = 'acknowledged'::ticket_state))"
    t.index ["state"], name: "ix_tickets_state"
    t.index ["tenant_id"], name: "idx_tickets_tenant"
    t.index ["work_order_number"], name: "ix_tickets_work_order", where: "(work_order_number IS NOT NULL)"
    t.unique_constraint ["qid"], name: "tickets_qid_key"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "avatar_url"
    t.timestamptz "created_at", default: -> { "now()" }, null: false
    t.string "discord_user_id", limit: 50
    t.string "display_name", limit: 200, null: false
    t.string "email", limit: 320, null: false
    t.timestamptz "last_login_at"
    t.text "password_hash", null: false
    t.string "role", limit: 50, default: "user", null: false
    t.string "slack_user_id", limit: 50
    t.uuid "tenant_id", null: false
    t.index ["tenant_id"], name: "idx_users_tenant"
    t.unique_constraint ["tenant_id", "email"], name: "users_tenant_id_email_key"
  end

  add_foreign_key "agent_actions", "tenants", name: "agent_actions_tenant_id_fkey"
  add_foreign_key "agent_actions", "users", column: "rolled_back_by", name: "agent_actions_rolled_back_by_fkey"
  add_foreign_key "agent_events", "tenants", name: "agent_events_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "agent_memory", "tenants", name: "agent_memory_tenant_id_fkey"
  add_foreign_key "agent_token_usage", "tenants", name: "agent_token_usage_tenant_id_fkey"
  add_foreign_key "ai_conversation_summaries", "tenants", name: "ai_conversation_summaries_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "ai_conversations", "tenants", name: "ai_conversations_tenant_id_fkey"
  add_foreign_key "ai_feedback", "ai_conversations", column: "conversation_id", name: "ai_feedback_conversation_id_fkey", on_delete: :cascade
  add_foreign_key "ai_suggestions", "properties", primary_key: "property_id", name: "ai_suggestions_property_id_fkey", on_delete: :nullify
  add_foreign_key "ai_suggestions", "tenants", name: "ai_suggestions_tenant_id_fkey"
  add_foreign_key "api_keys", "tenants", name: "api_keys_tenant_id_fkey"
  add_foreign_key "api_keys", "users", column: "created_by", name: "api_keys_created_by_fkey"
  add_foreign_key "api_request_log", "tenants", name: "api_request_log_tenant_id_fkey"
  add_foreign_key "attachments", "tenants", name: "attachments_tenant_id_fkey"
  add_foreign_key "audit_logs", "tenants", name: "audit_logs_tenant_id_fkey"
  add_foreign_key "calendar_connections", "tenants", name: "calendar_connections_tenant_id_fkey"
  add_foreign_key "detected_exceptions", "tenants", name: "detected_exceptions_tenant_id_fkey"
  add_foreign_key "escalation_rules", "sla_rules", name: "escalation_rules_sla_rule_id_fkey", on_delete: :cascade
  add_foreign_key "escalation_rules", "tenants", name: "escalation_rules_tenant_id_fkey"
  add_foreign_key "event_invites", "events"
  add_foreign_key "event_invites", "invites"
  add_foreign_key "guests", "invites"
  add_foreign_key "holly_knowledge", "snapshot_analysis_log", column: "source_snapshot_log_id", name: "holly_knowledge_source_snapshot_log_id_fkey", on_delete: :nullify
  add_foreign_key "holly_knowledge", "tenants", name: "holly_knowledge_tenant_id_fkey"
  add_foreign_key "holly_skill_metrics", "tenants", name: "holly_skill_metrics_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "holly_typed_memory", "holly_typed_memory", column: "supersedes_memory_id", name: "holly_typed_memory_supersedes_memory_id_fkey", on_delete: :nullify
  add_foreign_key "holly_typed_memory", "properties", primary_key: "property_id", name: "holly_typed_memory_property_id_fkey", on_delete: :nullify
  add_foreign_key "holly_typed_memory", "tenants", name: "holly_typed_memory_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "hotel_bookings", "invites"
  add_foreign_key "imported_prompts", "tenants", name: "imported_prompts_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "integration_channels", "integrations", name: "integration_channels_integration_id_fkey", on_delete: :cascade
  add_foreign_key "integration_channels", "properties", primary_key: "property_id", name: "integration_channels_property_id_fkey", on_delete: :cascade
  add_foreign_key "integrations", "tenants", name: "integrations_tenant_id_fkey"
  add_foreign_key "notification_suppressions", "properties", primary_key: "property_id", name: "notification_suppressions_property_id_fkey", on_delete: :cascade
  add_foreign_key "notification_suppressions", "tenants", name: "notification_suppressions_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "plan_steps", "planned_tasks", column: "task_id", name: "plan_steps_task_id_fkey", on_delete: :cascade
  add_foreign_key "planned_task_assignees", "planned_tasks", column: "task_id", name: "planned_task_assignees_task_id_fkey", on_delete: :cascade
  add_foreign_key "planned_task_assignees", "users", name: "planned_task_assignees_user_id_fkey"
  add_foreign_key "planned_task_chunks", "planned_tasks", column: "task_id", name: "planned_task_chunks_task_id_fkey", on_delete: :cascade
  add_foreign_key "planned_task_chunks", "tenants", name: "planned_task_chunks_tenant_id_fkey"
  add_foreign_key "planned_tasks", "task_templates", column: "template_id", name: "planned_tasks_template_id_fkey"
  add_foreign_key "planned_tasks", "tenants", name: "planned_tasks_tenant_id_fkey"
  add_foreign_key "planned_tasks", "users", column: "created_by", name: "planned_tasks_created_by_fkey"
  add_foreign_key "properties", "tenants", name: "properties_tenant_id_fkey"
  add_foreign_key "property_department_channels", "properties", primary_key: "property_id", name: "property_department_channels_property_id_fkey", on_delete: :cascade
  add_foreign_key "property_latest_stats", "properties", primary_key: "property_id", name: "property_latest_stats_property_id_fkey", on_delete: :cascade
  add_foreign_key "property_stats_forecast", "properties", primary_key: "property_id", name: "property_stats_forecast_property_id_fkey", on_delete: :cascade
  add_foreign_key "property_stats_history", "properties", primary_key: "property_id", name: "property_stats_history_property_id_fkey", on_delete: :cascade
  add_foreign_key "push_subscriptions", "tenants", name: "push_subscriptions_tenant_id_fkey"
  add_foreign_key "raw_ingestion_log", "tenants", name: "raw_ingestion_log_tenant_id_fkey"
  add_foreign_key "responses", "tickets", name: "responses_ticket_id_fkey", on_delete: :cascade
  add_foreign_key "rsvps", "events"
  add_foreign_key "rsvps", "guests"
  add_foreign_key "sessions", "tenants", name: "sessions_tenant_id_fkey"
  add_foreign_key "sessions", "users", name: "sessions_user_id_fkey", on_delete: :cascade
  add_foreign_key "sla_rules", "tenants", name: "sla_rules_tenant_id_fkey"
  add_foreign_key "snapshot_analysis_log", "tenants", name: "snapshot_analysis_log_tenant_id_fkey"
  add_foreign_key "task_chat_messages", "planned_tasks", column: "task_id", name: "task_chat_messages_task_id_fkey", on_delete: :cascade
  add_foreign_key "task_chat_messages", "tenants", name: "task_chat_messages_tenant_id_fkey"
  add_foreign_key "task_chat_messages", "users", name: "task_chat_messages_user_id_fkey"
  add_foreign_key "task_templates", "tenants", name: "task_templates_tenant_id_fkey"
  add_foreign_key "tenant_cron_jobs", "tenants", name: "tenant_cron_jobs_tenant_id_fkey", on_delete: :cascade
  add_foreign_key "ticket_notes", "tickets", name: "ticket_notes_ticket_id_fkey", on_delete: :cascade
  add_foreign_key "ticket_state_transitions", "tickets", name: "ticket_state_transitions_ticket_id_fkey", on_delete: :cascade
  add_foreign_key "tickets", "detected_exceptions", name: "tickets_detected_exception_id_fkey", on_delete: :nullify
  add_foreign_key "tickets", "exceptions", name: "tickets_exception_id_fkey", on_delete: :nullify
  add_foreign_key "tickets", "tenants", name: "tickets_tenant_id_fkey"
  add_foreign_key "users", "tenants", name: "users_tenant_id_fkey"
end
