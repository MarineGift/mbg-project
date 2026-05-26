# URM Refactoring Specification — mbg-project

**Purpose**: This document is the handoff spec for refactoring the mbg-project codebase from the legacy `app.*` schema to the new `urm.*` schema.

**Target audience**: Claude Code (or any developer) doing the systematic refactor.

**Status**: Database migration complete; codebase refactor not started.

---

## 1. Background

The `app.*` schema accumulated naming confusion and design drift over multiple sessions. Two major flaws were identified:

1. **Naming collision**: `app.engagements` was actually a **Deals/Opportunities** table (has `value_amount`, `probability_pct`, `current_stage_id`, `won_lost_reason` — classic Deal columns). The activity layer (meetings/calls/emails) was split across 4 different tables.

2. **Schema sprawl**: Per-domain `*_partner_profile` / `*_contact_profile` tables (4 of them) for what should be a unified Contacts concept.

The new `urm.*` schema corrects both. See section 2 for table mapping, section 3 for column mapping.

---

## 2. Schema-level mapping

### 2a. Tables migrated to `urm.*`

| Old (`app.*`) | New (`urm.*`) | Status | Notes |
|---|---|---|---|
| `app.parties` (industry 3 modules, firm-level) | `urm.parties` | ✓ Migrated, 1,549 rows | Person-level rows excluded |
| (module enum, hardcoded) | `urm.party_types` | ✓ Lookup, 7 rows | investor/paper_mill/filler_supplier/buyer/customer/partner/government_grant |
| (party_type enum, hardcoded) | `urm.entity_types` | ✓ Lookup, 5 rows | company/organization/individual/fund/government |
| `app.investor_partner_profile` (118 rows) | `urm.contacts` | ✓ Migrated, type='partner' | + buyer/filler logic ready but 0 rows currently |
| `app.buyer_partner_profile` | `urm.contacts` | ✓ Ready (0 rows) | type='employee' |
| `app.filler_supplier_contact_profile` | `urm.contacts` | ✓ Ready (0 rows) | type='employee' |
| `app.govt_grant_contact_profile` | (skipped) | ✗ Schema incompatible | No firm_party_id; 0 rows |
| (contact_type, hardcoded) | `urm.contact_types` | ✓ Lookup, 5 rows | employee/partner/consultant/advisor/executive |
| `app.pipeline_definitions` | `urm.pipelines` | ✓ Created, 1 default | Single unified pipeline |
| `app.pipeline_stages` | `urm.stages` | ✓ Created, 6 seeded | lead/qualified/proposal/negotiation/won/lost |
| **`app.engagements` (= Deals!)** | **`urm.deals`** | ✓ Created (empty) | **Renaming is critical** |
| `app.tasks` | `urm.tasks` | ✓ Created (empty) | `deal_id` NOT NULL per URM design |
| **`app.meetings` + `app.calendar_events` + `app.communications` + `app.consultations`** | **`urm.engagements`** | ✓ Created (empty) | Unified via `engagement_type_id` FK |
| (engagement type) | `urm.engagement_types` | ✓ Lookup, 6 rows | meeting/call/email/note/message/consultation |
| `app.meeting_attendees` + `app.engagement_participants` | `urm.engagement_attendees` | ✓ Created (empty) | Single junction table |
| `app.attachments` (polymorphic) | `urm.engagement_documents` | ✓ Created (empty) | Engagement-scoped only |

### 2b. Tables NOT migrated (still on `app.*`)

These tables are still active and used by the codebase. Code touching them must remain on `app.*` until URM equivalents are built.

