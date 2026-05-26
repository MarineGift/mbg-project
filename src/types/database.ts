export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  ai: {
    Tables: {
      agents: {
        Row: {
          applicable_languages: string[]
          applicable_modules: Database["app"]["Enums"]["party_type"][]
          blocked_keywords: string[]
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string | null
          fallback_model: string | null
          id: string
          is_active: boolean
          knowledge_collection: string | null
          max_tokens: number
          model: string
          name: string
          organization_id: string
          output_format: string
          output_schema: Json | null
          require_pii_masking: boolean
          role: Database["ai"]["Enums"]["agent_role"]
          system_prompt: string
          temperature: number
          timeout_seconds: number
          top_p: number | null
          updated_at: string
          updated_by: string | null
          user_prompt_template: string | null
          version: number
        }
        Insert: {
          applicable_languages?: string[]
          applicable_modules: Database["app"]["Enums"]["party_type"][]
          blocked_keywords?: string[]
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          fallback_model?: string | null
          id?: string
          is_active?: boolean
          knowledge_collection?: string | null
          max_tokens?: number
          model: string
          name: string
          organization_id: string
          output_format?: string
          output_schema?: Json | null
          require_pii_masking?: boolean
          role: Database["ai"]["Enums"]["agent_role"]
          system_prompt: string
          temperature?: number
          timeout_seconds?: number
          top_p?: number | null
          updated_at?: string
          updated_by?: string | null
          user_prompt_template?: string | null
          version?: number
        }
        Update: {
          applicable_languages?: string[]
          applicable_modules?: Database["app"]["Enums"]["party_type"][]
          blocked_keywords?: string[]
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          fallback_model?: string | null
          id?: string
          is_active?: boolean
          knowledge_collection?: string | null
          max_tokens?: number
          model?: string
          name?: string
          organization_id?: string
          output_format?: string
          output_schema?: Json | null
          require_pii_masking?: boolean
          role?: Database["ai"]["Enums"]["agent_role"]
          system_prompt?: string
          temperature?: number
          timeout_seconds?: number
          top_p?: number | null
          updated_at?: string
          updated_by?: string | null
          user_prompt_template?: string | null
          version?: number
        }
        Relationships: []
      }
      auto_send_rules: {
        Row: {
          allowed_languages: string[]
          allowed_modules: Database["app"]["Enums"]["party_type"][]
          block_reason: string | null
          blocked_keywords_in_body: string[]
          classification_category: string
          created_at: string
          created_by: string | null
          daily_limit: number
          hourly_limit: number
          id: string
          is_active: boolean
          is_blocked: boolean
          min_confidence: number
          organization_id: string
          per_party_daily_limit: number
          requires_calendar_data: boolean
          requires_human_approval: boolean
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          allowed_languages?: string[]
          allowed_modules: Database["app"]["Enums"]["party_type"][]
          block_reason?: string | null
          blocked_keywords_in_body?: string[]
          classification_category: string
          created_at?: string
          created_by?: string | null
          daily_limit?: number
          hourly_limit?: number
          id?: string
          is_active?: boolean
          is_blocked?: boolean
          min_confidence?: number
          organization_id: string
          per_party_daily_limit?: number
          requires_calendar_data?: boolean
          requires_human_approval?: boolean
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          allowed_languages?: string[]
          allowed_modules?: Database["app"]["Enums"]["party_type"][]
          block_reason?: string | null
          blocked_keywords_in_body?: string[]
          classification_category?: string
          created_at?: string
          created_by?: string | null
          daily_limit?: number
          hourly_limit?: number
          id?: string
          is_active?: boolean
          is_blocked?: boolean
          min_confidence?: number
          organization_id?: string
          per_party_daily_limit?: number
          requires_calendar_data?: boolean
          requires_human_approval?: boolean
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      brand_voice: {
        Row: {
          closing_patterns: Json
          created_at: string
          created_by: string | null
          do_say: Json
          dont_say: Json
          few_shot_examples: Json
          glossary: Json
          greeting_patterns: Json
          id: string
          is_active: boolean
          language: string
          organization_id: string
          party_type: Database["app"]["Enums"]["party_type"]
          tone_guidelines: string
          updated_at: string
          updated_by: string | null
          version: number
        }
        Insert: {
          closing_patterns?: Json
          created_at?: string
          created_by?: string | null
          do_say?: Json
          dont_say?: Json
          few_shot_examples?: Json
          glossary?: Json
          greeting_patterns?: Json
          id?: string
          is_active?: boolean
          language?: string
          organization_id: string
          party_type: Database["app"]["Enums"]["party_type"]
          tone_guidelines: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Update: {
          closing_patterns?: Json
          created_at?: string
          created_by?: string | null
          do_say?: Json
          dont_say?: Json
          few_shot_examples?: Json
          glossary?: Json
          greeting_patterns?: Json
          id?: string
          is_active?: boolean
          language?: string
          organization_id?: string
          party_type?: Database["app"]["Enums"]["party_type"]
          tone_guidelines?: string
          updated_at?: string
          updated_by?: string | null
          version?: number
        }
        Relationships: []
      }
      drafts: {
        Row: {
          agent_id: string
          ai_generated: boolean
          auto_send_blocked_reasons: string[]
          auto_send_eligible: boolean
          auto_send_evaluation_log: Json
          auto_send_rule_id: string | null
          body_html: string | null
          body_plain: string
          classification_category: string | null
          classifier_run_id: string | null
          confidence_score: number | null
          contact_id: string | null
          created_at: string
          drafter_run_id: string | null
          edit_distance: number | null
          engagement_id: string | null
          expired_handled: boolean
          expires_at: string
          final_body_plain: string | null
          final_subject: string | null
          id: string
          inbound_communication_id: string | null
          language: string
          organization_id: string
          party_id: string | null
          party_type: Database["app"]["Enums"]["party_type"] | null
          rationale: string | null
          requires_human_approval: boolean
          review_notes: string | null
          reviewed_at: string | null
          reviewed_by_user_id: string | null
          risk_flags: string[]
          run_id: string | null
          sent_communication_id: string | null
          status: Database["ai"]["Enums"]["draft_status"]
          subject: string | null
          updated_at: string
        }
        Insert: {
          agent_id: string
          ai_generated?: boolean
          auto_send_blocked_reasons?: string[]
          auto_send_eligible?: boolean
          auto_send_evaluation_log?: Json
          auto_send_rule_id?: string | null
          body_html?: string | null
          body_plain: string
          classification_category?: string | null
          classifier_run_id?: string | null
          confidence_score?: number | null
          contact_id?: string | null
          created_at?: string
          drafter_run_id?: string | null
          edit_distance?: number | null
          engagement_id?: string | null
          expired_handled?: boolean
          expires_at?: string
          final_body_plain?: string | null
          final_subject?: string | null
          id?: string
          inbound_communication_id?: string | null
          language?: string
          organization_id: string
          party_id?: string | null
          party_type?: Database["app"]["Enums"]["party_type"] | null
          rationale?: string | null
          requires_human_approval?: boolean
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by_user_id?: string | null
          risk_flags?: string[]
          run_id?: string | null
          sent_communication_id?: string | null
          status?: Database["ai"]["Enums"]["draft_status"]
          subject?: string | null
          updated_at?: string
        }
        Update: {
          agent_id?: string
          ai_generated?: boolean
          auto_send_blocked_reasons?: string[]
          auto_send_eligible?: boolean
          auto_send_evaluation_log?: Json
          auto_send_rule_id?: string | null
          body_html?: string | null
          body_plain?: string
          classification_category?: string | null
          classifier_run_id?: string | null
          confidence_score?: number | null
          contact_id?: string | null
          created_at?: string
          drafter_run_id?: string | null
          edit_distance?: number | null
          engagement_id?: string | null
          expired_handled?: boolean
          expires_at?: string
          final_body_plain?: string | null
          final_subject?: string | null
          id?: string
          inbound_communication_id?: string | null
          language?: string
          organization_id?: string
          party_id?: string | null
          party_type?: Database["app"]["Enums"]["party_type"] | null
          rationale?: string | null
          requires_human_approval?: boolean
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by_user_id?: string | null
          risk_flags?: string[]
          run_id?: string | null
          sent_communication_id?: string | null
          status?: Database["ai"]["Enums"]["draft_status"]
          subject?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_drafts_agent_id"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "agents"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_drafts_auto_send_rule_id"
            columns: ["auto_send_rule_id"]
            isOneToOne: false
            referencedRelation: "auto_send_rules"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_drafts_classifier_run_id"
            columns: ["classifier_run_id"]
            isOneToOne: false
            referencedRelation: "runs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_drafts_drafter_run_id"
            columns: ["drafter_run_id"]
            isOneToOne: false
            referencedRelation: "runs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_drafts_run_id"
            columns: ["run_id"]
            isOneToOne: false
            referencedRelation: "runs"
            referencedColumns: ["id"]
          },
        ]
      }
      knowledge_chunks: {
        Row: {
          chunk_index: number
          chunk_total: number
          collection: string
          content: string
          content_hash: string | null
          created_at: string
          created_by: string | null
          embedding: string | null
          embedding_model: string
          id: string
          is_active: boolean
          language: string
          metadata: Json
          organization_id: string
          source_entity_id: string | null
          source_entity_type: string | null
          source_type: string
          source_url: string | null
          tags: string[]
          title: string | null
          updated_at: string
        }
        Insert: {
          chunk_index?: number
          chunk_total?: number
          collection: string
          content: string
          content_hash?: string | null
          created_at?: string
          created_by?: string | null
          embedding?: string | null
          embedding_model?: string
          id?: string
          is_active?: boolean
          language?: string
          metadata?: Json
          organization_id: string
          source_entity_id?: string | null
          source_entity_type?: string | null
          source_type: string
          source_url?: string | null
          tags?: string[]
          title?: string | null
          updated_at?: string
        }
        Update: {
          chunk_index?: number
          chunk_total?: number
          collection?: string
          content?: string
          content_hash?: string | null
          created_at?: string
          created_by?: string | null
          embedding?: string | null
          embedding_model?: string
          id?: string
          is_active?: boolean
          language?: string
          metadata?: Json
          organization_id?: string
          source_entity_id?: string | null
          source_entity_type?: string | null
          source_type?: string
          source_url?: string | null
          tags?: string[]
          title?: string | null
          updated_at?: string
        }
        Relationships: []
      }
      runs: {
        Row: {
          agent_id: string
          completed_at: string | null
          cost_usd: number
          created_at: string
          error_message: string | null
          id: string
          input_payload: Json | null
          input_tokens: number | null
          latency_ms: number | null
          metadata: Json
          model_used: string
          organization_id: string
          output_payload: Json | null
          output_tokens: number | null
          pii_categories_detected: string[]
          pii_masked: boolean
          related_entity_id: string | null
          related_entity_type: string | null
          started_at: string
          status: Database["ai"]["Enums"]["run_status"]
          tokens_in: number | null
          tokens_out: number | null
          triggered_by_kind: string
          triggered_by_user_id: string | null
        }
        Insert: {
          agent_id: string
          completed_at?: string | null
          cost_usd?: number
          created_at?: string
          error_message?: string | null
          id?: string
          input_payload?: Json | null
          input_tokens?: number | null
          latency_ms?: number | null
          metadata?: Json
          model_used: string
          organization_id: string
          output_payload?: Json | null
          output_tokens?: number | null
          pii_categories_detected?: string[]
          pii_masked?: boolean
          related_entity_id?: string | null
          related_entity_type?: string | null
          started_at?: string
          status?: Database["ai"]["Enums"]["run_status"]
          tokens_in?: number | null
          tokens_out?: number | null
          triggered_by_kind?: string
          triggered_by_user_id?: string | null
        }
        Update: {
          agent_id?: string
          completed_at?: string | null
          cost_usd?: number
          created_at?: string
          error_message?: string | null
          id?: string
          input_payload?: Json | null
          input_tokens?: number | null
          latency_ms?: number | null
          metadata?: Json
          model_used?: string
          organization_id?: string
          output_payload?: Json | null
          output_tokens?: number | null
          pii_categories_detected?: string[]
          pii_masked?: boolean
          related_entity_id?: string | null
          related_entity_type?: string | null
          started_at?: string
          status?: Database["ai"]["Enums"]["run_status"]
          tokens_in?: number | null
          tokens_out?: number | null
          triggered_by_kind?: string
          triggered_by_user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_runs_agent_id"
            columns: ["agent_id"]
            isOneToOne: false
            referencedRelation: "agents"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      expire_stale_drafts: {
        Args: never
        Returns: {
          expired_count: number
          organization_id: string
        }[]
      }
      search_knowledge: {
        Args: {
          p_collection?: string
          p_language?: string
          p_min_similarity?: number
          p_organization_id: string
          p_query_embedding: string
          p_top_k?: number
        }
        Returns: {
          collection: string
          content: string
          id: string
          language: string
          metadata: Json
          similarity: number
          source_url: string
          title: string
        }[]
      }
    }
    Enums: {
      agent_role:
        | "classifier"
        | "reply_drafter"
        | "strategy_advisor"
        | "summarizer"
        | "translator"
        | "extractor"
      draft_status:
        | "pending_review"
        | "approved"
        | "sent"
        | "rejected"
        | "expired"
        | "auto_sent"
      run_status:
        | "running"
        | "completed"
        | "failed"
        | "timed_out"
        | "rate_limited"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  app: {
    Tables: {
      attachments: {
        Row: {
          content_hash_sha256: string | null
          deleted_at: string | null
          description: string | null
          entity_id: string
          entity_type: string
          expires_at: string | null
          file_name: string
          file_size_bytes: number
          id: string
          is_inline: boolean
          is_quarantined: boolean
          mime_type: string
          organization_id: string
          storage_bucket: string | null
          storage_path: string
          storage_provider: string
          uploaded_at: string
          uploaded_by: string | null
          virus_scan_status: string | null
        }
        Insert: {
          content_hash_sha256?: string | null
          deleted_at?: string | null
          description?: string | null
          entity_id: string
          entity_type: string
          expires_at?: string | null
          file_name: string
          file_size_bytes: number
          id?: string
          is_inline?: boolean
          is_quarantined?: boolean
          mime_type: string
          organization_id: string
          storage_bucket?: string | null
          storage_path: string
          storage_provider?: string
          uploaded_at?: string
          uploaded_by?: string | null
          virus_scan_status?: string | null
        }
        Update: {
          content_hash_sha256?: string | null
          deleted_at?: string | null
          description?: string | null
          entity_id?: string
          entity_type?: string
          expires_at?: string | null
          file_name?: string
          file_size_bytes?: number
          id?: string
          is_inline?: boolean
          is_quarantined?: boolean
          mime_type?: string
          organization_id?: string
          storage_bucket?: string | null
          storage_path?: string
          storage_provider?: string
          uploaded_at?: string
          uploaded_by?: string | null
          virus_scan_status?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "attachments_uploaded_by_fkey"
            columns: ["uploaded_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_attachments_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      buyer_inquiries: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          engagement_id: string | null
          id: string
          inquiry_type: string
          notes: string | null
          organization_id: string
          party_id: string
          product_interest: string[]
          requested_quantity: number | null
          requested_quantity_unit: string | null
          status: string
          updated_at: string
          updated_by: string | null
          urgency: Database["app"]["Enums"]["priority_level"]
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          engagement_id?: string | null
          id?: string
          inquiry_type: string
          notes?: string | null
          organization_id: string
          party_id: string
          product_interest?: string[]
          requested_quantity?: number | null
          requested_quantity_unit?: string | null
          status?: string
          updated_at?: string
          updated_by?: string | null
          urgency?: Database["app"]["Enums"]["priority_level"]
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          engagement_id?: string | null
          id?: string
          inquiry_type?: string
          notes?: string | null
          organization_id?: string
          party_id?: string
          product_interest?: string[]
          requested_quantity?: number | null
          requested_quantity_unit?: string | null
          status?: string
          updated_at?: string
          updated_by?: string | null
          urgency?: Database["app"]["Enums"]["priority_level"]
        }
        Relationships: [
          {
            foreignKeyName: "buyer_inquiries_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "buyer_inquiries_engagement_id_fkey"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "buyer_inquiries_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "buyer_inquiries_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "buyer_inquiries_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "buyer_inquiries_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "buyer_inquiries_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "buyer_inquiries_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "buyer_inquiries_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "buyer_inquiries_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "buyer_inquiries_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "buyer_inquiries_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      calendar_connections: {
        Row: {
          access_token: string
          account_email: string
          account_name: string | null
          created_at: string
          delta_link: string | null
          expires_at: string | null
          id: string
          is_active: boolean
          is_primary: boolean
          last_error: string | null
          last_sync_at: string | null
          last_sync_status:
            | Database["app"]["Enums"]["calendar_sync_status"]
            | null
          organization_id: string
          provider: Database["app"]["Enums"]["calendar_provider"]
          refresh_token: string | null
          scopes: string[]
          sync_failures: number
          sync_token: string | null
          token_type: string | null
          updated_at: string
          user_id: string
        }
        Insert: {
          access_token: string
          account_email: string
          account_name?: string | null
          created_at?: string
          delta_link?: string | null
          expires_at?: string | null
          id?: string
          is_active?: boolean
          is_primary?: boolean
          last_error?: string | null
          last_sync_at?: string | null
          last_sync_status?:
            | Database["app"]["Enums"]["calendar_sync_status"]
            | null
          organization_id: string
          provider: Database["app"]["Enums"]["calendar_provider"]
          refresh_token?: string | null
          scopes?: string[]
          sync_failures?: number
          sync_token?: string | null
          token_type?: string | null
          updated_at?: string
          user_id: string
        }
        Update: {
          access_token?: string
          account_email?: string
          account_name?: string | null
          created_at?: string
          delta_link?: string | null
          expires_at?: string | null
          id?: string
          is_active?: boolean
          is_primary?: boolean
          last_error?: string | null
          last_sync_at?: string | null
          last_sync_status?:
            | Database["app"]["Enums"]["calendar_sync_status"]
            | null
          organization_id?: string
          provider?: Database["app"]["Enums"]["calendar_provider"]
          refresh_token?: string | null
          scopes?: string[]
          sync_failures?: number
          sync_token?: string | null
          token_type?: string | null
          updated_at?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "calendar_connections_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_connections_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      calendar_events: {
        Row: {
          attendees: Json
          auto_matched: boolean
          connection_id: string | null
          created_at: string
          description: string | null
          end_at: string
          engagement_id: string | null
          external_created_at: string | null
          external_etag: string | null
          external_id: string | null
          external_modified_at: string | null
          id: string
          is_all_day: boolean
          is_recurrence_instance: boolean
          location: string | null
          match_confidence: number | null
          meeting_id: string | null
          meeting_url: string | null
          organization_id: string
          organizer_email: string | null
          organizer_name: string | null
          party_id: string | null
          recurrence_rule: string | null
          recurring_event_id: string | null
          source: Database["app"]["Enums"]["calendar_provider"]
          start_at: string
          status: Database["app"]["Enums"]["event_status"]
          timezone: string
          title: string
          updated_at: string
          user_id: string
          visibility: string | null
        }
        Insert: {
          attendees?: Json
          auto_matched?: boolean
          connection_id?: string | null
          created_at?: string
          description?: string | null
          end_at: string
          engagement_id?: string | null
          external_created_at?: string | null
          external_etag?: string | null
          external_id?: string | null
          external_modified_at?: string | null
          id?: string
          is_all_day?: boolean
          is_recurrence_instance?: boolean
          location?: string | null
          match_confidence?: number | null
          meeting_id?: string | null
          meeting_url?: string | null
          organization_id: string
          organizer_email?: string | null
          organizer_name?: string | null
          party_id?: string | null
          recurrence_rule?: string | null
          recurring_event_id?: string | null
          source: Database["app"]["Enums"]["calendar_provider"]
          start_at: string
          status?: Database["app"]["Enums"]["event_status"]
          timezone?: string
          title?: string
          updated_at?: string
          user_id: string
          visibility?: string | null
        }
        Update: {
          attendees?: Json
          auto_matched?: boolean
          connection_id?: string | null
          created_at?: string
          description?: string | null
          end_at?: string
          engagement_id?: string | null
          external_created_at?: string | null
          external_etag?: string | null
          external_id?: string | null
          external_modified_at?: string | null
          id?: string
          is_all_day?: boolean
          is_recurrence_instance?: boolean
          location?: string | null
          match_confidence?: number | null
          meeting_id?: string | null
          meeting_url?: string | null
          organization_id?: string
          organizer_email?: string | null
          organizer_name?: string | null
          party_id?: string | null
          recurrence_rule?: string | null
          recurring_event_id?: string | null
          source?: Database["app"]["Enums"]["calendar_provider"]
          start_at?: string
          status?: Database["app"]["Enums"]["event_status"]
          timezone?: string
          title?: string
          updated_at?: string
          user_id?: string
          visibility?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "calendar_events_connection_id_fkey"
            columns: ["connection_id"]
            isOneToOne: false
            referencedRelation: "calendar_connections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_events_engagement_id_fkey"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_events_meeting_id_fkey"
            columns: ["meeting_id"]
            isOneToOne: false
            referencedRelation: "meetings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_events_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_events_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_events_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_events_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "calendar_events_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "calendar_events_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "calendar_events_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "calendar_events_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "calendar_events_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calendar_events_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      calendar_sync_log: {
        Row: {
          connection_id: string | null
          created_at: string
          details: Json
          duration_ms: number | null
          error_message: string | null
          event_id: string | null
          id: string
          meeting_id: string | null
          operation: Database["app"]["Enums"]["sync_operation"]
          organization_id: string
          status: Database["app"]["Enums"]["calendar_sync_status"]
          user_id: string | null
        }
        Insert: {
          connection_id?: string | null
          created_at?: string
          details?: Json
          duration_ms?: number | null
          error_message?: string | null
          event_id?: string | null
          id?: string
          meeting_id?: string | null
          operation: Database["app"]["Enums"]["sync_operation"]
          organization_id: string
          status?: Database["app"]["Enums"]["calendar_sync_status"]
          user_id?: string | null
        }
        Update: {
          connection_id?: string | null
          created_at?: string
          details?: Json
          duration_ms?: number | null
          error_message?: string | null
          event_id?: string | null
          id?: string
          meeting_id?: string | null
          operation?: Database["app"]["Enums"]["sync_operation"]
          organization_id?: string
          status?: Database["app"]["Enums"]["calendar_sync_status"]
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_csl_connection"
            columns: ["connection_id"]
            isOneToOne: false
            referencedRelation: "calendar_connections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_csl_event"
            columns: ["event_id"]
            isOneToOne: false
            referencedRelation: "calendar_events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_csl_meeting"
            columns: ["meeting_id"]
            isOneToOne: false
            referencedRelation: "meetings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_csl_organization"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_csl_user"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      communications: {
        Row: {
          ai_classification: Json | null
          ai_draft_id: string | null
          ai_generated: boolean
          ai_processing_status: string
          bcc_addresses: string[]
          body_html: string | null
          body_plain: string | null
          body_summary: string | null
          bounce_reason: string | null
          bounced_at: string | null
          cc_addresses: string[]
          channel: Database["app"]["Enums"]["engagement_channel"]
          clicked_at: string | null
          contact_id: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          delivered_at: string | null
          direction: Database["app"]["Enums"]["direction_type"]
          engagement_id: string | null
          external_data: Json
          from_address: string | null
          from_name: string | null
          id: string
          in_reply_to: string | null
          is_important: boolean
          is_starred: boolean
          language_detected: string | null
          message_id: string | null
          notes: string | null
          occurred_at: string
          opened_at: string | null
          organization_id: string
          party_id: string | null
          party_type: Database["app"]["Enums"]["party_type"] | null
          read_at: string | null
          received_at: string | null
          replied_at: string | null
          reply_to_address: string | null
          sent_at: string | null
          sent_by_user_id: string | null
          status: string
          subject: string | null
          template_id: string | null
          template_variables: Json
          thread_id: string | null
          to_addresses: string[]
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          ai_classification?: Json | null
          ai_draft_id?: string | null
          ai_generated?: boolean
          ai_processing_status?: string
          bcc_addresses?: string[]
          body_html?: string | null
          body_plain?: string | null
          body_summary?: string | null
          bounce_reason?: string | null
          bounced_at?: string | null
          cc_addresses?: string[]
          channel: Database["app"]["Enums"]["engagement_channel"]
          clicked_at?: string | null
          contact_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          delivered_at?: string | null
          direction: Database["app"]["Enums"]["direction_type"]
          engagement_id?: string | null
          external_data?: Json
          from_address?: string | null
          from_name?: string | null
          id?: string
          in_reply_to?: string | null
          is_important?: boolean
          is_starred?: boolean
          language_detected?: string | null
          message_id?: string | null
          notes?: string | null
          occurred_at?: string
          opened_at?: string | null
          organization_id: string
          party_id?: string | null
          party_type?: Database["app"]["Enums"]["party_type"] | null
          read_at?: string | null
          received_at?: string | null
          replied_at?: string | null
          reply_to_address?: string | null
          sent_at?: string | null
          sent_by_user_id?: string | null
          status?: string
          subject?: string | null
          template_id?: string | null
          template_variables?: Json
          thread_id?: string | null
          to_addresses?: string[]
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          ai_classification?: Json | null
          ai_draft_id?: string | null
          ai_generated?: boolean
          ai_processing_status?: string
          bcc_addresses?: string[]
          body_html?: string | null
          body_plain?: string | null
          body_summary?: string | null
          bounce_reason?: string | null
          bounced_at?: string | null
          cc_addresses?: string[]
          channel?: Database["app"]["Enums"]["engagement_channel"]
          clicked_at?: string | null
          contact_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          delivered_at?: string | null
          direction?: Database["app"]["Enums"]["direction_type"]
          engagement_id?: string | null
          external_data?: Json
          from_address?: string | null
          from_name?: string | null
          id?: string
          in_reply_to?: string | null
          is_important?: boolean
          is_starred?: boolean
          language_detected?: string | null
          message_id?: string | null
          notes?: string | null
          occurred_at?: string
          opened_at?: string | null
          organization_id?: string
          party_id?: string | null
          party_type?: Database["app"]["Enums"]["party_type"] | null
          read_at?: string | null
          received_at?: string | null
          replied_at?: string | null
          reply_to_address?: string | null
          sent_at?: string | null
          sent_by_user_id?: string | null
          status?: string
          subject?: string | null
          template_id?: string | null
          template_variables?: Json
          thread_id?: string | null
          to_addresses?: string[]
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "communications_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "communications_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_communications_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_communications_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_communications_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_communications_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_communications_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_communications_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_communications_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_communications_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_communications_engagement_id"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_communications_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_communications_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_communications_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_communications_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_communications_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_communications_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_communications_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_communications_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_communications_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_communications_sent_by_user_id"
            columns: ["sent_by_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      consultations: {
        Row: {
          ai_processing_completed_at: string | null
          ai_processing_error_class: string | null
          ai_processing_error_message: string | null
          ai_processing_failed_at: string | null
          ai_processing_retryable: boolean | null
          ai_processing_started_at: string | null
          ai_processing_status: string
          attachments_meta: Json
          channel: Database["app"]["Enums"]["consultation_channel"]
          consultation_type: string | null
          contact_id: string | null
          content_processed: string | null
          content_raw: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          engagement_id: string | null
          id: string
          language: string | null
          notes: string | null
          organization_id: string
          party_id: string | null
          party_type: Database["app"]["Enums"]["party_type"] | null
          pii_categories_detected: string[]
          pii_masked: boolean
          priority: Database["app"]["Enums"]["priority_level"]
          received_at: string
          source_communication_id: string | null
          source_meeting_id: string | null
          tags: string[]
          title: string | null
          updated_at: string
          updated_by: string | null
          urgency: string | null
        }
        Insert: {
          ai_processing_completed_at?: string | null
          ai_processing_error_class?: string | null
          ai_processing_error_message?: string | null
          ai_processing_failed_at?: string | null
          ai_processing_retryable?: boolean | null
          ai_processing_started_at?: string | null
          ai_processing_status?: string
          attachments_meta?: Json
          channel: Database["app"]["Enums"]["consultation_channel"]
          consultation_type?: string | null
          contact_id?: string | null
          content_processed?: string | null
          content_raw: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          engagement_id?: string | null
          id?: string
          language?: string | null
          notes?: string | null
          organization_id: string
          party_id?: string | null
          party_type?: Database["app"]["Enums"]["party_type"] | null
          pii_categories_detected?: string[]
          pii_masked?: boolean
          priority?: Database["app"]["Enums"]["priority_level"]
          received_at?: string
          source_communication_id?: string | null
          source_meeting_id?: string | null
          tags?: string[]
          title?: string | null
          updated_at?: string
          updated_by?: string | null
          urgency?: string | null
        }
        Update: {
          ai_processing_completed_at?: string | null
          ai_processing_error_class?: string | null
          ai_processing_error_message?: string | null
          ai_processing_failed_at?: string | null
          ai_processing_retryable?: boolean | null
          ai_processing_started_at?: string | null
          ai_processing_status?: string
          attachments_meta?: Json
          channel?: Database["app"]["Enums"]["consultation_channel"]
          consultation_type?: string | null
          contact_id?: string | null
          content_processed?: string | null
          content_raw?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          engagement_id?: string | null
          id?: string
          language?: string | null
          notes?: string | null
          organization_id?: string
          party_id?: string | null
          party_type?: Database["app"]["Enums"]["party_type"] | null
          pii_categories_detected?: string[]
          pii_masked?: boolean
          priority?: Database["app"]["Enums"]["priority_level"]
          received_at?: string
          source_communication_id?: string | null
          source_meeting_id?: string | null
          tags?: string[]
          title?: string | null
          updated_at?: string
          updated_by?: string | null
          urgency?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "consultations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "consultations_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_consultations_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_consultations_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_consultations_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_consultations_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_consultations_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_consultations_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_consultations_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_consultations_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_consultations_engagement_id"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_consultations_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_consultations_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_consultations_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_consultations_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_consultations_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_consultations_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_consultations_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_consultations_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_consultations_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_consultations_source_communication_id"
            columns: ["source_communication_id"]
            isOneToOne: false
            referencedRelation: "communications"
            referencedColumns: ["id"]
          },
        ]
      }
      custom_field_definitions: {
        Row: {
          created_at: string
          created_by: string | null
          default_value: string | null
          entity_type: string
          field_key: string
          field_label: string
          field_type: string
          id: string
          is_active: boolean
          is_required: boolean
          options: Json
          organization_id: string
          party_type: Database["app"]["Enums"]["party_type"] | null
          sort_order: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          default_value?: string | null
          entity_type: string
          field_key: string
          field_label: string
          field_type: string
          id?: string
          is_active?: boolean
          is_required?: boolean
          options?: Json
          organization_id: string
          party_type?: Database["app"]["Enums"]["party_type"] | null
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          default_value?: string | null
          entity_type?: string
          field_key?: string
          field_label?: string
          field_type?: string
          id?: string
          is_active?: boolean
          is_required?: boolean
          options?: Json
          organization_id?: string
          party_type?: Database["app"]["Enums"]["party_type"] | null
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "custom_field_definitions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "custom_field_definitions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_custom_field_definitions_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      custom_field_values: {
        Row: {
          created_at: string
          created_by: string | null
          definition_id: string
          entity_id: string
          entity_type: string
          id: string
          organization_id: string
          updated_at: string
          updated_by: string | null
          value: Json
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          definition_id: string
          entity_id: string
          entity_type: string
          id?: string
          organization_id: string
          updated_at?: string
          updated_by?: string | null
          value: Json
        }
        Update: {
          created_at?: string
          created_by?: string | null
          definition_id?: string
          entity_id?: string
          entity_type?: string
          id?: string
          organization_id?: string
          updated_at?: string
          updated_by?: string | null
          value?: Json
        }
        Relationships: [
          {
            foreignKeyName: "custom_field_values_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "custom_field_values_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_custom_field_values_definition_id"
            columns: ["definition_id"]
            isOneToOne: false
            referencedRelation: "custom_field_definitions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_custom_field_values_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_purchases: {
        Row: {
          created_at: string
          id: string
          notes: string | null
          organization_id: string
          party_id: string
          product_id: string | null
          product_name: string
          purchase_date: string
          quantity: number
          sales_order_id: string | null
          total_usd: number | null
          unit_price_usd: number | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          notes?: string | null
          organization_id: string
          party_id: string
          product_id?: string | null
          product_name: string
          purchase_date: string
          quantity?: number
          sales_order_id?: string | null
          total_usd?: number | null
          unit_price_usd?: number | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          notes?: string | null
          organization_id?: string
          party_id?: string
          product_id?: string | null
          product_name?: string
          purchase_date?: string
          quantity?: number
          sales_order_id?: string | null
          total_usd?: number | null
          unit_price_usd?: number | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_purchases_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_purchases_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_purchases_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_purchases_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "customer_purchases_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "customer_purchases_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "customer_purchases_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "customer_purchases_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "customer_purchases_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_customer_purchases_product_id"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_customer_purchases_sales_order_id"
            columns: ["sales_order_id"]
            isOneToOne: false
            referencedRelation: "sales_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      customer_segments: {
        Row: {
          color: string
          created_at: string
          created_by: string | null
          criteria: Json
          description: string | null
          id: string
          is_dynamic: boolean
          member_count: number
          name: string
          organization_id: string
          updated_at: string
        }
        Insert: {
          color?: string
          created_at?: string
          created_by?: string | null
          criteria?: Json
          description?: string | null
          id?: string
          is_dynamic?: boolean
          member_count?: number
          name: string
          organization_id: string
          updated_at?: string
        }
        Update: {
          color?: string
          created_at?: string
          created_by?: string | null
          criteria?: Json
          description?: string | null
          id?: string
          is_dynamic?: boolean
          member_count?: number
          name?: string
          organization_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "customer_segments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "customer_segments_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      email_sequence_enrollments: {
        Row: {
          cancelled_at: string | null
          completed_at: string | null
          contact_id: string | null
          created_at: string
          engagement_id: string | null
          enrolled_at: string
          enrolled_by: string | null
          id: string
          next_send_at: string | null
          next_step_order: number
          organization_id: string
          party_id: string | null
          sequence_id: string
          status: Database["app"]["Enums"]["enrollment_status"]
          updated_at: string
        }
        Insert: {
          cancelled_at?: string | null
          completed_at?: string | null
          contact_id?: string | null
          created_at?: string
          engagement_id?: string | null
          enrolled_at?: string
          enrolled_by?: string | null
          id?: string
          next_send_at?: string | null
          next_step_order?: number
          organization_id: string
          party_id?: string | null
          sequence_id: string
          status?: Database["app"]["Enums"]["enrollment_status"]
          updated_at?: string
        }
        Update: {
          cancelled_at?: string | null
          completed_at?: string | null
          contact_id?: string | null
          created_at?: string
          engagement_id?: string | null
          enrolled_at?: string
          enrolled_by?: string | null
          id?: string
          next_send_at?: string | null
          next_step_order?: number
          organization_id?: string
          party_id?: string | null
          sequence_id?: string
          status?: Database["app"]["Enums"]["enrollment_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "email_sequence_enrollments_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_org_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_sequence_enrollments_sequence_id_fkey"
            columns: ["sequence_id"]
            isOneToOne: false
            referencedRelation: "email_sequences"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_ese_engagement"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
        ]
      }
      email_sequence_sends: {
        Row: {
          bounce_reason: string | null
          communication_id: string | null
          delivered_at: string | null
          enrollment_id: string
          id: string
          organization_id: string
          sent_at: string
          status: Database["app"]["Enums"]["send_status"]
          step_id: string
          step_order: number
          updated_at: string
        }
        Insert: {
          bounce_reason?: string | null
          communication_id?: string | null
          delivered_at?: string | null
          enrollment_id: string
          id?: string
          organization_id: string
          sent_at?: string
          status?: Database["app"]["Enums"]["send_status"]
          step_id: string
          step_order: number
          updated_at?: string
        }
        Update: {
          bounce_reason?: string | null
          communication_id?: string | null
          delivered_at?: string | null
          enrollment_id?: string
          id?: string
          organization_id?: string
          sent_at?: string
          status?: Database["app"]["Enums"]["send_status"]
          step_id?: string
          step_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "email_sequence_sends_enrollment_id_fkey"
            columns: ["enrollment_id"]
            isOneToOne: false
            referencedRelation: "email_sequence_enrollments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_sequence_sends_step_id_fkey"
            columns: ["step_id"]
            isOneToOne: false
            referencedRelation: "email_sequence_steps"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_esn_communication"
            columns: ["communication_id"]
            isOneToOne: false
            referencedRelation: "communications"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_esn_organization"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      email_sequence_steps: {
        Row: {
          body_plain: string
          created_at: string
          day_offset: number
          id: string
          organization_id: string
          sequence_id: string
          step_order: number
          subject: string
          updated_at: string
        }
        Insert: {
          body_plain: string
          created_at?: string
          day_offset?: number
          id?: string
          organization_id: string
          sequence_id: string
          step_order: number
          subject: string
          updated_at?: string
        }
        Update: {
          body_plain?: string
          created_at?: string
          day_offset?: number
          id?: string
          organization_id?: string
          sequence_id?: string
          step_order?: number
          subject?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "email_sequence_steps_sequence_id_fkey"
            columns: ["sequence_id"]
            isOneToOne: false
            referencedRelation: "email_sequences"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_ess_organization"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      email_sequences: {
        Row: {
          created_at: string
          description: string | null
          id: string
          name: string
          organization_id: string
          status: Database["app"]["Enums"]["email_sequence_status"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          name: string
          organization_id: string
          status?: Database["app"]["Enums"]["email_sequence_status"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          organization_id?: string
          status?: Database["app"]["Enums"]["email_sequence_status"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "email_sequences_org_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      email_signatures: {
        Row: {
          created_at: string
          html_content: string
          id: string
          is_default: boolean
          name: string
          organization_id: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          html_content: string
          id?: string
          is_default?: boolean
          name: string
          organization_id: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          html_content?: string
          id?: string
          is_default?: boolean
          name?: string
          organization_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "email_signatures_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      email_templates: {
        Row: {
          body_html: string | null
          body_plain: string
          category: string | null
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          name: string
          organization_id: string
          party_type: string | null
          subject: string
          updated_at: string
        }
        Insert: {
          body_html?: string | null
          body_plain: string
          category?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name: string
          organization_id: string
          party_type?: string | null
          subject: string
          updated_at?: string
        }
        Update: {
          body_html?: string | null
          body_plain?: string
          category?: string | null
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          name?: string
          organization_id?: string
          party_type?: string | null
          subject?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "email_templates_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      email_tracking: {
        Row: {
          click_count: number
          communication_id: string | null
          contact_id: string | null
          created_at: string
          draft_id: string | null
          first_opened_at: string | null
          id: string
          open_count: number
          open_token: string
          organization_id: string
          party_id: string | null
          sent_at: string
          sent_to: string
          subject: string | null
        }
        Insert: {
          click_count?: number
          communication_id?: string | null
          contact_id?: string | null
          created_at?: string
          draft_id?: string | null
          first_opened_at?: string | null
          id?: string
          open_count?: number
          open_token?: string
          organization_id: string
          party_id?: string | null
          sent_at?: string
          sent_to?: string
          subject?: string | null
        }
        Update: {
          click_count?: number
          communication_id?: string | null
          contact_id?: string | null
          created_at?: string
          draft_id?: string | null
          first_opened_at?: string | null
          id?: string
          open_count?: number
          open_token?: string
          organization_id?: string
          party_id?: string | null
          sent_at?: string
          sent_to?: string
          subject?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "email_tracking_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_tracking_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_tracking_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_tracking_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_tracking_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "email_tracking_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_tracking_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "email_tracking_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_tracking_org_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_tracking_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_tracking_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_tracking_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_tracking_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_tracking_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "email_tracking_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "email_tracking_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "email_tracking_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      email_tracking_events: {
        Row: {
          created_at: string
          event_type: string
          id: string
          ip: string | null
          link_id: string | null
          tracking_id: string
          url: string | null
          user_agent: string | null
        }
        Insert: {
          created_at?: string
          event_type: string
          id?: string
          ip?: string | null
          link_id?: string | null
          tracking_id: string
          url?: string | null
          user_agent?: string | null
        }
        Update: {
          created_at?: string
          event_type?: string
          id?: string
          ip?: string | null
          link_id?: string | null
          tracking_id?: string
          url?: string | null
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "email_tracking_events_link_id_fkey"
            columns: ["link_id"]
            isOneToOne: false
            referencedRelation: "email_tracking_links"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_tracking_events_tracking_id_fkey"
            columns: ["tracking_id"]
            isOneToOne: false
            referencedRelation: "email_tracking"
            referencedColumns: ["id"]
          },
        ]
      }
      email_tracking_links: {
        Row: {
          click_count: number
          id: string
          original_url: string
          token: string
          tracking_id: string
        }
        Insert: {
          click_count?: number
          id?: string
          original_url: string
          token?: string
          tracking_id: string
        }
        Update: {
          click_count?: number
          id?: string
          original_url?: string
          token?: string
          tracking_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "email_tracking_links_tracking_id_fkey"
            columns: ["tracking_id"]
            isOneToOne: false
            referencedRelation: "email_tracking"
            referencedColumns: ["id"]
          },
        ]
      }
      email_whitelist: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          is_active: boolean
          kind: string
          notes: string | null
          organization_id: string
          pattern: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          kind: string
          notes?: string | null
          organization_id: string
          pattern: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          is_active?: boolean
          kind?: string
          notes?: string | null
          organization_id?: string
          pattern?: string
        }
        Relationships: [
          {
            foreignKeyName: "email_whitelist_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "email_whitelist_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      engagement_participants: {
        Row: {
          attended: boolean | null
          contribution_pct: number | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          event_id: string
          event_kind: string
          id: string
          notes: string | null
          organization_id: string
          person_party_id: string
          role: Database["app"]["Enums"]["participant_role"]
          rsvp_response: string | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          attended?: boolean | null
          contribution_pct?: number | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          event_id: string
          event_kind: string
          id?: string
          notes?: string | null
          organization_id: string
          person_party_id: string
          role?: Database["app"]["Enums"]["participant_role"]
          rsvp_response?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          attended?: boolean | null
          contribution_pct?: number | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          event_id?: string
          event_kind?: string
          id?: string
          notes?: string | null
          organization_id?: string
          person_party_id?: string
          role?: Database["app"]["Enums"]["participant_role"]
          rsvp_response?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "engagement_participants_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      engagement_stage_history: {
        Row: {
          duration_in_from_seconds: number | null
          engagement_id: string
          from_stage_id: string | null
          id: string
          moved_at: string
          moved_by: string | null
          notes: string | null
          organization_id: string
          reason: string | null
          to_stage_id: string
        }
        Insert: {
          duration_in_from_seconds?: number | null
          engagement_id: string
          from_stage_id?: string | null
          id?: string
          moved_at?: string
          moved_by?: string | null
          notes?: string | null
          organization_id: string
          reason?: string | null
          to_stage_id: string
        }
        Update: {
          duration_in_from_seconds?: number | null
          engagement_id?: string
          from_stage_id?: string | null
          id?: string
          moved_at?: string
          moved_by?: string | null
          notes?: string | null
          organization_id?: string
          reason?: string | null
          to_stage_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "engagement_stage_history_moved_by_fkey"
            columns: ["moved_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagement_stage_history_engagement_id"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagement_stage_history_from_stage_id"
            columns: ["from_stage_id"]
            isOneToOne: false
            referencedRelation: "pipeline_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagement_stage_history_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagement_stage_history_to_stage_id"
            columns: ["to_stage_id"]
            isOneToOne: false
            referencedRelation: "pipeline_stages"
            referencedColumns: ["id"]
          },
        ]
      }
      engagement_type_registry: {
        Row: {
          created_at: string
          deleted_at: string | null
          description: string | null
          display_order: number
          engagement_kind: string
          id: string
          is_active: boolean
          is_default_for_module: boolean
          label_en: string
          label_ja: string | null
          label_ko: string
          module_data: Json
          organization_id: string
          party_kind: Database["app"]["Enums"]["party_kind"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          display_order?: number
          engagement_kind: string
          id?: string
          is_active?: boolean
          is_default_for_module?: boolean
          label_en: string
          label_ja?: string | null
          label_ko: string
          module_data?: Json
          organization_id: string
          party_kind: Database["app"]["Enums"]["party_kind"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          display_order?: number
          engagement_kind?: string
          id?: string
          is_active?: boolean
          is_default_for_module?: boolean
          label_en?: string
          label_ja?: string | null
          label_ko?: string
          module_data?: Json
          organization_id?: string
          party_kind?: Database["app"]["Enums"]["party_kind"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "engagement_type_registry_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      engagements: {
        Row: {
          actual_close_date: string | null
          created_at: string
          created_by: string | null
          current_stage_id: string | null
          deleted_at: string | null
          description: string | null
          expected_close_date: string | null
          id: string
          last_activity_at: string | null
          mill_id: number | null
          module_data: Json
          name: string
          next_action_at: string | null
          organization_id: string
          owner_team_id: string | null
          owner_user_id: string | null
          party_id: string
          party_type: Database["app"]["Enums"]["party_type"]
          pipeline_definition_id: string | null
          primary_contact_id: string | null
          priority: Database["app"]["Enums"]["priority_level"]
          probability_pct: number
          source: string | null
          status: Database["app"]["Enums"]["engagement_status"]
          updated_at: string
          updated_by: string | null
          value_amount: number | null
          value_currency: string
          weighted_amount: number | null
          won_lost_reason: string | null
        }
        Insert: {
          actual_close_date?: string | null
          created_at?: string
          created_by?: string | null
          current_stage_id?: string | null
          deleted_at?: string | null
          description?: string | null
          expected_close_date?: string | null
          id?: string
          last_activity_at?: string | null
          mill_id?: number | null
          module_data?: Json
          name: string
          next_action_at?: string | null
          organization_id: string
          owner_team_id?: string | null
          owner_user_id?: string | null
          party_id: string
          party_type: Database["app"]["Enums"]["party_type"]
          pipeline_definition_id?: string | null
          primary_contact_id?: string | null
          priority?: Database["app"]["Enums"]["priority_level"]
          probability_pct?: number
          source?: string | null
          status?: Database["app"]["Enums"]["engagement_status"]
          updated_at?: string
          updated_by?: string | null
          value_amount?: number | null
          value_currency?: string
          weighted_amount?: number | null
          won_lost_reason?: string | null
        }
        Update: {
          actual_close_date?: string | null
          created_at?: string
          created_by?: string | null
          current_stage_id?: string | null
          deleted_at?: string | null
          description?: string | null
          expected_close_date?: string | null
          id?: string
          last_activity_at?: string | null
          mill_id?: number | null
          module_data?: Json
          name?: string
          next_action_at?: string | null
          organization_id?: string
          owner_team_id?: string | null
          owner_user_id?: string | null
          party_id?: string
          party_type?: Database["app"]["Enums"]["party_type"]
          pipeline_definition_id?: string | null
          primary_contact_id?: string | null
          priority?: Database["app"]["Enums"]["priority_level"]
          probability_pct?: number
          source?: string | null
          status?: Database["app"]["Enums"]["engagement_status"]
          updated_at?: string
          updated_by?: string | null
          value_amount?: number | null
          value_currency?: string
          weighted_amount?: number | null
          won_lost_reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "engagements_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagements_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_current_stage_id"
            columns: ["current_stage_id"]
            isOneToOne: false
            referencedRelation: "pipeline_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_owner_team_id"
            columns: ["owner_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_owner_user_id"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_engagements_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_engagements_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_engagements_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_engagements_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_engagements_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_pipeline_definition_id"
            columns: ["pipeline_definition_id"]
            isOneToOne: false
            referencedRelation: "pipelines"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_primary_contact_id"
            columns: ["primary_contact_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_primary_contact_id"
            columns: ["primary_contact_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_engagements_primary_contact_id"
            columns: ["primary_contact_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_engagements_primary_contact_id"
            columns: ["primary_contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_engagements_primary_contact_id"
            columns: ["primary_contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_engagements_primary_contact_id"
            columns: ["primary_contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_engagements_primary_contact_id"
            columns: ["primary_contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_engagements_primary_contact_id"
            columns: ["primary_contact_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      entity_tags: {
        Row: {
          entity_id: string
          entity_type: string
          id: string
          organization_id: string
          tag_id: string
          tagged_at: string
          tagged_by: string | null
        }
        Insert: {
          entity_id: string
          entity_type: string
          id?: string
          organization_id: string
          tag_id: string
          tagged_at?: string
          tagged_by?: string | null
        }
        Update: {
          entity_id?: string
          entity_type?: string
          id?: string
          organization_id?: string
          tag_id?: string
          tagged_at?: string
          tagged_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "entity_tags_tagged_by_fkey"
            columns: ["tagged_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_entity_tags_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_entity_tags_tag_id"
            columns: ["tag_id"]
            isOneToOne: false
            referencedRelation: "tags"
            referencedColumns: ["id"]
          },
        ]
      }
      filler_supplier_profile: {
        Row: {
          auto_promoted_at: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          evidence_level: string | null
          id: string
          industry_source: string
          market_role: string | null
          module_data: Json
          notes: string | null
          onsite_pcc_evidence: string | null
          organization_id: string
          party_id: string
          supplier_type: string | null
          supply_model: string | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          auto_promoted_at?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          evidence_level?: string | null
          id?: string
          industry_source?: string
          market_role?: string | null
          module_data?: Json
          notes?: string | null
          onsite_pcc_evidence?: string | null
          organization_id: string
          party_id: string
          supplier_type?: string | null
          supply_model?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          auto_promoted_at?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          evidence_level?: string | null
          id?: string
          industry_source?: string
          market_role?: string | null
          module_data?: Json
          notes?: string | null
          onsite_pcc_evidence?: string | null
          organization_id?: string
          party_id?: string
          supplier_type?: string | null
          supply_model?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "filler_supplier_profile_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "filler_supplier_profile_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "filler_supplier_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "filler_supplier_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "filler_supplier_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "filler_supplier_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "filler_supplier_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "filler_supplier_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "filler_supplier_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "filler_supplier_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "filler_supplier_profile_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      industry_collections: {
        Row: {
          code: string
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string | null
          geography_focus: string[]
          id: string
          industry_tags: string[]
          is_active: boolean
          last_run_at: string | null
          name: string
          notes: string | null
          organization_id: string
          primary_party_type: Database["app"]["Enums"]["party_type"]
          research_objective: string | null
          target_volume: number | null
          total_imported: number
          total_normalized: number
          total_targets: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          code: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          geography_focus?: string[]
          id?: string
          industry_tags?: string[]
          is_active?: boolean
          last_run_at?: string | null
          name: string
          notes?: string | null
          organization_id: string
          primary_party_type: Database["app"]["Enums"]["party_type"]
          research_objective?: string | null
          target_volume?: number | null
          total_imported?: number
          total_normalized?: number
          total_targets?: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          code?: string
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          geography_focus?: string[]
          id?: string
          industry_tags?: string[]
          is_active?: boolean
          last_run_at?: string | null
          name?: string
          notes?: string | null
          organization_id?: string
          primary_party_type?: Database["app"]["Enums"]["party_type"]
          research_objective?: string | null
          target_volume?: number | null
          total_imported?: number
          total_normalized?: number
          total_targets?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_industry_collections_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "industry_collections_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "industry_collections_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      investor_partner_profile: {
        Row: {
          background: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          education: string | null
          email: string | null
          firm_party_id: string
          focus_areas: string[]
          id: string
          is_decision_maker: boolean
          joined_year: number | null
          notes: string | null
          organization_id: string
          party_id: string
          phone: string | null
          seniority_level: Database["app"]["Enums"]["partner_seniority"]
          source: string | null
          title_text: string | null
          twitter_handle: string | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          background?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          education?: string | null
          email?: string | null
          firm_party_id: string
          focus_areas?: string[]
          id?: string
          is_decision_maker?: boolean
          joined_year?: number | null
          notes?: string | null
          organization_id: string
          party_id: string
          phone?: string | null
          seniority_level?: Database["app"]["Enums"]["partner_seniority"]
          source?: string | null
          title_text?: string | null
          twitter_handle?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          background?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          education?: string | null
          email?: string | null
          firm_party_id?: string
          focus_areas?: string[]
          id?: string
          is_decision_maker?: boolean
          joined_year?: number | null
          notes?: string | null
          organization_id?: string
          party_id?: string
          phone?: string | null
          seniority_level?: Database["app"]["Enums"]["partner_seniority"]
          source?: string | null
          title_text?: string | null
          twitter_handle?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_ipp_organization"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_partner_profile_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_partner_profile_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_partner_profile_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "investor_partner_profile_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "investor_partner_profile_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "investor_partner_profile_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "investor_partner_profile_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "investor_partner_profile_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_partner_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_partner_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_partner_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "investor_partner_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "investor_partner_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "investor_partner_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "investor_partner_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "investor_partner_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      investor_portfolio_companies: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          investment_amount_usd: number | null
          investment_stage: string | null
          investment_year: number | null
          investor_party_id: string
          is_active: boolean
          is_lead: boolean
          notes: string | null
          organization_id: string
          portfolio_company_country: string | null
          portfolio_company_id: string | null
          portfolio_company_name: string
          portfolio_company_website: string | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          investment_amount_usd?: number | null
          investment_stage?: string | null
          investment_year?: number | null
          investor_party_id: string
          is_active?: boolean
          is_lead?: boolean
          notes?: string | null
          organization_id: string
          portfolio_company_country?: string | null
          portfolio_company_id?: string | null
          portfolio_company_name: string
          portfolio_company_website?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          investment_amount_usd?: number | null
          investment_stage?: string | null
          investment_year?: number | null
          investor_party_id?: string
          is_active?: boolean
          is_lead?: boolean
          notes?: string | null
          organization_id?: string
          portfolio_company_country?: string | null
          portfolio_company_id?: string | null
          portfolio_company_name?: string
          portfolio_company_website?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_portfolio_investor_id"
            columns: ["investor_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_portfolio_investor_id"
            columns: ["investor_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_portfolio_investor_id"
            columns: ["investor_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_portfolio_investor_id"
            columns: ["investor_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_portfolio_investor_id"
            columns: ["investor_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_portfolio_investor_id"
            columns: ["investor_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_portfolio_investor_id"
            columns: ["investor_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_portfolio_investor_id"
            columns: ["investor_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_portfolio_companies_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_portfolio_companies_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_portfolio_companies_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      investor_profile: {
        Row: {
          aum_usd: number | null
          created_at: string
          created_by: string | null
          fund_name: string | null
          fund_size_usd: number | null
          fund_vintage_year: number | null
          geographic_focus: string[]
          id: string
          investment_stages: string[]
          is_lead_investor: boolean
          is_strategic: boolean
          organization_id: string
          party_id: string
          sector_focus: string[]
          subtype: Database["app"]["Enums"]["investor_subtype"] | null
          ticket_max_usd: number | null
          ticket_min_usd: number | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          aum_usd?: number | null
          created_at?: string
          created_by?: string | null
          fund_name?: string | null
          fund_size_usd?: number | null
          fund_vintage_year?: number | null
          geographic_focus?: string[]
          id?: string
          investment_stages?: string[]
          is_lead_investor?: boolean
          is_strategic?: boolean
          organization_id: string
          party_id: string
          sector_focus?: string[]
          subtype?: Database["app"]["Enums"]["investor_subtype"] | null
          ticket_max_usd?: number | null
          ticket_min_usd?: number | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          aum_usd?: number | null
          created_at?: string
          created_by?: string | null
          fund_name?: string | null
          fund_size_usd?: number | null
          fund_vintage_year?: number | null
          geographic_focus?: string[]
          id?: string
          investment_stages?: string[]
          is_lead_investor?: boolean
          is_strategic?: boolean
          organization_id?: string
          party_id?: string
          sector_focus?: string[]
          subtype?: Database["app"]["Enums"]["investor_subtype"] | null
          ticket_max_usd?: number | null
          ticket_min_usd?: number | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_investor_profile_party_id"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_investor_profile_party_id"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_investor_profile_party_id"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_investor_profile_party_id"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_investor_profile_party_id"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_investor_profile_party_id"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_investor_profile_party_id"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_investor_profile_party_id"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_profile_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_profile_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "investor_profile_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      investor_subtype_meta: {
        Row: {
          code: Database["app"]["Enums"]["investor_subtype"]
          created_at: string
          description_en: string | null
          display_name_en: string
          display_name_ja: string | null
          display_name_ko: string
          icon_emoji: string | null
          is_active: boolean
          is_corporate: boolean
          is_institutional: boolean
          is_personal: boolean
          is_public_sector: boolean
          notes: string | null
          sort_order: number
          typical_check_max_usd: number | null
          typical_check_min_usd: number | null
          typical_horizon_years: number | null
          updated_at: string
        }
        Insert: {
          code: Database["app"]["Enums"]["investor_subtype"]
          created_at?: string
          description_en?: string | null
          display_name_en: string
          display_name_ja?: string | null
          display_name_ko: string
          icon_emoji?: string | null
          is_active?: boolean
          is_corporate?: boolean
          is_institutional?: boolean
          is_personal?: boolean
          is_public_sector?: boolean
          notes?: string | null
          sort_order?: number
          typical_check_max_usd?: number | null
          typical_check_min_usd?: number | null
          typical_horizon_years?: number | null
          updated_at?: string
        }
        Update: {
          code?: Database["app"]["Enums"]["investor_subtype"]
          created_at?: string
          description_en?: string | null
          display_name_en?: string
          display_name_ja?: string | null
          display_name_ko?: string
          icon_emoji?: string | null
          is_active?: boolean
          is_corporate?: boolean
          is_institutional?: boolean
          is_personal?: boolean
          is_public_sector?: boolean
          notes?: string | null
          sort_order?: number
          typical_check_max_usd?: number | null
          typical_check_min_usd?: number | null
          typical_horizon_years?: number | null
          updated_at?: string
        }
        Relationships: []
      }
      invoices: {
        Row: {
          balance_amount: number | null
          created_at: string
          created_by: string | null
          currency: string
          deleted_at: string | null
          due_date: string | null
          id: string
          invoice_number: string
          issue_date: string
          notes: string | null
          order_id: string | null
          organization_id: string
          paid_amount: number
          party_id: string
          pdf_attachment_id: string | null
          status: Database["app"]["Enums"]["invoice_status"]
          subtotal_amount: number
          tax_amount: number
          total_amount: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          balance_amount?: number | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          due_date?: string | null
          id?: string
          invoice_number: string
          issue_date?: string
          notes?: string | null
          order_id?: string | null
          organization_id: string
          paid_amount?: number
          party_id: string
          pdf_attachment_id?: string | null
          status?: Database["app"]["Enums"]["invoice_status"]
          subtotal_amount?: number
          tax_amount?: number
          total_amount?: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          balance_amount?: number | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          due_date?: string | null
          id?: string
          invoice_number?: string
          issue_date?: string
          notes?: string | null
          order_id?: string | null
          organization_id?: string
          paid_amount?: number
          party_id?: string
          pdf_attachment_id?: string | null
          status?: Database["app"]["Enums"]["invoice_status"]
          subtotal_amount?: number
          tax_amount?: number
          total_amount?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "invoices_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "sales_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "invoices_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "invoices_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "invoices_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "invoices_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "invoices_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_pdf_attachment_id_fkey"
            columns: ["pdf_attachment_id"]
            isOneToOne: false
            referencedRelation: "attachments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "invoices_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      lead_scores: {
        Row: {
          computed_at: string
          computed_by: string
          confidence: number
          created_at: string
          factors: Json
          id: string
          notes: string | null
          organization_id: string
          party_id: string
          score: number
          updated_at: string
          valid_until: string | null
        }
        Insert: {
          computed_at?: string
          computed_by?: string
          confidence?: number
          created_at?: string
          factors?: Json
          id?: string
          notes?: string | null
          organization_id: string
          party_id: string
          score?: number
          updated_at?: string
          valid_until?: string | null
        }
        Update: {
          computed_at?: string
          computed_by?: string
          confidence?: number
          created_at?: string
          factors?: Json
          id?: string
          notes?: string | null
          organization_id?: string
          party_id?: string
          score?: number
          updated_at?: string
          valid_until?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "lead_scores_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "lead_scores_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "lead_scores_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "lead_scores_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "lead_scores_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "lead_scores_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "lead_scores_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "lead_scores_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "lead_scores_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      mail_merge_jobs: {
        Row: {
          ab_test_id: string | null
          completed_at: string | null
          created_at: string
          created_by: string | null
          description: string | null
          error_message: string | null
          estimated_recipient_count: number | null
          from_address: string
          from_name: string | null
          id: string
          legal_approved_at: string | null
          legal_approved_by: string | null
          name: string
          organization_id: string
          progress: Json
          quiet_hours: Json
          rate_limit_per_hour: number
          rate_limit_per_minute: number
          recipient_contact_ids: string[]
          recipient_filter: Json
          recipient_party_ids: string[]
          reply_to_address: string | null
          requires_legal_approval: boolean
          scheduled_at: string | null
          started_at: string | null
          status: string
          tabs_campaign_id: string | null
          tabs_campaign_status: string | null
          tabs_campaign_synced_at: string | null
          template_id: string
          template_version_id: string | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          ab_test_id?: string | null
          completed_at?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          error_message?: string | null
          estimated_recipient_count?: number | null
          from_address: string
          from_name?: string | null
          id?: string
          legal_approved_at?: string | null
          legal_approved_by?: string | null
          name: string
          organization_id: string
          progress?: Json
          quiet_hours?: Json
          rate_limit_per_hour?: number
          rate_limit_per_minute?: number
          recipient_contact_ids?: string[]
          recipient_filter?: Json
          recipient_party_ids?: string[]
          reply_to_address?: string | null
          requires_legal_approval?: boolean
          scheduled_at?: string | null
          started_at?: string | null
          status?: string
          tabs_campaign_id?: string | null
          tabs_campaign_status?: string | null
          tabs_campaign_synced_at?: string | null
          template_id: string
          template_version_id?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          ab_test_id?: string | null
          completed_at?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          error_message?: string | null
          estimated_recipient_count?: number | null
          from_address?: string
          from_name?: string | null
          id?: string
          legal_approved_at?: string | null
          legal_approved_by?: string | null
          name?: string
          organization_id?: string
          progress?: Json
          quiet_hours?: Json
          rate_limit_per_hour?: number
          rate_limit_per_minute?: number
          recipient_contact_ids?: string[]
          recipient_filter?: Json
          recipient_party_ids?: string[]
          reply_to_address?: string | null
          requires_legal_approval?: boolean
          scheduled_at?: string | null
          started_at?: string | null
          status?: string
          tabs_campaign_id?: string | null
          tabs_campaign_status?: string | null
          tabs_campaign_synced_at?: string | null
          template_id?: string
          template_version_id?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_mail_merge_jobs_ab_test_id"
            columns: ["ab_test_id"]
            isOneToOne: false
            referencedRelation: "template_ab_tests"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_mail_merge_jobs_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_mail_merge_jobs_template_version_id"
            columns: ["template_version_id"]
            isOneToOne: false
            referencedRelation: "template_versions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "mail_merge_jobs_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "mail_merge_jobs_legal_approved_by_fkey"
            columns: ["legal_approved_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "mail_merge_jobs_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      mailcarrier_state: {
        Row: {
          kind: string
          last_processed_uid: number
          organization_id: string
          uid_validity: number | null
          updated_at: string
          username: string
        }
        Insert: {
          kind: string
          last_processed_uid?: number
          organization_id: string
          uid_validity?: number | null
          updated_at?: string
          username: string
        }
        Update: {
          kind?: string
          last_processed_uid?: number
          organization_id?: string
          uid_validity?: number | null
          updated_at?: string
          username?: string
        }
        Relationships: []
      }
      meeting_attendees: {
        Row: {
          contact_id: string | null
          created_at: string
          email: string
          id: string
          is_internal: boolean
          meeting_id: string
          name: string | null
          notes: string | null
          organization_id: string
          person_party_id: string | null
          response: Database["app"]["Enums"]["attendee_response"]
          role: Database["app"]["Enums"]["attendee_role"]
          user_id: string | null
        }
        Insert: {
          contact_id?: string | null
          created_at?: string
          email: string
          id?: string
          is_internal?: boolean
          meeting_id: string
          name?: string | null
          notes?: string | null
          organization_id: string
          person_party_id?: string | null
          response?: Database["app"]["Enums"]["attendee_response"]
          role?: Database["app"]["Enums"]["attendee_role"]
          user_id?: string | null
        }
        Update: {
          contact_id?: string | null
          created_at?: string
          email?: string
          id?: string
          is_internal?: boolean
          meeting_id?: string
          name?: string | null
          notes?: string | null
          organization_id?: string
          person_party_id?: string | null
          response?: Database["app"]["Enums"]["attendee_response"]
          role?: Database["app"]["Enums"]["attendee_role"]
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "meeting_attendees_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_attendees_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_attendees_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "meeting_attendees_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "meeting_attendees_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "meeting_attendees_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "meeting_attendees_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "meeting_attendees_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_attendees_meeting_id_fkey"
            columns: ["meeting_id"]
            isOneToOne: false
            referencedRelation: "meetings"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_attendees_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_attendees_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_attendees_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_attendees_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "meeting_attendees_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "meeting_attendees_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "meeting_attendees_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "meeting_attendees_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "meeting_attendees_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meeting_attendees_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      meetings: {
        Row: {
          action_items: Json
          actual_ended_at: string | null
          actual_started_at: string | null
          agenda: string | null
          ai_summary: string | null
          calendar_event_id: string | null
          channel: Database["app"]["Enums"]["engagement_channel"] | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          duration_min: number | null
          engagement_id: string | null
          follow_up_task_ids: string[]
          id: string
          location: string | null
          meeting_type: string
          meeting_url: string | null
          next_steps: string | null
          notes: string | null
          occurred_at: string
          organization_id: string
          outcome: string | null
          party_id: string
          scheduled_at: string | null
          stage_id: string | null
          status: Database["app"]["Enums"]["meeting_status"]
          title: string
          updated_at: string
          updated_by: string | null
          user_id: string | null
        }
        Insert: {
          action_items?: Json
          actual_ended_at?: string | null
          actual_started_at?: string | null
          agenda?: string | null
          ai_summary?: string | null
          calendar_event_id?: string | null
          channel?: Database["app"]["Enums"]["engagement_channel"] | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          duration_min?: number | null
          engagement_id?: string | null
          follow_up_task_ids?: string[]
          id?: string
          location?: string | null
          meeting_type: string
          meeting_url?: string | null
          next_steps?: string | null
          notes?: string | null
          occurred_at: string
          organization_id: string
          outcome?: string | null
          party_id: string
          scheduled_at?: string | null
          stage_id?: string | null
          status?: Database["app"]["Enums"]["meeting_status"]
          title: string
          updated_at?: string
          updated_by?: string | null
          user_id?: string | null
        }
        Update: {
          action_items?: Json
          actual_ended_at?: string | null
          actual_started_at?: string | null
          agenda?: string | null
          ai_summary?: string | null
          calendar_event_id?: string | null
          channel?: Database["app"]["Enums"]["engagement_channel"] | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          duration_min?: number | null
          engagement_id?: string | null
          follow_up_task_ids?: string[]
          id?: string
          location?: string | null
          meeting_type?: string
          meeting_url?: string | null
          next_steps?: string | null
          notes?: string | null
          occurred_at?: string
          organization_id?: string
          outcome?: string | null
          party_id?: string
          scheduled_at?: string | null
          stage_id?: string | null
          status?: Database["app"]["Enums"]["meeting_status"]
          title?: string
          updated_at?: string
          updated_by?: string | null
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_meetings_calendar_event"
            columns: ["calendar_event_id"]
            isOneToOne: false
            referencedRelation: "calendar_events"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meetings_engagement_id_fkey"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meetings_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meetings_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meetings_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meetings_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "meetings_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "meetings_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "meetings_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "meetings_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "meetings_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meetings_stage_id_fkey"
            columns: ["stage_id"]
            isOneToOne: false
            referencedRelation: "pipeline_stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meetings_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "meetings_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      organizations: {
        Row: {
          allowed_modules: Database["app"]["Enums"]["party_type"][]
          country_code: string | null
          created_at: string
          default_currency: string
          default_language: string
          default_timezone: string
          deleted_at: string | null
          domain: string | null
          id: string
          logo_url: string | null
          name: string
          plan: string
          plan_expires_at: string | null
          settings: Json
          slug: string
          updated_at: string
        }
        Insert: {
          allowed_modules: Database["app"]["Enums"]["party_type"][]
          country_code?: string | null
          created_at?: string
          default_currency?: string
          default_language?: string
          default_timezone?: string
          deleted_at?: string | null
          domain?: string | null
          id?: string
          logo_url?: string | null
          name: string
          plan?: string
          plan_expires_at?: string | null
          settings?: Json
          slug: string
          updated_at?: string
        }
        Update: {
          allowed_modules?: Database["app"]["Enums"]["party_type"][]
          country_code?: string | null
          created_at?: string
          default_currency?: string
          default_language?: string
          default_timezone?: string
          deleted_at?: string | null
          domain?: string | null
          id?: string
          logo_url?: string | null
          name?: string
          plan?: string
          plan_expires_at?: string | null
          settings?: Json
          slug?: string
          updated_at?: string
        }
        Relationships: []
      }
      paper_mill_profile: {
        Row: {
          auto_promoted_at: string | null
          created_at: string
          deleted_at: string | null
          europe_mills_footprint: string | null
          evidence_level: string | null
          filler_use_intensity: string | null
          headquarters: string | null
          id: string
          industry_source: string | null
          main_product_category: string | null
          main_products: string | null
          module_data: Json
          organization_id: string
          party_id: string
          updated_at: string
        }
        Insert: {
          auto_promoted_at?: string | null
          created_at?: string
          deleted_at?: string | null
          europe_mills_footprint?: string | null
          evidence_level?: string | null
          filler_use_intensity?: string | null
          headquarters?: string | null
          id?: string
          industry_source?: string | null
          main_product_category?: string | null
          main_products?: string | null
          module_data?: Json
          organization_id: string
          party_id: string
          updated_at?: string
        }
        Update: {
          auto_promoted_at?: string | null
          created_at?: string
          deleted_at?: string | null
          europe_mills_footprint?: string | null
          evidence_level?: string | null
          filler_use_intensity?: string | null
          headquarters?: string | null
          id?: string
          industry_source?: string | null
          main_product_category?: string | null
          main_products?: string | null
          module_data?: Json
          organization_id?: string
          party_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "paper_mill_profile_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "paper_mill_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "paper_mill_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "paper_mill_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "paper_mill_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "paper_mill_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "paper_mill_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "paper_mill_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "paper_mill_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      parties: {
        Row: {
          address: string | null
          annual_revenue_usd: number | null
          city: string | null
          country_code: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          domain_normalized: string | null
          employee_count: number | null
          founded_year: number | null
          id: string
          industry_tags: string[]
          interest_tags: string[]
          legal_name: string | null
          lei_code: string | null
          linkedin_url: string | null
          module_data: Json
          name: string
          name_normalized: string | null
          notes: string | null
          organization_id: string
          owner_team_id: string | null
          owner_user_id: string | null
          parent_party_id: string | null
          party_kind: Database["app"]["Enums"]["party_kind"]
          party_level: string | null
          party_type: Database["app"]["Enums"]["party_type"]
          phone_e164: string | null
          phone_normalized: string | null
          region: string | null
          relationship_score: number | null
          source: string | null
          source_external_id: string | null
          status: Database["app"]["Enums"]["entity_status"]
          tax_id: string | null
          tier: Database["app"]["Enums"]["tier_level"]
          timezone: string | null
          updated_at: string
          updated_by: string | null
          website: string | null
        }
        Insert: {
          address?: string | null
          annual_revenue_usd?: number | null
          city?: string | null
          country_code?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          domain_normalized?: string | null
          employee_count?: number | null
          founded_year?: number | null
          id?: string
          industry_tags?: string[]
          interest_tags?: string[]
          legal_name?: string | null
          lei_code?: string | null
          linkedin_url?: string | null
          module_data?: Json
          name: string
          name_normalized?: string | null
          notes?: string | null
          organization_id: string
          owner_team_id?: string | null
          owner_user_id?: string | null
          parent_party_id?: string | null
          party_kind?: Database["app"]["Enums"]["party_kind"]
          party_level?: string | null
          party_type: Database["app"]["Enums"]["party_type"]
          phone_e164?: string | null
          phone_normalized?: string | null
          region?: string | null
          relationship_score?: number | null
          source?: string | null
          source_external_id?: string | null
          status?: Database["app"]["Enums"]["entity_status"]
          tax_id?: string | null
          tier?: Database["app"]["Enums"]["tier_level"]
          timezone?: string | null
          updated_at?: string
          updated_by?: string | null
          website?: string | null
        }
        Update: {
          address?: string | null
          annual_revenue_usd?: number | null
          city?: string | null
          country_code?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          domain_normalized?: string | null
          employee_count?: number | null
          founded_year?: number | null
          id?: string
          industry_tags?: string[]
          interest_tags?: string[]
          legal_name?: string | null
          lei_code?: string | null
          linkedin_url?: string | null
          module_data?: Json
          name?: string
          name_normalized?: string | null
          notes?: string | null
          organization_id?: string
          owner_team_id?: string | null
          owner_user_id?: string | null
          parent_party_id?: string | null
          party_kind?: Database["app"]["Enums"]["party_kind"]
          party_level?: string | null
          party_type?: Database["app"]["Enums"]["party_type"]
          phone_e164?: string | null
          phone_normalized?: string | null
          region?: string | null
          relationship_score?: number | null
          source?: string | null
          source_external_id?: string | null
          status?: Database["app"]["Enums"]["entity_status"]
          tax_id?: string | null
          tier?: Database["app"]["Enums"]["tier_level"]
          timezone?: string | null
          updated_at?: string
          updated_by?: string | null
          website?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_parties_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_parties_owner_team_id"
            columns: ["owner_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_parties_owner_user_id"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      partner_seniority_meta: {
        Row: {
          code: Database["app"]["Enums"]["partner_seniority"]
          created_at: string
          description_en: string | null
          display_name_en: string
          display_name_ja: string | null
          display_name_ko: string
          icon_emoji: string | null
          is_active: boolean
          is_decision_maker_default: boolean
          notes: string | null
          outreach_score_weight: number
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: Database["app"]["Enums"]["partner_seniority"]
          created_at?: string
          description_en?: string | null
          display_name_en: string
          display_name_ja?: string | null
          display_name_ko: string
          icon_emoji?: string | null
          is_active?: boolean
          is_decision_maker_default?: boolean
          notes?: string | null
          outreach_score_weight?: number
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: Database["app"]["Enums"]["partner_seniority"]
          created_at?: string
          description_en?: string | null
          display_name_en?: string
          display_name_ja?: string | null
          display_name_ko?: string
          icon_emoji?: string | null
          is_active?: boolean
          is_decision_maker_default?: boolean
          notes?: string | null
          outreach_score_weight?: number
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      party_supply_links: {
        Row: {
          created_at: string
          deleted_at: string | null
          filler_party_id: string
          id: string
          mill_party_id: string
          module_data: Json
          notes: string | null
          organization_id: string
          product_grade: string | null
          link_type: Database["app"]["Enums"]["supply_link_type"]
          updated_at: string
          volume_estimate: number | null
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          filler_party_id: string
          id?: string
          mill_party_id: string
          module_data?: Json
          notes?: string | null
          organization_id: string
          product_grade?: string | null
          link_type?: Database["app"]["Enums"]["supply_link_type"]
          updated_at?: string
          volume_estimate?: number | null
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          filler_party_id?: string
          id?: string
          mill_party_id?: string
          module_data?: Json
          notes?: string | null
          organization_id?: string
          product_grade?: string | null
          link_type?: Database["app"]["Enums"]["supply_link_type"]
          updated_at?: string
          volume_estimate?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "party_supply_links_filler_party_id_fkey"
            columns: ["filler_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_supply_links_filler_party_id_fkey"
            columns: ["filler_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_supply_links_filler_party_id_fkey"
            columns: ["filler_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "party_supply_links_filler_party_id_fkey"
            columns: ["filler_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "party_supply_links_filler_party_id_fkey"
            columns: ["filler_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "party_supply_links_filler_party_id_fkey"
            columns: ["filler_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "party_supply_links_filler_party_id_fkey"
            columns: ["filler_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "party_supply_links_filler_party_id_fkey"
            columns: ["filler_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_supply_links_mill_party_id_fkey"
            columns: ["mill_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_supply_links_mill_party_id_fkey"
            columns: ["mill_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_supply_links_mill_party_id_fkey"
            columns: ["mill_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "party_supply_links_mill_party_id_fkey"
            columns: ["mill_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "party_supply_links_mill_party_id_fkey"
            columns: ["mill_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "party_supply_links_mill_party_id_fkey"
            columns: ["mill_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "party_supply_links_mill_party_id_fkey"
            columns: ["mill_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "party_supply_links_mill_party_id_fkey"
            columns: ["mill_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_supply_links_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      payments: {
        Row: {
          amount: number
          created_at: string
          created_by: string | null
          currency: string
          deleted_at: string | null
          id: string
          invoice_id: string | null
          notes: string | null
          organization_id: string
          party_id: string
          payment_date: string
          payment_method: string | null
          reference_number: string | null
          updated_at: string
        }
        Insert: {
          amount: number
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          id?: string
          invoice_id?: string | null
          notes?: string | null
          organization_id: string
          party_id: string
          payment_date?: string
          payment_method?: string | null
          reference_number?: string | null
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          id?: string
          invoice_id?: string | null
          notes?: string | null
          organization_id?: string
          party_id?: string
          payment_date?: string
          payment_method?: string | null
          reference_number?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "payments_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_invoice_id_fkey"
            columns: ["invoice_id"]
            isOneToOne: false
            referencedRelation: "invoices"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "payments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "payments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "payments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "payments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "payments_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      permissions: {
        Row: {
          action: string
          created_at: string
          description: string | null
          id: string
          resource: string
        }
        Insert: {
          action: string
          created_at?: string
          description?: string | null
          id?: string
          resource: string
        }
        Update: {
          action?: string
          created_at?: string
          description?: string | null
          id?: string
          resource?: string
        }
        Relationships: []
      }
      person_firm_history: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          firm_party_id: string
          id: string
          is_decision_maker: boolean | null
          is_primary: boolean
          joined_at: string
          left_at: string | null
          module_data: Json
          notes: string | null
          organization_id: string
          party_type: Database["app"]["Enums"]["party_type"] | null
          person_party_id: string
          role_category: string
          seniority_level: Database["app"]["Enums"]["partner_seniority"] | null
          source: string | null
          title_text: string | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          firm_party_id: string
          id?: string
          is_decision_maker?: boolean | null
          is_primary?: boolean
          joined_at: string
          left_at?: string | null
          module_data?: Json
          notes?: string | null
          organization_id: string
          party_type?: Database["app"]["Enums"]["party_type"] | null
          person_party_id: string
          role_category: string
          seniority_level?: Database["app"]["Enums"]["partner_seniority"] | null
          source?: string | null
          title_text?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          firm_party_id?: string
          id?: string
          is_decision_maker?: boolean | null
          is_primary?: boolean
          joined_at?: string
          left_at?: string | null
          module_data?: Json
          notes?: string | null
          organization_id?: string
          party_type?: Database["app"]["Enums"]["party_type"] | null
          person_party_id?: string
          role_category?: string
          seniority_level?: Database["app"]["Enums"]["partner_seniority"] | null
          source?: string | null
          title_text?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "person_firm_history_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      pipeline_stages: {
        Row: {
          auto_actions: Json
          code: string
          color_hex: string | null
          created_at: string
          default_probability_pct: number
          deleted_at: string | null
          description: string | null
          id: string
          is_lost: boolean
          is_terminal: boolean
          is_won: boolean
          name: string
          organization_id: string
          pipeline_definition_id: string
          sort_order: number
          stage_type: Database["app"]["Enums"]["pipeline_stage_type"]
          updated_at: string
        }
        Insert: {
          auto_actions?: Json
          code: string
          color_hex?: string | null
          created_at?: string
          default_probability_pct?: number
          deleted_at?: string | null
          description?: string | null
          id?: string
          is_lost?: boolean
          is_terminal?: boolean
          is_won?: boolean
          name: string
          organization_id: string
          pipeline_definition_id: string
          sort_order: number
          stage_type: Database["app"]["Enums"]["pipeline_stage_type"]
          updated_at?: string
        }
        Update: {
          auto_actions?: Json
          code?: string
          color_hex?: string | null
          created_at?: string
          default_probability_pct?: number
          deleted_at?: string | null
          description?: string | null
          id?: string
          is_lost?: boolean
          is_terminal?: boolean
          is_won?: boolean
          name?: string
          organization_id?: string
          pipeline_definition_id?: string
          sort_order?: number
          stage_type?: Database["app"]["Enums"]["pipeline_stage_type"]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_pipeline_stages_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_pipeline_stages_pipeline_definition_id"
            columns: ["pipeline_definition_id"]
            isOneToOne: false
            referencedRelation: "pipelines"
            referencedColumns: ["id"]
          },
        ]
      }
      pipelines: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string | null
          id: string
          is_active: boolean
          is_default: boolean
          name: string
          organization_id: string
          party_type: Database["app"]["Enums"]["party_type"]
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          is_default?: boolean
          name: string
          organization_id: string
          party_type: Database["app"]["Enums"]["party_type"]
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          is_default?: boolean
          name?: string
          organization_id?: string
          party_type?: Database["app"]["Enums"]["party_type"]
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_pipeline_definitions_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pipeline_definitions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "pipeline_definitions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      plant_supply_links: {
        Row: {
          confidence_grade: string | null
          contracted_at: string | null
          created_at: string | null
          filler_plant_id: string | null
          filler_type: string | null
          first_contact_at: string | null
          id: string
          notes: string | null
          organization_id: string
          paper_mill_plant_id: string
          source_channel: string | null
          supply_status: string | null
          updated_at: string | null
        }
        Insert: {
          confidence_grade?: string | null
          contracted_at?: string | null
          created_at?: string | null
          filler_plant_id?: string | null
          filler_type?: string | null
          first_contact_at?: string | null
          id: string
          notes?: string | null
          organization_id: string
          paper_mill_plant_id: string
          source_channel?: string | null
          supply_status?: string | null
          updated_at?: string | null
        }
        Update: {
          confidence_grade?: string | null
          contracted_at?: string | null
          created_at?: string | null
          filler_plant_id?: string | null
          filler_type?: string | null
          first_contact_at?: string | null
          id?: string
          notes?: string | null
          organization_id?: string
          paper_mill_plant_id?: string
          source_channel?: string | null
          supply_status?: string | null
          updated_at?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "plant_supply_links_filler_plant_id_fkey"
            columns: ["filler_plant_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plant_supply_links_filler_plant_id_fkey"
            columns: ["filler_plant_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plant_supply_links_filler_plant_id_fkey"
            columns: ["filler_plant_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "plant_supply_links_filler_plant_id_fkey"
            columns: ["filler_plant_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "plant_supply_links_filler_plant_id_fkey"
            columns: ["filler_plant_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "plant_supply_links_filler_plant_id_fkey"
            columns: ["filler_plant_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "plant_supply_links_filler_plant_id_fkey"
            columns: ["filler_plant_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "plant_supply_links_filler_plant_id_fkey"
            columns: ["filler_plant_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plant_supply_links_paper_mill_plant_id_fkey"
            columns: ["paper_mill_plant_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plant_supply_links_paper_mill_plant_id_fkey"
            columns: ["paper_mill_plant_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plant_supply_links_paper_mill_plant_id_fkey"
            columns: ["paper_mill_plant_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "plant_supply_links_paper_mill_plant_id_fkey"
            columns: ["paper_mill_plant_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "plant_supply_links_paper_mill_plant_id_fkey"
            columns: ["paper_mill_plant_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "plant_supply_links_paper_mill_plant_id_fkey"
            columns: ["paper_mill_plant_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "plant_supply_links_paper_mill_plant_id_fkey"
            columns: ["paper_mill_plant_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "plant_supply_links_paper_mill_plant_id_fkey"
            columns: ["paper_mill_plant_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      products: {
        Row: {
          category: string | null
          cost_usd: number | null
          created_at: string
          created_by: string | null
          currency: string | null
          deleted_at: string | null
          description: string | null
          id: string
          image_url: string | null
          is_active: boolean
          is_sellable: boolean
          metadata: Json
          name: string
          organization_id: string
          sku: string
          standard_price_usd: number | null
          uom: string | null
          updated_at: string
          updated_by: string | null
          weight_kg: number | null
        }
        Insert: {
          category?: string | null
          cost_usd?: number | null
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          description?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_sellable?: boolean
          metadata?: Json
          name: string
          organization_id: string
          sku: string
          standard_price_usd?: number | null
          uom?: string | null
          updated_at?: string
          updated_by?: string | null
          weight_kg?: number | null
        }
        Update: {
          category?: string | null
          cost_usd?: number | null
          created_at?: string
          created_by?: string | null
          currency?: string | null
          deleted_at?: string | null
          description?: string | null
          id?: string
          image_url?: string | null
          is_active?: boolean
          is_sellable?: boolean
          metadata?: Json
          name?: string
          organization_id?: string
          sku?: string
          standard_price_usd?: number | null
          uom?: string | null
          updated_at?: string
          updated_by?: string | null
          weight_kg?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "products_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "products_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      quotations: {
        Row: {
          accepted_at: string | null
          created_at: string
          created_by: string | null
          currency: string
          deleted_at: string | null
          discount_amount: number
          engagement_id: string | null
          id: string
          incoterms: string | null
          line_items: Json
          notes: string | null
          organization_id: string
          parent_quote_id: string | null
          party_id: string
          payment_terms: string | null
          pdf_attachment_id: string | null
          quote_number: string
          rejected_at: string | null
          sent_at: string | null
          status: Database["app"]["Enums"]["order_status"]
          subtotal_amount: number
          tax_amount: number
          total_amount: number
          updated_at: string
          updated_by: string | null
          valid_until: string | null
          version: number
        }
        Insert: {
          accepted_at?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          discount_amount?: number
          engagement_id?: string | null
          id?: string
          incoterms?: string | null
          line_items?: Json
          notes?: string | null
          organization_id: string
          parent_quote_id?: string | null
          party_id: string
          payment_terms?: string | null
          pdf_attachment_id?: string | null
          quote_number: string
          rejected_at?: string | null
          sent_at?: string | null
          status?: Database["app"]["Enums"]["order_status"]
          subtotal_amount?: number
          tax_amount?: number
          total_amount?: number
          updated_at?: string
          updated_by?: string | null
          valid_until?: string | null
          version?: number
        }
        Update: {
          accepted_at?: string | null
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          discount_amount?: number
          engagement_id?: string | null
          id?: string
          incoterms?: string | null
          line_items?: Json
          notes?: string | null
          organization_id?: string
          parent_quote_id?: string | null
          party_id?: string
          payment_terms?: string | null
          pdf_attachment_id?: string | null
          quote_number?: string
          rejected_at?: string | null
          sent_at?: string | null
          status?: Database["app"]["Enums"]["order_status"]
          subtotal_amount?: number
          tax_amount?: number
          total_amount?: number
          updated_at?: string
          updated_by?: string | null
          valid_until?: string | null
          version?: number
        }
        Relationships: [
          {
            foreignKeyName: "quotations_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotations_engagement_id_fkey"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotations_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotations_parent_quote_id_fkey"
            columns: ["parent_quote_id"]
            isOneToOne: false
            referencedRelation: "quotations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotations_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotations_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotations_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "quotations_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "quotations_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "quotations_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "quotations_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "quotations_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotations_pdf_attachment_id_fkey"
            columns: ["pdf_attachment_id"]
            isOneToOne: false
            referencedRelation: "attachments"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quotations_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      response_strategies: {
        Row: {
          agent_id: string | null
          ai_generated: boolean
          confidence_score: number | null
          consultation_id: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          engagement_id: string | null
          id: string
          key_messages: string[]
          key_signals: string[]
          organization_id: string
          party_id: string | null
          party_type: Database["app"]["Enums"]["party_type"] | null
          questions_to_ask_internally: string[]
          raw_ai_output: Json
          recommended_approach: string
          requires_finance_review: boolean
          requires_human_review: boolean
          requires_legal_review: boolean
          review_notes: string | null
          reviewed_at: string | null
          reviewed_by_user_id: string | null
          risks_to_avoid: string[]
          run_id: string | null
          situation_analysis: string
          status: Database["app"]["Enums"]["strategy_status"]
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          agent_id?: string | null
          ai_generated?: boolean
          confidence_score?: number | null
          consultation_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          engagement_id?: string | null
          id?: string
          key_messages?: string[]
          key_signals?: string[]
          organization_id: string
          party_id?: string | null
          party_type?: Database["app"]["Enums"]["party_type"] | null
          questions_to_ask_internally?: string[]
          raw_ai_output?: Json
          recommended_approach: string
          requires_finance_review?: boolean
          requires_human_review?: boolean
          requires_legal_review?: boolean
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by_user_id?: string | null
          risks_to_avoid?: string[]
          run_id?: string | null
          situation_analysis: string
          status?: Database["app"]["Enums"]["strategy_status"]
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          agent_id?: string | null
          ai_generated?: boolean
          confidence_score?: number | null
          consultation_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          engagement_id?: string | null
          id?: string
          key_messages?: string[]
          key_signals?: string[]
          organization_id?: string
          party_id?: string | null
          party_type?: Database["app"]["Enums"]["party_type"] | null
          questions_to_ask_internally?: string[]
          raw_ai_output?: Json
          recommended_approach?: string
          requires_finance_review?: boolean
          requires_human_review?: boolean
          requires_legal_review?: boolean
          review_notes?: string | null
          reviewed_at?: string | null
          reviewed_by_user_id?: string | null
          risks_to_avoid?: string[]
          run_id?: string | null
          situation_analysis?: string
          status?: Database["app"]["Enums"]["strategy_status"]
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_response_strategies_consultation_id"
            columns: ["consultation_id"]
            isOneToOne: false
            referencedRelation: "consultations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_response_strategies_engagement_id"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_response_strategies_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_response_strategies_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_response_strategies_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_response_strategies_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_response_strategies_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_response_strategies_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_response_strategies_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_response_strategies_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_response_strategies_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_response_strategies_reviewed_by_user_id"
            columns: ["reviewed_by_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "response_strategies_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "response_strategies_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      role_permissions: {
        Row: {
          granted_at: string
          granted_by: string | null
          permission_id: string
          role_id: string
        }
        Insert: {
          granted_at?: string
          granted_by?: string | null
          permission_id: string
          role_id: string
        }
        Update: {
          granted_at?: string
          granted_by?: string | null
          permission_id?: string
          role_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_role_permissions_permission_id"
            columns: ["permission_id"]
            isOneToOne: false
            referencedRelation: "permissions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_role_permissions_role_id"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "role_permissions_granted_by_fkey"
            columns: ["granted_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      roles: {
        Row: {
          code: string
          created_at: string
          deleted_at: string | null
          description: string | null
          id: string
          is_system: boolean
          name: string
          organization_id: string
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          id?: string
          is_system?: boolean
          name: string
          organization_id: string
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          id?: string
          is_system?: boolean
          name?: string
          organization_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_roles_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      sales_order_items: {
        Row: {
          created_at: string
          description: string
          discount_pct: number
          id: string
          line_number: number
          line_total: number
          notes: string | null
          order_id: string
          organization_id: string
          product_id: string | null
          quantity: number
          unit_price: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          description: string
          discount_pct?: number
          id?: string
          line_number: number
          line_total?: number
          notes?: string | null
          order_id: string
          organization_id: string
          product_id?: string | null
          quantity?: number
          unit_price?: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string
          discount_pct?: number
          id?: string
          line_number?: number
          line_total?: number
          notes?: string | null
          order_id?: string
          organization_id?: string
          product_id?: string | null
          quantity?: number
          unit_price?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "sales_order_items_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "sales_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_order_items_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_order_items_product_id_fkey"
            columns: ["product_id"]
            isOneToOne: false
            referencedRelation: "products"
            referencedColumns: ["id"]
          },
        ]
      }
      sales_orders: {
        Row: {
          created_at: string
          created_by: string | null
          currency: string
          deleted_at: string | null
          discount_amount: number
          engagement_id: string | null
          expected_delivery_date: string | null
          expected_ship_date: string | null
          id: string
          incoterms: string | null
          notes: string | null
          order_date: string
          order_number: string
          organization_id: string
          party_id: string
          payment_terms: string | null
          quotation_id: string | null
          shipping_amount: number
          status: string
          subtotal_amount: number
          tax_amount: number
          total_amount: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          discount_amount?: number
          engagement_id?: string | null
          expected_delivery_date?: string | null
          expected_ship_date?: string | null
          id?: string
          incoterms?: string | null
          notes?: string | null
          order_date?: string
          order_number: string
          organization_id: string
          party_id: string
          payment_terms?: string | null
          quotation_id?: string | null
          shipping_amount?: number
          status?: string
          subtotal_amount?: number
          tax_amount?: number
          total_amount?: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          currency?: string
          deleted_at?: string | null
          discount_amount?: number
          engagement_id?: string | null
          expected_delivery_date?: string | null
          expected_ship_date?: string | null
          id?: string
          incoterms?: string | null
          notes?: string | null
          order_date?: string
          order_number?: string
          organization_id?: string
          party_id?: string
          payment_terms?: string | null
          quotation_id?: string | null
          shipping_amount?: number
          status?: string
          subtotal_amount?: number
          tax_amount?: number
          total_amount?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "sales_orders_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_orders_engagement_id_fkey"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_orders_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_orders_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_orders_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_orders_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "sales_orders_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "sales_orders_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "sales_orders_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "sales_orders_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "sales_orders_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_orders_quotation_id_fkey"
            columns: ["quotation_id"]
            isOneToOne: false
            referencedRelation: "quotations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "sales_orders_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      saved_views: {
        Row: {
          color: string | null
          created_at: string
          description: string | null
          entity_type: string
          filter_params: Json
          icon: string | null
          id: string
          is_pinned: boolean
          is_shared: boolean
          last_used_at: string | null
          name: string
          organization_id: string
          party_type: string | null
          sort_by: string | null
          updated_at: string
          use_count: number
          user_id: string
          visible_columns: string[]
        }
        Insert: {
          color?: string | null
          created_at?: string
          description?: string | null
          entity_type: string
          filter_params?: Json
          icon?: string | null
          id?: string
          is_pinned?: boolean
          is_shared?: boolean
          last_used_at?: string | null
          name: string
          organization_id: string
          party_type?: string | null
          sort_by?: string | null
          updated_at?: string
          use_count?: number
          user_id: string
          visible_columns?: string[]
        }
        Update: {
          color?: string | null
          created_at?: string
          description?: string | null
          entity_type?: string
          filter_params?: Json
          icon?: string | null
          id?: string
          is_pinned?: boolean
          is_shared?: boolean
          last_used_at?: string | null
          name?: string
          organization_id?: string
          party_type?: string | null
          sort_by?: string | null
          updated_at?: string
          use_count?: number
          user_id?: string
          visible_columns?: string[]
        }
        Relationships: [
          {
            foreignKeyName: "saved_views_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      scraping_jobs: {
        Row: {
          collection_id: string | null
          completed_at: string | null
          cost_usd: number
          created_at: string
          deleted_at: string | null
          id: string
          job_kind: string
          job_name: string
          last_error_at: string | null
          last_error_message: string | null
          max_depth: number
          max_retries: number
          max_targets: number
          next_retry_at: string | null
          organization_id: string
          parameters: Json
          priority: Database["app"]["Enums"]["priority_level"]
          retry_count: number
          scheduled_at: string | null
          seed_urls: string[]
          source_id: string
          started_at: string | null
          status: Database["app"]["Enums"]["scraping_job_status"]
          summary: Json
          targets_discovered: number
          targets_failed: number
          targets_processed: number
          targets_skipped: number
          triggered_by_user_id: string | null
          updated_at: string
        }
        Insert: {
          collection_id?: string | null
          completed_at?: string | null
          cost_usd?: number
          created_at?: string
          deleted_at?: string | null
          id?: string
          job_kind?: string
          job_name: string
          last_error_at?: string | null
          last_error_message?: string | null
          max_depth?: number
          max_retries?: number
          max_targets?: number
          next_retry_at?: string | null
          organization_id: string
          parameters?: Json
          priority?: Database["app"]["Enums"]["priority_level"]
          retry_count?: number
          scheduled_at?: string | null
          seed_urls?: string[]
          source_id: string
          started_at?: string | null
          status?: Database["app"]["Enums"]["scraping_job_status"]
          summary?: Json
          targets_discovered?: number
          targets_failed?: number
          targets_processed?: number
          targets_skipped?: number
          triggered_by_user_id?: string | null
          updated_at?: string
        }
        Update: {
          collection_id?: string | null
          completed_at?: string | null
          cost_usd?: number
          created_at?: string
          deleted_at?: string | null
          id?: string
          job_kind?: string
          job_name?: string
          last_error_at?: string | null
          last_error_message?: string | null
          max_depth?: number
          max_retries?: number
          max_targets?: number
          next_retry_at?: string | null
          organization_id?: string
          parameters?: Json
          priority?: Database["app"]["Enums"]["priority_level"]
          retry_count?: number
          scheduled_at?: string | null
          seed_urls?: string[]
          source_id?: string
          started_at?: string | null
          status?: Database["app"]["Enums"]["scraping_job_status"]
          summary?: Json
          targets_discovered?: number
          targets_failed?: number
          targets_processed?: number
          targets_skipped?: number
          triggered_by_user_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_scraping_jobs_collection_id"
            columns: ["collection_id"]
            isOneToOne: false
            referencedRelation: "industry_collections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_scraping_jobs_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_scraping_jobs_source_id"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "scraping_sources"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "scraping_jobs_triggered_by_user_id_fkey"
            columns: ["triggered_by_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      scraping_raw: {
        Row: {
          body_hash_sha256: string | null
          body_size_bytes: number | null
          body_storage_path: string | null
          body_plain: string | null
          content_encoding: string | null
          content_type: string | null
          created_at: string
          fetch_duration_ms: number | null
          fetched_at: string
          http_status: number | null
          id: string
          job_id: string | null
          organization_id: string
          parse_errors: Json | null
          parsed_at: string | null
          parsed_data: Json | null
          proxy_used: string | null
          response_headers: Json | null
          target_id: string
          user_agent: string | null
        }
        Insert: {
          body_hash_sha256?: string | null
          body_size_bytes?: number | null
          body_storage_path?: string | null
          body_plain?: string | null
          content_encoding?: string | null
          content_type?: string | null
          created_at?: string
          fetch_duration_ms?: number | null
          fetched_at?: string
          http_status?: number | null
          id?: string
          job_id?: string | null
          organization_id: string
          parse_errors?: Json | null
          parsed_at?: string | null
          parsed_data?: Json | null
          proxy_used?: string | null
          response_headers?: Json | null
          target_id: string
          user_agent?: string | null
        }
        Update: {
          body_hash_sha256?: string | null
          body_size_bytes?: number | null
          body_storage_path?: string | null
          body_plain?: string | null
          content_encoding?: string | null
          content_type?: string | null
          created_at?: string
          fetch_duration_ms?: number | null
          fetched_at?: string
          http_status?: number | null
          id?: string
          job_id?: string | null
          organization_id?: string
          parse_errors?: Json | null
          parsed_at?: string | null
          parsed_data?: Json | null
          proxy_used?: string | null
          response_headers?: Json | null
          target_id?: string
          user_agent?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_scraping_raw_job_id"
            columns: ["job_id"]
            isOneToOne: false
            referencedRelation: "scraping_jobs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_scraping_raw_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_scraping_raw_target_id"
            columns: ["target_id"]
            isOneToOne: false
            referencedRelation: "scraping_targets"
            referencedColumns: ["id"]
          },
        ]
      }
      scraping_sources: {
        Row: {
          auth_credentials_ref: string | null
          auth_method: string | null
          base_url: string
          blocked_reason: string | null
          code: string
          collection_id: string | null
          cooldown_seconds: number
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string | null
          id: string
          is_active: boolean
          is_blocked: boolean
          last_failure_at: string | null
          last_success_at: string | null
          name: string
          notes: string | null
          organization_id: string
          parser_config: Json
          parser_type: string
          quality_score: number
          requests_per_day: number
          requests_per_minute: number
          requires_auth: boolean
          respects_robots_txt: boolean
          robots_txt_allow: boolean | null
          robots_txt_last_checked_at: string | null
          source_type: Database["app"]["Enums"]["scraping_source_type"]
          tags: string[]
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          auth_credentials_ref?: string | null
          auth_method?: string | null
          base_url: string
          blocked_reason?: string | null
          code: string
          collection_id?: string | null
          cooldown_seconds?: number
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          is_blocked?: boolean
          last_failure_at?: string | null
          last_success_at?: string | null
          name: string
          notes?: string | null
          organization_id: string
          parser_config?: Json
          parser_type?: string
          quality_score?: number
          requests_per_day?: number
          requests_per_minute?: number
          requires_auth?: boolean
          respects_robots_txt?: boolean
          robots_txt_allow?: boolean | null
          robots_txt_last_checked_at?: string | null
          source_type: Database["app"]["Enums"]["scraping_source_type"]
          tags?: string[]
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          auth_credentials_ref?: string | null
          auth_method?: string | null
          base_url?: string
          blocked_reason?: string | null
          code?: string
          collection_id?: string | null
          cooldown_seconds?: number
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          is_blocked?: boolean
          last_failure_at?: string | null
          last_success_at?: string | null
          name?: string
          notes?: string | null
          organization_id?: string
          parser_config?: Json
          parser_type?: string
          quality_score?: number
          requests_per_day?: number
          requests_per_minute?: number
          requires_auth?: boolean
          respects_robots_txt?: boolean
          robots_txt_allow?: boolean | null
          robots_txt_last_checked_at?: string | null
          source_type?: Database["app"]["Enums"]["scraping_source_type"]
          tags?: string[]
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_scraping_sources_collection_id"
            columns: ["collection_id"]
            isOneToOne: false
            referencedRelation: "industry_collections"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_scraping_sources_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "scraping_sources_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "scraping_sources_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      scraping_targets: {
        Row: {
          created_at: string
          depth: number
          discovered_at: string
          domain_normalized: string | null
          fetch_attempts: number
          fingerprint: string | null
          fingerprint_changed_at: string | null
          id: string
          job_id: string | null
          last_attempt_at: string | null
          last_error_message: string | null
          last_success_at: string | null
          organization_id: string
          parent_target_id: string | null
          source_id: string
          status: string
          updated_at: string
          url: string
          url_hash: string
        }
        Insert: {
          created_at?: string
          depth?: number
          discovered_at?: string
          domain_normalized?: string | null
          fetch_attempts?: number
          fingerprint?: string | null
          fingerprint_changed_at?: string | null
          id?: string
          job_id?: string | null
          last_attempt_at?: string | null
          last_error_message?: string | null
          last_success_at?: string | null
          organization_id: string
          parent_target_id?: string | null
          source_id: string
          status?: string
          updated_at?: string
          url: string
          url_hash: string
        }
        Update: {
          created_at?: string
          depth?: number
          discovered_at?: string
          domain_normalized?: string | null
          fetch_attempts?: number
          fingerprint?: string | null
          fingerprint_changed_at?: string | null
          id?: string
          job_id?: string | null
          last_attempt_at?: string | null
          last_error_message?: string | null
          last_success_at?: string | null
          organization_id?: string
          parent_target_id?: string | null
          source_id?: string
          status?: string
          updated_at?: string
          url?: string
          url_hash?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_scraping_targets_job_id"
            columns: ["job_id"]
            isOneToOne: false
            referencedRelation: "scraping_jobs"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_scraping_targets_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_scraping_targets_parent_id"
            columns: ["parent_target_id"]
            isOneToOne: false
            referencedRelation: "scraping_targets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_scraping_targets_source_id"
            columns: ["source_id"]
            isOneToOne: false
            referencedRelation: "scraping_sources"
            referencedColumns: ["id"]
          },
        ]
      }
      shipments: {
        Row: {
          actual_arrival: string | null
          carrier: string | null
          created_at: string
          estimated_arrival: string | null
          id: string
          notes: string | null
          order_id: string
          organization_id: string
          shipment_number: string
          shipped_date: string | null
          shipping_address: Json | null
          status: string
          tracking_number: string | null
          updated_at: string
        }
        Insert: {
          actual_arrival?: string | null
          carrier?: string | null
          created_at?: string
          estimated_arrival?: string | null
          id?: string
          notes?: string | null
          order_id: string
          organization_id: string
          shipment_number: string
          shipped_date?: string | null
          shipping_address?: Json | null
          status?: string
          tracking_number?: string | null
          updated_at?: string
        }
        Update: {
          actual_arrival?: string | null
          carrier?: string | null
          created_at?: string
          estimated_arrival?: string | null
          id?: string
          notes?: string | null
          order_id?: string
          organization_id?: string
          shipment_number?: string
          shipped_date?: string | null
          shipping_address?: Json | null
          status?: string
          tracking_number?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "shipments_order_id_fkey"
            columns: ["order_id"]
            isOneToOne: false
            referencedRelation: "sales_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "shipments_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
      strategy_actions: {
        Row: {
          action_type: Database["app"]["Enums"]["strategy_type"]
          completion_notes: string | null
          created_at: string
          created_by: string | null
          depends_on_action_id: string | null
          description: string | null
          id: string
          linked_task_id: string | null
          organization_id: string
          priority: Database["app"]["Enums"]["priority_level"]
          rationale: string | null
          sort_order: number
          status: Database["app"]["Enums"]["task_status"]
          strategy_id: string
          suggested_due_at: string | null
          suggested_due_in_days: number | null
          suggested_due_in_hours: number | null
          suggested_owner_role: string | null
          title: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          action_type: Database["app"]["Enums"]["strategy_type"]
          completion_notes?: string | null
          created_at?: string
          created_by?: string | null
          depends_on_action_id?: string | null
          description?: string | null
          id?: string
          linked_task_id?: string | null
          organization_id: string
          priority?: Database["app"]["Enums"]["priority_level"]
          rationale?: string | null
          sort_order?: number
          status?: Database["app"]["Enums"]["task_status"]
          strategy_id: string
          suggested_due_at?: string | null
          suggested_due_in_days?: number | null
          suggested_due_in_hours?: number | null
          suggested_owner_role?: string | null
          title: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          action_type?: Database["app"]["Enums"]["strategy_type"]
          completion_notes?: string | null
          created_at?: string
          created_by?: string | null
          depends_on_action_id?: string | null
          description?: string | null
          id?: string
          linked_task_id?: string | null
          organization_id?: string
          priority?: Database["app"]["Enums"]["priority_level"]
          rationale?: string | null
          sort_order?: number
          status?: Database["app"]["Enums"]["task_status"]
          strategy_id?: string
          suggested_due_at?: string | null
          suggested_due_in_days?: number | null
          suggested_due_in_hours?: number | null
          suggested_owner_role?: string | null
          title?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_strategy_actions_depends_on_action_id"
            columns: ["depends_on_action_id"]
            isOneToOne: false
            referencedRelation: "strategy_actions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_strategy_actions_linked_task_id"
            columns: ["linked_task_id"]
            isOneToOne: false
            referencedRelation: "tasks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_strategy_actions_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_strategy_actions_strategy_id"
            columns: ["strategy_id"]
            isOneToOne: false
            referencedRelation: "response_strategies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "strategy_actions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "strategy_actions_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      strategy_outcomes: {
        Row: {
          action_id: string | null
          actual_outcome: string | null
          created_at: string
          created_by: string | null
          deviation_from_predicted: string | null
          engagement_advanced_stage: boolean
          engagement_value_change_usd: number | null
          id: string
          lessons_learned: string | null
          measured_at: string
          measurement_method: string | null
          organization_id: string
          promoted_to_brand_voice_id: string | null
          promoted_to_few_shot_at: string | null
          strategy_id: string
          success_metrics: Json
          suitable_for_few_shot: boolean
          updated_at: string
          updated_by: string | null
          was_successful: boolean
        }
        Insert: {
          action_id?: string | null
          actual_outcome?: string | null
          created_at?: string
          created_by?: string | null
          deviation_from_predicted?: string | null
          engagement_advanced_stage?: boolean
          engagement_value_change_usd?: number | null
          id?: string
          lessons_learned?: string | null
          measured_at?: string
          measurement_method?: string | null
          organization_id: string
          promoted_to_brand_voice_id?: string | null
          promoted_to_few_shot_at?: string | null
          strategy_id: string
          success_metrics?: Json
          suitable_for_few_shot?: boolean
          updated_at?: string
          updated_by?: string | null
          was_successful: boolean
        }
        Update: {
          action_id?: string | null
          actual_outcome?: string | null
          created_at?: string
          created_by?: string | null
          deviation_from_predicted?: string | null
          engagement_advanced_stage?: boolean
          engagement_value_change_usd?: number | null
          id?: string
          lessons_learned?: string | null
          measured_at?: string
          measurement_method?: string | null
          organization_id?: string
          promoted_to_brand_voice_id?: string | null
          promoted_to_few_shot_at?: string | null
          strategy_id?: string
          success_metrics?: Json
          suitable_for_few_shot?: boolean
          updated_at?: string
          updated_by?: string | null
          was_successful?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "fk_strategy_outcomes_action_id"
            columns: ["action_id"]
            isOneToOne: false
            referencedRelation: "strategy_actions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_strategy_outcomes_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_strategy_outcomes_strategy_id"
            columns: ["strategy_id"]
            isOneToOne: false
            referencedRelation: "response_strategies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "strategy_outcomes_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "strategy_outcomes_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      tags: {
        Row: {
          code: string
          color_hex: string | null
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          is_active: boolean
          name: string
          organization_id: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          code: string
          color_hex?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          name: string
          organization_id: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          code?: string
          color_hex?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          name?: string
          organization_id?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_tags_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tags_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tags_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      tasks: {
        Row: {
          actual_minutes: number | null
          assigned_to_team_id: string | null
          assigned_to_user_id: string | null
          blocked_reason: string | null
          completed_at: string | null
          completion_notes: string | null
          contact_id: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string | null
          due_at: string | null
          engagement_id: string | null
          estimated_minutes: number | null
          id: string
          linked_strategy_action_id: string | null
          module_data: Json
          organization_id: string
          parent_task_id: string | null
          party_id: string | null
          party_type: Database["app"]["Enums"]["party_type"] | null
          priority: Database["app"]["Enums"]["priority_level"]
          reminder_at: string | null
          started_at: string | null
          status: Database["app"]["Enums"]["task_status"]
          tags: string[]
          title: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          actual_minutes?: number | null
          assigned_to_team_id?: string | null
          assigned_to_user_id?: string | null
          blocked_reason?: string | null
          completed_at?: string | null
          completion_notes?: string | null
          contact_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          due_at?: string | null
          engagement_id?: string | null
          estimated_minutes?: number | null
          id?: string
          linked_strategy_action_id?: string | null
          module_data?: Json
          organization_id: string
          parent_task_id?: string | null
          party_id?: string | null
          party_type?: Database["app"]["Enums"]["party_type"] | null
          priority?: Database["app"]["Enums"]["priority_level"]
          reminder_at?: string | null
          started_at?: string | null
          status?: Database["app"]["Enums"]["task_status"]
          tags?: string[]
          title: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          actual_minutes?: number | null
          assigned_to_team_id?: string | null
          assigned_to_user_id?: string | null
          blocked_reason?: string | null
          completed_at?: string | null
          completion_notes?: string | null
          contact_id?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          due_at?: string | null
          engagement_id?: string | null
          estimated_minutes?: number | null
          id?: string
          linked_strategy_action_id?: string | null
          module_data?: Json
          organization_id?: string
          parent_task_id?: string | null
          party_id?: string | null
          party_type?: Database["app"]["Enums"]["party_type"] | null
          priority?: Database["app"]["Enums"]["priority_level"]
          reminder_at?: string | null
          started_at?: string | null
          status?: Database["app"]["Enums"]["task_status"]
          tags?: string[]
          title?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_tasks_assigned_to_team_id"
            columns: ["assigned_to_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_assigned_to_user_id"
            columns: ["assigned_to_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_tasks_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_tasks_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_tasks_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_tasks_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_tasks_contact_id"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_engagement_id"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_linked_strategy_action_id"
            columns: ["linked_strategy_action_id"]
            isOneToOne: false
            referencedRelation: "strategy_actions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_parent_task_id"
            columns: ["parent_task_id"]
            isOneToOne: false
            referencedRelation: "tasks"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_tasks_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_tasks_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_tasks_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_tasks_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "fk_tasks_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "fk_tasks_party_id"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tasks_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tasks_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      team_members: {
        Row: {
          joined_at: string
          left_at: string | null
          organization_id: string
          role_in_team: string
          team_id: string
          user_id: string
        }
        Insert: {
          joined_at?: string
          left_at?: string | null
          organization_id: string
          role_in_team?: string
          team_id: string
          user_id: string
        }
        Update: {
          joined_at?: string
          left_at?: string | null
          organization_id?: string
          role_in_team?: string
          team_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_team_members_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_team_members_team_id"
            columns: ["team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_team_members_user_id"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      teams: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string | null
          focus_modules: Database["app"]["Enums"]["party_type"][]
          id: string
          is_active: boolean
          name: string
          organization_id: string
          parent_team_id: string | null
          slug: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          focus_modules: Database["app"]["Enums"]["party_type"][]
          id?: string
          is_active?: boolean
          name: string
          organization_id: string
          parent_team_id?: string | null
          slug: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          focus_modules?: Database["app"]["Enums"]["party_type"][]
          id?: string
          is_active?: boolean
          name?: string
          organization_id?: string
          parent_team_id?: string | null
          slug?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_teams_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_teams_parent_team_id"
            columns: ["parent_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "teams_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "teams_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      template_ab_tests: {
        Row: {
          confidence_level: number | null
          created_at: string
          created_by: string | null
          description: string | null
          ended_at: string | null
          hypothesis: string | null
          id: string
          minimum_sample_size: number
          name: string
          organization_id: string
          primary_metric: string
          started_at: string | null
          status: string
          target_end_at: string | null
          updated_at: string
          updated_by: string | null
          variant_a_metric: number | null
          variant_a_pct: number
          variant_a_sent: number
          variant_a_template_id: string
          variant_b_metric: number | null
          variant_b_sent: number
          variant_b_template_id: string
          winning_variant: string | null
        }
        Insert: {
          confidence_level?: number | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          ended_at?: string | null
          hypothesis?: string | null
          id?: string
          minimum_sample_size?: number
          name: string
          organization_id: string
          primary_metric?: string
          started_at?: string | null
          status?: string
          target_end_at?: string | null
          updated_at?: string
          updated_by?: string | null
          variant_a_metric?: number | null
          variant_a_pct?: number
          variant_a_sent?: number
          variant_a_template_id: string
          variant_b_metric?: number | null
          variant_b_sent?: number
          variant_b_template_id: string
          winning_variant?: string | null
        }
        Update: {
          confidence_level?: number | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          ended_at?: string | null
          hypothesis?: string | null
          id?: string
          minimum_sample_size?: number
          name?: string
          organization_id?: string
          primary_metric?: string
          started_at?: string | null
          status?: string
          target_end_at?: string | null
          updated_at?: string
          updated_by?: string | null
          variant_a_metric?: number | null
          variant_a_pct?: number
          variant_a_sent?: number
          variant_a_template_id?: string
          variant_b_metric?: number | null
          variant_b_sent?: number
          variant_b_template_id?: string
          winning_variant?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_template_ab_tests_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "template_ab_tests_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "template_ab_tests_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      template_categories: {
        Row: {
          applicable_modules: Database["app"]["Enums"]["party_type"][]
          code: string
          color_hex: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          description: string | null
          icon: string | null
          id: string
          is_active: boolean
          name: string
          organization_id: string
          parent_id: string | null
          sort_order: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          applicable_modules: Database["app"]["Enums"]["party_type"][]
          code: string
          color_hex?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          icon?: string | null
          id?: string
          is_active?: boolean
          name: string
          organization_id: string
          parent_id?: string | null
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          applicable_modules?: Database["app"]["Enums"]["party_type"][]
          code?: string
          color_hex?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          description?: string | null
          icon?: string | null
          id?: string
          is_active?: boolean
          name?: string
          organization_id?: string
          parent_id?: string | null
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_template_categories_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_template_categories_parent_id"
            columns: ["parent_id"]
            isOneToOne: false
            referencedRelation: "template_categories"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "template_categories_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "template_categories_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      template_variables: {
        Row: {
          created_at: string
          created_by: string | null
          data_type: string
          default_value: string | null
          description: string | null
          display_name: string
          fallback_template: string | null
          id: string
          is_active: boolean
          is_pii: boolean
          is_required: boolean
          organization_id: string
          sample_values: Json
          source_entity: string
          source_field: string | null
          updated_at: string
          updated_by: string | null
          variable_path: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          data_type: string
          default_value?: string | null
          description?: string | null
          display_name: string
          fallback_template?: string | null
          id?: string
          is_active?: boolean
          is_pii?: boolean
          is_required?: boolean
          organization_id: string
          sample_values?: Json
          source_entity: string
          source_field?: string | null
          updated_at?: string
          updated_by?: string | null
          variable_path: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          data_type?: string
          default_value?: string | null
          description?: string | null
          display_name?: string
          fallback_template?: string | null
          id?: string
          is_active?: boolean
          is_pii?: boolean
          is_required?: boolean
          organization_id?: string
          sample_values?: Json
          source_entity?: string
          source_field?: string | null
          updated_at?: string
          updated_by?: string | null
          variable_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_template_variables_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "template_variables_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "template_variables_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      template_versions: {
        Row: {
          body_html_template: string | null
          body_template: string
          change_reason: string | null
          change_summary: string | null
          created_at: string
          created_by: string | null
          diff_from_previous: Json | null
          id: string
          is_published: boolean
          organization_id: string
          preheader: string | null
          published_at: string | null
          published_by: string | null
          required_variables: string[]
          subject_template: string
          template_id: string
          version_number: number
        }
        Insert: {
          body_html_template?: string | null
          body_template: string
          change_reason?: string | null
          change_summary?: string | null
          created_at?: string
          created_by?: string | null
          diff_from_previous?: Json | null
          id?: string
          is_published?: boolean
          organization_id: string
          preheader?: string | null
          published_at?: string | null
          published_by?: string | null
          required_variables?: string[]
          subject_template: string
          template_id: string
          version_number: number
        }
        Update: {
          body_html_template?: string | null
          body_template?: string
          change_reason?: string | null
          change_summary?: string | null
          created_at?: string
          created_by?: string | null
          diff_from_previous?: Json | null
          id?: string
          is_published?: boolean
          organization_id?: string
          preheader?: string | null
          published_at?: string | null
          published_by?: string | null
          required_variables?: string[]
          subject_template?: string
          template_id?: string
          version_number?: number
        }
        Relationships: [
          {
            foreignKeyName: "fk_template_versions_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "template_versions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "template_versions_published_by_fkey"
            columns: ["published_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      user_roles: {
        Row: {
          assigned_at: string
          assigned_by: string | null
          expires_at: string | null
          organization_id: string
          role_id: string
          user_id: string
        }
        Insert: {
          assigned_at?: string
          assigned_by?: string | null
          expires_at?: string | null
          organization_id: string
          role_id: string
          user_id: string
        }
        Update: {
          assigned_at?: string
          assigned_by?: string | null
          expires_at?: string | null
          organization_id?: string
          role_id?: string
          user_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_user_roles_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_user_roles_role_id"
            columns: ["role_id"]
            isOneToOne: false
            referencedRelation: "roles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_user_roles_user_id"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "user_roles_assigned_by_fkey"
            columns: ["assigned_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          avatar_url: string | null
          created_at: string
          deleted_at: string | null
          department: string | null
          display_name: string | null
          email: string
          email_personal: string | null
          email_role: string | null
          email_shared: string | null
          full_name: string
          id: string
          is_active: boolean
          is_owner: boolean
          job_title: string | null
          last_seen_at: string | null
          organization_id: string
          phone: string | null
          preferred_language: string
          sending_email: string | null
          sending_signature: string | null
          settings: Json
          timezone: string
          updated_at: string
        }
        Insert: {
          avatar_url?: string | null
          created_at?: string
          deleted_at?: string | null
          department?: string | null
          display_name?: string | null
          email: string
          email_personal?: string | null
          email_role?: string | null
          email_shared?: string | null
          full_name: string
          id: string
          is_active?: boolean
          is_owner?: boolean
          job_title?: string | null
          last_seen_at?: string | null
          organization_id: string
          phone?: string | null
          preferred_language?: string
          sending_email?: string | null
          sending_signature?: string | null
          settings?: Json
          timezone?: string
          updated_at?: string
        }
        Update: {
          avatar_url?: string | null
          created_at?: string
          deleted_at?: string | null
          department?: string | null
          display_name?: string | null
          email?: string
          email_personal?: string | null
          email_role?: string | null
          email_shared?: string | null
          full_name?: string
          id?: string
          is_active?: boolean
          is_owner?: boolean
          job_title?: string | null
          last_seen_at?: string | null
          organization_id?: string
          phone?: string | null
          preferred_language?: string
          sending_email?: string | null
          sending_signature?: string | null
          settings?: Json
          timezone?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_users_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      contacts: {
        Row: {
          created_at: string | null
          created_by: string | null
          decision_role: Database["app"]["Enums"]["decision_role"] | null
          deleted_at: string | null
          department: string | null
          do_not_contact: boolean | null
          do_not_contact_reason: string | null
          email: string | null
          email_secondary: string | null
          family_name: string | null
          full_name: string | null
          given_name: string | null
          id: string | null
          is_active: boolean | null
          is_primary: boolean | null
          linkedin_url: string | null
          module_data: Json | null
          notes: string | null
          organization_id: string | null
          party_id: string | null
          phone: string | null
          phone_mobile: string | null
          preferred_language: string | null
          seniority: string | null
          timezone: string | null
          title: string | null
          updated_at: string | null
          updated_by: string | null
        }
        Insert: {
          created_at?: string | null
          created_by?: string | null
          decision_role?: never
          deleted_at?: string | null
          department?: never
          do_not_contact?: never
          do_not_contact_reason?: never
          email?: never
          email_secondary?: never
          family_name?: never
          full_name?: string | null
          given_name?: never
          id?: string | null
          is_active?: never
          is_primary?: never
          linkedin_url?: string | null
          module_data?: Json | null
          notes?: never
          organization_id?: string | null
          party_id?: never
          phone?: string | null
          phone_mobile?: never
          preferred_language?: never
          seniority?: never
          timezone?: never
          title?: never
          updated_at?: string | null
          updated_by?: string | null
        }
        Update: {
          created_at?: string | null
          created_by?: string | null
          decision_role?: never
          deleted_at?: string | null
          department?: never
          do_not_contact?: never
          do_not_contact_reason?: never
          email?: never
          email_secondary?: never
          family_name?: never
          full_name?: string | null
          given_name?: never
          id?: string | null
          is_active?: never
          is_primary?: never
          linkedin_url?: string | null
          module_data?: Json | null
          notes?: never
          organization_id?: string | null
          party_id?: never
          phone?: string | null
          phone_mobile?: never
          preferred_language?: never
          seniority?: never
          timezone?: never
          title?: never
          updated_at?: string | null
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_parties_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_updated_by_fkey"
            columns: ["updated_by"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      v_engagement_events: {
        Row: {
          channel: string | null
          created_at: string | null
          deal_id: string | null
          direction: string | null
          event_at: string | null
          event_id: string | null
          event_kind: string | null
          firm_party_id: string | null
          notes: string | null
          organization_id: string | null
          status: string | null
          subject: string | null
          updated_at: string | null
        }
        Relationships: []
      }
      v_engagement_participants: {
        Row: {
          attended: boolean | null
          channel: string | null
          contribution_pct: number | null
          event_at: string | null
          event_id: string | null
          event_kind: string | null
          firm_name: string | null
          firm_party_id: string | null
          id: string | null
          notes: string | null
          organization_id: string | null
          person_name: string | null
          person_party_id: string | null
          role: string | null
          rsvp_response: string | null
        }
        Relationships: [
          {
            foreignKeyName: "engagement_participants_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      v_filler_suppliers: {
        Row: {
          auto_promoted_at: string | null
          country_code: string | null
          evidence_level: string | null
          firm_id: string | null
          firm_module: Database["app"]["Enums"]["party_type"] | null
          firm_name: string | null
          has_full_supplier_data: boolean | null
          has_pcc_evidence: boolean | null
          industry_source: string | null
          industry_tags: string[] | null
          interest_tags: string[] | null
          linkedin_url: string | null
          market_role: string | null
          onsite_pcc_evidence: string | null
          organization_id: string | null
          parent_name: string | null
          parent_party_id: string | null
          profile_created_at: string | null
          profile_id: string | null
          profile_updated_at: string | null
          relationship_score: number | null
          supplier_type: string | null
          supply_model: string | null
          website: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_parties_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["parent_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      v_firm_alumni: {
        Row: {
          current_firm_id: string | null
          current_firm_name: string | null
          current_title: string | null
          firm_module: Database["app"]["Enums"]["party_type"] | null
          firm_name: string | null
          firm_party_id: string | null
          joined_at: string | null
          left_at: string | null
          organization_id: string | null
          person_linkedin: string | null
          person_name: string | null
          person_party_id: string | null
          role_category: string | null
          tenure_status: string | null
          title_text: string | null
        }
        Relationships: [
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["current_firm_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["current_firm_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["current_firm_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["current_firm_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["current_firm_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["current_firm_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["current_firm_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["current_firm_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      v_firm_engagement_summary: {
        Row: {
          channels_used: string[] | null
          communication_count: number | null
          firm_name: string | null
          firm_party_id: string | null
          first_event_at: string | null
          last_event_at: string | null
          meeting_count: number | null
          organization_id: string | null
          total_event_count: number | null
        }
        Relationships: []
      }
      v_investor_outreach_list: {
        Row: {
          city: string | null
          country_code: string | null
          firm_aum_usd: number | null
          firm_founded: number | null
          firm_fund_size_usd: number | null
          firm_id: string | null
          firm_interests: string[] | null
          firm_name: string | null
          firm_sectors: string[] | null
          firm_stages: string[] | null
          firm_subtype: Database["app"]["Enums"]["investor_subtype"] | null
          firm_tags: string[] | null
          firm_website: string | null
          partner_background: string | null
          partner_email: string | null
          partner_focus: string[] | null
          partner_id: string | null
          partner_is_decision_maker: boolean | null
          partner_linkedin: string | null
          partner_name: string | null
          partner_seniority:
            | Database["app"]["Enums"]["partner_seniority"]
            | null
          partner_title: string | null
          region: string | null
        }
        Relationships: []
      }
      v_investor_subtype_options: {
        Row: {
          code: Database["app"]["Enums"]["investor_subtype"] | null
          display_name_en: string | null
          display_name_ja: string | null
          display_name_ko: string | null
          firm_count: number | null
          has_data: boolean | null
          icon_emoji: string | null
          is_active: boolean | null
          is_corporate: boolean | null
          is_institutional: boolean | null
          is_personal: boolean | null
          is_public_sector: boolean | null
          sort_order: number | null
          typical_check_max_usd: number | null
          typical_check_min_usd: number | null
        }
        Relationships: []
      }
      v_investor_with_partners: {
        Row: {
          firm_aum_b: number | null
          firm_hq: string | null
          firm_id: string | null
          firm_name: string | null
          firm_tags: string[] | null
          firm_website: string | null
          partner_background: string | null
          partner_email: string | null
          partner_focus: Json | null
          partner_id: string | null
          partner_linkedin: string | null
          partner_name: string | null
          partner_title: string | null
        }
        Relationships: []
      }
      v_paper_mills: {
        Row: {
          active_supplier_count: number | null
          address: string | null
          annual_revenue_usd: number | null
          auto_promoted_at: string | null
          city: string | null
          country_code: string | null
          created_at: string | null
          deleted_at: string | null
          domain_normalized: string | null
          employee_count: number | null
          europe_mills_footprint: string | null
          evidence_level: string | null
          filler_use_intensity: string | null
          headquarters: string | null
          historical_supplier_count: number | null
          id: string | null
          industry_source: string | null
          industry_tags: string[] | null
          interest_tags: string[] | null
          legal_name: string | null
          linkedin_url: string | null
          main_product_category: string | null
          main_products: string | null
          name: string | null
          organization_id: string | null
          owner_team_id: string | null
          owner_user_id: string | null
          party_module_data: Json | null
          potential_supplier_count: number | null
          profile_created_at: string | null
          profile_module_data: Json | null
          profile_updated_at: string | null
          region: string | null
          relationship_score: number | null
          source: string | null
          source_external_id: string | null
          status: Database["app"]["Enums"]["entity_status"] | null
          tier: Database["app"]["Enums"]["tier_level"] | null
          timezone: string | null
          updated_at: string | null
          website: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_parties_organization_id"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_parties_owner_team_id"
            columns: ["owner_team_id"]
            isOneToOne: false
            referencedRelation: "teams"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "fk_parties_owner_user_id"
            columns: ["owner_user_id"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      v_partner_seniority_options: {
        Row: {
          code: Database["app"]["Enums"]["partner_seniority"] | null
          display_name_en: string | null
          display_name_ja: string | null
          display_name_ko: string | null
          icon_emoji: string | null
          is_active: boolean | null
          is_decision_maker_default: boolean | null
          outreach_score_weight: number | null
          partner_count: number | null
          sort_order: number | null
        }
        Relationships: []
      }
      v_party_dedup_candidates: {
        Row: {
          a_parent_id: string | null
          a_root_id: string | null
          b_parent_id: string | null
          b_root_id: string | null
          country_a: string | null
          country_b: string | null
          match_kind: string | null
          module: Database["app"]["Enums"]["party_type"] | null
          name_a: string | null
          name_b: string | null
          party_a: string | null
          party_b: string | null
          party_type: Database["app"]["Enums"]["party_kind"] | null
          similarity_score: number | null
        }
        Relationships: [
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      v_person_career_history: {
        Row: {
          context_module: Database["app"]["Enums"]["party_type"] | null
          firm_module: Database["app"]["Enums"]["party_type"] | null
          firm_name: string | null
          firm_party_id: string | null
          firm_website: string | null
          history_id: string | null
          is_decision_maker: boolean | null
          is_primary: boolean | null
          joined_at: string | null
          left_at: string | null
          notes: string | null
          organization_id: string | null
          person_linkedin: string | null
          person_name: string | null
          person_party_id: string | null
          role_category: string | null
          seniority_level: Database["app"]["Enums"]["partner_seniority"] | null
          source: string | null
          status: string | null
          title_text: string | null
          years_at_firm: number | null
        }
        Relationships: [
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "person_firm_history_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      v_person_dedup_candidates: {
        Row: {
          a_parent_id: string | null
          a_root_id: string | null
          b_parent_id: string | null
          b_root_id: string | null
          country_a: string | null
          country_b: string | null
          match_kind: string | null
          module: Database["app"]["Enums"]["party_type"] | null
          name_a: string | null
          name_b: string | null
          party_a: string | null
          party_b: string | null
          party_type: Database["app"]["Enums"]["party_kind"] | null
          similarity_score: number | null
        }
        Relationships: [
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["a_parent_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_parent_party_id_fkey"
            columns: ["b_parent_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
      v_person_engagement_participation: {
        Row: {
          channels_used: string[] | null
          communication_count: number | null
          firms_engaged: string[] | null
          first_event_at: string | null
          last_event_at: string | null
          meeting_count: number | null
          organization_id: string | null
          person_name: string | null
          person_party_id: string | null
          roles_played: string[] | null
          rsvp_accepted_count: number | null
          rsvp_declined_count: number | null
          total_event_count: number | null
          unique_firms_engaged: number | null
        }
        Relationships: [
          {
            foreignKeyName: "engagement_participants_organization_id_fkey"
            columns: ["organization_id"]
            isOneToOne: false
            referencedRelation: "organizations"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_filler_suppliers"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_outreach_list"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["firm_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_investor_with_partners"
            referencedColumns: ["partner_id"]
          },
          {
            foreignKeyName: "engagement_participants_person_party_id_fkey"
            columns: ["person_party_id"]
            isOneToOne: false
            referencedRelation: "v_paper_mills"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      compute_default_lead_score: {
        Args: { p_party_id: string }
        Returns: number
      }
      create_meeting_with_host: {
        Args: {
          p_firm_party_id: string
          p_host_person_party_id: string
          p_meeting_mode?: string
          p_meeting_type: string
          p_notes?: string
          p_occurred_at: string
          p_organization_id: string
          p_title: string
        }
        Returns: string
      }
      current_is_owner: { Args: never; Returns: boolean }
      current_organization_id: { Args: never; Returns: string }
      current_preferred_language: { Args: never; Returns: string }
      current_user_id: { Args: never; Returns: string }
      decrypt_calendar_token: { Args: { p_encrypted: string }; Returns: string }
      encrypt_calendar_token: { Args: { p_plain: string }; Returns: string }
      fn_detect_calendar_channel: {
        Args: { p_location: string; p_meeting_url: string }
        Returns: Database["app"]["Enums"]["engagement_channel"]
      }
      get_buyer_engagement_summary: {
        Args: { p_engagement_id: string }
        Returns: Json
      }
      get_pipeline_forecast: {
        Args: { p_months?: number; p_org_id: string }
        Returns: {
          currency: string
          month_start: string
          open_count: number
          total_value: number
          weighted_value: number
        }[]
      }
      is_member_of_organization: {
        Args: { p_organization_id: string }
        Returns: boolean
      }
      is_organization_owner: {
        Args: { p_organization_id: string }
        Returns: boolean
      }
      log_communication_with_parties: {
        Args: {
          p_body: string
          p_cc_person_party_ids?: string[]
          p_channel_type: string
          p_direction: string
          p_firm_party_id: string
          p_occurred_at?: string
          p_organization_id: string
          p_recipient_person_party_ids: string[]
          p_sender_person_party_id: string
          p_subject: string
        }
        Returns: string
      }
      normalize_domain: { Args: { url: string }; Returns: string }
      normalize_phone: { Args: { p_phone: string }; Returns: string }
      promote_buyer_engagement_to_sales_order: {
        Args: { p_engagement_id: string }
        Returns: string
      }
      record_engagement_participant: {
        Args: {
          p_event_id: string
          p_event_kind: string
          p_organization_id: string
          p_person_party_id: string
          p_role: Database["app"]["Enums"]["participant_role"]
          p_rsvp_response?: string
        }
        Returns: string
      }
      sync_calendar_match_party: {
        Args: { p_event_id: string }
        Returns: string
      }
      sync_calendar_promote_to_meeting: {
        Args: { p_engagement_id?: string; p_event_id: string }
        Returns: string
      }
      sync_calendar_pull: {
        Args: { p_connection_id: string; p_events: Json }
        Returns: {
          failed_count: number
          inserted_count: number
          log_id: string
          skipped_count: number
          updated_count: number
        }[]
      }
      sync_calendar_push_prep: {
        Args: { p_meeting_id: string }
        Returns: {
          event_id: string
          payload: Json
        }[]
      }
      update_party_lead_score: { Args: { p_party_id: string }; Returns: number }
      upsert_calendar_connection: {
        Args: {
          p_access_token: string
          p_account_email: string
          p_account_name: string
          p_enc_key: string
          p_expires_at: string
          p_organization_id: string
          p_provider: string
          p_refresh_token: string
          p_scopes: string[]
          p_user_id: string
        }
        Returns: string
      }
    }
    Enums: {
      attendee_response: "no_response" | "accepted" | "declined" | "tentative"
      attendee_role: "organizer" | "required" | "optional" | "resource"
      buyer_subtype:
        | "distributor"
        | "wholesaler"
        | "retailer"
        | "oem_partner"
        | "end_brand"
        | "direct_user"
        | "other"
      calendar_provider: "google" | "microsoft" | "internal"
      calendar_sync_status:
        | "pending"
        | "syncing"
        | "success"
        | "partial"
        | "failed"
      consultation_channel:
        | "inbound_email"
        | "meeting_notes"
        | "phone_call"
        | "manual_entry"
        | "attachment"
      decision_role:
        | "champion"
        | "decision_maker"
        | "influencer"
        | "gatekeeper"
        | "user"
        | "unknown"
      dedup_status:
        | "pending"
        | "auto_merged"
        | "manual_merged"
        | "rejected_duplicate"
        | "kept_separate"
      direction_type: "inbound" | "outbound" | "internal"
      email_sequence_status: "draft" | "active" | "paused" | "archived"
      engagement_channel:
        | "in_person"
        | "video_call"
        | "video_conference"
        | "phone_call"
        | "email"
        | "sms"
        | "kakaotalk"
        | "wechat"
        | "whatsapp"
        | "linkedin"
        | "slack"
        | "webform"
        | "postal"
        | "hybrid"
        | "other"
      engagement_status:
        | "open"
        | "in_progress"
        | "on_hold"
        | "won"
        | "lost"
        | "archived"
      enrollment_status:
        | "active"
        | "completed"
        | "cancelled"
        | "failed"
        | "paused"
      entity_status: "active" | "inactive" | "archived" | "blocked"
      event_status: "confirmed" | "tentative" | "cancelled"
      investor_subtype:
        | "vc"
        | "cvc"
        | "growth_equity"
        | "private_equity"
        | "family_office"
        | "accelerator"
        | "angel"
        | "crowdfunding"
        | "government"
        | "other"
      invoice_status:
        | "draft"
        | "issued"
        | "partial_paid"
        | "paid"
        | "overdue"
        | "void"
      meeting_status:
        | "scheduled"
        | "completed"
        | "cancelled"
        | "no_show"
        | "rescheduled"
      meeting_type:
        | "intro"
        | "discovery"
        | "pitch"
        | "negotiation"
        | "due_diligence"
        | "kickoff"
        | "review"
        | "closing"
        | "other"
      order_status:
        | "draft"
        | "confirmed"
        | "in_production"
        | "ready_to_ship"
        | "shipped"
        | "delivered"
        | "cancelled"
        | "returned"
      participant_role:
        | "sender"
        | "recipient"
        | "cc"
        | "bcc"
        | "host"
        | "attendee"
        | "observer"
        | "decision_maker"
        | "introducer"
      partner_seniority:
        | "founder"
        | "partner"
        | "principal"
        | "associate"
        | "advisor"
        | "other"
      party_kind:
        | "company"
        | "organization"
        | "individual"
        | "fund"
        | "government"
      party_type:
        | "investor"
        | "paper_mill"
        | "partner"
        | "customer"
        | "filler_supplier"
      pipeline_stage_type:
        | "lead"
        | "qualified"
        | "proposal"
        | "negotiation"
        | "won"
        | "lost"
      priority_level: "low" | "medium" | "high" | "urgent"
      scraping_job_status:
        | "queued"
        | "running"
        | "completed"
        | "failed"
        | "cancelled"
        | "rate_limited"
      scraping_source_type:
        | "industry_directory"
        | "public_disclosure"
        | "company_website"
        | "gleif_lei"
        | "sec_edgar"
        | "dart_kr"
        | "press_release"
        | "other"
      send_status: "pending" | "sent" | "skipped" | "bounced" | "failed"
      strategy_status: "draft" | "active" | "completed" | "abandoned"
      strategy_type: "immediate" | "short_term" | "long_term"
      supply_link_type: "potential" | "active" | "historical"
      sync_operation:
        | "pull"
        | "push"
        | "match_party"
        | "promote"
        | "conflict"
        | "error"
      task_status: "todo" | "in_progress" | "blocked" | "done" | "cancelled"
      template_status: "draft" | "active" | "archived" | "deprecated"
      tier_level: "tier_1" | "tier_2" | "tier_3" | "tier_4" | "tier_5"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  ingest: {
    Tables: {
      rows: {
        Row: {
          created_at: string
          dedup_key: string | null
          error_message: string | null
          id: string
          module: string
          name: string
          payload: Json
          promoted_party_id: string | null
          run_id: string
          seq: number | null
          status: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          dedup_key?: string | null
          error_message?: string | null
          id?: string
          module: string
          name: string
          payload: Json
          promoted_party_id?: string | null
          run_id: string
          seq?: number | null
          status?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          dedup_key?: string | null
          error_message?: string | null
          id?: string
          module?: string
          name?: string
          payload?: Json
          promoted_party_id?: string | null
          run_id?: string
          seq?: number | null
          status?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "rows_run_id_fkey"
            columns: ["run_id"]
            isOneToOne: false
            referencedRelation: "runs"
            referencedColumns: ["id"]
          },
        ]
      }
      runs: {
        Row: {
          actor: string
          description: string | null
          finished_at: string | null
          id: string
          label: string
          module: string
          notes: string | null
          organization_id: string
          rows_failed: number
          rows_merged: number
          rows_promoted: number
          rows_skipped: number
          rows_staged: number
          sources: string[]
          started_at: string
        }
        Insert: {
          actor?: string
          description?: string | null
          finished_at?: string | null
          id?: string
          label: string
          module: string
          notes?: string | null
          organization_id: string
          rows_failed?: number
          rows_merged?: number
          rows_promoted?: number
          rows_skipped?: number
          rows_staged?: number
          sources?: string[]
          started_at?: string
        }
        Update: {
          actor?: string
          description?: string | null
          finished_at?: string | null
          id?: string
          label?: string
          module?: string
          notes?: string | null
          organization_id?: string
          rows_failed?: number
          rows_merged?: number
          rows_promoted?: number
          rows_skipped?: number
          rows_staged?: number
          sources?: string[]
          started_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      failed_rows: {
        Row: {
          created_at: string | null
          dedup_key: string | null
          error_message: string | null
          name: string | null
          payload: Json | null
          run_label: string | null
          seq: number | null
        }
        Relationships: []
      }
      run_summary: {
        Row: {
          actor: string | null
          description: string | null
          finished_at: string | null
          label: string | null
          module: string | null
          organization_id: string | null
          rows_failed: number | null
          rows_merged: number | null
          rows_promoted: number | null
          rows_skipped: number | null
          rows_staged: number | null
          started_at: string | null
          status: string | null
        }
        Insert: {
          actor?: string | null
          description?: string | null
          finished_at?: string | null
          label?: string | null
          module?: string | null
          organization_id?: string | null
          rows_failed?: number | null
          rows_merged?: number | null
          rows_promoted?: number | null
          rows_skipped?: number | null
          rows_staged?: number | null
          started_at?: string | null
          status?: never
        }
        Update: {
          actor?: string | null
          description?: string | null
          finished_at?: string | null
          label?: string | null
          module?: string | null
          organization_id?: string | null
          rows_failed?: number | null
          rows_merged?: number | null
          rows_promoted?: number | null
          rows_skipped?: number | null
          rows_staged?: number | null
          started_at?: string | null
          status?: never
        }
        Relationships: []
      }
    }
    Functions: {
      coerce_investor_subtype: {
        Args: { p_raw: string }
        Returns: Database["app"]["Enums"]["investor_subtype"]
      }
      coerce_text_array: { Args: { p_value: Json }; Returns: string[] }
      finish_run: { Args: { p_run_label: string }; Returns: undefined }
      infer_is_decision_maker: { Args: { p_title: string }; Returns: boolean }
      infer_seniority: {
        Args: { p_title: string }
        Returns: Database["app"]["Enums"]["partner_seniority"]
      }
      normalize_domain: { Args: { p_url: string }; Returns: string }
      normalize_linkedin: { Args: { p_url: string }; Returns: string }
      promote_investor_partners: {
        Args: { p_run_label: string }
        Returns: {
          action: string
          n: number
        }[]
      }
      promote_investors: {
        Args: { p_run_label: string }
        Returns: {
          action: string
          n: number
        }[]
      }
      rollback_run: {
        Args: { p_confirm?: boolean; p_run_label: string }
        Returns: {
          deleted_table: string
          n: number
        }[]
      }
      stage_row: {
        Args: { p_payload: Json; p_run_label: string }
        Returns: string
      }
      stage_rows_bulk: {
        Args: { p_payloads: Json; p_run_label: string }
        Returns: number
      }
      start_run: {
        Args: {
          p_description?: string
          p_label: string
          p_module: string
          p_organization_id: string
          p_sources?: string[]
        }
        Returns: string
      }
      upsert_govt_grant_contact: {
        Args: {
          p_is_decision_maker?: boolean
          p_name: string
          p_organization_id: string
          p_parent_party_id?: string
          p_preferred_channel?: string
          p_role_category?: string
          p_source?: string
          p_specialty_areas?: string[]
        }
        Returns: string
      }
      upsert_govt_grant_program: {
        Args: {
          p_agency_code: string
          p_agency_country_code: string
          p_application_status?: string
          p_budget_total_usd?: number
          p_eligible_sectors?: string[]
          p_fiscal_year?: number
          p_funding_mechanism?: string
          p_name: string
          p_next_deadline?: string
          p_organization_id: string
          p_program_category?: string
          p_program_name?: string
          p_program_url?: string
          p_source?: string
        }
        Returns: string
      }
      upsert_portfolio_company: {
        Args: {
          p_country: string
          p_name: string
          p_org_id: string
          p_sector?: string
          p_website: string
        }
        Returns: string
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      add_email_whitelist: {
        Args: {
          p_kind: string
          p_notes?: string
          p_org_id: string
          p_pattern: string
        }
        Returns: string
      }
      advance_enrollment: {
        Args: {
          p_communication_id: string
          p_enrollment_id: string
          p_is_last_step: boolean
          p_status?: Database["app"]["Enums"]["send_status"]
          p_step_id: string
          p_step_order: number
        }
        Returns: undefined
      }
      archive_sequence: { Args: { p_sequence_id: string }; Returns: undefined }
      bulk_enroll_filtered:
        | {
            Args: {
              p_country_code?: string
              p_dry_run?: boolean
              p_enrolled_by?: string
              p_module?: string
              p_organization_id: string
              p_sequence_id: string
              p_status?: string
              p_tiers?: string[]
            }
            Returns: {
              enrolled_count: number
              sample_names: string[]
              skipped_already_enrolled: number
              skipped_no_email: number
              total_matching: number
            }[]
          }
        | {
            Args: {
              p_country_code?: string
              p_dry_run?: boolean
              p_enrolled_by?: string
              p_industry_tag?: string
              p_module?: string
              p_name_contains?: string
              p_organization_id: string
              p_sequence_id: string
              p_status?: string
              p_tiers?: string[]
            }
            Returns: {
              enrolled_count: number
              sample_names: string[]
              skipped_already_enrolled: number
              skipped_no_email: number
              total_matching: number
            }[]
          }
      cancel_enrollment: {
        Args: { p_enrollment_id: string }
        Returns: undefined
      }
      count_email_history: {
        Args: { p_organization_id: string }
        Returns: number
      }
      create_campaign_from_template:
        | {
            Args: {
              p_campaign_name: string
              p_country_code?: string
              p_enrolled_by?: string
              p_module?: string
              p_organization_id: string
              p_status?: string
              p_template_id: string
              p_tiers?: string[]
            }
            Returns: {
              enrolled_count: number
              sample_names: string[]
              sequence_id: string
              skipped_already_enrolled: number
              skipped_no_email: number
              total_matching: number
            }[]
          }
        | {
            Args: {
              p_campaign_name: string
              p_country_code?: string
              p_enrolled_by?: string
              p_industry_tag?: string
              p_module?: string
              p_name_contains?: string
              p_organization_id: string
              p_status?: string
              p_template_id: string
              p_tiers?: string[]
            }
            Returns: {
              enrolled_count: number
              sample_names: string[]
              sequence_id: string
              skipped_already_enrolled: number
              skipped_no_email: number
              total_matching: number
            }[]
          }
      create_email_tracking: {
        Args: {
          p_communication_id?: string
          p_contact_id?: string
          p_draft_id?: string
          p_links?: Json
          p_org_id: string
          p_party_id?: string
          p_sent_to?: string
          p_subject?: string
        }
        Returns: Json
      }
      create_sequence: {
        Args: {
          p_description: string
          p_name: string
          p_organization_id: string
          p_steps: Json
        }
        Returns: string
      }
      custom_access_token_hook: { Args: { event: Json }; Returns: Json }
      delete_email_whitelist: { Args: { p_id: string }; Returns: undefined }
      enroll_in_sequence: {
        Args: {
          p_contact_id: string
          p_enrolled_by: string
          p_organization_id: string
          p_party_id: string
          p_sequence_id: string
        }
        Returns: string
      }
      get_communications_stats_per_party: {
        Args: { p_party_id: string }
        Returns: {
          opened: number
          received: number
          replied: number
          sent: number
          threads: number
          total: number
        }[]
      }
      get_contact_communications_timeline: {
        Args: { p_contact_id: string; p_limit?: number }
        Returns: {
          ai_classification: Json
          ai_generated: boolean
          body_html: string
          body_plain: string
          body_summary: string
          clicked_at: string
          direction: string
          from_address: string
          from_name: string
          id: string
          in_reply_to: string
          is_starred: boolean
          message_id: string
          occurred_at: string
          opened_at: string
          received_at: string
          replied_at: string
          sent_at: string
          status: string
          subject: string
          template_id: string
          thread_id: string
          thread_position: number
          to_addresses: string[]
        }[]
      }
      get_due_enrollments: {
        Args: never
        Returns: {
          contact_id: string
          enrolled_at: string
          enrolled_by: string
          enrollment_id: string
          is_last_step: boolean
          next_step_order: number
          organization_id: string
          party_id: string
          sequence_id: string
          step_body_text: string
          step_day_offset: number
          step_id: string
          step_subject: string
        }[]
      }
      get_email_history: {
        Args: { p_limit?: number; p_offset?: number; p_organization_id: string }
        Returns: {
          click_count: number
          communication_id: string
          contact_email: string
          contact_full_name: string
          enrollment_id: string
          first_opened_at: string
          open_count: number
          party_id: string
          party_name: string
          send_id: string
          send_status: Database["app"]["Enums"]["send_status"]
          sent_at: string
          sequence_id: string
          sequence_name: string
          step_order: number
        }[]
      }
      get_lead_scores_many: {
        Args: { p_party_ids: string[] }
        Returns: {
          computed_at: string
          factors: Json
          party_id: string
          score: number
        }[]
      }
      get_party_communications_timeline: {
        Args: { p_limit?: number; p_party_id: string }
        Returns: {
          ai_classification: Json
          ai_generated: boolean
          body_html: string
          body_plain: string
          body_summary: string
          clicked_at: string
          contact_email: string
          contact_id: string
          contact_name: string
          direction: string
          from_address: string
          from_name: string
          id: string
          in_reply_to: string
          is_starred: boolean
          message_id: string
          occurred_at: string
          opened_at: string
          received_at: string
          replied_at: string
          sent_at: string
          status: string
          subject: string
          template_id: string
          thread_id: string
          thread_position: number
          to_addresses: string[]
        }[]
      }
      get_party_enrollments: {
        Args: { p_party_id: string }
        Returns: {
          enrolled_at: string
          id: string
          next_send_at: string
          next_step_order: number
          sends_count: number
          sequence_id: string
          sequence_name: string
          status: Database["app"]["Enums"]["enrollment_status"]
          total_steps: number
        }[]
      }
      get_sequence_with_steps: {
        Args: { p_sequence_id: string }
        Returns: Json
      }
      get_thread_context: {
        Args: { p_communication_id: string }
        Returns: Json
      }
      get_tracking_for_communications: {
        Args: { p_communication_ids: string[] }
        Returns: {
          click_count: number
          communication_id: string
          first_opened_at: string
          open_count: number
          sent_at: string
          tracking_id: string
        }[]
      }
      get_tracking_for_drafts: {
        Args: { p_draft_ids: string[] }
        Returns: {
          click_count: number
          draft_id: string
          first_opened_at: string
          open_count: number
          sent_at: string
          tracking_id: string
        }[]
      }
      get_unregistered_party_domains: {
        Args: { p_org_id: string }
        Returns: {
          contact_count: number
          domain: string
          party_names: string
        }[]
      }
      get_upcoming_meetings: {
        Args: { p_days_ahead?: number; p_user_id?: string }
        Returns: {
          channel: Database["app"]["Enums"]["engagement_channel"]
          duration_min: number
          meeting_id: string
          party_id: string
          party_name: string
          scheduled_at: string
          status: Database["app"]["Enums"]["meeting_status"]
          title: string
        }[]
      }
      list_active_templates: {
        Args: { p_org_id: string }
        Returns: {
          body_plain: string
          category: string
          id: string
          module: string
          name: string
          subject: string
        }[]
      }
      list_email_whitelist: {
        Args: { p_org_id: string }
        Returns: {
          created_at: string
          id: string
          is_active: boolean
          kind: string
          notes: string
          pattern: string
        }[]
      }
      list_sequences: {
        Args: { p_organization_id: string }
        Returns: {
          active_enrollments: number
          created_at: string
          description: string
          id: string
          name: string
          status: Database["app"]["Enums"]["email_sequence_status"]
          step_count: number
          total_sends: number
        }[]
      }
      list_templates_for_compose: {
        Args: { p_module?: string; p_org_id: string }
        Returns: {
          body_html: string
          body_plain: string
          category: string
          id: string
          module: string
          name: string
          subject: string
        }[]
      }
      preview_campaign_filter:
        | {
            Args: {
              p_country_code?: string
              p_module?: string
              p_org_id: string
              p_status?: string
              p_tiers?: string[]
            }
            Returns: {
              no_email: number
              sample_names: string[]
              total_matching: number
              with_email: number
            }[]
          }
        | {
            Args: {
              p_country_code?: string
              p_industry_tag?: string
              p_module?: string
              p_name_contains?: string
              p_org_id: string
              p_status?: string
              p_tiers?: string[]
            }
            Returns: {
              no_email: number
              sample_names: string[]
              total_matching: number
              with_email: number
            }[]
          }
      record_email_click: {
        Args: { p_ip?: string; p_token: string; p_ua?: string }
        Returns: string
      }
      record_email_open: {
        Args: { p_ip?: string; p_token: string; p_ua?: string }
        Returns: undefined
      }
      save_manual_email: {
        Args: {
          p_ai_generated?: boolean
          p_body_html: string
          p_body_plain: string
          p_contact_id: string
          p_from_address: string
          p_from_name: string
          p_in_reply_to?: string
          p_org_id: string
          p_party_id: string
          p_sent_by_user_id?: string
          p_status?: string
          p_subject: string
          p_template_id?: string
          p_to_addresses: string[]
        }
        Returns: string
      }
      show_limit: { Args: never; Returns: number }
      show_trgm: { Args: { "": string }; Returns: string[] }
      toggle_email_whitelist: {
        Args: { p_active: boolean; p_id: string }
        Returns: undefined
      }
      unaccent: { Args: { "": string }; Returns: string }
      update_sequence: {
        Args: {
          p_description: string
          p_name: string
          p_sequence_id: string
          p_steps: Json
        }
        Returns: undefined
      }
    }
    Enums: {
      tier_role: "HQ" | "Regional" | "Country" | "Plant"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  urm: {
    Tables: {
      contact_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          display_name_en: string
          display_name_ja: string | null
          display_name_ko: string
          id: number
          is_active: boolean
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          display_name_en: string
          display_name_ja?: string | null
          display_name_ko: string
          id: number
          is_active?: boolean
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          display_name_en?: string
          display_name_ja?: string | null
          display_name_ko?: string
          id?: number
          is_active?: boolean
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      contacts: {
        Row: {
          background: string | null
          contact_type_id: number
          created_at: string
          deleted_at: string | null
          department: string | null
          education: string | null
          email: string | null
          email_secondary: string | null
          family_name: string | null
          firm_party_id: string
          focus_areas: string[] | null
          full_name: string | null
          given_name: string | null
          id: string
          is_active: boolean
          is_decision_maker: boolean
          is_primary: boolean
          joined_at: string | null
          last_contacted_at: string | null
          left_at: string | null
          linkedin_url: string | null
          module_data: Json
          notes: string | null
          phone_e164: string | null
          phone_mobile: string | null
          role_category: string | null
          seniority_level: string | null
          source: string | null
          source_external_id: string | null
          title_text: string | null
          twitter_handle: string | null
          updated_at: string
        }
        Insert: {
          background?: string | null
          contact_type_id: number
          created_at?: string
          deleted_at?: string | null
          department?: string | null
          education?: string | null
          email?: string | null
          email_secondary?: string | null
          family_name?: string | null
          firm_party_id: string
          focus_areas?: string[] | null
          full_name?: string | null
          given_name?: string | null
          id: string
          is_active?: boolean
          is_decision_maker?: boolean
          is_primary?: boolean
          joined_at?: string | null
          last_contacted_at?: string | null
          left_at?: string | null
          linkedin_url?: string | null
          module_data?: Json
          notes?: string | null
          phone_e164?: string | null
          phone_mobile?: string | null
          role_category?: string | null
          seniority_level?: string | null
          source?: string | null
          source_external_id?: string | null
          title_text?: string | null
          twitter_handle?: string | null
          updated_at?: string
        }
        Update: {
          background?: string | null
          contact_type_id?: number
          created_at?: string
          deleted_at?: string | null
          department?: string | null
          education?: string | null
          email?: string | null
          email_secondary?: string | null
          family_name?: string | null
          firm_party_id?: string
          focus_areas?: string[] | null
          full_name?: string | null
          given_name?: string | null
          id?: string
          is_active?: boolean
          is_decision_maker?: boolean
          is_primary?: boolean
          joined_at?: string | null
          last_contacted_at?: string | null
          left_at?: string | null
          linkedin_url?: string | null
          module_data?: Json
          notes?: string | null
          phone_e164?: string | null
          phone_mobile?: string | null
          role_category?: string | null
          seniority_level?: string | null
          source?: string | null
          source_external_id?: string | null
          title_text?: string | null
          twitter_handle?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "contacts_contact_type_id_fkey"
            columns: ["contact_type_id"]
            isOneToOne: false
            referencedRelation: "contact_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contacts_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
        ]
      }
      contacts_history: {
        Row: {
          contact_id: string
          created_at: string | null
          created_by: string | null
          deleted_at: string | null
          department: string | null
          ended_at: string | null
          firm_party_id: string
          id: string
          module_data: Json | null
          notes: string | null
          role_category: string | null
          seniority_level: string | null
          started_at: string | null
          title_text: string | null
          updated_at: string | null
          updated_by: string | null
        }
        Insert: {
          contact_id: string
          created_at?: string | null
          created_by?: string | null
          deleted_at?: string | null
          department?: string | null
          ended_at?: string | null
          firm_party_id: string
          id?: string
          module_data?: Json | null
          notes?: string | null
          role_category?: string | null
          seniority_level?: string | null
          started_at?: string | null
          title_text?: string | null
          updated_at?: string | null
          updated_by?: string | null
        }
        Update: {
          contact_id?: string
          created_at?: string | null
          created_by?: string | null
          deleted_at?: string | null
          department?: string | null
          ended_at?: string | null
          firm_party_id?: string
          id?: string
          module_data?: Json | null
          notes?: string | null
          role_category?: string | null
          seniority_level?: string | null
          started_at?: string | null
          title_text?: string | null
          updated_at?: string | null
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "contacts_history_contact_id_fkey"
            columns: ["contact_id"]
            isOneToOne: false
            referencedRelation: "contacts"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "contacts_history_firm_party_id_fkey"
            columns: ["firm_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
        ]
      }
      deal_checklists: {
        Row: {
          completed_at: string | null
          completed_by: string | null
          created_at: string | null
          created_by: string | null
          deal_id: string
          deleted_at: string | null
          id: string
          is_complete: boolean | null
          module_data: Json | null
          notes: string | null
          sort_order: number | null
          title: string
          updated_at: string | null
          updated_by: string | null
        }
        Insert: {
          completed_at?: string | null
          completed_by?: string | null
          created_at?: string | null
          created_by?: string | null
          deal_id: string
          deleted_at?: string | null
          id?: string
          is_complete?: boolean | null
          module_data?: Json | null
          notes?: string | null
          sort_order?: number | null
          title: string
          updated_at?: string | null
          updated_by?: string | null
        }
        Update: {
          completed_at?: string | null
          completed_by?: string | null
          created_at?: string | null
          created_by?: string | null
          deal_id?: string
          deleted_at?: string | null
          id?: string
          is_complete?: boolean | null
          module_data?: Json | null
          notes?: string | null
          sort_order?: number | null
          title?: string
          updated_at?: string | null
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "deal_checklists_deal_id_fkey"
            columns: ["deal_id"]
            isOneToOne: false
            referencedRelation: "deals"
            referencedColumns: ["id"]
          },
        ]
      }
      deal_stage_history: {
        Row: {
          changed_at: string
          changed_by: string | null
          created_at: string | null
          deal_id: string
          from_stage_id: string | null
          id: string
          module_data: Json | null
          notes: string | null
          to_stage_id: string
        }
        Insert: {
          changed_at?: string
          changed_by?: string | null
          created_at?: string | null
          deal_id: string
          from_stage_id?: string | null
          id?: string
          module_data?: Json | null
          notes?: string | null
          to_stage_id: string
        }
        Update: {
          changed_at?: string
          changed_by?: string | null
          created_at?: string | null
          deal_id?: string
          from_stage_id?: string | null
          id?: string
          module_data?: Json | null
          notes?: string | null
          to_stage_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "deal_stage_history_deal_id_fkey"
            columns: ["deal_id"]
            isOneToOne: false
            referencedRelation: "deals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "deal_stage_history_from_stage_id_fkey"
            columns: ["from_stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "deal_stage_history_to_stage_id_fkey"
            columns: ["to_stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
        ]
      }
      deals: {
        Row: {
          actual_close_date: string | null
          created_at: string
          created_by: string | null
          current_stage_id: string
          deal_name: string
          deleted_at: string | null
          description: string | null
          expected_close_date: string | null
          id: string
          last_activity_at: string | null
          module_data: Json
          notes: string | null
          owner_user_id: string | null
          party_id: string
          pipeline_id: string
          primary_contact_id: string | null
          priority: string
          probability_pct: number | null
          source: string | null
          source_external_id: string | null
          status: string
          updated_at: string
          updated_by: string | null
          value_amount: number | null
          value_currency: string
          won_lost_reason: string | null
        }
        Insert: {
          actual_close_date?: string | null
          created_at?: string
          created_by?: string | null
          current_stage_id: string
          deal_name: string
          deleted_at?: string | null
          description?: string | null
          expected_close_date?: string | null
          id?: string
          last_activity_at?: string | null
          module_data?: Json
          notes?: string | null
          owner_user_id?: string | null
          party_id: string
          pipeline_id: string
          primary_contact_id?: string | null
          priority?: string
          probability_pct?: number | null
          source?: string | null
          source_external_id?: string | null
          status?: string
          updated_at?: string
          updated_by?: string | null
          value_amount?: number | null
          value_currency?: string
          won_lost_reason?: string | null
        }
        Update: {
          actual_close_date?: string | null
          created_at?: string
          created_by?: string | null
          current_stage_id?: string
          deal_name?: string
          deleted_at?: string | null
          description?: string | null
          expected_close_date?: string | null
          id?: string
          last_activity_at?: string | null
          module_data?: Json
          notes?: string | null
          owner_user_id?: string | null
          party_id?: string
          pipeline_id?: string
          primary_contact_id?: string | null
          priority?: string
          probability_pct?: number | null
          source?: string | null
          source_external_id?: string | null
          status?: string
          updated_at?: string
          updated_by?: string | null
          value_amount?: number | null
          value_currency?: string
          won_lost_reason?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "deals_current_stage_id_fkey"
            columns: ["current_stage_id"]
            isOneToOne: false
            referencedRelation: "stages"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "deals_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "deals_pipeline_id_fkey"
            columns: ["pipeline_id"]
            isOneToOne: false
            referencedRelation: "pipelines"
            referencedColumns: ["id"]
          },
        ]
      }
      engagement_attendees: {
        Row: {
          attended: boolean | null
          contact_id: string
          created_at: string
          engagement_id: string
          id: string
          notes: string | null
          response: string | null
          role: string
          updated_at: string
        }
        Insert: {
          attended?: boolean | null
          contact_id: string
          created_at?: string
          engagement_id: string
          id?: string
          notes?: string | null
          response?: string | null
          role?: string
          updated_at?: string
        }
        Update: {
          attended?: boolean | null
          contact_id?: string
          created_at?: string
          engagement_id?: string
          id?: string
          notes?: string | null
          response?: string | null
          role?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "engagement_attendees_engagement_id_fkey"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
        ]
      }
      engagement_documents: {
        Row: {
          created_at: string
          deleted_at: string | null
          description: string | null
          document_kind: string | null
          engagement_id: string
          file_name: string
          file_size_bytes: number | null
          id: string
          mime_type: string | null
          storage_path: string
          storage_provider: string | null
          updated_at: string
          uploaded_at: string
          uploaded_by_user_id: string | null
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          document_kind?: string | null
          engagement_id: string
          file_name: string
          file_size_bytes?: number | null
          id?: string
          mime_type?: string | null
          storage_path: string
          storage_provider?: string | null
          updated_at?: string
          uploaded_at?: string
          uploaded_by_user_id?: string | null
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          description?: string | null
          document_kind?: string | null
          engagement_id?: string
          file_name?: string
          file_size_bytes?: number | null
          id?: string
          mime_type?: string | null
          storage_path?: string
          storage_provider?: string | null
          updated_at?: string
          uploaded_at?: string
          uploaded_by_user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "engagement_documents_engagement_id_fkey"
            columns: ["engagement_id"]
            isOneToOne: false
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
        ]
      }
      engagement_email_details: {
        Row: {
          bcc_addresses: string[]
          body_html: string | null
          cc_addresses: string[]
          created_at: string
          engagement_id: string
          from_address: string
          has_attachments: boolean
          in_reply_to: string | null
          message_id: string | null
          spam_score: number | null
          subject: string
          thread_id: string | null
          to_addresses: string[]
          updated_at: string
        }
        Insert: {
          bcc_addresses?: string[]
          body_html?: string | null
          cc_addresses?: string[]
          created_at?: string
          engagement_id: string
          from_address: string
          has_attachments?: boolean
          in_reply_to?: string | null
          message_id?: string | null
          spam_score?: number | null
          subject: string
          thread_id?: string | null
          to_addresses?: string[]
          updated_at?: string
        }
        Update: {
          bcc_addresses?: string[]
          body_html?: string | null
          cc_addresses?: string[]
          created_at?: string
          engagement_id?: string
          from_address?: string
          has_attachments?: boolean
          in_reply_to?: string | null
          message_id?: string | null
          spam_score?: number | null
          subject?: string
          thread_id?: string | null
          to_addresses?: string[]
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "engagement_email_details_engagement_id_fkey"
            columns: ["engagement_id"]
            isOneToOne: true
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
        ]
      }
      engagement_meeting_details: {
        Row: {
          actual_ended_at: string | null
          actual_started_at: string | null
          agenda: string | null
          created_at: string
          engagement_id: string
          external_calendar_id: string | null
          location: string | null
          meeting_kind: string | null
          meeting_platform: string | null
          recording_url: string | null
          scheduled_end_at: string | null
          scheduled_start_at: string | null
          transcript_url: string | null
          updated_at: string
          virtual_url: string | null
        }
        Insert: {
          actual_ended_at?: string | null
          actual_started_at?: string | null
          agenda?: string | null
          created_at?: string
          engagement_id: string
          external_calendar_id?: string | null
          location?: string | null
          meeting_kind?: string | null
          meeting_platform?: string | null
          recording_url?: string | null
          scheduled_end_at?: string | null
          scheduled_start_at?: string | null
          transcript_url?: string | null
          updated_at?: string
          virtual_url?: string | null
        }
        Update: {
          actual_ended_at?: string | null
          actual_started_at?: string | null
          agenda?: string | null
          created_at?: string
          engagement_id?: string
          external_calendar_id?: string | null
          location?: string | null
          meeting_kind?: string | null
          meeting_platform?: string | null
          recording_url?: string | null
          scheduled_end_at?: string | null
          scheduled_start_at?: string | null
          transcript_url?: string | null
          updated_at?: string
          virtual_url?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "engagement_meeting_details_engagement_id_fkey"
            columns: ["engagement_id"]
            isOneToOne: true
            referencedRelation: "engagements"
            referencedColumns: ["id"]
          },
        ]
      }
      engagement_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          display_name_en: string
          display_name_ja: string | null
          display_name_ko: string
          id: number
          is_active: boolean
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          display_name_en: string
          display_name_ja?: string | null
          display_name_ko: string
          id: number
          is_active?: boolean
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          display_name_en?: string
          display_name_ja?: string | null
          display_name_ko?: string
          id?: number
          is_active?: boolean
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      engagements: {
        Row: {
          channel: string | null
          content: string | null
          created_at: string
          created_by: string | null
          deal_id: string | null
          deleted_at: string | null
          direction: string | null
          duration_min: number | null
          engagement_type_id: number
          id: string
          module_data: Json
          next_steps: string | null
          notes: string | null
          occurred_at: string
          outcome: string | null
          party_id: string | null
          recorded_by_user_id: string | null
          sentiment: string | null
          status: string
          summary: string | null
          task_id: string | null
          title: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          channel?: string | null
          content?: string | null
          created_at?: string
          created_by?: string | null
          deal_id?: string | null
          deleted_at?: string | null
          direction?: string | null
          duration_min?: number | null
          engagement_type_id: number
          id?: string
          module_data?: Json
          next_steps?: string | null
          notes?: string | null
          occurred_at: string
          outcome?: string | null
          party_id?: string | null
          recorded_by_user_id?: string | null
          sentiment?: string | null
          status?: string
          summary?: string | null
          task_id?: string | null
          title: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          channel?: string | null
          content?: string | null
          created_at?: string
          created_by?: string | null
          deal_id?: string | null
          deleted_at?: string | null
          direction?: string | null
          duration_min?: number | null
          engagement_type_id?: number
          id?: string
          module_data?: Json
          next_steps?: string | null
          notes?: string | null
          occurred_at?: string
          outcome?: string | null
          party_id?: string | null
          recorded_by_user_id?: string | null
          sentiment?: string | null
          status?: string
          summary?: string | null
          task_id?: string | null
          title?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "engagements_deal_id_fkey"
            columns: ["deal_id"]
            isOneToOne: false
            referencedRelation: "deals"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagements_engagement_type_id_fkey"
            columns: ["engagement_type_id"]
            isOneToOne: false
            referencedRelation: "engagement_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagements_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "engagements_task_id_fkey"
            columns: ["task_id"]
            isOneToOne: false
            referencedRelation: "tasks"
            referencedColumns: ["id"]
          },
        ]
      }
      entity_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          display_name_en: string
          display_name_ja: string | null
          display_name_ko: string
          id: number
          is_active: boolean
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          display_name_en: string
          display_name_ja?: string | null
          display_name_ko: string
          id: number
          is_active?: boolean
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          display_name_en?: string
          display_name_ja?: string | null
          display_name_ko?: string
          id?: number
          is_active?: boolean
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      filler_supplier_profile: {
        Row: {
          auto_promoted_at: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          evidence_level: string | null
          id: string
          industry_source: string
          market_role: string | null
          module_data: Json
          notes: string | null
          onsite_pcc_evidence: string | null
          party_id: string
          supplier_type: string | null
          supply_model: string | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          auto_promoted_at?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          evidence_level?: string | null
          id?: string
          industry_source?: string
          market_role?: string | null
          module_data?: Json
          notes?: string | null
          onsite_pcc_evidence?: string | null
          party_id: string
          supplier_type?: string | null
          supply_model?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          auto_promoted_at?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          evidence_level?: string | null
          id?: string
          industry_source?: string
          market_role?: string | null
          module_data?: Json
          notes?: string | null
          onsite_pcc_evidence?: string | null
          party_id?: string
          supplier_type?: string | null
          supply_model?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "urm_filler_supplier_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
        ]
      }
      investor_portfolio_companies: {
        Row: {
          created_at: string
          created_by: string | null
          deleted_at: string | null
          id: string
          investment_amount_usd: number | null
          investment_stage: string | null
          investment_year: number | null
          investor_party_id: string
          is_active: boolean
          is_lead: boolean
          module_data: Json
          notes: string | null
          portfolio_company_country: string | null
          portfolio_company_name: string
          portfolio_company_name_normalized: string | null
          portfolio_company_website: string | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          investment_amount_usd?: number | null
          investment_stage?: string | null
          investment_year?: number | null
          investor_party_id: string
          is_active?: boolean
          is_lead?: boolean
          module_data?: Json
          notes?: string | null
          portfolio_company_country?: string | null
          portfolio_company_name: string
          portfolio_company_name_normalized?: string | null
          portfolio_company_website?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          id?: string
          investment_amount_usd?: number | null
          investment_stage?: string | null
          investment_year?: number | null
          investor_party_id?: string
          is_active?: boolean
          is_lead?: boolean
          module_data?: Json
          notes?: string | null
          portfolio_company_country?: string | null
          portfolio_company_name?: string
          portfolio_company_name_normalized?: string | null
          portfolio_company_website?: string | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "investor_portfolio_companies_investor_party_id_fkey"
            columns: ["investor_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
        ]
      }
      investor_profile: {
        Row: {
          aum_usd: number | null
          created_at: string
          created_by: string | null
          fund_name: string | null
          fund_size_usd: number | null
          fund_vintage_year: number | null
          geographic_focus: string[]
          id: string
          investment_stages: string[]
          is_lead_investor: boolean
          is_strategic: boolean
          party_id: string
          sector_focus: string[]
          subtype: Database["app"]["Enums"]["investor_subtype"] | null
          ticket_max_usd: number | null
          ticket_min_usd: number | null
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          aum_usd?: number | null
          created_at?: string
          created_by?: string | null
          fund_name?: string | null
          fund_size_usd?: number | null
          fund_vintage_year?: number | null
          geographic_focus?: string[]
          id?: string
          investment_stages?: string[]
          is_lead_investor?: boolean
          is_strategic?: boolean
          party_id: string
          sector_focus?: string[]
          subtype?: Database["app"]["Enums"]["investor_subtype"] | null
          ticket_max_usd?: number | null
          ticket_min_usd?: number | null
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          aum_usd?: number | null
          created_at?: string
          created_by?: string | null
          fund_name?: string | null
          fund_size_usd?: number | null
          fund_vintage_year?: number | null
          geographic_focus?: string[]
          id?: string
          investment_stages?: string[]
          is_lead_investor?: boolean
          is_strategic?: boolean
          party_id?: string
          sector_focus?: string[]
          subtype?: Database["app"]["Enums"]["investor_subtype"] | null
          ticket_max_usd?: number | null
          ticket_min_usd?: number | null
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "urm_investor_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
        ]
      }
      paper_mill_profile: {
        Row: {
          auto_promoted_at: string | null
          created_at: string
          deleted_at: string | null
          europe_mills_footprint: string | null
          evidence_level: string | null
          filler_use_intensity: string | null
          headquarters: string | null
          id: string
          industry_source: string | null
          main_product_category: string | null
          main_products: string | null
          module_data: Json
          party_id: string
          updated_at: string
        }
        Insert: {
          auto_promoted_at?: string | null
          created_at?: string
          deleted_at?: string | null
          europe_mills_footprint?: string | null
          evidence_level?: string | null
          filler_use_intensity?: string | null
          headquarters?: string | null
          id?: string
          industry_source?: string | null
          main_product_category?: string | null
          main_products?: string | null
          module_data?: Json
          party_id: string
          updated_at?: string
        }
        Update: {
          auto_promoted_at?: string | null
          created_at?: string
          deleted_at?: string | null
          europe_mills_footprint?: string | null
          evidence_level?: string | null
          filler_use_intensity?: string | null
          headquarters?: string | null
          id?: string
          industry_source?: string | null
          main_product_category?: string | null
          main_products?: string | null
          module_data?: Json
          party_id?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "urm_paper_mill_profile_party_id_fkey"
            columns: ["party_id"]
            isOneToOne: true
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
        ]
      }
      parties: {
        Row: {
          address: string | null
          annual_revenue_usd: number | null
          city: string | null
          country_code: string | null
          created_at: string
          created_by: string | null
          deleted_at: string | null
          domain_normalized: string | null
          email: string | null
          employee_count: number | null
          entity_type_id: number
          founded_year: number | null
          id: string
          lei_code: string | null
          linkedin_url: string | null
          notes: string | null
          owner_user_id: string | null
          party_name: string
          party_type_id: number
          phone_e164: string | null
          region: string | null
          source: string | null
          source_external_id: string | null
          status: string
          tax_id: string | null
          updated_at: string
          updated_by: string | null
          website: string | null
        }
        Insert: {
          address?: string | null
          annual_revenue_usd?: number | null
          city?: string | null
          country_code?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          domain_normalized?: string | null
          email?: string | null
          employee_count?: number | null
          entity_type_id: number
          founded_year?: number | null
          id?: string
          lei_code?: string | null
          linkedin_url?: string | null
          notes?: string | null
          owner_user_id?: string | null
          party_name: string
          party_type_id: number
          phone_e164?: string | null
          region?: string | null
          source?: string | null
          source_external_id?: string | null
          status?: string
          tax_id?: string | null
          updated_at?: string
          updated_by?: string | null
          website?: string | null
        }
        Update: {
          address?: string | null
          annual_revenue_usd?: number | null
          city?: string | null
          country_code?: string | null
          created_at?: string
          created_by?: string | null
          deleted_at?: string | null
          domain_normalized?: string | null
          email?: string | null
          employee_count?: number | null
          entity_type_id?: number
          founded_year?: number | null
          id?: string
          lei_code?: string | null
          linkedin_url?: string | null
          notes?: string | null
          owner_user_id?: string | null
          party_name?: string
          party_type_id?: number
          phone_e164?: string | null
          region?: string | null
          source?: string | null
          source_external_id?: string | null
          status?: string
          tax_id?: string | null
          updated_at?: string
          updated_by?: string | null
          website?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "parties_entity_type_id_fkey"
            columns: ["entity_type_id"]
            isOneToOne: false
            referencedRelation: "entity_types"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parties_party_type_id_fkey"
            columns: ["party_type_id"]
            isOneToOne: false
            referencedRelation: "party_types"
            referencedColumns: ["id"]
          },
        ]
      }
      party_supply_links: {
        Row: {
          active_since: string | null
          active_until: string | null
          confidence: string | null
          created_at: string | null
          deleted_at: string | null
          filler_party_id: string
          id: string
          link_type: string | null
          mill_party_id: string
          module_data: Json | null
          notes: string | null
          updated_at: string | null
          volume_estimate: string | null
        }
        Insert: {
          active_since?: string | null
          active_until?: string | null
          confidence?: string | null
          created_at?: string | null
          deleted_at?: string | null
          filler_party_id: string
          id?: string
          link_type?: string | null
          mill_party_id: string
          module_data?: Json | null
          notes?: string | null
          updated_at?: string | null
          volume_estimate?: string | null
        }
        Update: {
          active_since?: string | null
          active_until?: string | null
          confidence?: string | null
          created_at?: string | null
          deleted_at?: string | null
          filler_party_id?: string
          id?: string
          link_type?: string | null
          mill_party_id?: string
          module_data?: Json | null
          notes?: string | null
          updated_at?: string | null
          volume_estimate?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "party_supply_links_filler_party_id_fkey"
            columns: ["filler_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "party_supply_links_mill_party_id_fkey"
            columns: ["mill_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
        ]
      }
      party_types: {
        Row: {
          code: string
          created_at: string
          description: string | null
          display_name_en: string
          display_name_ja: string | null
          display_name_ko: string
          id: number
          is_active: boolean
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          created_at?: string
          description?: string | null
          display_name_en: string
          display_name_ja?: string | null
          display_name_ko: string
          id: number
          is_active?: boolean
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          created_at?: string
          description?: string | null
          display_name_en?: string
          display_name_ja?: string | null
          display_name_ko?: string
          id?: number
          is_active?: boolean
          sort_order?: number
          updated_at?: string
        }
        Relationships: []
      }
      pipelines: {
        Row: {
          code: string
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          is_active: boolean
          is_default: boolean
          name: string
          sort_order: number
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          code: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          is_default?: boolean
          name: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          code?: string
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_active?: boolean
          is_default?: boolean
          name?: string
          sort_order?: number
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: []
      }
      plant_supply_links: {
        Row: {
          active_since: string | null
          active_until: string | null
          confidence: string | null
          created_at: string | null
          created_by: string | null
          deleted_at: string | null
          filler_party_id: string
          id: string
          link_type: string | null
          mill_party_id: string
          module_data: Json | null
          notes: string | null
          plant_country_code: string | null
          plant_identifier: string
          plant_location: string | null
          updated_at: string | null
          updated_by: string | null
          volume_estimate: string | null
        }
        Insert: {
          active_since?: string | null
          active_until?: string | null
          confidence?: string | null
          created_at?: string | null
          created_by?: string | null
          deleted_at?: string | null
          filler_party_id: string
          id?: string
          link_type?: string | null
          mill_party_id: string
          module_data?: Json | null
          notes?: string | null
          plant_country_code?: string | null
          plant_identifier: string
          plant_location?: string | null
          updated_at?: string | null
          updated_by?: string | null
          volume_estimate?: string | null
        }
        Update: {
          active_since?: string | null
          active_until?: string | null
          confidence?: string | null
          created_at?: string | null
          created_by?: string | null
          deleted_at?: string | null
          filler_party_id?: string
          id?: string
          link_type?: string | null
          mill_party_id?: string
          module_data?: Json | null
          notes?: string | null
          plant_country_code?: string | null
          plant_identifier?: string
          plant_location?: string | null
          updated_at?: string | null
          updated_by?: string | null
          volume_estimate?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "plant_supply_links_filler_party_id_fkey"
            columns: ["filler_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "plant_supply_links_mill_party_id_fkey"
            columns: ["mill_party_id"]
            isOneToOne: false
            referencedRelation: "parties"
            referencedColumns: ["id"]
          },
        ]
      }
      stages: {
        Row: {
          code: string
          color_hex: string | null
          created_at: string
          default_probability_pct: number
          description: string | null
          id: string
          is_active: boolean
          is_lost: boolean
          is_terminal: boolean
          is_won: boolean
          name: string
          pipeline_id: string
          sort_order: number
          updated_at: string
        }
        Insert: {
          code: string
          color_hex?: string | null
          created_at?: string
          default_probability_pct?: number
          description?: string | null
          id?: string
          is_active?: boolean
          is_lost?: boolean
          is_terminal?: boolean
          is_won?: boolean
          name: string
          pipeline_id: string
          sort_order?: number
          updated_at?: string
        }
        Update: {
          code?: string
          color_hex?: string | null
          created_at?: string
          default_probability_pct?: number
          description?: string | null
          id?: string
          is_active?: boolean
          is_lost?: boolean
          is_terminal?: boolean
          is_won?: boolean
          name?: string
          pipeline_id?: string
          sort_order?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "stages_pipeline_id_fkey"
            columns: ["pipeline_id"]
            isOneToOne: false
            referencedRelation: "pipelines"
            referencedColumns: ["id"]
          },
        ]
      }
      tasks: {
        Row: {
          actual_minutes: number | null
          assigned_to_contact_id: string | null
          assigned_to_user_id: string | null
          checklist_id: string | null
          completed_at: string | null
          created_at: string
          created_by: string | null
          deal_id: string
          deleted_at: string | null
          description: string | null
          due_at: string | null
          estimated_minutes: number | null
          id: string
          module_data: Json
          notes: string | null
          priority: string
          started_at: string | null
          status: string
          title: string
          updated_at: string
          updated_by: string | null
        }
        Insert: {
          actual_minutes?: number | null
          assigned_to_contact_id?: string | null
          assigned_to_user_id?: string | null
          checklist_id?: string | null
          completed_at?: string | null
          created_at?: string
          created_by?: string | null
          deal_id: string
          deleted_at?: string | null
          description?: string | null
          due_at?: string | null
          estimated_minutes?: number | null
          id?: string
          module_data?: Json
          notes?: string | null
          priority?: string
          started_at?: string | null
          status?: string
          title: string
          updated_at?: string
          updated_by?: string | null
        }
        Update: {
          actual_minutes?: number | null
          assigned_to_contact_id?: string | null
          assigned_to_user_id?: string | null
          checklist_id?: string | null
          completed_at?: string | null
          created_at?: string
          created_by?: string | null
          deal_id?: string
          deleted_at?: string | null
          description?: string | null
          due_at?: string | null
          estimated_minutes?: number | null
          id?: string
          module_data?: Json
          notes?: string | null
          priority?: string
          started_at?: string | null
          status?: string
          title?: string
          updated_at?: string
          updated_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "tasks_checklist_id_fkey"
            columns: ["checklist_id"]
            isOneToOne: false
            referencedRelation: "deal_checklists"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "tasks_deal_id_fkey"
            columns: ["deal_id"]
            isOneToOne: false
            referencedRelation: "deals"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      [_ in never]: never
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  ai: {
    Enums: {
      agent_role: [
        "classifier",
        "reply_drafter",
        "strategy_advisor",
        "summarizer",
        "translator",
        "extractor",
      ],
      draft_status: [
        "pending_review",
        "approved",
        "sent",
        "rejected",
        "expired",
        "auto_sent",
      ],
      run_status: [
        "running",
        "completed",
        "failed",
        "timed_out",
        "rate_limited",
      ],
    },
  },
  app: {
    Enums: {
      attendee_response: ["no_response", "accepted", "declined", "tentative"],
      attendee_role: ["organizer", "required", "optional", "resource"],
      buyer_subtype: [
        "distributor",
        "wholesaler",
        "retailer",
        "oem_partner",
        "end_brand",
        "direct_user",
        "other",
      ],
      calendar_provider: ["google", "microsoft", "internal"],
      calendar_sync_status: [
        "pending",
        "syncing",
        "success",
        "partial",
        "failed",
      ],
      consultation_channel: [
        "inbound_email",
        "meeting_notes",
        "phone_call",
        "manual_entry",
        "attachment",
      ],
      decision_role: [
        "champion",
        "decision_maker",
        "influencer",
        "gatekeeper",
        "user",
        "unknown",
      ],
      dedup_status: [
        "pending",
        "auto_merged",
        "manual_merged",
        "rejected_duplicate",
        "kept_separate",
      ],
      direction_type: ["inbound", "outbound", "internal"],
      email_sequence_status: ["draft", "active", "paused", "archived"],
      engagement_channel: [
        "in_person",
        "video_call",
        "video_conference",
        "phone_call",
        "email",
        "sms",
        "kakaotalk",
        "wechat",
        "whatsapp",
        "linkedin",
        "slack",
        "webform",
        "postal",
        "hybrid",
        "other",
      ],
      engagement_status: [
        "open",
        "in_progress",
        "on_hold",
        "won",
        "lost",
        "archived",
      ],
      enrollment_status: [
        "active",
        "completed",
        "cancelled",
        "failed",
        "paused",
      ],
      entity_status: ["active", "inactive", "archived", "blocked"],
      event_status: ["confirmed", "tentative", "cancelled"],
      investor_subtype: [
        "vc",
        "cvc",
        "growth_equity",
        "private_equity",
        "family_office",
        "accelerator",
        "angel",
        "crowdfunding",
        "government",
        "other",
      ],
      invoice_status: [
        "draft",
        "issued",
        "partial_paid",
        "paid",
        "overdue",
        "void",
      ],
      meeting_status: [
        "scheduled",
        "completed",
        "cancelled",
        "no_show",
        "rescheduled",
      ],
      meeting_type: [
        "intro",
        "discovery",
        "pitch",
        "negotiation",
        "due_diligence",
        "kickoff",
        "review",
        "closing",
        "other",
      ],
      order_status: [
        "draft",
        "confirmed",
        "in_production",
        "ready_to_ship",
        "shipped",
        "delivered",
        "cancelled",
        "returned",
      ],
      participant_role: [
        "sender",
        "recipient",
        "cc",
        "bcc",
        "host",
        "attendee",
        "observer",
        "decision_maker",
        "introducer",
      ],
      partner_seniority: [
        "founder",
        "partner",
        "principal",
        "associate",
        "advisor",
        "other",
      ],
      party_kind: [
        "company",
        "organization",
        "individual",
        "fund",
        "government",
      ],
      party_type: [
        "investor",
        "paper_mill",
        "partner",
        "customer",
        "filler_supplier",
      ],
      pipeline_stage_type: [
        "lead",
        "qualified",
        "proposal",
        "negotiation",
        "won",
        "lost",
      ],
      priority_level: ["low", "medium", "high", "urgent"],
      scraping_job_status: [
        "queued",
        "running",
        "completed",
        "failed",
        "cancelled",
        "rate_limited",
      ],
      scraping_source_type: [
        "industry_directory",
        "public_disclosure",
        "company_website",
        "gleif_lei",
        "sec_edgar",
        "dart_kr",
        "press_release",
        "other",
      ],
      send_status: ["pending", "sent", "skipped", "bounced", "failed"],
      strategy_status: ["draft", "active", "completed", "abandoned"],
      strategy_type: ["immediate", "short_term", "long_term"],
      supply_link_type: ["potential", "active", "historical"],
      sync_operation: [
        "pull",
        "push",
        "match_party",
        "promote",
        "conflict",
        "error",
      ],
      task_status: ["todo", "in_progress", "blocked", "done", "cancelled"],
      template_status: ["draft", "active", "archived", "deprecated"],
      tier_level: ["tier_1", "tier_2", "tier_3", "tier_4", "tier_5"],
    },
  },
  ingest: {
    Enums: {},
  },
  public: {
    Enums: {
      tier_role: ["HQ", "Regional", "Country", "Plant"],
    },
  },
  urm: {
    Enums: {},
  },
} as const
