# HANDOFF — Nasdaq IPO module in URM (session close 2026-09-21)

Read this first in the next conversation. Everything below is already applied to the live URM (Supabase, org `MBG Project` = `<ORG_UUID>`) and pushed to `MarineGift/mbg-project` branch `marinebiogroup` (last commit `ee05fa0`, Railway auto-deploys).

## 1. What exists now

### Business framing (confirmed with the founder)
- MarineBio Group Inc. (Delaware; Houston, Greentown Labs) licenses FCC paper-filler tech. Korean Marinepad is the KR operating agent; **all patents are owned by Marinepad and transfer to MBG Inc by end of Oct 2026**. US application already assigned to MBG.
- Moorim (무림) tested FCC for years; **9,000 t/yr order (2025)**; global filler manufacturer starts commercial production **Oct 2026**; if validated they convert their own plants; tissue next. **The 30,000 t figure is deleted everywhere — never reintroduce it.**
- Royalty planning assumption: 5–10% of net sales, ~$15/t (= $200/t × 7.5%, derived, never stored).
- Target: **Build-to 2029 Q4; IPO window 2029 Q4 (Accelerated) – 2030 Q2 (Base)**. Nasdaq Capital Market, Equity Standard, firm-commitment IPO. Decision in 3 gates: Gate 1 2028-12 (prelim), Gate 2 2029-03 (after FY2028 audit), Gate 3 2029 H1 (underwriter bake-off). Critical path: **PCAOB auditor engaged by 2027 Q1**.
- Korea is not a "Restrictive Market"; Delaware corp cannot be an FPI (10-K/10-Q/8-K regime).

### Database (schema `app`) — all applied
- Module tables: `ipo_programs, ipo_phases, ipo_workstreams, ipo_milestones(+deps,+parties), ipo_metrics, ipo_metric_snapshots` (only numeric input point), `ipo_listing_criteria` (nasdaq/sec), `ipo_internal_kpis`, `ipo_readiness_gates` (L1–L6, human verdict, `unknown/pass/watch/fail`, evidence required), `ipo_gate_milestones, ipo_decision_schedule, ipo_decision_reviews, ipo_assumptions, ipo_scenarios(+points)`, `patents`, `royalty_reports`, `license_terms`, `ipo_publications`.
- Views: `v_ipo_dashboard, v_ipo_listing_status, v_ipo_kpi_status, v_ipo_gate_readiness, v_ipo_phase_progress, v_ipo_gantt, v_ipo_scenario_royalty, v_patent_horizon, v_royalty_metrics, v_royalty_reconciliation, v_royalty_vs_gaap, v_ipo_milestone_tasks`.
- Seeded: program 1, phases 7, milestones **66** (38 gates), gates **28**, metrics 27, listing criteria 17, internal KPIs 7, assumptions 5, scenarios 3 (only Conservative filled), license-term template 24, publications 3. **All text is English.**
- Patents: **14 rows** — 5 KR granted (10-1510313, 10-1535522, 10-1742962, 10-1910649, 10-2887327; patentee Marinepad; `not_started`) + family FCC-HYBRID (KR priorities 10-2023-0092012 / 10-2024-0089038, PCT/KR2024/009859, US 19/396,332 `recorded` but recordation_date empty, EP 24843407.8, CN 202480047931.9, IN 202617009550, ID P00202600235, JP placeholder `PCT/KR2024/009859-JP`). Horizon: earliest 2033-08-21, latest 2044-07-10, min remaining 6.9 yrs → `kpi_patent_life` fails by design.
- URM integration: pipeline `ipo_program` (stages P0–P6), deal `Nasdaq Listing 2029` (party Self / MarineBio Group `<PARTY_UUID>`), campaign `IPO Program — Nasdaq Listing 2029`, **66 tasks** linked via `ipo_milestones.task_id`, 28 stage checklists, two-way status sync triggers, `due_at → target_date` one-way, stage guard (P5 needs gate2 review, P6 needs gate3). Advisors live in pipeline `nasdaq_advisors` (8 stages).

