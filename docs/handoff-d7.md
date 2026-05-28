# mbg-project — D7 Handoff

**Branch:** `marinebiogroup` &nbsp;·&nbsp; **Working dir:** `C:\dev\mbg-project` &nbsp;·&nbsp; **As of:** 2026-05-28

This document hands off the in-progress D7 work to a new chat. Read it top to bottom; everything you need to continue is here.

---

## Stack snapshot

- **Frontend:** Next.js 14.2.35 (App Router, sync params), React 19, Tailwind, shadcn/ui (Dialog, Button confirmed installed), @dnd-kit, lucide-react
- **Backend:** Supabase (PostgreSQL, multi-schema: `app`, `industry`, `urm` to be dropped)
- **Org:** marinebiogroup (`b25de8f2-1020-482f-9012-183f63883169`), single-tenant for now but RLS scoped throughout
- **i18n:** next-intl, `nav` namespace, files at `src/i18n/messages/{en,ko,ja}.json`
- **Env:** Windows + PowerShell 5.x; ASCII-only console, UTF-8 BOM only for `.md`

---

## Where we are: D7 pipeline-centric CRM

### What works end-to-end

1. **Pipeline kanban** at `/pipelines/[code]` &mdash; columns by stage, cards by deal, drag&drop to move stage, value totals per column, deal count badge in sidebar via `pipelines(deals(count))` embed.
2. **New deal modal** (header "+ New deal" button) &mdash; 3 fields (name / counterparty / value), server-side debounced party search across 1,537 rows, navigates to new deal detail on save.
3. **Deal detail** at `/pipelines/[code]/deals/[id]` &mdash; header (breadcrumb + name + inline meta), tabs (Activity / Tasks / Backers* for crowdfunding), two-column body (tab content + persistent right rail with About/Company/Notes).
4. **Activity tab** &mdash; client wrapper `ActivityTabClient` with "+ Log activity" button. Modal has 6 fields (type / title / when / direction / summary / notes). 6 engagement types (Meeting/Call/Email/Note/Message/Consultation) rendered as icon button grid. Direction field shows only for two-way comms (call/email/message). `logEngagement` server action inserts row + bumps `deal.last_activity_at` + revalidates kanban.
5. **Tasks tab** &mdash; client wrapper `TasksTabClient` with "+ Add task" button. Modal has 5 fields (title / due date / priority / assignee / description). Priority is colored button grid (Low/Medium/High). Assignee uses server-side debounced contact search across 217 rows with graceful name fallback (`title_text + " at " + firm.party_name` when name is empty). Due dates stored as UTC noon for timezone-safe display.
6. **Backers tab** (crowdfunding only) &mdash; summary cards (Backers / Pledged / % Funded), reward tiers table, backers list. Name column is a Link to `/contacts/[contact_id]` when backer is linked to a contact.
7. **Contacts** at `/contacts` and `/contacts/[id]` &mdash; index with 217 rows (avatar/name/badges/firm), profile page with lifetime pledge history.
8. **Sidebar** with dynamic pipelines + deal count badges, fallback to STATIC_PIPELINES if fetch fails.

### File layout for D7 work

```
src/app/(app)/pipelines/[code]/
├── page.tsx                        # server: pipeline + stages + deals
├── kanban-client.tsx               # client: dnd-kit board + "+ New deal"
├── new-deal-modal.tsx              # modal + PartySearchInput
├── actions.ts                      # moveDealStage, createDeal, searchParties
└── deals/[id]/
    ├── page.tsx                    # server (v5): tab routing + conditional fetches
    ├── log-activity-modal.tsx      # ActivityTabClient + LogActivityModal
    ├── add-task-modal.tsx          # TasksTabClient + AddTaskModal + ContactSearchInput
    └── actions.ts                  # logEngagement, addTask, searchContacts
```

### Design decisions (locked, don't re-litigate)

- **Quick-create modal pattern** (HubSpot/Pipedrive): 3&ndash;5 fields max, shadcn Dialog + server action + revalidatePath. Anything beyond V1 is edited inline on deal detail later. Same pattern for any future modal (e.g. checklist creation).
- **`tasks.deal_id` is NOT NULL**; `tasks.checklist_id` is optional grouping. Tasks query is `WHERE deal_id = X`, then load referenced checklists separately. Same approach for engagements.
- **Schema embeds**: `engagement_type:engagement_types!engagement_type_id(*)`, `contact:contacts(id, full_name, given_name, family_name)`, `firm:parties!firm_party_id(party_name)`. PostgREST follows FK by constraint name.
- **`organization_id` always pulled from a related row** (pipeline for deal create, deal for engagement/task create) instead of hardcoded UUID. RLS-safe and multi-tenant-ready.
- **No "Ad hoc" group label** for standalone tasks &mdash; flat list when no checklists exist; "Other tasks" header only when checklists ALSO exist.
- **React Rules of Hooks**: every component declares ALL hooks (`useState`/`useEffect`/`useRef`/`useTransition`) BEFORE any conditional early return. The `PartySearchInput`/`ContactSearchInput` "selected vs unselected" branch sits AFTER the click-outside `useEffect`. This bit us twice already.
- **Server actions live in `actions.ts` per route directory**, not centralized. Each action returns `{ ok: true, ... } | { ok: false, error: string }`.
- **No `parties` rename** (would touch 1537 rows + 100+ TS files for cosmetic gain). "Party" is the correct legal/business term covering investors/suppliers/customers/partners.

