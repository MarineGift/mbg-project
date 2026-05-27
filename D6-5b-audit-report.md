# D6-5b Code Audit Report

Generated: 2026-05-26 21:11:37
Files scanned: 339 (.ts, .tsx under src/)

## 1. `.schema()` method-chain pattern

Pattern: `.schema('xxx')` ??method-chain style. D5-1 audit missed these.

| schema | call count | unique files |
|---|---:|---:|
| `app` | 165 | 47 |
| `ai` | 28 | 16 |
| `urm` | 18 | 8 |
| `xxx` | 1 | 1 |

### Detail rows

#### schema=`app`

- `src/app/(app)/layout.tsx:21`
- `src/app/(app)/layout.tsx:32`
- `src/app/(app)/layout.tsx:39`
- `src/app/(app)/page.tsx:46`
- `src/app/(app)/page.tsx:52`
- `src/app/(app)/page.tsx:65`
- `src/app/(app)/settings/email-signature/page.tsx:19`
- `src/app/actions/party.ts:69`
- `src/app/actions/party.ts:83`
- `src/app/actions/party.ts:127`
- `src/app/actions/party.ts:145`
- `src/app/actions/party.ts:167`
- `src/app/actions/party.ts:202`
- `src/app/actions/party.ts:218`
- `src/app/actions/party.ts:250`
- `src/app/actions/party.ts:278`
- `src/app/actions/party.ts:305`
- `src/app/actions/party.ts:316`
- `src/app/actions/party.ts:327`
- `src/app/api/calendar/google/callback/route.ts:48`
- `src/app/api/calendar/microsoft/callback/route.ts:38`
- `src/app/api/parties/search/route.ts:12`
- `src/app/api/supply-links/route.ts:16`
- `src/app/api/supply-links/route.ts:46`
- `src/components/nav/nav-unread-badge.tsx:7`
- `src/components/parties/country-peers-panel.tsx:29`
- `src/components/parties/country-peers-panel.tsx:36`
- `src/lib/actions/communications.ts:121`
- `src/lib/actions/communications.ts:162`
- `src/lib/actions/communications.ts:221`
- `src/lib/actions/communications.ts:239`
- `src/lib/actions/contacts.ts:95`
- `src/lib/actions/contacts.ts:108`
- `src/lib/actions/contacts.ts:161`
- `src/lib/actions/contacts.ts:174`
- `src/lib/actions/contacts.ts:199`
- `src/lib/actions/drafts.ts:589`
- `src/lib/actions/drafts.ts:617`
- `src/lib/actions/drafts.ts:647`
- `src/lib/actions/drafts.ts:711`
- `src/lib/actions/drafts.ts:754`
- `src/lib/actions/email-templates.ts:10`
- `src/lib/actions/email-templates.ts:66`
- `src/lib/actions/email-templates.ts:111`
- `src/lib/actions/email-templates.ts:128`
- `src/lib/actions/email-templates.ts:148`
- `src/lib/actions/parties.ts:107`
- `src/lib/actions/parties.ts:168`
- `src/lib/actions/parties.ts:209`
- `src/lib/actions/pipeline-stages.ts:31`
- `src/lib/actions/pipeline-stages.ts:42`
- `src/lib/actions/pipeline-stages.ts:75`
- `src/lib/actions/pipeline-stages.ts:107`
- `src/lib/actions/pipeline-stages.ts:129`
- `src/lib/actions/pipeline-stages.ts:140`
- `src/lib/actions/pipeline-stages.ts:166`
- `src/lib/actions/pipeline-stages.ts:176`
- `src/lib/actions/pipeline-stages.ts:207`
- `src/lib/actions/pipeline-stages.ts:214`
- `src/lib/actions/pipeline-stages.ts:221`
- `src/lib/actions/profile.ts:65`
- `src/lib/actions/profile.ts:99`
- `src/lib/actions/tasks.ts:54`
- `src/lib/actions/tasks.ts:94`
- `src/lib/actions/tasks.ts:176`
- `src/lib/actions/tasks.ts:233`
- `src/lib/actions/tasks.ts:270`
- `src/lib/actions/tasks.ts:319`
- `src/lib/ai/prompt-renderer.ts:184`
- `src/lib/ai/prompt-renderer.ts:251`
- `src/lib/email/auto-send-gate.ts:349`
- `src/lib/email/auto-send-gate.ts:374`
- `src/lib/email/auto-send-gate.ts:405`
- `src/lib/email/header-parser.ts:214`
- `src/lib/email/header-parser.ts:233`
- `src/lib/email/header-parser.ts:252`
- `src/lib/email/header-parser.ts:296`
- `src/lib/email/header-parser.ts:337`
- `src/lib/email/mailcarrier.ts:425`
- `src/lib/email/mailcarrier.ts:449`
- `src/lib/email/mailcarrier.ts:634`
- `src/lib/email/mailcarrier.ts:675`
- `src/lib/email/mailcarrier.ts:789`
- `src/lib/email/processor.ts:198`
- `src/lib/email/processor.ts:228`
- `src/lib/email/processor.ts:241`
- `src/lib/email/processor.ts:508`
- `src/lib/email/processor.ts:537`
- `src/lib/email/processor.ts:567`
- `src/lib/email/tabs-mailer.mock.ts:162`
- `src/lib/email/tabs-mailer.mock.ts:173`
- `src/lib/email/tabs-mailer.ts:388`
- `src/lib/email/tabs-mailer.ts:415`
- `src/lib/email/tabs-mailer.ts:484`
- `src/lib/email/tabs-mailer.ts:494`
- `src/lib/email/whitelist.ts:41`
- `src/lib/queries/calendar.ts:44`
- `src/lib/queries/calendar.ts:57`
- `src/lib/queries/calendar.ts:70`
- `src/lib/queries/calendar.ts:82`
- `src/lib/queries/calendar.ts:189`
- `src/lib/queries/communication-detail-v2.ts:13`
- `src/lib/queries/communications.ts:103`
- `src/lib/queries/communications.ts:153`
- `src/lib/queries/communications.ts:167`
- `src/lib/queries/country-peers.ts:22`
- `src/lib/queries/draft-detail.ts:100`
- `src/lib/queries/draft-detail.ts:111`
- `src/lib/queries/drafts.ts:315`
- `src/lib/queries/drafts.ts:329`
- `src/lib/queries/email-sequences.ts:3`
- `src/lib/queries/email-templates.ts:67`
- `src/lib/queries/email-templates.ts:82`
- `src/lib/queries/email-tracking.ts:25`
- `src/lib/queries/email-tracking.ts:42`
- `src/lib/queries/email-tracking.ts:59`
- `src/lib/queries/email-tracking.ts:74`
- `src/lib/queries/inbox.ts:137`
- `src/lib/queries/meetings.ts:162`
- `src/lib/queries/meetings.ts:230`
- `src/lib/queries/meetings.ts:281`
- `src/lib/queries/meetings.ts:325`
- `src/lib/queries/meetings.ts:359`
- `src/lib/queries/meetings.ts:426`
- `src/lib/queries/meetings.ts:437`
- `src/lib/queries/meetings.ts:464`
- `src/lib/queries/meetings.ts:480`
- `src/lib/queries/party-detail.ts:140`
- `src/lib/queries/party-detail.ts:168`
- `src/lib/queries/party-detail.ts:195`
- `src/lib/queries/party-detail.ts:206`
- `src/lib/queries/party-detail.ts:427`
- `src/lib/queries/party-detail.ts:449`
- `src/lib/queries/party-detail.ts:480`
- `src/lib/queries/pipelines.ts:105`
- `src/lib/queries/pipelines.ts:127`
- `src/lib/queries/pipelines.ts:149`
- `src/lib/queries/pipelines.ts:177`
- `src/lib/queries/pipelines.ts:188`
- `src/lib/queries/pipelines.ts:236`
- `src/lib/queries/saved-views.ts:26`
- `src/lib/queries/tasks.ts:144`
- `src/lib/queries/tasks.ts:259`
- `src/lib/queries/user-profile.ts:32`
- `src/lib/queries/user-profile.ts:41`
- `src/lib/supabase/schema-helpers.ts:63`
- `src/lib/utils/sequence-processor.ts:110`
- `src/lib/utils/sequence-processor.ts:183`
- `src/lib/utils/sequence-processor.ts:203`
- `src/lib/utils/sequence-processor.ts:215`
- `src/scripts/simulate-inbound.ts:53`
- `src/scripts/simulate-inbound.ts:94`
- `src/workers/consultation-worker.ts:93`
- `src/workers/consultation-worker.ts:125`
- `src/workers/consultation-worker.ts:160`
- `src/workers/consultation-worker.ts:200`
- `src/workers/consultation-worker.ts:238`
- `src/workers/consultation-worker.ts:258`
- `src/workers/consultation-worker.ts:268`
- `src/workers/consultation-worker.ts:292`
- `src/workers/mail-merge-worker.ts:73`
- `src/workers/mail-merge-worker.ts:108`
- `src/workers/mail-merge-worker.ts:150`
- `src/workers/mail-merge-worker.ts:181`
- `src/workers/mail-merge-worker.ts:218`

