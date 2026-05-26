# D5-1 caller audit report

**Generated**: 2026-05-26 15:18:21
**Project root**: `C:\dev\mbg-project`

---

## 1. database.ts location and urm presence

- Path: `src\types\database.ts`
- Size: 437812 bytes
- urm schema header count: 2
- urm tables in database.ts: 24

### urm tables

- contact_types
- contacts
- contacts_history
- deal_checklists
- deal_stage_history
- deals
- engagement_attendees
- engagement_documents
- engagement_email_details
- engagement_meeting_details
- engagement_types
- engagements
- entity_types
- filler_supplier_profile
- investor_portfolio_companies
- investor_profile
- paper_mill_profile
- parties
- party_supply_links
- party_types
- pipelines
- plant_supply_links
- stages
- tasks

---

## 2. Supabase client schema configs

| File | Line | Schema |
|---|---:|---|
| `src\app\actions\calendar-sync.ts` | 64 | `app` |
| `src\app\actions\calendar-sync.ts` | 89 | `app` |
| `src\app\actions\delete-communication.ts` | 104 | `app` |
| `src\app\actions\delete-task.ts` | 44 | `app` |
| `src\components\providers\realtime-provider.tsx` | 67 | `app` |
| `src\components\providers\realtime-provider.tsx` | 84 | `app` |
| `src\components\providers\realtime-provider.tsx` | 103 | `ai` |
| `src\components\providers\realtime-provider.tsx` | 116 | `ai` |
| `src\lib\calendar\sync-engine.ts` | 31 | `app` |
| `src\lib\calendar\token-crypto.ts` | 16 | `app` |

---

## 3. `.from()` call argument distribution

Total: 506 calls across 452 files

| Arg | Count |
|---|---:|
| `parties` | 176 |
| `communications` | 41 |
| `paper_companies` | 33 |
| `paper_mills` | 31 |
| `supplier_mill_linkages` | 18 |
| `tasks` | 18 |
| `drafts` | 17 |
| `filler_suppliers` | 17 |
| `pipeline_stages` | 14 |
| `contacts` | 13 |
| `deals` | 13 |
| `email_signatures` | 12 |
| `meetings` | 9 |
| `users` | 9 |
| `mail_merge_jobs` | 9 |
| `email_templates` | 8 |
| `party_supply_links` | 6 |
| `runs` | 5 |
| `email-attachments` | 5 |
| `calendar_events` | 4 |
| `pipeline_definitions` | 4 |
| `meeting_attendees` | 4 |
| `consultations` | 4 |
| `R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7` | 3 |
| `markets` | 3 |
| `calendar_connections` | 3 |
| `email_tracking` | 3 |
| `strategy_actions` | 2 |
| `mailcarrier_state` | 2 |
| `email_whitelist` | 2 |
| `organizations` | 2 |
| `auto_send_rules` | 2 |
| `response_strategies` | 1 |
| `email_sequence_sends` | 1 |
| `msg2` | 1 |
| `fake pdf bytes` | 1 |
| `raw rfc822` | 1 |
| `msg1` | 1 |
| `brand_voice` | 1 |
| `attachments` | 1 |
| `stages` | 1 |
| `agents` | 1 |
| `pipelines` | 1 |
| `saved_views` | 1 |
| `email_tracking_events` | 1 |
| `engagement_stage_history` | 1 |

---

## 4. `.rpc()` call argument distribution

Total: 15 calls

| Arg | Count |
|---|---:|
| `record_email_open` | 3 |
| `record_email_click` | 2 |
| `get_sequence_with_steps` | 1 |
| `list_sequences` | 1 |
| `get_party_enrollments` | 1 |
| `expire_stale_drafts` | 1 |
| `get_lead_scores_many` | 1 |
| `upsert_calendar_connection` | 1 |
| `search_knowledge` | 1 |
| `decrypt_calendar_token` | 1 |
| `update_calendar_sync_state` | 1 |
| `update_calendar_tokens` | 1 |

---

## 5. Column rename target hits (stage29c handoff)