| Category | Tables |
|---|---|
| Industry detail | `investor_profile`, `paper_mill_profile`, `filler_supplier_profile` |
| Portfolio | `portfolio_companies`, `investor_portfolio_companies` |
| Supply links | `party_supply_links`, `plant_supply_links`, `person_firm_history` |
| Email infra | `email_sequences`, `email_sequence_steps`, `email_sequence_enrollments`, `email_sequence_sends`, `email_templates`, `email_tracking`, `email_tracking_events`, `email_tracking_links`, `email_whitelist`, `mail_merge_jobs`, `mailcarrier_state`, `template_*` |
| Sales/finance | `sales_orders`, `sales_order_items`, `quotations`, `invoices`, `payments`, `shipments`, `products`, `customer_purchases` |
| Industry research | `industry_collections`, `scraping_sources`, `scraping_jobs`, `scraping_targets`, `scraping_raw` |
| Custom fields | `custom_field_definitions`, `custom_field_values` |
| Engagement support | `engagement_type_registry`, `engagement_stage_history` |
| Tags/segments | `tags`, `entity_tags`, `customer_segments`, `buyer_inquiries`, `consultations` |
| Strategy | `response_strategies`, `strategy_actions`, `strategy_outcomes` |
| Org/auth | `organizations`, `users`, `teams`, `team_members`, `roles`, `permissions`, `user_roles`, `role_permissions` |
| Calendar sync | `calendar_connections`, `calendar_sync_log` |
| Partner | `partner_capabilities`, `partner_audits`, `partner_seniority_meta` |
| Investor meta | `investor_subtype_meta` |
| Misc | `saved_views`, `customer_profile`, `partner_profile`, `buyer_profile` |
| AI schema | `ai.agents`, `ai.drafts`, `ai.runs`, `ai.brand_voice`, `ai.knowledge_chunks`, `ai.auto_send_rules` |

---

## 3. Column-level mapping (migrated tables)

### 3a. `urm.parties` (vs `app.parties`)

| `app.parties` column | `urm.parties` column | Transformation |
|---|---|---|
| `id` (uuid) | `id` | preserved verbatim |
| `name` | `party_name` | renamed |
| `name_normalized` | (removed) | redundant; recreate with `lower(party_name)` if needed |
| `legal_name` | (merged into `party_name`) | values copied where present, then dropped |
| `module` (enum) | (removed; via FK) | → `party_type_id` smallint FK to `urm.party_types` |
| `party_type` (enum) | (removed; via FK) | → `entity_type_id` smallint FK to `urm.entity_types` |
| `country_code`, `region`, `city`, `address` | same | preserved |
| `domain_normalized`, `website` | same | preserved |
| `phone_e164` | same | preserved |
| `phone_normalized` | (removed) | redundant |
| `lei_code`, `tax_id`, `linkedin_url` | same | preserved |
| `founded_year`, `employee_count`, `annual_revenue_usd` | same | preserved |
| `status` (enum) | `status` (text) | type changed: enum → text |
| `source`, `source_external_id` | same | preserved |
| `organization_id` | (removed) | single tenant confirmed |
| `owner_user_id` | same | preserved |
| `owner_team_id` | (removed) | unused |
| `parent_party_id`, `party_level` | (removed) | 3-tier hierarchy dropped |
| `tier`, `timezone`, `relationship_score` | (removed) | unused |
| `industry_tags`, `interest_tags` | (removed) | dropped |
| `module_data` (jsonb) | (removed from parties) | will go to detail tables (Step 5, future) |
| `notes` | same | preserved |
| `created_at`, `updated_at`, `deleted_at` | same | preserved |
| `created_by`, `updated_by` | same | preserved |
| **NEW** | `party_type_id` smallint NOT NULL | FK to `urm.party_types` |
| **NEW** | `entity_type_id` smallint NOT NULL | FK to `urm.entity_types` |

### 3b. `urm.contacts` (vs 4 source tables)

The new `urm.contacts.id` = source person `party_id` (UUID preserved for traceability).

| Source | Source column | `urm.contacts` column | Notes |
|---|---|---|---|
| `investor_partner_profile.party_id` | UUID | `id` | identity preserved |
| `investor_partner_profile.firm_party_id` | UUID | `firm_party_id` | FK to `urm.parties` |
| (hardcoded based on source) | — | `contact_type_id` | 'partner' for investor, 'employee' for buyer/filler |
| `app.parties.name` (via JOIN on party_id) | text | `full_name` | from person party |
| `investor_partner_profile.email` | text | `email` | |
| `investor_partner_profile.phone` | text | `phone_e164` | NOTE: raw, not E.164 normalized |
| `app.parties.linkedin_url` (via JOIN) | text | `linkedin_url` | linkedin lives on parties, not partner profile |
| `investor_partner_profile.twitter_handle` | text | `twitter_handle` | |
| `*.title_text` | text | `title_text` | |
| `buyer_partner_profile.department` | text | `department` | |
| `buyer_partner_profile.decision_role` | text | `role_category` | |
| `filler_supplier_contact_profile.role_in_firm` | text | `role_category` | |
| `*.seniority_level` (enum) | text | `seniority_level` | type cast to text |
| `*.is_decision_maker` | boolean | `is_decision_maker` | |
| `*.joined_year` (int) | date | `joined_at` | `make_date(year, 1, 1)` |
| `*.background`, `*.education`, `*.focus_areas[]` | various | same | |
| `filler_supplier_contact_profile.module_data` | jsonb | `module_data` | filler only |

