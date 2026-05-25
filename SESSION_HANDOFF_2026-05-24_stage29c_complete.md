# SESSION_HANDOFF — Stage 29-c COMPLETE

**작성일**: 2026-05-24
**작성자 세션**: Stage 29-c autonomous + interactive
**프로젝트**: mbg-project (Next.js 14 / TypeScript / Supabase)
**브랜치**: `feature/stage23-urm-cleanup`
**최신 commits**:
```
2c4bfe1  stage29c: COMPLETE - handoff for stage29d cooldown
9b1ba70  stage29c: phase1 - org_id->organization_id, body_text->body_plain (communications)
3506d2a  stage29c: regen database.ts with urm schema
0e75321  Session 10.5 detail: urm satellite migration completed (4 tables)
2b9adc2  Session 11 exit: .gitignore cleanup, URM V2 redesign queued
```

---

## §0. 새 세션 진입 메시지 (이걸 첫 메시지로 쓰세요)

> "Stage 29-c COMPLETE. Phase 1 (column rename) 적용 완료. tsc delta 0. Phase 2 (SbClient cutover + A4/A8) 는 Stage 29-d (app.\* DROP) 와 일괄 처리하기로 결정. 1-2주 cooldown 진행 중. 본 handoff 첨부했음. 다음 단계는 [Stage 29-d 진입 / 추가 정리 작업 / 기타]."

새 세션 시작 시:
1. **이 파일** (`SESSION_HANDOFF_2026-05-24_stage29c_complete.md`) 첨부
2. (선택) `stage29c_audit_report.md` 첨부 — 770 매치 detail 필요시
3. (선택) 이전 handoff `SESSION_HANDOFF_2026-05-24_stage29b_complete.md` 첨부 — 깊은 컨텍스트 필요시
4. 위 진입 메시지 + 구체적 다음 단계 명시

---

## §1. 프로젝트 / 사용자 컨텍스트

### 사용자
- **이름**: YunYoung
- **언어**: Korean (1순위), English, Japanese
- **운영 환경**: Windows + PowerShell 5.x (한국어 locale, 일부 명령 옛 버전 한계 — `Get-Content -Raw` 미지원, `Set-Content -Encoding UTF8` BOM 추가)
- **선호 사항**:
  - PowerShell 명령은 한 번에 paste 가능한 형태로
  - SQL 은 Supabase SQL Editor 에서 실행 (single statement, no BEGIN/COMMIT, no TEMP TABLE)
  - patch 는 dry-run → apply 2단계
  - 한글 응답
  - 자세한 진단 → 정확한 결정 → 안전한 실행

### 프로젝트
- **이름**: mbg-project
- **스택**: Next.js 14 / TypeScript / Supabase (PostgreSQL + Auth + Storage) / Anthropic SDK
- **목적**: B2B CRM/sales intelligence platform — paper industry filler supplier business
- **위치 (사용자 로컬)**: `C:\dev\mbg-project`

---

## §2. Stage 진행 흐름

```
Stage 28-a ✅ schema generic 'app' 으로 통합 (SbClient single-cast 패턴)
Stage 29-a ✅ schema 사전 작업
Stage 29-b ✅ data migration (γ + α+β + ε + δ)
Stage 29-c ✅ caller code Phase 1 — column rename (COMPLETE, 본 세션)
Stage 29-d 🔴 NEXT — app.* DROP + caller cutover Phase 2 (1-2주 cooldown 후)
```

---

## §3. Stage 29-c 결과 요약

### ✅ Phase 1 적용 완료 (commit 9b1ba70)
| 변경 | 사이트 | 파일 수 |
|---|---:|---:|
| `org_id` → `organization_id` (컬럼 참조) | 21 | 6 |
| `body_text` → `body_plain` (communications 한정) | 2 | 1 |

영향 파일:
- `src/app/actions/delete-communication.ts`
- `src/app/actions/delete-task.ts`
- `src/components/settings/email-signature-client.tsx`
- `src/lib/actions/email-compose.ts` (가장 큼 — 13 사이트)
- `src/lib/queries/email-signatures.ts`
- `src/lib/utils/sequence-processor.ts`