| V1 | V2 | Table | File | Count |
|---|---|---|---|---:|
| `body_text` | `body_plain` | communications | `src\components\settings\sequence-form-dialog.tsx` | 7 |
| `body_text` | `body_plain` | communications | `src\lib\actions\email-sequences.ts` | 4 |
| `body_text` | `body_plain` | communications | `src\types\database.ts` | 6 |
| `body_text` | `body_plain` | communications | `src\types\phase21b.ts` | 2 |
| `joined_at` | `started_at` | contacts_history | `src\types\database.ts` | 11 |
| `left_at` | `ended_at` | contacts_history | `src\types\database.ts` | 11 |
| `org_id` | `organization_id` | email_whitelist/communications | `src\app\(app)\[partyType]\parties\[id]\page.tsx` | 1 |
| `org_id` | `organization_id` | email_whitelist/communications | `src\lib\actions\email-compose.ts` | 1 |
| `org_id` | `organization_id` | email_whitelist/communications | `src\types\database.ts` | 4 |
| `org_id` | `organization_id` | email_whitelist/communications | `src\types\phase21.ts` | 1 |
| `supply_type` | `link_type` | party_supply_links | `src\app\api\supply-links\route.ts` | 3 |
| `supply_type` | `link_type` | party_supply_links | `src\components\parties\party-supply-links-panel.tsx` | 3 |
| `supply_type` | `link_type` | party_supply_links | `src\types\database.ts` | 3 |
| `volume_tpy` | `volume_estimate` | party_supply_links | `src\app\api\supply-links\route.ts` | 3 |
| `volume_tpy` | `volume_estimate` | party_supply_links | `src\components\parties\party-supply-links-panel.tsx` | 4 |
| `volume_tpy` | `volume_estimate` | party_supply_links | `src\types\database.ts` | 3 |

---

## 6. `party_type` direct references

Stage 29-c handoff: `parties.party_type` (enum) -> `party_type_id` (FK) requires manual P1-P7 JOIN pattern.
Total: 103 refs in 30 files

| File | Count |
|---|---:|
| `src\types\database.ts` | 57 |
| `src\lib\actions\tasks.ts` | 10 |
| `src\lib\actions\parties.ts` | 4 |
| `src\lib\queries\country-peers.ts` | 2 |
| `src\lib\ai\prompt-renderer.ts` | 2 |
| `src\lib\queries\pipelines.ts` | 2 |
| `src\app\(app)\[partyType]\parties\page.tsx` | 2 |
| `src\components\parties\country-peers-panel.tsx` | 2 |
| `src\app\api\parties\search\route.ts` | 1 |
| `src\app\api\sequences\process` | 1 |
| `src\lib\queries\saved-views.ts` | 1 |
| `src\lib\queries\tasks.ts` | 1 |
| `src\app\(app)\page.tsx` | 1 |
| `src\lib\queries\communication-detail-v2.ts` | 1 |
| `src\lib\queries\inbox.ts` | 1 |
| `src\lib\queries\party-detail.ts` | 1 |
| `src\app\api\parties` | 1 |
| `src\app\api\sequences` | 1 |
| `src\app\api\supply-links` | 1 |
| `src\app\api\communications` | 1 |
| `src\app\(app)\settings\pipelines\page.tsx` | 1 |
| `src\app\actions\party.ts` | 1 |
| `src\app\api\calendar` | 1 |
| `src\app\api\calendar\sync` | 1 |
| `src\app\api\calendar\google\callback` | 1 |
| `src\app\api\calendar\google\connect` | 1 |
| `src\app\api\calendar\microsoft` | 1 |
| `src\app\api\tasks` | 1 |
| `src\app\api\track` | 1 |
| `src\app\api\calendar\google` | 1 |

---

## 7. `.from()` call sites (first 50)