### 3c. `urm.deals` (vs `app.engagements`)

**THE BIGGEST RENAMING**: code referencing `app.engagements` as "deal" / "opportunity" should now reference `urm.deals`.

| `app.engagements` column | `urm.deals` column | Transformation |
|---|---|---|
| `id` | `id` | preserved |
| `name` | `deal_name` | renamed |
| `description` | `description` | same |
| `party_id` (NOT NULL) | `party_id` (NOT NULL) | same FK target (urm.parties) |
| `primary_contact_id` | `primary_contact_id` | now FK to `urm.contacts` |
| `pipeline_definition_id` | `pipeline_id` | renamed; FK to `urm.pipelines` |
| `current_stage_id` | `current_stage_id` | FK to `urm.stages` |
| `module` (enum) | (removed) | inferred via party_id → party.party_type_id |
| `status` (enum) | `status` (text) | 'active'/'on_hold'/'archived' |
| `priority` (enum) | `priority` (text) | 'low'/'medium'/'high'/'urgent' |
| `probability_pct` | `probability_pct` | same |
| `value_amount` | `value_amount` | same |
| `value_currency` | `value_currency` | same |
| `weighted_amount` | (removed) | compute on demand: `value_amount * probability_pct / 100` |
| `expected_close_date` | `expected_close_date` | same |
| `actual_close_date` | `actual_close_date` | same |
| `won_lost_reason` | `won_lost_reason` | same |
| `last_activity_at` | `last_activity_at` | same |
| `next_action_at` | (removed) | use tasks for next actions |
| `owner_user_id`, `owner_team_id` | `owner_user_id` only | |
| `mill_id` (integer) | (removed) | legacy |
| `source` | `source` | same |
| `module_data` (jsonb) | `module_data` (jsonb) | preserved |
| `organization_id` | (removed) | single tenant |
| `created_at`, etc. | same | preserved |
| **NEW** | `notes` text | for free-form deal notes |
| **NEW** | `source_external_id` text | external system tracking |

### 3d. `urm.tasks` (vs `app.tasks`)

| `app.tasks` column | `urm.tasks` column | Transformation |
|---|---|---|
| `id` | `id` | preserved |
| `title` | `title` | same |
| `description` | `description` | same |
| `engagement_id` (= deal_id!) | `deal_id` (NOT NULL) | semantic rename |
| `party_id` | (removed) | inferred via deal.party_id |
| `assigned_to_user_id` | `assigned_to_user_id` | same |
| `assigned_to_team_id` | (removed) | no team support |
| `contact_id` | `assigned_to_contact_id` | semantic rename |
| `status` (enum) | `status` (text) | 'pending'/'in_progress'/'completed'/'cancelled'/'blocked' |
| `priority` (enum) | `priority` (text) | |
| `due_at` | `due_at` | same |
| `reminder_at` | (removed) | not migrated |
| `started_at`, `completed_at` | same | preserved |
| `estimated_minutes`, `actual_minutes` | same | preserved |
| `completion_notes` | (use `notes`) | merged |
| `blocked_reason` | (use `notes` or `module_data`) | merged |
| `parent_task_id` | (removed) | no subtask hierarchy |
| `linked_strategy_action_id` | (use `module_data`) | preserved if needed |
| `tags[]` | (use `module_data`) | preserved if needed |
| `module`, `module_data` | `module_data` only | module inferred |
| `organization_id` | (removed) | single tenant |
| audit columns | same | preserved |

### 3e. `urm.engagements` (vs 4 source tables)

The new `urm.engagements.engagement_type_id` discriminates what was previously 4 separate tables.