#### schema=`ai`

- `src/app/(app)/layout.tsx:27`
- `src/app/(app)/page.tsx:41`
- `src/lib/actions/drafts.ts:92`
- `src/lib/actions/drafts.ts:112`
- `src/lib/actions/drafts.ts:169`
- `src/lib/actions/drafts.ts:204`
- `src/lib/actions/drafts.ts:304`
- `src/lib/actions/drafts.ts:382`
- `src/lib/actions/drafts.ts:474`
- `src/lib/actions/drafts.ts:723`
- `src/lib/ai/claude-client.ts:431`
- `src/lib/ai/cost-tracker.ts:134`
- `src/lib/ai/cost-tracker.ts:195`
- `src/lib/ai/cost-tracker.ts:249`
- `src/lib/ai/prompt-renderer.ts:145`
- `src/lib/email/auto-send-gate.ts:211`
- `src/lib/email/processor.ts:452`
- `src/lib/queries/communication-detail-v2.ts:40`
- `src/lib/queries/draft-detail.ts:77`
- `src/lib/queries/draft-detail.ts:131`
- `src/lib/queries/draft-detail.ts:142`
- `src/lib/queries/draft-detail.ts:153`
- `src/lib/queries/drafts.ts:209`
- `src/lib/queries/inbox.ts:191`
- `src/lib/queries/party-detail.ts:218`
- `src/lib/supabase/schema-helpers.ts:101`
- `src/scripts/simulate-inbound.ts:148`
- `src/workers/draft-expiry-worker.ts:35`