### ✅ database.ts regen 완료 (commit 3506d2a)
- 850,132 bytes (V1: 968,142)
- urm schema 포함 확인 (line 10780)
- 5 schema: public / app / ai / audit / urm

### ✅ tsc regression 검증
- Before Phase 1: **181 errors**
- After Phase 1: **181 errors**
- **delta: 0** (Phase 1 가 단 하나의 새 에러도 만들지 않음)

### ❌ Phase 2 연기 (Stage 29-d 와 일괄)
| ID | 작업 | 매치 | 연기 사유 |
|---|---|---:|---|
| A1 | `SupabaseClient<Database, 'app'>` → `'urm'` | 3 파일 / 6 라인 | **30+ default `.from()` 사이트가 app 테이블 직접 호출**. 변경시 break |
| A2 | 163곳 `.schema('app')` 검토 | 163 | A1 안 했으므로 그대로 작동 |
| A4 | `party_type: 'company'` (party.ts) | 2 | app.parties.party_type enum 살아있음 |
| A8 | `parent_party_id` / `party_level` 제거 | 19 (4파일) | app.parties 에 컬럼 잔존 (information_schema 검증) |

→ 위 4 작업은 **app.\* 테이블이 살아있는 동안 모두 정상 작동**. Stage 29-d 에서 app.\* DROP 과 동시에 처리.

---

## §4. Stage 29-c 의 중요한 새 발견 (Stage 29-d carry-forward)

### Discovery 1: 9 deprecated profile DROP 실제 검증
- handoff §5 δ 의 명시는 정확. DB 실제 부재 확인 (`information_schema.tables` 쿼리)
- 1 잔존: `app.investor_partner_profile` (108 row, ε 잔재)
- Stage 29-d 자동 drop 후보

### Discovery 2: app.parties 의 hierarchy 컬럼 잔존
```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'app' AND table_name = 'parties'
  AND column_name IN ('parent_party_id', 'party_level', 'tier');
-- 결과: 3 컬럼 모두 존재
```
→ handoff §8 의 "3-tier hierarchy DROP" 은 **urm 에만 적용**. app.parties 측 컬럼은 Stage 29-d 때 app.parties DROP 시 함께 정리.

### Discovery 3: app.parties drift
- handoff §7 expected: 1738 active
- 실제 측정: **1441 active** (delta -297)
- handoff 캡처 시점 이후 추가 정리 발생. cutover 영향 없음.

### Discovery 4: urm 측 minor drift
- urm.parties +6 (1532 → 1538)
- urm.investor_profile +5 (101 → 106) — `deleted_at` 컬럼 부재로 soft-delete 불가, 5 fund profiles 가 hard-delete 안 됐을 수 있음
- urm.paper_mill_profile -4 (1074 → 1070)
- 모두 URM 원칙 위반 아님 (`identify_non_urm_data.sql` 실행 결과 모든 orphan = 0)

### Discovery 5: 3 HQ 보존 확인
handoff §5 ε 의 명시대로 urm 측에만 보존된 3 HQ 확인:
```
Schaefer Kalk (HQ) — DE — filler_supplier
Carmeuse (HQ)     — BE — filler_supplier
Sibelco (HQ)      — BE — filler_supplier
```
모두 `source = manual_entry_2026Q2_*` (intended).

### Discovery 6: app.parties 의 23 row 가 urm.parties 에 없음
- `party_type=company` 활성 23개가 urm 측 미존재
- Stage 29-b 후 신규 추가 또는 migration 누락
- Stage 29-d 시 일괄 처리 필요 (상세 표본 조회 SQL 은 §10 참조)

### Discovery 7: `p_org_id` (RPC 매개변수) 8 사이트 보존
- DB RPC 함수 시그니처. **컬럼 rename 대상 아님**
- `email-sequences.ts`, `email-tracking.ts`, `email-whitelist.ts`, `communications.ts`, `typed-rpc.ts`