| Source table | Maps to `engagement_type_id` | Common columns |
|---|---|---|
| `app.meetings` | `engagement_type_id` = 1 ('meeting') | title, occurred_at, duration_min, location, notes, action_items |
| `app.calendar_events` | also `engagement_type_id` = 1 if matched | external_id, start_at→occurred_at, end_at→duration |
| `app.communications` | `engagement_type_id` = 3 ('email') | subject→title, body→content, direction, channel |
| `app.consultations` | `engagement_type_id` = 6 ('consultation') | title, content_raw→content, channel |

Common destination columns in `urm.engagements`:

| Concept | Column | Notes |
|---|---|---|
| Type | `engagement_type_id` FK | discriminator |
| Linkage | `deal_id` (nullable), `party_id` (nullable), `task_id` (nullable) | flexible |
| Display | `title`, `summary`, `content` | content for full text |
| Timing | `occurred_at` (NOT NULL), `duration_min` | |
| Channel | `channel`, `direction` | |
| Result | `status`, `outcome`, `next_steps`, `sentiment` | |
| Author | `recorded_by_user_id`, audit cols | |
| Extras | `module_data jsonb` | preserves source-specific fields |

### 3f. `urm.engagement_attendees` (vs `app.meeting_attendees` + `app.engagement_participants`)

`app.engagement_participants` was polymorphic (event_kind ∈ {engagement, meeting, event}). In URM all participants attach to `urm.engagements` uniformly.

| Old | New | Notes |
|---|---|---|
| `app.meeting_attendees.meeting_id` + `app.engagement_participants.event_id WHERE event_kind='meeting'` | `engagement_attendees.engagement_id` | unified |
| `app.meeting_attendees.person_party_id` + `app.engagement_participants.person_party_id` | `engagement_attendees.contact_id` | unified, FK to `urm.contacts` |
| `app.meeting_attendees.role` (enum) | `engagement_attendees.role` (text) | host/participant/optional/observer |
| `app.meeting_attendees.response` (enum) | `engagement_attendees.response` (text) | accepted/declined/tentative |
| `app.engagement_participants.attended` | `engagement_attendees.attended` | preserved |

---

## 4. Code transformation patterns

### 4a. Simple SELECT

```typescript
// BEFORE
const { data } = await supabase
  .schema('app')
  .from('parties')
  .select('id, name, module, country_code')
  .eq('module', 'investor');

// AFTER
const { data } = await supabase
  .schema('urm')
  .from('parties')
  .select(`
    id,
    party_name,
    country_code,
    party_type:party_types!inner(code)
  `)
  .eq('party_types.code', 'investor');
```

### 4b. Type changes

```typescript
// BEFORE
type Party = Database['app']['Tables']['parties']['Row'];
// has: name, module ('investor'|'paper_mill'|...), party_type ('company'|...), etc.

// AFTER
type Party = Database['urm']['Tables']['parties']['Row'];
// has: party_name, party_type_id (number), entity_type_id (number)
// no name, no module enum, no party_type enum

// For displaying party type / entity type, JOIN with lookup or fetch types separately:
type PartyType = Database['urm']['Tables']['party_types']['Row'];
```

### 4c. Engagements/Deals naming

This is critical — rename throughout codebase:

```typescript
// BEFORE
const { data: engagements } = await supabase.from('engagements').select('*');
// (these were actually deals!)
engagement.probability_pct
engagement.value_amount
engagement.current_stage_id

// AFTER
const { data: deals } = await supabase.schema('urm').from('deals').select('*');
deal.probability_pct
deal.value_amount
deal.current_stage_id
```

```typescript
// BEFORE
const { data: meetings } = await supabase.from('meetings').select('*');
const { data: communications } = await supabase.from('communications').select('*');

// AFTER (unified)
const { data: engagements } = await supabase
  .schema('urm')
  .from('engagements')
  .select('*, engagement_type:engagement_types!inner(code, display_name_en)')
  .eq('engagement_types.code', 'meeting');  // or 'email'
```

### 4d. Contact resolution

