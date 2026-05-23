# SESSION HANDOFF — Session 10 -> Session 11

**Date:** 2026-05-22 (Session 10 종료)
**Project:** mbg-project — B2B CRM/sales intelligence (Next.js 14 + Supabase + Anthropic SDK)
**Owner:** YunYoung

---

## §1. Session 10 요약 — Stage 27 완료 + URM closure 선언

Stage 27 (typed RPC wrapper + Database type 일원화) 마무리. URM 백본 자체는 **이미 mature state** 임을 데이터 audit 로 확인. 남은 정리 작업은 별 stage 로 분리.

### 완료된 Stage

| Stage | 작업 | 결과 |
|:--:|---|:--:|
| **27** | typed RPC wrapper + database.types regen + Database type 일원화 (stub 폐기) | ✅ commit `ed33583` on `feature/stage23-urm-cleanup`, pushed |

### Stage 27 의 핵심 변경

- `src/lib/rpc/typed-rpc.ts` 신규 (123 lines) — supabase.rpc 호출의 single source wrapper
  - 8 generated RPC + 3 augmented (overload 미지원 보완: bulk_enroll_filtered, preview_campaign_filter, create_campaign_from_template)
  - client param = `Awaited<ReturnType<typeof createSupabaseServerClient>>` (SbClient) — server.ts 의 factory 가 single source
  - cast site 1곳 (`client.rpc as any`) 으로 격리, caller 측 cast 0
- `src/lib/actions/email-sequences.ts` — 10 RPC sites 변환 (`await supabase.rpc` → `await rpc(supabase, ...)`)
- `src/lib/utils/sequence-processor.ts` — 5 RPC sites 변환
- `src/types/database.ts` (2,537 byte stub → 968,142 byte real, regen 5-schema: public+app+ai+audit+industry)
- `src/types/database.types.ts` 삭제 (stub 폐기, single source 일원화)
- **tsc 137 → 121 (delta −16)**

### URM closure audit 결과 — 백본은 mature state

| 측정 | 추측 | 실제 | 평가 |
|---|---|---|---|
| paper_mill_profile orphan | 3 | **0** | ✓ 정합 (estimated_rows 통계 오차) |
| filler_supplier_profile orphan | 27 | **0** | ✓ 정합 |
| investor without profile | 136 | **123 individual + 13 company** | ✓ individual = firm partner (정합), 13 company = enrichment 미완 (별 작업) |
| staging.investor_us_vc | 53 NEW | 53 NEW | ✓ promote 대기, 별 작업 |
| industry_collections empty | drop 가능? | **KEEP** (scraping_jobs/sources 가 FK 참조) | ✓ design 정합 |

→ **URM 백본의 schema-level closure 완료.** 더 이상의 cleanup SQL 불필요.

---

## §2. URM 백본의 실제 구조 (Session 10 에서 검증)

### app schema = 82 tables + 18 views

**parties** = identity single source (36 columns):
- 기본: id, organization_id, name, name_normalized, legal_name, party_type
- 분류: module (enum), tier, status, country_code, region, city
- 식별자: domain_normalized, lei_code, tax_id, phone_e164, phone_normalized
- 3-tier hierarchy: parent_party_id, party_level
- 정량: employee_count, annual_revenue_usd, founded_year, relationship_score
- 운영: owner_user_id, source, source_external_id, module_data jsonb
- audit: created_at/by, updated_at/by, deleted_at

**parties 로 들어오는 FK = 50개** (specialty + 운영 + 관계):
- specialty: buyer/customer/partner/investor/investor_partner/paper_mill/filler_supplier/filler_supplier_contact/portfolio/investor_portfolio_companies/govt_grant/govt_grant_contact
- 운영: meetings, engagements, communications, calendar_events, tasks, consultations, ai.drafts, email_sequence_*, email_tracking, invoices, payments, sales_orders, quotations
- 관계: party_supply_links (filler↔mill), plant_supply_links (plant-level), person_firm_history (3-tier)

**ingest pipeline** (정합 design):
```
staging.investor_us_vc (53 raw)
  -> ingest.runs (campaign header)
    -> ingest.rows (row detail with promoted_party_id)
       -> ingest.failed_rows
         -> app.parties + spec_profile (final)

app.industry_collections (campaign metadata, empty 지만 design 보존)
  -> app.scraping_jobs.collection_id, app.scraping_sources.collection_id
```