---

## Recent SQL applied (verified working)

```sql
-- engagements.deal_id FK to deals (was missing before D7)
ALTER TABLE app.engagements
  ADD CONSTRAINT engagements_deal_id_fkey
  FOREIGN KEY (deal_id) REFERENCES app.deals(id) ON DELETE SET NULL;

-- engagement_types RLS (lookup table; was deny-by-default after RLS enable)
ALTER TABLE app.engagement_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "engagement_types_read_authenticated" ON app.engagement_types;
CREATE POLICY "engagement_types_read_authenticated"
  ON app.engagement_types FOR SELECT TO authenticated USING (true);
GRANT SELECT ON app.engagement_types TO authenticated;
```

## Schema inventory (verified 2026-05-28)

### `app.engagements`
- `id`, `deal_id` uuid (FK, NULL allowed, indexed), `party_id`, `task_id`, `stage_id_at_time`, `organization_id`
- `engagement_type_id` smallint NOT NULL &rarr; `engagement_types(id)`
- `title` NOT NULL, `summary`, `content`, `channel`, `direction`, `outcome`, `next_steps`, `sentiment`
- `duration_min`, `status` DEFAULT `'completed'`, `occurred_at` NOT NULL, `recorded_by_user_id`, `notes`
- Indexes: `deal_id`, `party_id`, `occurred_at desc`, `status`, `engagement_type_id`

### `app.tasks`
- `id` uuid PK, `deal_id` uuid NOT NULL (FK to deals), `organization_id` uuid NOT NULL DEFAULT marinebiogroup UUID
- `title` text NOT NULL, `description` text, `status` text NOT NULL DEFAULT `'pending'`, `priority` text NOT NULL DEFAULT `'medium'`
- `due_at`, `started_at`, `completed_at` timestamptz; `estimated_minutes`, `actual_minutes` int
- `assigned_to_contact_id` uuid &rarr; contacts; `assigned_to_user_id` uuid &rarr; users
- `checklist_id` uuid NULL &rarr; deal_checklists (optional grouping)
- `module_data` jsonb DEFAULT `'{}'`, `notes` text
- Indexes: `deal_id`, `due_at` (partial WHERE status in pending/in_progress), `status`, `assigned_to_contact_id`, `assigned_to_user_id`, `checklist_id`

### `app.engagement_types` (6 rows, all `is_active = true`)
| id | code | EN | KO | JA |
|----|------|------|------|------|
| 1 | meeting | Meeting | &#54924;&#51032; | &#20250;&#35696; |
| 2 | call | Call | &#51204;&#54868; | &#38651;&#35441; |
| 3 | email | Email | &#51060;&#47700;&#51068; | &#12513;&#12540;&#12523; |
| 4 | note | Note | &#47700;&#47784; | &#12513;&#12514; |
| 5 | message | Message | &#47700;&#49884;&#51648; | &#12513;&#12483;&#12475;&#12540;&#12472; |
| 6 | consultation | Consultation | &#49345;&#45924; | &#30456;&#35527; |

### `app.contacts` (217 rows)
- `id` uuid (NO default &mdash; needs `ALTER TABLE ... ALTER COLUMN id SET DEFAULT gen_random_uuid();`)
- `firm_party_id` uuid NOT NULL &rarr; parties
- `contact_type_id` smallint NOT NULL
- `full_name`, `given_name`, `family_name`, `email`, `email_secondary`, `phone_e164`, `phone_mobile`
- `linkedin_url`, `twitter_handle`, `title_text`, `department`, `role_category`, `seniority_level`
- `is_decision_maker`, `is_primary`, `is_active` boolean NOT NULL
- `last_contacted_at`, `focus_areas` text[], `joined_at`, `left_at`, `notes`, `source`, `source_external_id`
- Many imported VC contacts have title+firm but no name (use `contactLabel()` helper with fallback chain)

### `app.deals` (2 rows currently)
- "Q2 2026 Series A round" (Investors / Cold outreach / Lux Capital Management LLC / US$5M)
- "2026 Kickstarter Sunscreen Summer" (Crowdfunding / US$50K / 2 sample backers)

---

## Pending SQL (next session can apply)

```sql
-- 1) contacts.id needs default (blocks future contact creation)
ALTER TABLE app.contacts ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- 2) Link sample backers A/B to a real contact (optional; demo for backer history)
--    See sample-backer-linkage.sql from prior session.

-- 3) urm schema drop (D6-6) -- absorbed into app schema, no longer used
DROP SCHEMA urm CASCADE;
```

---

## Next work: `/tasks` top-level page