#### schema=`urm`

- `src/app/(app)/page.tsx:79`
- `src/lib/actions/engagements.ts:127`
- `src/lib/actions/engagements.ts:135`
- `src/lib/actions/engagements.ts:206`
- `src/lib/actions/engagements.ts:273`
- `src/lib/actions/engagements.ts:376`
- `src/lib/actions/engagements.ts:430`
- `src/lib/actions/engagements.ts:465`
- `src/lib/queries/draft-detail.ts:120`
- `src/lib/queries/drafts.ts:322`
- `src/lib/queries/engagements.ts:207`
- `src/lib/queries/engagements.ts:256`
- `src/lib/queries/engagements.ts:276`
- `src/lib/queries/engagements.ts:284`
- `src/lib/queries/engagements.ts:361`
- `src/lib/queries/party-detail.ts:180`
- `src/lib/queries/pipelines.ts:262`
- `src/lib/supabase/schema-helpers.ts:86`

#### schema=`xxx`

- `src/lib/supabase/server.ts:41`

## 2. `.from()` table references

Total: 265 calls (130 with `as never` cast)

Note: only matches `.from('xxx')` with string literal. Calls like `.from(tableVar)` are not captured.

| table | total | as_never | unique files |
|---|---:|---:|---:|
| `communications` | 41 | 15 | 23 |
| `parties` | 30 | 12 | 16 |
| `drafts` | 17 | 15 | 10 |
| `pipeline_stages` | 14 | 3 | 3 |
| `tasks` | 14 | 12 | 8 |
| `contacts` | 13 | 7 | 6 |
| `deals` | 13 | 13 | 6 |
| `email_signatures` | 12 |  | 2 |
| `meetings` | 9 | 9 | 3 |
| `users` | 9 | 7 | 8 |
| `mail_merge_jobs` | 9 | 0 | 3 |
| `email_templates` | 8 | 7 | 3 |
| `paper_mills` | 6 | 2 | 5 |
| `paper_companies` | 6 | 2 | 5 |
| `supplier_mill_linkages` | 5 | 2 | 3 |
| `runs` | 5 | 2 | 2 |
| `consultations` | 4 | 0 | 1 |
| `filler_suppliers` | 4 | 2 | 3 |
| `meeting_attendees` | 4 | 4 | 1 |
| `calendar_events` | 4 | 2 | 2 |
| `pipeline_definitions` | 4 | 3 | 3 |
| `calendar_connections` | 3 | 0 | 2 |
| `markets` | 3 | 0 | 3 |
| `email_tracking` | 3 | 0 | 1 |
| `mailcarrier_state` | 2 | 0 | 1 |
| `party_supply_links` | 2 | 2 | 1 |
| `email_whitelist` | 2 | 0 | 2 |
| `strategy_actions` | 2 | 0 | 1 |
| `organizations` | 2 |  | 2 |
| `auto_send_rules` | 2 |  | 2 |
| `xxx` | 1 | 0 | 1 |
| `email_sequence_sends` | 1 | 0 | 1 |
| `msg2` | 1 |  | 1 |
| `msg1` | 1 |  | 1 |
| `response_strategies` | 1 | 0 | 1 |
| `saved_views` | 1 |  | 1 |
| `brand_voice` | 1 | 0 | 1 |
| `stages` | 1 |  | 1 |
| `agents` | 1 | 0 | 1 |
| `attachments` | 1 | 0 | 1 |
| `pipelines` | 1 |  | 1 |
| `engagement_stage_history` | 1 |  | 1 |
| `email_tracking_events` | 1 | 0 | 1 |