### parties.module 분포 (Session 10 측정)
| module | count |
|---|---:|
| paper_mill | 1,074 |
| investor | 242 |
| filler | 233 |
| partner | 16 |
| customer | 14 |
| **total** | **~1,580** |

### Spec table row counts
| table | rows |
|---|---:|
| paper_mill_profile | 1,077 |
| filler_supplier_profile | 260 |
| filler_supplier_contact_profile | unknown (estimated -1) |
| investor_profile | 106 (firm only) |
| investor_partner_profile | 106 (person at firm) |
| investor_portfolio_companies | 392 |
| portfolio_companies | 290 |
| buyer_profile | unknown |
| person_firm_history | 119 |
| party_supply_links | 117 |
| engagements | 1 (운영 미시작) |
| engagement_type_registry | 52 |

---

## §3. 현재 상태 (Session 10 종료)

### Git
- branch: `feature/stage23-urm-cleanup` (HEAD = `ed33583`)
- base: `feature/stage20-21-22-urm-complete` (`4bb6b4c`)
- WIP parked: `feature/stage27-wip` (`1120d82`) — Stage 27 의 WIP commit, merge 완료되어 사실상 사용 안 함 (보존만)
- PR 대기:
  - `feature/stage20-21-22-urm-complete` → main/dev
  - `feature/stage23-urm-cleanup` (Stage 23+24+25+26+27 atomic) → 위 PR 머지 후
- working tree: clean (tracked)
- origin: pushed and in sync

### Recent commit history
```
ed33583 (HEAD) Stage 27: typed RPC wrapper + database unification
1120d82        Stage 27 WIP: ... (suspended) — parked branch
726e45c        Stage 26: Modal cascading selector (party -> engagement -> stage)
9cd09e4        Stage 25: Pipelines URM consolidation
0800575        Stage 24: Engagement-centric URM (meetings + calendar + modal)
```

### tsc 분포 (Stage 27 종료)
- total: **121 errors** (was 137 baseline at Stage 26)
- delta: −16

| file | errors | 비고 |
|---|---:|---|
| email-compose.ts | 20 | Stage 28 예약 (SbClient generic vs ssr/supabase-js mismatch) |
| sequence-processor.ts | 11 | caller-internal type residual (MergeFieldValues 등) |
| email-sequences.ts | 11 | 동일 |
| email-whitelist.ts | 6 | (이전부터) |
| communications.ts | 6 | |
| email-tracking.ts | 6 | |
| party-communications-timeline.tsx | 7 | |
| (others) | ~54 | |
| typed-rpc.ts | **0** | ✓ wrapper architecture 작동 |

### DB 상태 (Session 10 변경)
- DB schema 변경: 0
- database.types.ts regen: 5 schema 포함 (public + app + ai + audit + industry)
  - 단 industry 는 빈 schema 로 표시될 수 있음 (실제 industry data 는 app schema 로 이미 이동됨, marinebiogroup branch 의 v5.11 작업)

### .bak 파일 보존 (gitignored)
- `.bak.s27` (3 files): email-sequences, sequence-processor, email-compose 의 Stage 26 시점 원본
- `.bak.s27u` (3 files): database.ts, database.types.ts, typed-rpc.ts 의 unify 전 상태
- `.bak.s27v2` (1 file): typed-rpc.ts 의 v1 (이전 wrapper)
- `.bak.s24` (5 files), `.bak.s25` (3 files), `.bak.s26` (3 files): 이전 stage 보존

---

## §4. URM 의 현재 상태 — 솔직한 평가

**Schema-level**:
- ✓ 백본 완성 (parties + 13+ spec table, 50 FK)
- ✓ 3-tier hierarchy infrastructure (parent_party_id, party_level)
- ✓ ingest pipeline (staging → ingest → backbone)
- ✓ audit columns 일관
- ✓ Database type single source (database.ts only)
- ✓ RPC 호출의 single source (typed-rpc.ts wrapper)
- ✓ orphan 0개