| File | Line | Arg |
|---|---:|---|
| `src\app\(app)\layout.tsx` | 22 | `users` |
| `src\app\(app)\layout.tsx` | 28 | `drafts` |
| `src\app\(app)\layout.tsx` | 33 | `communications` |
| `src\app\(app)\layout.tsx` | 40 | `tasks` |
| `src\app\(app)\page.tsx` | 42 | `drafts` |
| `src\app\(app)\page.tsx` | 47 | `communications` |
| `src\app\(app)\page.tsx` | 53 | `tasks` |
| `src\app\(app)\page.tsx` | 66 | `parties` |
| `src\app\(app)\page.tsx` | 80 | `deals` |
| `src\app\(app)\industry\filler-suppliers\page.tsx` | 24 | `filler_suppliers` |
| `src\app\(app)\industry\filler-suppliers\page.tsx` | 60 | `markets` |
| `src\app\(app)\industry\paper-companies\page.tsx` | 33 | `paper_companies` |
| `src\app\(app)\industry\paper-companies\page.tsx` | 76 | `markets` |
| `src\app\(app)\industry\paper-companies\[id]\page.tsx` | 37 | `paper_companies` |
| `src\app\(app)\industry\paper-mills\[id]` | 37 | `paper_companies` |
| `src\app\(app)\industry\paper-mills\page.tsx` | 22 | `paper_mills` |
| `src\app\(app)\industry\paper-mills\page.tsx` | 42 | `paper_companies` |
| `src\app\(app)\industry\paper-mills\page.tsx` | 70 | `markets` |
| `src\app\(app)\industry\paper-mills\[id]\page.tsx` | 31 | `paper_mills` |
| `src\app\(app)\industry\paper-mills\[id]\page.tsx` | 47 | `paper_companies` |
| `src\app\(app)\industry\paper-mills\[id]\page.tsx` | 56 | `supplier_mill_linkages` |
| `src\app\(app)\industry\paper-mills\[id]\page.tsx` | 72 | `filler_suppliers` |
| `src\app\(app)\settings\calendar` | 31 | `paper_mills` |
| `src\app\(app)\settings\calendar` | 47 | `paper_companies` |
| `src\app\(app)\settings\calendar` | 56 | `supplier_mill_linkages` |
| `src\app\(app)\settings\calendar` | 72 | `filler_suppliers` |
| `src\app\(app)\settings\email-history` | 31 | `paper_mills` |
| `src\app\(app)\settings\email-history` | 47 | `paper_companies` |
| `src\app\(app)\settings\email-history` | 56 | `supplier_mill_linkages` |
| `src\app\(app)\settings\email-history` | 72 | `filler_suppliers` |
| `src\app\(app)\settings\email-sequences` | 31 | `paper_mills` |
| `src\app\(app)\settings\email-sequences` | 47 | `paper_companies` |
| `src\app\(app)\settings\email-sequences` | 56 | `supplier_mill_linkages` |
| `src\app\(app)\settings\email-sequences` | 72 | `filler_suppliers` |
| `src\app\(app)\settings\email-signature` | 31 | `paper_mills` |
| `src\app\(app)\settings\email-signature` | 47 | `paper_companies` |
| `src\app\(app)\settings\email-signature` | 56 | `supplier_mill_linkages` |
| `src\app\(app)\settings\email-signature` | 72 | `filler_suppliers` |
| `src\app\(app)\settings\email-signatures` | 31 | `paper_mills` |
| `src\app\(app)\settings\email-signatures` | 47 | `paper_companies` |
| `src\app\(app)\settings\email-signatures` | 56 | `supplier_mill_linkages` |
| `src\app\(app)\settings\email-signatures` | 72 | `filler_suppliers` |
| `src\app\(app)\settings\email-templates` | 31 | `paper_mills` |
| `src\app\(app)\settings\email-templates` | 47 | `paper_companies` |
| `src\app\(app)\settings\email-templates` | 56 | `supplier_mill_linkages` |
| `src\app\(app)\settings\email-templates` | 72 | `filler_suppliers` |
| `src\app\(app)\settings\email-whitelist` | 31 | `paper_mills` |
| `src\app\(app)\settings\email-whitelist` | 47 | `paper_companies` |
| `src\app\(app)\settings\email-whitelist` | 56 | `supplier_mill_linkages` |
| `src\app\(app)\settings\email-whitelist` | 72 | `filler_suppliers` |

## 8. `.rpc()` call sites (first 30)

| File | Line | Arg |
|---|---:|---|
| `src\app\api\track\click\[token]\route.ts` | 24 | `record_email_click` |
| `src\app\api\track\open\[token]` | 24 | `record_email_click` |
| `src\app\api\track\open\[token]\route.ts` | 31 | `record_email_open` |
| `src\app\auth\callback` | 31 | `record_email_open` |
| `src\app\auth\error` | 31 | `record_email_open` |
| `src\lib\ai\prompt-renderer.ts` | 209 | `search_knowledge` |
| `src\lib\calendar\token-crypto.ts` | 38 | `upsert_calendar_connection` |
| `src\lib\calendar\token-crypto.ts` | 60 | `decrypt_calendar_token` |
| `src\lib\calendar\token-crypto.ts` | 78 | `update_calendar_tokens` |
| `src\lib\calendar\token-crypto.ts` | 101 | `update_calendar_sync_state` |
| `src\lib\queries\email-sequences.ts` | 11 | `list_sequences` |
| `src\lib\queries\email-sequences.ts` | 19 | `get_sequence_with_steps` |
| `src\lib\queries\email-sequences.ts` | 27 | `get_party_enrollments` |
| `src\lib\queries\lead-score.ts` | 24 | `get_lead_scores_many` |
| `src\workers\draft-expiry-worker.ts` | 36 | `expire_stale_drafts` |