```typescript
// BEFORE — multiple tables to check
const investorContacts = await supabase
  .from('investor_partner_profile')
  .select('*, firm:parties!firm_party_id(name)');

const fillerContacts = await supabase
  .from('filler_supplier_contact_profile')
  .select('*, firm:parties!firm_party_id(name)');

// AFTER — unified
const contacts = await supabase
  .schema('urm')
  .from('contacts')
  .select(`
    *,
    contact_type:contact_types!inner(code, display_name_ko),
    firm:parties!firm_party_id(party_name)
  `)
  .eq('contact_types.code', 'partner');  // filter by type if needed
```

### 4e. Stage history

`app.engagement_stage_history` was for tracking deal stage transitions. Not migrated to urm yet. Code referencing this should either:
- Keep using `app.engagement_stage_history` (interim)
- Build `urm.deal_stage_history` later

---

## 5. Files most likely needing changes

Based on Session 10 handoff (~121 tsc errors):

### High-impact (20+ errors each)
- `src/lib/actions/email-compose.ts` (20 errors) — schema-generic mismatch
- `src/lib/utils/sequence-processor.ts` (11 errors)
- `src/lib/actions/email-sequences.ts` (11 errors)

### Medium-impact (6-10 errors each)
- `src/lib/actions/email-whitelist.ts` (6)
- `src/lib/actions/communications.ts` (6)
- `src/lib/actions/email-tracking.ts` (6)
- `src/components/party-communications-timeline.tsx` (7)

### Lower-impact (scattered)
- ~54 errors across other files (UI components, helpers, server actions)

### Critical files to inspect first
- `src/types/database.ts` — regen with urm schema (see section 8)
- `src/lib/rpc/typed-rpc.ts` — already exists, may need urm RPC additions
- `src/lib/actions/*.ts` — server actions touching parties/engagements/contacts
- `src/app/**/*.tsx` — pages/components rendering party/deal data
- `src/lib/supabase/server.ts` — client factory; may need schema('urm') wrapper

---

## 6. Refactoring strategy

### Phased approach (recommended)

**Phase 1: Foundation (low risk)**
1. Regen `src/types/database.ts` with urm schema added (see section 8)
2. Update `src/lib/supabase/server.ts` if needed to support `.schema('urm')` calls
3. Run `npx tsc --noEmit` to baseline new error count

**Phase 2: Read paths (medium risk)**
4. Find all `supabase.from('parties')` reads → switch to `urm.parties` where appropriate
5. Find all `supabase.from('engagements')` reads → split:
   - If using probability_pct/value_amount/stage_id → `urm.deals`
   - If logging meetings/calls → consider `urm.engagements` (but data is empty!)
6. Update component types to use new Database['urm']['Tables']['parties']['Row']

**Phase 3: Write paths (high risk)**
7. INSERT/UPDATE/DELETE on parties → urm.parties
8. INSERT on deals → urm.deals (was 'engagements')
9. Contact creation → urm.contacts

**Phase 4: Leave alone for now**
10. Email sequence code → keep on `app.*` (no urm equivalent)
11. Invoice/order code → keep on `app.*`
12. Scraping code → keep on `app.*`
13. AI draft code → keep on `ai.*`

### Verification per phase

- After each phase: `npx tsc --noEmit` should not INCREASE errors
- Manually test critical user flows: list parties, create deal, log activity
- Compare urm.* row counts to app.* counts (data integrity check)

---

## 7. Important gotchas

1. **`urm.contacts.id = source person party_id`** (UUID preserved). Code that previously joined `meeting_attendees.person_party_id` → `parties` can now do `engagement_attendees.contact_id` → `urm.contacts` directly using the same UUIDs.

2. **`urm.parties` does NOT contain person-level parties** (only firms). Person identity now lives in `urm.contacts`. Code that did `parties WHERE party_level = 'contact'` should now query `urm.contacts`.

3. **`urm.parties.legal_form` was DROPPED** (after entity_type_id verification). If old code needs the text value, JOIN `entity_types` instead.

4. **`urm.deals` is EMPTY**. Existing `app.engagements` data was NOT migrated (per user decision: "폐기는 나중에"). Migration of historical deal data is a future step if needed.

5. **`urm.engagements` is EMPTY**. Existing `app.meetings` / `app.communications` etc. data not migrated. Same as above.

6. **`organization_id` removed from urm tables**. Code passing organization_id to urm.* queries will fail. Remove the parameter or skip the filter.

7. **`source_external_id`** is still useful for tracing back to source systems; preserve.

