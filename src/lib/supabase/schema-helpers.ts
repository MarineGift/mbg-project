// src/lib/supabase/schema-helpers.ts
//
// Schema-scoped Supabase client helpers for the mbg-project URM cutover.
//
// Background (stage29b/stage29c):
//   The database has multiple logical schemas, each with distinct responsibilities.
//   Bare `.from('xxx')` calls hit the default `public` schema, which is almost
//   always wrong. These helpers make schema routing explicit at every call site.
//
// Schema map:
//   - app      : (1) mail infrastructure (PERMANENT after stage29d)
//                (2) legacy CRM parallels (DROP at stage29d)
//                (3) industry/business domain
//   - urm      : CRM domain (active V2). Use for new code.
//   - ai       : AI artifacts (drafts, agents, brand_voice, etc.)
//   - industry : global paper filler database (separate domain)
//
// Migration policy:
//   - For new code touching CRM tables (parties/contacts/deals/tasks/stages/
//     pipelines/engagements*), ALWAYS use sbUrm().
//   - For mail infra (communications/drafts/email_*), use sbApp() -- this is
//     the permanent location, not a transition state.
//   - For industry data (paper_mills/filler_suppliers/...), use sbIndustry().
//
// Usage:
//   import { sbApp, sbUrm, sbAi, sbIndustry } from '@/lib/supabase/schema-helpers';
//
//   const { data } = await sbUrm(supabase)
//     .from('parties')
//     .select('id, name, party_type_id');

import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database';

/**
 * Supabase client scoped to the `app` schema.
 *
 * **Use for (PERMANENT, mail infrastructure layer)**:
 * - `communications`         -- IMAP-ingested raw email
 * - `drafts`                 -- compose drafts (verify schema, may be ai.drafts)
 * - `mail_merge_jobs`        -- batch send orchestration
 * - `mailcarrier_state`      -- IMAP UID tracking
 * - `email_signatures`, `email_templates`, `template_*`
 * - `email_tracking`, `email_tracking_events`, `email_tracking_links`
 * - `email_sequences`, `email_sequence_steps`, `email_sequence_enrollments`,
 *   `email_sequence_sends`
 * - `email_whitelist`
 * - `meetings`, `consultations`, `calendar_events`, `calendar_connections`,
 *   `calendar_sync_log` -- calendar/meeting infra
 * - `attachments`, `users`, `roles`, `teams`, `organizations`
 *
 * **Use for (TRANSITIONAL, will be DROPped at stage29d)**:
 * - `app.parties`, `app.contacts`, `app.contacts_history`
 * - `app.investor_profile`, `app.paper_mill_profile`, `app.filler_supplier_profile`
 * - `app.investor_portfolio_companies`, `app.party_supply_links`
 * - `app.deals`, `app.pipelines`, `app.pipeline_stages`, `app.tasks`,
 *   `app.engagements`
 *
 *   For these, prefer `sbUrm()` in new code. Existing call sites are cut over
 *   in D5-3e.
 */
export function sbApp(client: SupabaseClient<Database>) {
  return client.schema('app');
}

/**
 * Supabase client scoped to the `urm` schema (CRM domain, V2 active).
 *
 * **Use for**:
 * - `parties`, `party_types`, `entity_types`
 * - `contacts`, `contact_types`, `contacts_history`
 * - `investor_profile`, `paper_mill_profile`, `filler_supplier_profile`
 * - `investor_portfolio_companies`
 * - `party_supply_links`, `plant_supply_links`
 * - `pipelines`, `stages`, `deals`, `deal_stage_history`, `deal_checklists`
 * - `tasks`
 * - `engagements`, `engagement_types`, `engagement_email_details`,
 *   `engagement_meeting_details`, `engagement_attendees`, `engagement_documents`
 *
 * **Note on parties.party_type**:
 *   `app.parties.party_type` is an enum; `urm.parties.party_type_id` is a FK
 *   to `urm.party_types(id)`. When migrating call sites, replace direct enum
 *   reads with JOINs via the P1-P7 patterns (see D5-3f).
 */
export function sbUrm(client: SupabaseClient<Database>) {
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

/**
 * Supabase client scoped to the `industry` schema (global paper filler DB).
 *
 * **Use for**:
 * - `paper_companies`, `paper_mills`, `paper_mill_plants`
 * - `filler_suppliers`, `supplier_mill_linkages`
 * - `markets`
 *
 * This schema is NOT part of URM cutover. It remains as-is after stage29d.
 */
export function sbIndustry(client: SupabaseClient<any>) {
  return client.schema('industry' as any);
}