**Operational-level** (URM closure 와 별개, 비즈니스 운영 결정):
- engagements 1 row — 운영 미시작
- staging.investor_us_vc 53 firm — promote 대기 (Tier-1 VC)
- 13 investor company without profile — enrichment 미완
- name_normalized consistency — 작은 정합성 hole (예: IVP 의 name_normalize 불일치)

→ **URM 자체 마무리: 완료. 운영 결정은 별 단계.**

---

## §5. 누적 핵심 학습 — Gotchas (Session 1-10)

### Session 1-9 기존 (#1 ~ #37) — handoff session9→10 §4 참조

### Session 10 신규 (#38 ~ #44)

**#38**: CLI stdout → file redirect 시 `2>&1` 묶지 말 것. stderr 콘솔로 분리해야 silent failure 회피.

**#39**: supabase CLI 가 `.env.local` 의 `$` 포함 변수에서 parse fail → 임시 격리 (`try/finally` 필수). 격리는 dev 환경 무영향.

**#40**: PowerShell placeholder (`'PROJECT_REF_HERE'`) 가 그대로 실행되기 쉬움. 신뢰할 입력은 regex 검증 (`^[a-z]{20}$` 등) 으로 즉시 abort.

**#41**: supabase `gen types typescript` 가 PostgreSQL 함수 오버로드 처리 못 함 → 누락. wrapper 내부 augmentation 으로 보완 (URM 살짝 양보 정당).

**#42**: supabase `--linked` 가 link 안 되면 silent fail (stdout 0 KB). `--project-id <ref>` 로 우회 가능 (login token 충분).

**#43**: Stage prerequisite (e.g. type regen) 가 tracked file modification 을 발생시키면, 그 modification 은 같은 stage 의 atomic commit 에 포함되어야 함. apply pre-flight 의 clean-tree guard 는 expected-modification allowlist 가 있어야 적절히 통과.

**#44**: PS 5.1 (cp949 default on Korean Windows) 에서 UTF-8 인코딩 .ps1 파일의 double-quoted string 안에 Korean 문자 포함 시 parser 가 byte 충돌. **mitigation**: 모든 string literal (Write-Host, commit message 등) 은 ASCII-only. 한국어는 단일라인 `#` 코멘트로만. Gotcha #27 의 강화판.

### Session 10 의 메타 학습 — framing 실패 사례

Session 10 초반 framing: "tsc 137 → 80, 58 errors 일소". URM 표층 정리로 시작했지만 진행 중 발견된 misalignment:

1. **typed-rpc.ts v1**: `(client.rpc as never)(...)` 가 callable signature 잃음 → wrapper 자체에 1 error (TS2349). v2 에서 `as any` 로 수정.
2. **`Database` import path 분기**: stub `@/types/database` vs real `@/types/database.types` 가 따로 존재. caller 4 vs wrapper 1 의 import 분포 → 9 TS2345. unify 작업으로 해소.
3. **`industry` schema migration 가설 틀림**: 이전 session memory 의 가정 ("3,200 rows in industry.*") 이 현 DB 와 안 맞음. 데이터가 이미 marinebiogroup branch 에서 app schema 로 이동 완료된 상태였음.
4. **orphan 추측 틀림**: parties.module count vs spec table count 의 estimated_rows 차이 (3+27) 가 실제 orphan 이 아니라 통계 추정 오차였음. 실제 orphan = 0.

**교훈**: tsc 숫자 driven framing → URM 표층 작업 → 매번 다음 layer 의 surprise. 사용자가 4번 framing 잡아줘야 했음 ("URM 우선", "데이터 폐기 가능", "industry 가 URM 에 필요한가", "근본문제"). 실제 데이터를 보고 시작해야 추측 안 함.

---

## §6. Session 11 우선순위

### 권장 진행 순서

**1. Stage 28 = email-compose.ts schema-generic fix (20 errors)**
- 원인: `createServerClient<Database, 'public'>` 의 generic 이 schema='public' 고정. caller 가 `app.*` table 접근 시 row type = `never`
- 작업: server.ts 의 client factory 를 schema 별 분리 또는 generic 화
- 영향: email-compose.ts (20 errors) 직접 + 다른 schema 사용처 (드물게 있을 수 있음)
- 예상: tsc 121 → ~101