8. **`module_data` jsonb** preserved on `parties`, `contacts`, `deals`, `tasks`, `engagements` for forward compatibility. Use as escape hatch for fields that don't have a column.

---

## 8. Database types regeneration

After confirming urm schema exists, regen TypeScript types:

```powershell
# PowerShell command (per Session 10 Gotcha #39 — env isolation)
$envBackup = ".env.local.urm_regen"
if (Test-Path .env.local) { Copy-Item .env.local $envBackup }

try {
  # Include urm in addition to existing schemas
  supabase gen types typescript `
    --project-id <YOUR_PROJECT_REF> `
    --schema public `
    --schema app `
    --schema ai `
    --schema audit `
    --schema urm `
    > src/types/database.new.ts
} finally {
  if (Test-Path $envBackup) { Move-Item $envBackup .env.local -Force }
}

# Diff check
$old = (Get-Item src/types/database.ts).Length
$new = (Get-Item src/types/database.new.ts).Length
Write-Host "old: $old bytes, new: $new bytes, delta: $($new - $old) bytes"

# Verify urm schema is included
Select-String -Path src/types/database.new.ts -Pattern "^  urm: \{"
# Expected: 1 match

# If diff looks good, replace
Move-Item src/types/database.new.ts src/types/database.ts -Force
```

After regen: `npx tsc --noEmit` to see updated error landscape.

---

## 9. Verification queries (post-refactor)

Run these against Supabase to confirm data integrity:

```sql
-- urm.parties counts by party_type
SELECT pt.code, COUNT(p.id) FROM urm.party_types pt
LEFT JOIN urm.parties p ON p.party_type_id = pt.id
GROUP BY pt.code, pt.sort_order
ORDER BY pt.sort_order;
-- Expected: investor 242, paper_mill 1074, filler_supplier 233

-- urm.contacts by type
SELECT ct.code, COUNT(c.id) FROM urm.contact_types ct
LEFT JOIN urm.contacts c ON c.contact_type_id = ct.id
GROUP BY ct.code, ct.sort_order
ORDER BY ct.sort_order;
-- Expected: partner 118 (others 0)

-- urm.pipelines + stages
SELECT p.name, s.code, s.sort_order, s.is_won, s.is_lost
FROM urm.pipelines p JOIN urm.stages s ON s.pipeline_id = p.id
ORDER BY p.name, s.sort_order;
-- Expected: 1 pipeline with 6 stages

-- Sample join: contact -> firm
SELECT c.full_name, c.title_text, p.party_name AS firm
FROM urm.contacts c
JOIN urm.parties p ON p.id = c.firm_party_id
LIMIT 5;
```

---

## 10. Suggested initial prompt for Claude Code

Paste the following into Claude Code as the initial task:

> I have an existing Next.js 14 + Supabase + Anthropic SDK CRM project at `C:\dev\mbg-project`. I just completed a database schema migration from `app.*` (legacy, naming-confused) to `urm.*` (clean Unified Relationship Model).
>
> The full refactoring specification is in `[paste path to this file]`. Please:
>
> 1. Read the spec end-to-end before touching any code
> 2. Regenerate `src/types/database.ts` using the command in section 8 (ask me to run it if needed)
> 3. Establish a baseline: `npx tsc --noEmit` before any changes
> 4. Proceed in phases per section 6
> 5. After each phase, report: (a) files changed, (b) tsc error delta, (c) any unexpected findings
> 6. Pause before Phase 3 (write paths) for my review
>
> Important: tables NOT migrated to `urm.*` (see section 2b) must keep their `app.*` references intact. Don't try to refactor email infra, invoices, or scraping code — they have no urm equivalent yet.
>
> Verify against the gotchas in section 7 throughout.

---

## 11. Future steps (not in this refactor scope)

After codebase stabilizes on `urm.*` for the migrated tables:

- **Step 5**: Build `urm.investor_detail`, `urm.paper_mill_detail`, `urm.filler_supplier_detail` (from existing `*_profile` tables)
- **Step 6**: Build urm email infra (sequences, templates, tracking)
- **Step 7**: Build urm sales infra (orders, invoices, payments)
- **Step 8**: Build urm research infra (scraping pipeline)
- **Step 9**: Once everything is on urm.*, drop app.* tables

---

**End of spec.**