User confirmed direction (A) in the last exchange: a top-level Tasks page accessed via the sidebar Tasks link, aggregating tasks across all deals.

### Design (locked)

```
/tasks                                          [+ Add task]
---------------------------------------------------------------
[Open] [Completed] [All]    Filter: All deals v   Me only v
---------------------------------------------------------------
OVERDUE (3)                                              !
  [] Send Series A term sheet draft         High  Due 2d ago
     Q2 2026 Series A round -> Investors
  [] Follow up with Kickstarter manager     Med   Due 5d ago
     2026 Kickstarter Sunscreen Summer -> Crowdfunding

TODAY (2)
  [] ...

THIS WEEK (5)
  [] ...

LATER          NO DUE DATE          COMPLETED (collapsed)
```

### Files to create

- `src/app/(app)/tasks/page.tsx` &mdash; server, fetches all open tasks WHERE `deleted_at IS NULL`, joins `deal:deals(id, deal_name, pipeline:pipelines(code, name))`, `assignee:contacts(...)`. Sorted by `due_at asc nullsLast`. RLS auto-scopes to org.
- `src/app/(app)/tasks/tasks-list-client.tsx` &mdash; client, computes groups by due bucket, renders rows, handles status filter tabs and "My tasks only" toggle.
- `src/app/(app)/tasks/actions.ts` &mdash; `toggleTaskStatus(taskId, newStatus)`, `setMyTasksFilter()`. The toggle action can be re-used inside the deal detail Tasks tab too (good refactor opportunity).

### Implementation notes

- **Grouping logic** runs client-side from the fetched list. Buckets: `now.getTime() > due` &rarr; Overdue; same day &rarr; Today; within 7 days &rarr; This week; later &rarr; Later; null &rarr; No due date.
- **Checkbox toggle** &mdash; `toggleTaskStatus` flips between `pending` and `completed`, sets `completed_at` accordingly. revalidatePath both `/tasks` and the deal detail page.
- **Add task from `/tasks`** needs a deal selector (search-as-you-type, similar to PartySearchInput pattern but targeting deals). Or simpler V1: button is disabled and tooltip "Add tasks from a deal page". Decide in the new chat.
- **Filter persistence** &mdash; `?filter=mine&status=open` in URL searchParams. Server reads, client toggles update href.
- **"Me" definition** &mdash; assigned_to_user_id matches current auth user. Skip assigned_to_contact_id for "me" filter (contacts are external).

### Decisions still open

1. Should `+ Add task` from `/tasks` show a deal selector in the modal (which fetches/searches across all deals)? Or disable and require deal-context?
2. Should we show completed tasks inline (collapsed) or on a separate tab? Probably tab.
3. Sidebar Tasks badge &mdash; show count of overdue + today open tasks? Add to dynamic sidebar fetcher.

---

## Environment rules (carry over)

- **Downloads** to `$env:USERPROFILE\Downloads` (English path)
- **`.ps1` files**: `Unblock-File` first, OR `powershell -ExecutionPolicy Bypass -File ...`
- **Console output ASCII only** &mdash; PS 5.x parses UTF-8 no-BOM as CP949 and corrupts Korean. Korean text only in `.md` reports with UTF-8 BOM.
- **Korean files**: use `[System.IO.File]::ReadAllText/WriteAllText` (never `Get-Content`/`Write-Content`).
- **`-LiteralPath`** for bracket paths like `(app)` and `[code]` and `[id]`.
- **`as never`** vs `as any` for Supabase typed queries: `as never` works for `.from('TABLE' as never)` and most chains, but fails for object spread or callability &mdash; use `as any` there.
- **Supabase schema('app')**: explicit and required; PostgREST exposed schemas list must include `app` in Supabase Dashboard.

---

## Repo conventions

- All TSX files written UTF-8 no BOM (Next.js/SWC requirement)
- Inline character escapes for special chars in JSX: `{'\u00b7'}` for middle dot, `'\u2014'` for em dash, `'\u221e'` for infinity. JSX text leaks raw escapes otherwise.
- Tailwind only with core utilities + shadcn (no custom JIT classes)
- No `localStorage`/`sessionStorage` in artifacts (covered elsewhere, n/a here)
- One server action file per route directory; co-located client modal components

---

## Starting the next chat

Suggested first message:

> mbg-project D7 continuation. Read `docs/handoff-d7.md` in the repo for full context. Next task: create the `/tasks` top-level page (sidebar Tasks link) following the design in the handoff doc. Use the TasksTabClient pattern from `src/app/(app)/pipelines/[code]/deals/[id]/add-task-modal.tsx` as reference. Repo: [paste your GitHub URL].

Then the new Claude can `web_fetch` any of these directly:

- `https://raw.githubusercontent.com/{user}/{repo}/marinebiogroup/docs/handoff-d7.md`
- `https://raw.githubusercontent.com/{user}/{repo}/marinebiogroup/src/app/(app)/pipelines/[code]/deals/[id]/add-task-modal.tsx`
- (etc.)

No more 100-file attachment limit.