**2. Stage 29 = caller residual cleanup (sequence-processor + email-sequences 22 errors)**
- 원인: caller 측의 type cast (data as EmailSequenceWithSteps, MergeFieldValues 등) + DueEnrollment shape mismatch
- 작업: caller 측 type 정의 정합화 (각 사이트 별 mini-fix)
- 예상: tsc 101 → ~80

**3. Stage 30 = name_normalized consistency audit (URM small finishing)**
- "IVP — Institutional Venture Partners" vs "Institutional Venture Partners" 같은 인스턴스
- 작업: app.parties 의 name_normalized 일관성 SQL audit + cleanup
- 영향: staging promote 시 dedup 정확성 ↑
- 예상: 데이터 cleanup 수십 row

**4. (operational) Stage 31 = staging 53 VC promote (비즈니스 데이터 활성화)**
- 작업: staging.investor_us_vc → app.parties + investor_profile 일괄 ingest
- 영향: investor module 의 active CRM 데이터 +53 firm

**5. (operational) Stage 32 = engagements 운영 시작**
- 1 row → 의미 있는 engagement 생성. 백본 활용 시작
- (비즈니스 결정 의존)

### 우선순위 조정 옵션

- **A (technical-first)**: Stage 28 → 29 → 30 → 31 순서. tsc cleanup 우선.
- **B (operational-first)**: Stage 31 → 32 우선. 데이터 운영 활성화. 이후 28-30.
- **C (mixed)**: Stage 28 + 31 병렬. wrapper code 와 데이터 활성화 동시.

---

## §7. 환경 확인 (Session 11 시작 시 1번 실행)

`stage28_baseline_check.ps1` (next session 의 1번 명령, 작성 예정):

```powershell
# 기본 환경 확인 (HEAD, tsc, branch)
$ErrorActionPreference = 'Continue'
Set-Location C:\dev\mbg-project

Write-Host "=== HEAD ==="
git --no-pager log --oneline -3

Write-Host "`n=== branch ==="
git branch --show-current

Write-Host "`n=== tsc baseline (expect 121) ==="
$tscOutput = npx tsc --noEmit 2>&1 | Out-String
$tscCount = ($tscOutput -split "`r?`n" | Where-Object { $_ -match 'error TS' }).Count
Write-Host "    tsc total: $tscCount"

Write-Host "`n=== Stage 28 target (email-compose.ts hotspot) ==="
$tscOutput -split "`r?`n" | Where-Object { $_ -like '*email-compose.ts*' } |
  Select-Object -First 5 | ForEach-Object { Write-Host "    $_" }