### Discovery 8: `body_text` (sequence_steps) 12 사이트 보존
- communications.body_text 와 다른 별도 컬럼
- `sequence-form-dialog.tsx`, `email-sequences.ts`, `phase21b.ts`
- Stage 29-d 시 별도 결정 필요 (sequence_steps 컬럼 rename 정책 미정)

### Discovery 9: 30+ default `.from()` 사이트 = A1 변경의 최대 risk
default `.from()` (no `.schema()`) 호출 사이트가 모두 **app 테이블**:
- `calendar_connections`, `communications`, `tasks`, `parties`, `party_contacts`, `contacts`, `email_signatures`, `org_members`, `email_whitelist`, `email_templates`, `calendar_events`

A1 변경 (default → 'urm') 시 모두 깨짐. **Stage 29-d 시 A1 변경 직전 모두 `.schema('app')` 명시 추가** 필요.

---

## §5. 환경 / 도구 / 함정 사항

### Supabase CLI 환경
- **CLI**: linked 상태 (`npx supabase status`)
- **gen types 명령**:
  ```powershell
  npx supabase gen types typescript --linked --schema public,app,urm,audit,ai > src\types\database.ts
  ```
- **⚠️ `.env.local` 함정**: line 99 `$key = node -e "..."` 가 supabase CLI 의 env parser 를 break. 해당 line 은 `# $key = ...` 로 주석 처리됨 (commit 2c4bfe1 이전에 수정). 새 라인 추가 시 `$` 시작 변수명 금지.
- **대안**: `Rename-Item .env.local .env.local.bak` 으로 임시 분리 후 gen → 복원 (linked 는 .env.local 안 읽음)

### PowerShell 5.x 함정
- `Get-Content -Raw` 미지원 → 라인 단위 읽기로 우회
- `Set-Content -Encoding UTF8` 이 BOM 추가 → `[System.IO.File]::WriteAllBytes()` 또는 raw bytes 사용
- 한국어 콘솔 출력 깨짐 (CP949) → 파일 자체는 UTF-8 정상. notepad 로 열어서 확인
- `Select-String -Pattern` 은 case-insensitive 가 기본 → case-sensitive 필요 시 `-CaseSensitive` 옵션

### git 함정
- `git stash push -u` 가 **untracked 파일 (apply_phase1.cjs, stage29c/, database.ts modified 등) 을 모두 가져감**. 본 세션에서 한 번 사고 발생 → `git stash pop` 으로 복구.
- **권장**: stash 대신 commit 으로 안전점 확보
- LF/CRLF warning 자동 발생 — autocrlf 설정이라 무시 OK

### Supabase SQL Editor 제약
- ❌ `BEGIN` / `COMMIT` (auto-rollback)
- ❌ `CREATE TEMP TABLE` (snippet isolation)
- ❌ `RAISE NOTICE` 출력 안 보임 → 별도 `SELECT` 로 검증
- ✅ Single statement 권장
- ✅ `DO $$ ... $$` block 으로 dynamic SQL
- ✅ `ON CONFLICT ... DO UPDATE` idempotent pattern
- ✅ `DROP CONSTRAINT IF EXISTS` + `ADD CONSTRAINT` (ADD 에는 IF NOT EXISTS 없음)

### Node.js 함정
- `package.json` 의 `"type": "module"` 때문에 `.js` 파일은 ESM 처리
- CommonJS 스크립트는 **`.cjs` 확장자** 필수 (apply_phase1.cjs 가 이 패턴)
- `inspect.js` 는 ESM 모드에서 `require` 사용으로 break → 해결 못함 (현재는 안 씀)

---

## §6. Stage 29-d 진입 조건 / 작업 큐