### App (`src/app/(app)/ipo/`)
`page.tsx, actions.ts, ipo-gantt.tsx, gate-panel.tsx, snapshot-panel.tsx, milestone-status-select.tsx, patents-panel.tsx`. Tabs: Overview · Timeline · Readiness Gates · Criteria & KPIs · Patents (incl. publications). Sidebar section **NASDAQ IPO › IPO Readiness** under Pipelines. Timeline rows have a `task` link; header links to `/pipelines/ipo_program`. Pattern: `.schema('app').from('x' as never)` + cast; React 18 (no async startTransition; async sections called as `await Fn()`); `noUncheckedIndexedAccess` on.

### Repo files (sql/)
`migration_ipo_module.sql, seed_ipo_module.sql (English, placeholder v_org), fix_ipo_module_english.sql, seed_ipo_advisor_pipeline.sql (rev.2, real pipelines/stages schema), migration_ipo_publications.sql, migration_ipo_urm_link.sql, seed_ipo_urm_link.sql`. Handoffs in `docs/handoff/2026-09-20` and `…/09-21`. Gantt HTML also published as a Claude artifact.

## 2. Conventions that bit us (keep)
- Live schema ≠ repo assumptions: it is `app.pipelines/app.stages` (`is_won/is_lost/is_terminal`, no `party_type_id`), **not** `pipeline_definitions/stage_kind`; `015_houston_pipelines.sql` was never applied. `party_types.id` is **integer**. `parties.party_name` (not `name`). `tasks.status` is text, existing rows all `pending`; app type says `todo/in_progress/blocked/done/cancelled`. `deals.party_id` and `deals.campaign_id` NOT NULL. `engagements.task_id` exists.
- Paste files (`paste_*.sql.txt`) carry the real org UUID and stay in Downloads; never commit them. Seeds in the repo keep `v_org = '0000…'` and raise if not replaced. Replace only the `:= '0000…'` declaration lines, never the `IF v_org = '0000…'` guard.
- Universal mover routes `seed_/migration_/fix_*.sql → sql\`, `handoff_*.md → docs\handoff\<date>\`, `patch_*.ps1 → tools\patches\`; `.tsx/.ts` need the inline mover with explicit `name`. Finish block ends with `git push origin marinebiogroup`.
- 12 pre-existing typecheck errors (parties/page.tsx, schedule-*.tsx, relay/mail/route.ts) are not ours and do not block deploy.
- Supabase SQL Editor shows only the last statement's result; run verification queries one at a time; don't paste `→ expected` notes into SQL.

## 3. Open items (next session candidates)
1. **Verify To-Do visibility** of the 66 IPO tasks (status `pending`). If the To-Do board filters on `todo`, change `app.ipo_milestone_status_to_task()` default from `pending` to `todo` (one-line SQL).
2. **US patent 19/396,332**: fill `recordation_date` with the USPTO assignment reel/frame date; JP: replace placeholder application_no with 特願2026-xxxxxx; confirm grant status of KR priorities 10-2023-0092012 / 10-2024-0089038.
3. **First metric snapshots** (Criteria & KPIs tab): stockholders_equity, operating_history_years, active_licensees (0), cash, monthly_burn → runway. Reduces "unmeasured 12".
4. Mark October milestones in progress: F-IP-01 (patent transfer), F-IP-03 (JP opposition due 10/27), F-CM-01 (Moorim production), A-FA-01 (start auditor interviews in Nov).
5. Optional UI: royalty ledger entry screen (needed by 2027 Q3), advisor↔milestone party linking screen (2028 H2), decision-log page.
6. Optional: revenue/volume KPIs are intentionally absent until the Management scenario is approved (C-CM-06, after Oct 2026 production results).

## 4. Where the money questions stand
Nasdaq CM Equity Standard: SE $5M, MVUPHS $15M **from offering proceeds only**, 2-yr history, 1M shares, 300 round-lot holders (150 with $2,500+), 3 market makers, $4 bid. Plan gross proceeds $20–30M. Fees: entry $50–75K, annual ~$56K+. Governance 5605/5615 phase-in exists but internal target is full compliance before listing.