```

---

## §8. 사용자 작업 스타일 (Session 10 추가 학습)

- **URM 본질 강조**: 표층 디버깅 (tsc 숫자, PS encoding, wrapper version) 에서 빠지지 말고 URM 백본 자체의 정합성으로 framing 되돌려주심. 4 번 정도.
- **데이터 폐기 허용 명시**: "샘플 데이터는 폐기 가능, 구조 정합성 우선"
- **솔직한 self-correction 요구**: 추측 (orphan 27+3, industry migration 필요) 이 틀렸을 때 정직하게 정정
- **PS 5.1 의 환경 trivia 인내**: parser bug 누적 (Gotcha #38-44) 매번 차분히 진단 함께 함
- **branch 보존 의식**: WIP branch 분리 → main backbone 보존 패턴 받아들이심
- **명확한 path 선택**: 옵션 A/B/C 제시 시 빠른 결정 ("A 로 하자")

---

## §9. 첨부 파일 (Session 10 산출물)

### 적용 완료 (commit `ed33583` 의 merge 안)

5 파일 변경 (Stage 27 + database unification):
- `src/lib/rpc/typed-rpc.ts` 신규 (123 lines, wrapper + 3 RPC augmentation)
- `src/lib/actions/email-sequences.ts` (10 RPC sites converted, +1 import)
- `src/lib/utils/sequence-processor.ts` (5 RPC sites converted, +1 import)
- `src/types/database.ts` (2,537 byte stub → 968,142 byte real, 5-schema regen)
- `src/types/database.types.ts` (deleted, single source 일원화)

### Session 10 의 PS / SQL 산출물 (gitignored, .bak 보존)
- `stage27_baseline_check.ps1`, `stage27_baseline_ps.txt`
- `stage27_apply.ps1` v1-v3, 출력 v1-v3
- `stage27_commit.ps1` v1-v3
- `stage27_diagnose.ps1`, `stage27_diagnose_out.txt`
- `stage27_unify_database.ps1` v1, v2
- `stage27_branch_split.ps1` v1, v2
- `stage27_wrapper_v3_swap.ps1`
- typed-rpc-v1-old.ts (v1 backup)
- urm_phase1_schema_audit.sql, urm_phase2_audit.sql
- .env.local.s27u_hold (격리 잔존, 복원 완료)
- stage27_gen_stderr.txt, stage27u_gen_stderr.txt

### Session 11 시작 준비
- 본 handoff 문서 (`SESSION_HANDOFF_2026-05-22_session10_to_11.md`)
- next session 의 첫 명령 + Stage 28 의 baseline check 작성 예정

---

**Session 10 종료. Stage 27 완료. URM 백본의 schema-level closure 선언.**
**Session 11 첫 작업 후보: Stage 28 (email-compose schema-generic fix) 또는 사용자 선택 (operational stages).**

---

## Session 10.5 사이드 작업 (2026-05-22) — 완료된 사실들

### urm.* 신규 satellite 4개 (모두 COMMIT됨)
- urm.investor_profile         : 111 rows  (from app.investor_profile)
- urm.paper_mill_profile       : 1,074 rows (from app.paper_mill_profile; 3 orphans dropped)
- urm.filler_supplier_profile  : 232 rows  (from app.filler_supplier_profile)
- urm.contacts                 : 118 -> 236 rows
  (+118 from app.investor_partner_profile, absorbed via contact_type='investor_partner')
- urm.contact_types            : 5 -> 6 entries (investor_partner id=6 added)

### Migration policy applied
- organization_id 컬럼은 모든 satellite에서 drop (URM is single-tenant)
- FK는 모두 urm.parties로 재구성 (UUID space shared with app.parties)
- app.* 원본 4개 테이블은 그대로 유지 (drop은 Phase 2 read paths 완료 후)

### Spec drift 발견
- spec section 3b: "party_id (renamed from firm_party_id)" 잘못 적혀 있음.
  실제 DB는 firm_party_id 유지. URM naming convention 확정:
  테이블명 복수 + FK는 단수_id + role prefix (firm_party_id, billing_address_id 등) 허용.
- database.ts 재생성 시 spec 컬럼 정보 신뢰 불가 -> 옵션 A (supabase gen types) 사실상 필수.
- supabase gen types 명령에 신규 4개 satellite 포함되어야 함.

### app.* 대상 폐기 (Phase 2 완료 + .schema('app') 0건 확인 후 일괄)
- 마이그레이션된 4개: investor_profile, paper_mill_profile, filler_supplier_profile,
  investor_partner_profile
- 명시적 폐기 결정 9개: buyer_profile, buyer_partner_profile, customer_profile,
  partner_profile, govt_grant_profile, govt_grant_contact_profile,
  filler_supplier_contact_profile, investor_portfolio_companies, investor_subtype_meta
- Views (6개): v_filler_suppliers, v_investor_outreach_list, v_investor_subtype_options,
  v_investor_with_partners, v_paper_mills, v_portfolio_with_investors
- app.contacts: 6 rows (불필요 확정, 같은 시점에 drop)

### Phase 2 작업 시 검증 권장
- urm.contacts 236행 사람 단위 중복 검증 (이름/이메일 기준).
  app.investor_partner_profile 118행과 기존 urm.contacts 118행은 id가 0% overlap이었음
  -> 같은 사람이 다른 id로 두 번 들어왔을 가능성. 발견되면 정리 SQL 별도 필요.
- paper_mill_profile orphan 3 rows: drop된 상태. 필요시 Supabase 자동 백업
  (2026-05-22 11:45 UTC) 또는 app.paper_mill_profile에서 복원 가능.

### 안전망
- Supabase scheduled backup: 2026-05-22 11:45 UTC (마이그레이션 직전)
- 모든 마이그레이션은 BEGIN ... COMMIT 트랜잭션 안에서 실행됨