### 진입 조건 (체크리스트)
- [x] Phase 1 commit (9b1ba70)
- [x] handoff commit (2c4bfe1)
- [x] caller audit complete (stage29c_audit_report.md)
- [x] database.ts regen (urm schema 포함)
- [x] tsc regression 없음 확인
- [ ] **Production traffic 1-2주 cooldown** (Phase 1 변경 안정성 모니터링)
- [ ] **(선택) tsc 181 errors 정리** — regen exposure 인 기존 잠재 버그

### 모니터링 (cooldown 동안)
- production logs: `organization_id` / `body_plain` 관련 error 없음
- email send / signature / sequence 기능 정상 작동
- 사용자 보고 anomaly 없음

### Stage 29-d 작업 큐 (cooldown 후)

#### A. app.\* 테이블 DROP (urm 으로 완전 이전된 것)
```
app.parties                          [cascade]
  ├── app.investor_partner_profile  (108 row, ε 잔재)
  ├── app.person_firm_history        (109 row, ε 잔재)
  ├── app.investor_portfolio_companies (422 row, ε 잔재)
  ├── app.party_supply_links         (이미 urm 이전 117 row)
  ├── app.plant_supply_links         (0 row)
  ├── app.investor_profile           (101 row → urm 106)
  ├── app.paper_mill_profile         (1074 row)
  └── app.filler_supplier_profile    (232 row)
app.pipelines                         (이미 TRUNCATE)
app.pipeline_stages                   (이미 TRUNCATE)
app.tasks                             (이미 TRUNCATE)
app.engagements                       (0 row)
app.engagement_stage_history          (0 row)
```

#### B. caller code cutover (A.DROP 과 동시)
1. **A1: 3 파일 한 줄씩** — `<Database, 'app'>` → `<Database, 'urm'>`
   - `src/lib/supabase/server.ts` line 43, 54
   - `src/lib/supabase/client.ts` line 21, 41
   - `src/lib/supabase/admin.ts` line 23, 33
   - ⚠️ `src/lib/supabase/middleware.ts` line 71 (`'public'`) 변경 불요

2. **A1 직전 사전 처리**: 30+ default `.from()` 사이트에 `.schema('app')` 명시 추가
   - 또는 urm 으로 이전된 테이블 발견 시 그쪽으로 명시 전환
   - 주요 파일: `email-compose.ts` (17곳), `email-signatures.ts` (6곳), `calendar-sync.ts`, `sync-engine.ts`, `delete-*.ts`, `communications-actions.ts` 등

3. **A2: 163곳 `.schema('app')` 분류**
   - app 테이블 유지 → 그대로
   - urm 이전 테이블 → `.schema('urm')` 으로 변경

4. **A4: party.ts 2곳** — `party_type: 'company'` 
   - urm 향 INSERT 라면 `party_type_id: PARTY_TYPE.COMPANY` + JOIN 패턴
   - 패턴 참고: `stage29c/04_column_rename/party_type_join_pattern.ts`

5. **A8: 4 파일 19 사이트** — parent_party_id / party_level 제거
   - `src/app/actions/party.ts` — cascade 로직 전체 수술 (가장 큼)
   - `src/lib/party/tier-cascade.ts` — 파일 전체 삭제 가능
   - `src/components/parties/country-peers-panel.tsx` — select 에서 제거
   - `src/app/(app)/[module]/parties/page.tsx` — select / interface 정리

6. **23 app-only row 처리**: `party_type=company` active 인 23개가 urm 에 부재
   - migration 누락이면 일괄 이전 SQL
   - 신규 traffic 이면 sbApp writer 추적 후 cutover

#### C. (선택) tsc 181 errors 정리
- Phase 1 와 무관한 regen exposure
- 대표 패턴:
  - `'country'` → `'country_code'` 등 V1 컬럼명 잔존
  - `never` type 에러 (database.ts strict typing 으로 노출)
  - Buffer overload (env 변수 undefined 처리 누락)
  - `industryPaperMillId`, `MeetingRow`, `PartyMeeting` 등 type mismatch

→ runtime 영향 가능성 낮음. Stage 29-d 의 B.cutover 후 다시 측정 → 잔여만 처리.

