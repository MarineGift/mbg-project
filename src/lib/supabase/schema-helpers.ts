// src/lib/supabase/schema-helpers.ts
//
// Schema-scoped Supabase client helpers.
//
// Background:
//   The database has multiple logical schemas with distinct responsibilities.
//   Bare `.from('xxx')` calls hit the default `public` schema, which is almost
//   always wrong. These helpers make schema routing explicit at every call site.
//
// Schema map (after the urm->app merge):
//   - app : single permanent application schema. CRM domain
//           (parties/contacts/deals/tasks/stages/pipelines/engagements) AND
//           mail infrastructure (communications/drafts/email_*). Use sbApp().
//   - ai  : AI artifacts (drafts, agents, brand_voice, etc.). Use sbAi().
//
// Usage:
//   import { sbApp, sbAi } from '@/lib/supabase/schema-helpers';
//
//   const { data } = await sbApp(supabase)
//     .from('parties')
//     .select('id, name, party_type_id');

import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database';

/**
 * Supabase client scoped to the `app` schema.
 *
 * The single permanent application schema (CRM + mail infrastructure) after the
 * urm->app merge. Use for:
 * - CRM: `parties`, `party_types`, `entity_types`, `contacts`,
 *   `contact_types`, `contacts_history`, `investor_profile`,
 *   `paper_mill_profile`, `filler_supplier_profile`,
 *   `investor_portfolio_companies`, `party_supply_links`, `pipelines`,
 *   `pipeline_stages`, `deals`, `tasks`, `engagements`
 * - Mail infra: `communications`, `drafts`, `mail_merge_jobs`,
 *   `mailcarrier_state`, `email_signatures`, `email_templates`,
 *   `template_*`, `email_tracking*`, `email_sequences*`, `email_whitelist`
 * - Calendar/meeting: `meetings`, `consultations`, `calendar_events`,
 *   `calendar_connections`, `calendar_sync_log`
 * - Core: `attachments`, `users`, `roles`, `teams`, `organizations`
 */
export function sbApp(client: SupabaseClient<Database>) {
  return client.schema('app');
}

/**
 * Supabase client scoped to the `ai` schema.
 *
 * **Use for**:
 * - `drafts`            -- AI-generated email drafts
 * - `agents`            -- AI agent definitions
 * - `brand_voice`       -- per-org brand voice configuration
 * - `knowledge_chunks`  -- vector store (pgvector)
 * - `runs`              -- AI run history
 * - `auto_send_rules`   -- automation rules
 */
export function sbAi(client: SupabaseClient<Database>) {
  return client.schema('ai');
}
