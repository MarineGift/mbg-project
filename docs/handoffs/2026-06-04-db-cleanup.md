# Handoff — 2026-06-04 — DB Cleanup (Parties Deduplication)

> Next session's main task: **clean up duplicate / inaccurate `app.parties` data.**
> Strategy chosen: **(가) Conservative** — never lose linked data. Confirm links,
> reassign to the canonical row, then soft-delete only the true duplicates.

---

## 0. How this project works (read first)

- Repo: `MarineGift/mbg-project`, branch `marinebiogroup`, local `C:\dev\mbg-project`.
- Supabase project `ogenmrgxwhpbfepeldqx`, org `b25de8f2-1020-482f-9012-183f63883169`.
- Stack: Next.js 14.2 / Supabase multi-schema (`app`, `ai`, `public`). RLS scopes by `app.current_organization_id()`.
- Gotcha #45: `.schema('app').from('TABLE' as never)` — only the table name (and write payloads) gets `as never`.
- Supabase `.select()` caps at **1000 rows** — use `{ count: 'exact', head: true }` for counts (already fixed sidebar + dashboard this session).
- Delivery loop: patch files -> `/mnt/user-data/outputs/` -> ASCII-only PowerShell mover (.ps1) -> user runs
  `powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\<name>.ps1"` -> `npx tsc --noEmit` (MUST be 0) -> commit -> **`git push origin marinebiogroup`** (push = auto-deploy to https://urm.marinebiogroup.com). User wants local + web updated together every time.
- PowerShell 5.x / CP949: mover scripts emit ASCII-only; Korean only in `.md` with UTF-8 BOM. `Unblock-File` downloaded `.ps1`. Movers Move-Item (remove from Downloads), so re-running needs re-download.

---

## 1. The cleanup task

Source of truth for duplicates: the diagnostic CSV the user ran
(`Schema_Column_Inventory ...csv` — actually a parties-dedup report grouped by
"base name" = text before the first `(`).
**Re-upload that CSV at the start of the next session** (files do not carry across sessions).

### Two clearly different cases

**(A) TRUE DUPLICATES — the same bare name repeated, no country in parens.**
These need cleanup. 9 groups, 108 rows, ~99 deletable (keep 1 canonical each):

| base name                | type            | total | notes |
|--------------------------|-----------------|-------|-------|
| Imerys                   | filler_supplier | 37    | 36x "Imerys" + 1x "Imerys (HQ)" -> keep (HQ) |
| [Other] Mid-tier mills   | paper_mill      | 23    | all identical — likely placeholder/bucket, CHECK deals |
| Multi-mill               | paper_mill      | 23    | all identical — likely placeholder/bucket, CHECK deals |
| Schaefer Kalk            | filler_supplier | 13    | 12x + 1x "(HQ)" -> keep (HQ) |
| [Sector]                 | paper_mill      | 3     | placeholder |
| Stora Enso Oyj           | paper_mill      | 3     | 2 identical + 1 variant |
| Brian Smith              | investor        | 2     | |
| Independent merchant site| paper_mill      | 2     | placeholder? CHECK deals |
| Stora Enso multi-mill    | paper_mill      | 2     | |

Full row IDs per group are in the attached `dup_ids.txt`.

**(B) NORMALIZED country/plant entities — DO NOT TOUCH.**
These look like "many rows" but are correct (one row per country/plant), exactly the
`Omya (Korea)` shape the user wants. 49 groups, e.g.:
Specialty Minerals 95, Omya 39, Sappi 14, Domtar 5, plus ~45 two-row country pairs
(International Paper, Georgia-Pacific, Mondi*, UPM*, Stora Enso Maxau/Poland, etc.).
Leaving these alone is required.

> Caution: `[Other] Mid-tier mills`, `Multi-mill`, `[Sector]`, `Independent merchant site`
> may be intentional aggregate/placeholder rows that real deals point at (a deal
> named "Q2 2026 Series A round" was seen on "[Other] Mid-tier mills"). Treat them as
> "confirm links first," not "blind delete."

### Conservative procedure (strategy 가)

For each TRUE-DUP group:

1. **Pick the canonical row.** Prefer the one ending in `(HQ)`; else the row with the
   most linked records; else the oldest `created_at`.
2. **Find links** on every non-canonical row in the group, across:
   - `app.deals` (party_id, and `app.deal_parties` if used)
   - `app.communications` (party_id)
   - `app.contacts` / party contacts
   - `app.party_supply_links` (filler_party_id / mill_party_id)
   - `app.engagements`, `app.tasks` (via deals)
3. **Reassign** any links from the duplicates to the canonical row.
4. **Soft-delete** the now-unlinked duplicates: `update app.parties set deleted_at = now() where id in (...)`.
   (App already filters `deleted_at is null` everywhere, so soft delete is safe + reversible.)
5. Re-run the dedup report to confirm the group is down to 1.

### Step-1 diagnostic SQL to run first (per group or all at once)

```sql
-- Link counts for candidate duplicate rows (run for the IDs in dup_ids.txt).
-- Replace the id list per group.
with dups as (select unnest(array[ /* paste duplicate ids here */ ]::uuid[]) as id)
select d.id,
  (select count(*) from app.deals          x where x.party_id = d.id and x.deleted_at is null) as deals,
  (select count(*) from app.communications x where x.party_id = d.id) as comms,
  (select count(*) from app.party_supply_links x where x.filler_party_id = d.id or x.mill_party_id = d.id) as supply_links
from dups d
order by deals desc, comms desc;
```

Rows with all-zero links are safe to soft-delete immediately. Rows with links get
reassigned to the canonical id first.

### Re-run dedup report (to regenerate / verify)

```sql
select
  trim(split_part(party_name, '(', 1)) as base_name,
  pt.code as party_type,
  count(*) as dup_count,
  array_agg(p.party_name order by p.party_name) as variants,
  array_agg(p.id) as ids
from app.parties p
join app.party_types pt on pt.id = p.party_type_id
where p.deleted_at is null
group by base_name, pt.code
having count(*) > 1
order by dup_count desc, base_name;
```

---

## 2. Other backlog (lower priority)

- **party_types with 0 parties**: buyer(4), customer(5), government_grant(7), consultant(8)
  all show 0. Dashboard/sidebar list them as 0. Decide: hide zero-count types, or remove
  the types. (Dashboard Parties card + sidebar are dynamic from `app.party_types`.)
- **industry_tags empty**: investor/etc. have no VC/Angel/PE tags, so the Tags column is
  blank. Data-fill task (not UI).
- **Dead component**: `src/components/parties/country-filter-bar.tsx` is no longer imported
  (replaced by `parties-filter-bar.tsx`). Safe to delete after confirming no other usage.
- **`@ts-nocheck` on `email-compose.ts`**: regenerate `database.ts` to drop it (long-standing backlog).
- **1000-row cap audit**: other places that do a full `.select()` to count/iterate may also
  undercount — audit and switch to head counts where needed.

---

## 3. What was completed THIS session (already pushed to web)

All committed to `marinebiogroup` and live on https://urm.marinebiogroup.com :

- **Sidebar**: Inbox sub-items (In Bound / Out Bound / AI Drafts), Partners moved into the
  Directory section (orange dot), live badge counts fetched directly by the sidebar.
- **Inbox badge format**: shows `unread/total` (e.g. 70/74). Sidebar sub-items and the
  dashboard Inbox card all use the same `A/B` format:
  In Bound = unread/total inbound, Out Bound = unread/total outbound,
  AI Drafts = pending-review/total drafts.
- **To-Do badge**: open tasks (status != Done).
- **Pipeline kanban**: columns WRAP to multiple rows (no horizontal scrollbar), fixed
  size `w-[18rem] h-[26rem]`, internal vertical scroll.
- **To-Do kanban**: full-height columns.
- **Dashboard**: Inbox card breakdown (removed standalone AI Drafts card), To-Do per-status
  breakdown, Deals & Engagements per-pipeline (Deal/Task/Eng, dynamic from app.pipelines),
  Parties per-type (dynamic from app.party_types).
- **Parties list (all party types share one page)**: common filter/search bar
  `[Country v] [search box] [Search] [Sort v]`; search by name when no country chosen;
  Country column (2-letter code) + Location now city-only; **clickable header sort with
  toggle + arrow** on Name / Score / Country / Location (URL `?sort=`).
- **Topbar**: removed the global "Type to search..." box.
- **Counts bug fix**: party counts used a `.select()` that capped at 1000 rows and
  undercounted (Investors 114 instead of 236, Partners 0 instead of 13). Now per-type
  **head counts** -> correct: Investors 236 / Paper Mills 1067 / Filler 232 / Partners 13.

Last commit on branch around `2facb11` (dashboard inbox A/B). Branch HEAD == origin.

Key files touched: `src/components/layout/sidebar.tsx`, `src/components/layout/topbar.tsx`,
`src/app/(app)/page.tsx`, `src/app/(app)/[partyType]/parties/page.tsx`,
`src/components/parties/parties-filter-bar.tsx` (new),
`src/app/(app)/pipelines/[code]/kanban-client.tsx`,
`src/components/tasks/task-board-view.tsx`.

---

## 4. First actions for the next session

1. User re-uploads the dedup CSV (and `dup_ids.txt` if kept).
2. Run the Step-1 link-count SQL for the 9 true-dup groups.
3. Decide canonical row per group; reassign links; soft-delete duplicates (conservative).
4. Re-run the dedup report to verify.
5. Then optionally tackle the section-2 backlog.