---

## §7. 데이터 snapshot (Stage 29-c 종결 시점)

| Table | Active | 비고 |
|---|---:|---|
| urm.parties active | **1538** | (handoff §7 1532 + 6 drift) |
| urm.contacts active | **217** | 변동 없음 |
| urm.contacts_history | **109** | 변동 없음 |
| urm.party_supply_links | **117** | 변동 없음 |
| urm.investor_profile | **106** | (handoff 101 + 5 drift, no soft-delete) |
| urm.paper_mill_profile | **1070** | (handoff 1074 - 4) |
| urm.filler_supplier_profile | **232** | 3 HQ 포함 보존 |
| urm.investor_portfolio_companies | **422** | δ Port-1 신설 |
| urm.deals / stages / pipelines / tasks / engagements | **0** | α+β TRUNCATE |
| **app.parties active** | **1441** | (handoff 1738 - 297 drift) |
| app.parties.company active | **1441** | |
| app.parties.fund / organization | **0** | ε hard-delete |
| app.parties.individual active | **0** | (118 soft-deleted) |
| app.investor_partner_profile | 108 | ε 잔재 → Stage 29-d drop |
| app.person_firm_history | 109 | ε 잔재 → Stage 29-d drop |
| app.investor_portfolio_companies | 422 | ε 잔재 → Stage 29-d drop |
| app.pipelines / pipeline_stages / tasks | 0 | TRUNCATE |

### URM 원칙 검증 (모두 0 = PASS)
- PARTY_TYPE_VIOLATION: 0
- *_ORPHAN (contact / history / supply / profile / ipc): 0
- APP_ENUM_REMNANT (fund / organization): 0
- PROFILE_TYPE_MISMATCH: 0
- URM_FLOW_ORPHAN: 0

---

## §8. 산출물 인벤토리

### Stage 29-c 산출물 (commit 9b1ba70 에 포함)
```
stage29c/
├── INDEX.md                                   네비게이션
├── STAGE_29C_PLAYBOOK.md                      마스터 실행 문서
├── 01_caller_audit/
│   ├── audit_v3.ps1                           ⭐ working version (CRLF + BOM + \x27/\x22 regex)
│   ├── audit.ps1 / audit_FIXED.ps1            구버전 (참고용)
│   ├── audit.sh                               Bash 버전 (WSL)
│   └── EXPECTED_FINDINGS.md                   결과 해석 가이드
├── 02_type_regeneration/
│   ├── REGEN_TYPES.md                         supabase gen types 절차
│   └── urm_schema_typescript_stub.ts          fallback type (gen 실패 시)
├── 03_sbclient_cutover/
│   ├── SBCLIENT_CUTOVER.md                    단계별 절차
│   └── SbClient_cutover_pattern.ts            2-tier sbApp + sbUrm 패턴
├── 04_column_rename/
│   ├── RENAME_TABLE.md                        전체 매핑 (auto vs manual)
│   ├── rename_codemod.ps1                     자동 변환
│   └── party_type_join_pattern.ts             ⭐ Stage 29-d A4 적용 시 참고
├── 05_urm_verification_sql/                   ⭐ 5건 모두 실행 완료
│   ├── verify_urm_schema.sql                  스키마 구조 검증
│   ├── verify_carry_forward_counts.sql        handoff §7 snapshot 검증
│   ├── identify_non_urm_data.sql              URM 위반 탐지 (READ-ONLY)
│   ├── cleanup_non_urm_data.sql               (수정 전 — buyer/supplier 컬럼 오류)
│   ├── cleanup_non_urm_data_FIXED.sql         ⭐ filler/mill 수정본
│   ├── identify_non_urm_data_FIXED.sql        ⭐ filler/mill 수정본
│   └── check_party_type_mapping.sql           app↔urm 분포 분석
├── 06_app_residual_cleanup/
│   └── app_residual_audit.sql                 Stage 29-d 사전 분석
└── 07_completion/
    └── completion_criteria.md                 DoD 체크리스트
```

