# mbg-project — D9 Handoff (URM normalization + module removal)

> Continuation doc for a fresh session. Project = B2B paper/pulp-industry CRM.
> Stack: Next.js 14.2.35, React 19, Supabase multi-schema (public, app, ai). **`ingest` schema was dropped this session.**
> Repo: `MarineGift/mbg-project`, branch `marinebiogroup`, local `C:\dev\mbg-project`,
> Supabase project `ogenmrgxwhpbfepeldqx`, org `b25de8f2-1020-482f-9012-183f63883169`,
> admin user `551fc4a0-b365-47eb-bf2f-0c3f594001c0`.
> **Respond in Korean.** Windows/PowerShell, ASCII-only console output.

## CRM normalized model (authoritative)
`party` (org/entity ONLY, never a person) · `contact` (person; FK `party_id` -> parties) ·
`pipeline` · `stage` (FK `pipeline_id` -> pipelines) · `checklist` (deal-scoped: `deal_checklists.deal_id`) ·
`task` (FK `deal_id`/`checklist_id`/`assigned_to_*`) · `engagement` (FK `party_id`/`deal_id`).
Rule: **no person is ever a party.** Rule: **the word `module` must not appear in the program** (DB columns, code, comments).

## DONE this session (all committed; tsc 0 at each step)
Commits on `marinebiogroup` (latest first): `9f9818b`, `dd8dde5`, `f0135bb`, `229f79b`, `157f278`.
- **D9-1 (DML)**: investor 117 individual-parties -> 91 converted to contacts under their firm (firm resolved by name), 26 deleted. Test parties (government_grant, partner) + 1 deal purged. Verified: individual_investors=0, salvage_contacts=91, investor_companies=119.
- **D9-2 (DDL)**: dropped `contacts_history`, `person_firm_history`; renamed `contacts.firm_party_id` -> `party_id` (+ index/FK names); recreated `get_unregistered_party_domains` on `party_id`. Dropped fn `sync_parent_from_primary_firm`.
- **Normalization cleanup**: dropped empty orphan tables `pipeline_stages`, `engagement_stage_history`, `engagement_participants` (the last violated "person is not a party" via person_party_id). `stages` (53 rows, FK pipeline_id) is the canonical stage table.
- **Dropped dead functions**: `bulk_enroll_filtered` x2, `preview_campaign_filter` x2, `get_buyer_engagement_summary` (app schema), `promote_buyer_engagement_to_sales_order`.
- **module removal (DB)**: dropped `ingest` schema entirely (CASCADE — 180+30 rows, 16 fns, 4 tables; no app/ai FK, no code use). Renamed `module_data` -> `extra_data` on 12 app tables. Renamed `applicable_modules`/`allowed_modules`/`focus_modules` -> `applicable_party_types`/`allowed_party_types`/`focus_party_types` (ai.agents, ai.auto_send_rules, app.organizations, app.teams, app.template_categories) and `engagement_type_registry.is_default_for_module` -> `is_default_for_party_type`. `app.consultations` already uses `party_type` (no module col).
- **module removal (code)**: `pipeline-stages.ts` rewritten for `stages` model (was `pipeline_stages`+`pipeline_definition_id`; removed `stage_type` which stages lacks; soft-delete now `is_active=false`). Removed `stage_type` UI from StageFormDialog/PipelinesAdminClient. consultation-worker.ts module->party_type (+ `ConsultationNotification.party_type?` field). simulate-inbound.ts module removed. phase22a.ts dropped dead `module`/`tier`/`industry_tags` type fields. test file module->party_type.
- **Types**: `src/types/database.ts` was UTF-16LE + got corrupted by a bad CLI regen mid-session; restored via `git restore`, then regenerated cleanly via Management API with `included_schemas=public,app,ai` (274,661 chars, UTF-8 no-BOM). tsc 0.

## IN PROGRESS — finishing "module" word removal (the only open task)
`src/types/database.ts` still shows **5 `module` hits**, all from **4 DEAD functions** that read a NON-EXISTENT `email_templates.module` column (confirmed: column does not exist). These have **zero app callers**. **DROP them** (this clears the 5 hits):
```sql
BEGIN;
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT p.oid::regprocedure AS sig FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname IN ('create_campaign_from_template','list_active_templates','list_templates_for_compose')
  LOOP EXECUTE 'DROP FUNCTION ' || r.sig; RAISE NOTICE 'dropped %', r.sig; END LOOP;
END $$;
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM pg_proc p JOIN pg_namespace ns ON ns.oid=p.pronamespace
   WHERE ns.nspname='public' AND p.proname IN ('create_campaign_from_template','list_active_templates','list_templates_for_compose');
  IF n<>0 THEN RAISE EXCEPTION 'POST: % remain', n; END IF; RAISE NOTICE 'POST OK'; END $$;
COMMIT;
```
(`create_campaign_from_template` has 2 overloads; the name-based loop drops both.)