## 3. `sb*()` helper uses

Helpers from `src/lib/supabase/schema-helpers.ts` (D5-3d).

| helper | call count | unique files |
|---|---:|---:|
| `sbUrm` | 5 | 1 |
| `sbIndustry` | 3 | 1 |
| `sbApp` | 3 | 1 |
| `sbAi` | 2 | 1 |

## 4. References to renamed columns

Columns renamed during D5-2. Non-zero hits indicate incomplete migration.

| pattern | renamed to | phase | hits | unique files |
|---|---|---|---:|---:|
| `\borg_id\b` | `organization_id` | D5-2 | 16 | 4 |
| `\bbody_text\b` | `body_plain` | D5-2 | 3 | 1 |

### Detail rows

#### pattern=`\borg_id\b`

- `src/app/actions/party.ts:20`
- `src/app/actions/party.ts:86`
- `src/app/actions/party.ts:221`
- `src/app/actions/party.ts:281`
- `src/lib/actions/email-whitelist.ts:5`
- `src/lib/actions/email-whitelist.ts:8`
- `src/lib/actions/email-whitelist.ts:9`
- `src/lib/actions/email-whitelist.ts:10`
- `src/lib/actions/email-whitelist.ts:11`
- `src/scripts/simulate-inbound.ts:36`
- `src/scripts/simulate-inbound.ts:56`
- `src/scripts/simulate-inbound.ts:98`
- `src/scripts/simulate-inbound.ts:128`
- `src/workers/mailcarrier-worker.ts:98`
- `src/workers/mailcarrier-worker.ts:125`
- `src/workers/mailcarrier-worker.ts:207`

#### pattern=`\bbody_text\b`

- `src/types/database.ts:6425`
- `src/types/database.ts:6447`
- `src/types/database.ts:6469`

Notes:
- `name` (parties.name -> party_name) and `party_type` (enum -> party_type_id smallint FK) are too generic to grep safely. Review parties-related files manually.
- D6-5a added `tier_id`, `interest_tags`, and `industry_tags` (via relation table) ??code must be updated to use these instead of legacy `tier`, `interest_tags` (text[]), `industry_tags` (text[]).

## 5. Top 30 files by combined reference count

Combined = `.schema()` + `.from()` + `sb*()` + renamed-column hits. Use this ranking to choose cutover order (highest first = biggest impact).

| refs | file |
|---:|---|
| 30 | `src/app/actions/party.ts` |
| 26 | `src/lib/actions/drafts.ts` |
| 22 | `src/lib/actions/pipeline-stages.ts` |
| 18 | `src/lib/supabase/schema-helpers.ts` |
| 18 | `src/lib/queries/meetings.ts` |
| 18 | `src/lib/queries/party-detail.ts` |
| 16 | `src/workers/consultation-worker.ts` |
| 14 | `src/lib/queries/pipelines.ts` |
| 14 | `src/lib/email/processor.ts` |
| 14 | `src/lib/actions/email-compose.ts` |
| 14 | `src/lib/queries/draft-detail.ts` |
| 14 | `src/lib/actions/engagements.ts` |
| 12 | `src/lib/actions/tasks.ts` |
| 10 | `src/lib/queries/engagements.ts` |
| 10 | `src/scripts/simulate-inbound.ts` |
| 10 | `src/lib/email/header-parser.ts` |
| 10 | `src/lib/email/mailcarrier.ts` |
| 10 | `src/lib/queries/calendar.ts` |
| 10 | `src/lib/actions/contacts.ts` |
| 10 | `src/workers/mail-merge-worker.ts` |
| 10 | `src/lib/actions/email-templates.ts` |
| 10 | `src/app/(app)/page.tsx` |
| 8 | `src/lib/queries/drafts.ts` |
| 8 | `src/lib/actions/communications.ts` |
| 8 | `src/lib/utils/sequence-processor.ts` |
| 8 | `src/lib/email/tabs-mailer.ts` |
| 8 | `src/app/(app)/layout.tsx` |
| 8 | `src/lib/queries/email-tracking.ts` |
| 8 | `src/lib/queries/industry-link.ts` |
| 8 | `src/lib/email/auto-send-gate.ts` |

---

## Summary

- `.schema()` calls: **212**
- `.from()` calls: **265** (130 with `as never`)
- `sb*()` helper uses: **13**
- Renamed column hits: **19**