### git 추적 안 되는 파일 (gitignored, 로컬 보존)
```
apply_phase1.cjs                   Phase 1 codemod script (Stage 29-d 참조용)
inspect.js                         컨텍스트 분석 script
inspect_output.txt                 inspect 결과
gen_stderr.log                     gen types 의 stderr
stage29c_audit_report.md           ⭐ 770 매치 detail (가장 큰 참조 자료)
src/types/database.v1-backup.ts    regen 전 V1 백업 (rollback 보험)
```

### 루트 handoff 문서
```
SESSION_HANDOFF_2026-05-24_stage29c_complete.md   ⭐ 본 파일 (committed)
SESSION_HANDOFF_2026-05-24_stage29b_complete.md   이전 stage handoff (committed)
```

---

## §9. 핵심 사실 / 결정 (Stage 29-d 진입 전 반드시 인지)

### URM 7 정규 party_types
```
id  code              display_name_ko
1   investor          투자자
2   paper_mill        제지 공장
3   filler_supplier   충전제 공급사
4   buyer             구매자
5   customer          고객
6   partner           파트너
7   government_grant  정부 보조금
```
fund / organization / individual / company 코드 **부재** (V2 미지원).

### urm.parties 의 실제 컬럼 (Discovery 통해 확정)
```
id, party_type_id (smallint), party_name (NOT name!), country_code,
region, city, address, domain_normalized, website, email, phone_e164,
lei_code, tax_id, linkedin_url, founded_year, employee_count, annual_revenue_usd,
status, source, source_external_id, owner_user_id, created_by, updated_by,
notes, created_at, updated_at, deleted_at, entity_type_id (smallint, additional)
```

### urm.party_supply_links 실제 컬럼
```
id, filler_party_id, mill_party_id (NOT buyer/supplier!), link_type,
confidence, active_since, active_until, volume_estimate, notes,
module_data, created_at, updated_at, deleted_at
```

### Phase 1 codemod 의 정확한 보존 사이트 (변경 안 한 것)
| 패턴 | 사이트 수 | 사유 |
|---|---:|---|
| `p_org_id:` (RPC 매개변수) | 8 | DB 함수 시그니처 |
| `// org_id` (주석) | 2 | 동작 무관 |
| `ORG_ID` (대문자 변수명) | 16 | JS 상수 |
| `body_text` in sequence_steps | 12 | 별도 컬럼 |

### handoff §3 의 column rename 표 (참고용)
| V1 (caller) | V2 (실제 DB) | 위치 | Phase 1 처리 |
|---|---|---|---|
| `email_whitelist.org_id` | `organization_id` | app | ✅ |
| `email_whitelist.value` | `pattern` | app | (영향 없음 — caller 없음) |
| `communications.org_id` | `organization_id` | app | ✅ |
| `communications.body_text` | `body_plain` | app | ✅ |
| `parties.country` | `country_code` | app | ❌ (tsc 181 errors 의 일부) |
| `urm.parties.party_type` | `party_type_id` (FK) | urm | ❌ (Stage 29-d A4) |
| `urm.stages.stage_position` | `sort_order` | urm | ❌ (사이트 0, 매치 없음) |

---

## §10. Stage 29-d 시 즉시 활용 SQL

### 23 app-only row 표본 조회
```sql
SELECT ap.id, ap.name, ap.country_code, ap.created_at, ap.source
FROM app.parties ap
WHERE ap.deleted_at IS NULL
  AND ap.party_type::text = 'company'
  AND NOT EXISTS (
    SELECT 1 FROM urm.parties up WHERE up.id = ap.id
  )
ORDER BY ap.created_at DESC;
```

### 3 urm-only row 표본 조회 (이미 확인됨 — 3 HQ)
```sql
SELECT up.id, up.party_name, up.country_code, up.created_at, up.source,
       (SELECT code FROM urm.party_types pt WHERE pt.id = up.party_type_id) AS party_type_code
FROM urm.parties up
WHERE NOT EXISTS (
  SELECT 1 FROM app.parties ap WHERE ap.id = up.id
);
```