Then **code identifiers** (declared but ZERO consumers — verified by grep):
- `src/types/party-type.ts` ~104-120: dead helpers `moduleToPartyType()` / `partyTypeToModule()` -> DELETE the functions.
- `src/types/ai.ts:113` `applicableModules?` -> `applicablePartyTypes?`; `:166` `allowedModules` -> `allowedPartyTypes`; comments :84,:93 remove "module"/"ModuleType".
- `src/types/inbox.ts:68` & `src/types/task.ts:32` `partyModule` -> `partyTypeCode`.
- `src/types/engagement.ts:70` comment: remove "module".

Then **6 app/public fns still contain the word "module" in prosrc** but DB has no module column, so it is almost certainly comments/varnames (NOT logic): `check_party_supply_link`, `consultations_notify_worker`, `sync_calendar_match_party`, `sync_calendar_promote_to_meeting`, `update_party_lead_score`, `get_thread_context`. **These are LIVE functions — verify each `module` line is a comment/string before touching.** Query to inspect:
```sql
SELECT n.nspname, p.proname, (regexp_matches(p.prosrc,'.*module.*','g'))[1] AS line
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname IN ('public','app') AND p.proname IN
  ('check_party_supply_link','consultations_notify_worker','sync_calendar_match_party','sync_calendar_promote_to_meeting','update_party_lead_score','get_thread_context')
ORDER BY 1,2;
```

After DB DROP + code rename: regenerate types, confirm `module` = 0 in database.ts, tsc 0, commit.

## NEXT (after module=0)
**RBAC own-scope integration test** (deferred since D8): invite a real sales_rep -> manually INSERT `app.users` row (NO auto-trigger; must include NOT-NULL `full_name`) -> assign Sales Rep role + specific parties -> verify via SQL-editor impersonation (`set request.jwt.claims` sub=rep uuid + `SET ROLE authenticated`) -> browser login confirms own-scope isolation.

## Environment rules / gotchas (must follow)
- **SQL** runs in Supabase SQL Editor (not PowerShell). Migrations as single `BEGIN..COMMIT` with PRE/POST-CHECK DO blocks. **No `%` in `RAISE` message text unless paired with an arg.**
- Supabase editor **temp tables fail** (`ON COMMIT DROP` + pooler) -> use **inline CTEs** instead.
- Editor caps results/export at **100 rows** -> use `OFFSET` pagination or the "No limit" toggle.
- Schema query pattern (Gotcha #45): `.schema('app')` (no cast) + `.from('TABLE' as never)`; strict `.update({...} as never)`.
- **Type regen**: use Management API (script `regen-types-v2.ps1`, `included_schemas=public,app,ai`). Needs a REAL Supabase access token `sbp_...` (40+ chars) in quotes — the user repeatedly pasted the placeholder; verify `len`>=40. The script has a validation gate that refuses to overwrite junk. `database.ts` should be normalized to **UTF-8 no-BOM** (it was UTF-16LE before).
- **PowerShell**: run `.ps1` from `$env:USERPROFILE\Downloads` with `-ExecutionPolicy Bypass`; scripts target `C:\dev\mbg-project` and `Unblock-File` themselves. Paths with `(app)` need `-LiteralPath`. UTF-8 file writes via `[System.IO.File]::WriteAllText(..., New-Object System.Text.UTF8Encoding $false)`. Code patches: prefer **Python regex patchers** (indent-insensitive) over PS string anchors — PS multi-line anchors kept MISSing.
- `.gitignore` has `*.bak*`. `git autocrlf` warns LF->CRLF (harmless).
- **Security**: a Supabase access token was once leaked in chat and revoked. Never paste token VALUES into chat — only report length/prefix.

## SECURITY/credential note
SMTP creds were exposed in an earlier session (pre-D8); rotation should be confirmed if not done. (Not touched this session.)