### URM 원칙 재검증 (Stage 29-d 전후)
- `stage29c/05_urm_verification_sql/identify_non_urm_data_FIXED.sql` 실행
- 모든 sample_count = 0 확인 후 Stage 29-d 진입

### Stage 29-d 사전 분석
- `stage29c/06_app_residual_cleanup/app_residual_audit.sql` 실행
- 분류: PRESERVE / DROP_AFTER_CUTOVER / RESIDUAL_AUTODROP / ALREADY_EMPTY

---

## §11. Open Issues / Risks

| 항목 | 상태 | 영향 |
|---|---|---|
| tsc 181 errors | regen exposure, Phase 1 무관 | runtime 영향 가능성 낮음. Stage 29-d 의 B.cutover 후 재측정 |
| 23 app-only company row | migration 누락 또는 신규 traffic | Stage 29-d 시 일괄 처리 |
| urm.investor_profile +5 (no deleted_at) | 5 fund profiles 잔재 가능성 | Stage 29-d A 단계에서 자연 정리 (app.parties cascade) |
| `.env.local` 의 `$` 시작 변수명 | line 99 주석 처리 완료 | 향후 동일 패턴 추가 금지 |
| sequence_steps.body_text 컬럼 정책 | 미정 | Stage 29-d 또는 후속 stage 에서 결정 |
| `app.investor_partner_profile` (108 row) | ε 잔재 | Stage 29-d DROP CASCADE 시 자동 정리 |

---

## §12. 다음 세션 시작 시 (실용 가이드)

### 시나리오 A: cooldown 종료 → Stage 29-d 진입
1. 본 파일 첨부
2. 첫 메시지: "Stage 29-d 진입. cooldown 종료. handoff 첨부했음. app.\* DROP + caller cutover Phase 2 시작."
3. 첫 작업: `identify_non_urm_data_FIXED.sql` 재실행 (1-2주 동안 새 traffic 으로 drift 발생했는지 확인)
4. 그 후 `app_residual_audit.sql` 실행 → DROP 순서 결정

### 시나리오 B: cooldown 중 문제 발견 (rollback)
1. 본 파일 첨부 + 문제 설명
2. 첫 메시지: "Stage 29-c Phase 1 이후 production 에서 [구체적 에러] 발생. rollback 검토 필요."
3. 첫 작업: `git revert 9b1ba70` 가능 (단일 commit, 깨끗하게 revert)

### 시나리오 C: 다른 작업 (tsc 정리 등)
1. 본 파일 첨부
2. 첫 메시지: "Stage 29-c COMPLETE. cooldown 동안 tsc 181 errors 정리하고 싶음."
3. 첫 작업: 에러 종류별 그룹화 → 우선순위 결정

### 시나리오 D: 새 stage / 기능 추가
1. 본 파일 첨부 (컨텍스트 유지)
2. 첫 메시지: "Stage 29-c COMPLETE. 다른 작업 [구체적 설명] 시작하고 싶음."
3. Stage 29-c/d 컨텍스트 인지하고 새 작업 진행

---

## §13. 작업 방식 (사용자 선호)

1. **진단 → 결정 → 실행** 3단계 분리
2. **codemod 는 dry-run → apply** 2단계
3. **SQL 은 [PRE 카운트] → [DELETE] → [POST 검증]** 3단계
4. **git commit 으로 안전점** 확보 (stash 위험)
5. **명령어는 한 번에 paste 가능한 형태** (PowerShell here-string 활용)
6. **한국어 응답** + 표/마크다운 형식
7. **위험 발견 시 즉시 stop** (사용자 결정 대기)

---

**작성 완료**. 본 handoff 와 함께 새 세션 시작 가능.

**다음 권장 행동**: 1-2주 cooldown 동안 production 모니터링. anomaly 없으면 Stage 29-d 진입.

🎯 Stage 29-c COMPLETE.
