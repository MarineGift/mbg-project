# D5-0 stage29c audit report

**Generated**: 2026-05-26 14:48:08
**Project root**: `C:\dev\mbg-project`
**Script**: D5-0-audit.ps1

---

## 1. stage29c directory tree

```
[DIR]  01_caller_audit
           7826  01_caller_audit\audit.ps1
           5997  01_caller_audit\audit.sh
           8132  01_caller_audit\audit_FIXED.ps1
           6217  01_caller_audit\audit_v3.ps1
           7758  01_caller_audit\EXPECTED_FINDINGS.md
[DIR]  02_type_regeneration
           4438  02_type_regeneration\REGEN_TYPES.md
          23016  02_type_regeneration\urm_schema_typescript_stub.ts
[DIR]  03_sbclient_cutover
           4458  03_sbclient_cutover\SBCLIENT_CUTOVER.md
          12245  03_sbclient_cutover\SbClient_cutover_pattern.ts
[DIR]  04_column_rename
          10709  04_column_rename\party_type_join_pattern.ts
          11060  04_column_rename\rename_codemod.ps1
           7009  04_column_rename\RENAME_TABLE.md
[DIR]  05_urm_verification_sql
          10328  05_urm_verification_sql\check_party_type_mapping.sql
          14951  05_urm_verification_sql\cleanup_non_urm_data.sql
          18087  05_urm_verification_sql\identify_non_urm_data.sql
          12850  05_urm_verification_sql\verify_carry_forward_counts.sql
          16234  05_urm_verification_sql\verify_urm_schema.sql
[DIR]  06_app_residual_cleanup
          11095  06_app_residual_cleanup\app_residual_audit.sql
[DIR]  07_completion
          10261  07_completion\completion_criteria.md
           6859  INDEX.md
          10259  STAGE_29C_PLAYBOOK.md
```

---

## 2. Key documents (full text)

### File: `INDEX.md`

```markdown
# Stage 29-c · URM V2 Caller Cutover · Deliverable Package

> autonomous session deliverables, 2026-05-24
> 입력: `SESSION_HANDOFF_2026-05-24_stage29b_complete.md`
> 산출물 17건. 모든 SQL 은 Supabase SQL Editor (atomic single-statement) 준수.

---

## 빠른 시작

```
1. STAGE_29C_PLAYBOOK.md 읽기 (10분)
2. 05/verify_*.sql 4건 순차 실행 (pre-flight gate)
3. 01/audit.ps1 실행 → caller 발견 위치 list 확보
4. 02 / 03 / 04 순서로 cutover 진행
5. 05/cleanup_non_urm_data.sql 로 URM 위반 정리 (필요시)
6. 07/completion_criteria.md 의 모든 항목 PASS 확인
7. 06/app_residual_audit.sql 결과 검토 → Stage 29-d 준비
```

---

## 디렉토리 구조

```
stage29c/
├── INDEX.md                                     ← 본 파일
├── STAGE_29C_PLAYBOOK.md                        ← 마스터 실행 문서
│
├── 01_caller_audit/                             ← 사전 분석
│   ├── audit.ps1                                  PowerShell 감사 스크립트
│   ├── audit.sh                                   Bash/WSL 버전
│   └── EXPECTED_FINDINGS.md                       결과 해석 가이드
│
├── 02_type_regeneration/                        ← TypeScript 타입
│   ├── REGEN_TYPES.md                             supabase gen types 절차
│   └── urm_schema_typescript_stub.ts              19개 urm 테이블 fallback 타입
│
├── 03_sbclient_cutover/                         ← SbClient 전환
│   ├── SBCLIENT_CUTOVER.md                        단계별 절차
│   └── SbClient_cutover_pattern.ts                2-tier sbApp + sbUrm 패턴
│
├── 04_column_rename/                            ← 컬럼명 변경
│   ├── RENAME_TABLE.md                            전체 매핑 (auto vs manual)
│   ├── rename_codemod.ps1                         자동 변환 (4개 단순 rename)
│   └── party_type_join_pattern.ts                 party_type→party_type_id 수동 P1-P7
│
├── 05_urm_verification_sql/                     ← URM 검증/정리 SQL
│   ├── verify_urm_schema.sql                      스키마 구조 검증 (S01-S08)
│   ├── verify_carry_forward_counts.sql            handoff §7 snapshot 검증
│   ├── identify_non_urm_data.sql                  URM 위반 탐지 (READ-ONLY)
│   ├── cleanup_non_urm_data.sql                   URM 위반 정리 (DELETE)
│   └── check_party_type_mapping.sql               app↔urm party_type 매핑 분석
│
├── 06_app_residual_cleanup/                     ← Stage 29-d 준비
│   └── app_residual_audit.sql                     app.* DROP 후보 분류
│
└── 07_completion/                               ← 완료 기준
    └── completion_criteria.md                     §0-§11 DoD 체크리스트
```

---

## URM 기본원칙 (사용자 명시)

> **Pipeline → Stages → Deals → Deals_Checklist → Tasks → Engagements**
> **Parties → Contacts → Contact_history → Filler_Suppliers_profile** (+ investor, paper_mill)
>
> 위 구조에 맞지 않는 데이터는 **삭제 OK**.

### 위반 탐지 → 정리 흐름

```
05/identify_non_urm_data.sql (READ-ONLY)
    ↓ 위반 row 발견
05/cleanup_non_urm_data.sql (DELETE, 사용자 권한)
    ↓ 정리
05/identify_non_urm_data.sql 재실행 (모두 0 확인)
```

---

## 7 정규 party_types (handoff §5 ε)

| id | code | display_name_ko |
|---|---|---|
| 1 | investor | 투자자 |
| 2 | paper_mill | 제지 공장 |
| 3 | filler_supplier | 충전제 공급사 |
| 4 | buyer | 구매자 |
| 5 | customer | 고객 |
| 6 | partner | 파트너 |
| 7 | government_grant | 정부 보조금 |

**삭제 대상** (V2 미지원):
- `fund` (5 row hard-deleted in ε)
- `organization` (9 row hard-deleted in ε, 3 HQ 는 filler_supplier_profile 로 보존)
- `individual` (118 row soft-deleted, urm 미이전)

---

## 핵심 column rename (handoff §3)

| V1 (caller 가 사용 중) | V2 (실제 컬럼) | 위치 | 처리 |
|---|---|---|---|
| `email_whitelist.org_id` | `organization_id` | app | codemod (자동) |
| `email_whitelist.value` | `pattern` | app | codemod (자동) |
| `communications.org_id` | `organization_id` | app | codemod (자동) |
| `communications.body_text` | `body_plain` | app | codemod (자동) |
| `parties.country` | `country_code` | app | codemod (자동) |
| `stages.stage_position` | `sort_order` | urm | codemod (자동) |
| `parties.party_type` (enum) | `party_type_id` (FK) | urm | **수동** (JOIN 패턴 P1-P7) |
| `contacts_history.joined_at` | `started_at` (date cast) | urm | 수동 |
| `contacts_history.left_at` | `ended_at` (date cast) | urm | 수동 |
| `party_supply_links.supply_type` | `link_type` | urm | 수동 |
| `party_supply_links.volume_tpy` | `volume_estimate` (text) | urm | 수동 |

---

## Supabase SQL Editor 제약 (모든 SQL 준수)

- ❌ `BEGIN` / `COMMIT` 직접 작성 불가 (auto-rollback on error)
- ❌ `CREATE TEMP TABLE` 불가 (snippet isolation)
- ✅ 단일 statement 권장
- ✅ `DO $$ ... $$` block 으로 dynamic SQL
- ✅ `ON CONFLICT ... DO UPDATE` idempotent pattern
- ✅ `DROP CONSTRAINT IF EXISTS` + `ADD CONSTRAINT` (ADD 에는 IF NOT EXISTS 없음)
- ⚠️ `RAISE NOTICE` 출력 미표시 → 별도 `SELECT` 로 결과 확인

---

## handoff §7 snapshot (검증 기준)

| Table | Expected | 메모 |
|---|---:|---|
| urm.parties active | **1532** | -11 from app (ε) |
| urm.contacts active | **217** | -19 hard-delete (R3) |
| urm.contacts_history | **109** | 118 - 9 (ε) |
| urm.party_supply_links | **117** | γ 신설 |
| urm.investor_profile | **101** | -5 fund |
| urm.paper_mill_profile | **1074** | 변동 없음 |
| urm.filler_supplier_profile | **232** | 3 HQ 포함 |
| urm.investor_portfolio_companies | **422** | δ Port-1 신설 |
| urm.deals / stages / pipelines / tasks / engagements | **0** | α+β TRUNCATE |
| app.parties active | **1738** | Stage 29-d 까지 carry |
| app.investor_partner_profile | **108** | ε 잔재 |
| app.person_firm_history | **109** | ε 잔재 |
| app.investor_portfolio_companies | **422** | ε 잔재 |

---

## Stage 진행 흐름

```
Stage 29-a ✅ schema 사전 작업
Stage 29-b ✅ data migration (γ + α+β + ε + δ)
Stage 29-c 🟡 caller code cutover ← 현재
Stage 29-d 🔴 app.* DROP (1-2주 cooldown 후)
```

---

## 참고

- `STAGE_29C_PLAYBOOK.md` — 상세 실행 절차 (Korean)
- `07_completion/completion_criteria.md` — Definition of Done
- `SESSION_HANDOFF_2026-05-24_stage29b_complete.md` — Stage 29-b 결산 (사용자 첨부)
```

### File: `STAGE_29C_PLAYBOOK.md`

```markdown
# STAGE 29-c PLAYBOOK — URM V2 cutover (caller code)

작성: 2026-05-24 (autonomous, 7h window)
산출 위치: `outputs/stage29c/`

---

## §0. 한 줄 요약

**Stage 29-c 는 application code 작업.** DB 는 Stage 29-b 에서 종결됨 (urm.* 신설 + app.* deprecation 9개 DROP + portfolio Port-1 422 row 이전). 이제 TypeScript caller code 를 V1(app)→V2(urm) 로 cutover.

**URM 원칙 (사용자 명시)**: 
- 유효 도메인: `Pipeline–Stages–Deals–Deal_Checklist–Tasks–Engagements` + `Parties–Contacts–Contact_history–{Investor|PaperMill|FillerSupplier}_profile + Portfolio + supply_links + party_types`
- 이 구조에 안 맞는 데이터/코드는 삭제

**실행 순서 (이대로)**:
1. `01_caller_audit/audit.ps1` 실행 → 영향 사이트 list
2. `02_type_regeneration/` 의 `npx supabase gen types` 실행 (urm schema 포함)
3. `03_sbclient_cutover/` 패치 적용
4. `04_column_rename/` 코드모드 적용
5. `05_urm_verification_sql/*.sql` 실행해서 DB 상태 vs handoff §7 일치 검증
6. `06_app_residual_cleanup/*.sql` 실행해서 Stage 29-d 대비
7. `07_completion/` 의 checklist 로 종료 확인

---

## §1. 환경 특이성 (다시 강조)

| 패턴 | 이유 |
|---|---|
| BEGIN/COMMIT 절대 사용 X | Supabase SQL Editor multi-snippet 에서 auto-rollback |
| CREATE TEMP TABLE X | snippet 간 안 보임 |
| atomic single-statement | PostgreSQL auto-commit 의존 |
| `ON CONFLICT (...) DO UPDATE SET col = COALESCE(target.col, EXCLUDED.col)` | idempotent INSERT |
| `DROP CONSTRAINT IF EXISTS + ADD CONSTRAINT` | `ALTER TABLE ADD CONSTRAINT` 에 IF NOT EXISTS 미지원 |
| RAISE NOTICE 표시 안 됨 | 검증은 별도 SELECT |
| 동적 SQL: `DO block + EXECUTE format()` | TRUNCATE/DELETE 의 동적 대상 |

---

## §2. Stage 29-c 의 5 작업 sequence

### Step 1 — Caller audit (10분)

```powershell
# PowerShell on Windows, mbg-project 루트에서
cd C:\path\to\mbg-project
.\stage29c\01_caller_audit\audit.ps1 -ProjectRoot . -OutFile .\stage29c_audit_report.md
```

산출: `stage29c_audit_report.md` — 영향 site list, 카운트 포함

**예상 발견**:
- `SbClient` factory 정의 site (보통 `src/lib/supabase/server.ts`, `client.ts`, `service.ts`)
- `.from('app.<table>')` 또는 schema-prefixed 호출 (해당 시)
- 컬럼 reference: `org_id`, `body_text`, `country`, `party_type` (직접), `stage_position`
- RPC wrapper (`src/lib/rpc/typed-rpc.ts`) 의 V1→V2 매핑 site

### Step 2 — Type regeneration (5분)

```powershell
# urm schema 가 types 에 안 잡힘. 재생성 필수
$env:SUPABASE_ACCESS_TOKEN="..."  # 기존 값
npx supabase gen types typescript `
  --project-id <project-id> `
  --schema app,ai,audit,urm,public `
  > .\src\lib\supabase\database.ts
```

**중요**: `--schema` 에 `urm` 명시. 누락하면 cutover 못 함.

검증: `Get-Content .\src\lib\supabase\database.ts | Select-String "urm:"` → 1개 line 이상 발견되어야 함.

### Step 3 — SbClient cutover (15분)

`03_sbclient_cutover/SbClient_cutover_pattern.ts` 의 diff 패턴 그대로 적용. **핵심 변경**: 
- `SupabaseClient<Database, 'app'>` → `SupabaseClient<Database, 'urm'>`
- 그러나 모든 호출이 urm 만 쓰는 게 아니므로 **2-tier client** 패턴 권장 (sbApp + sbUrm)

### Step 4 — Column rename codemod (30분)

`04_column_rename/rename_codemod.ps1` 실행. 각 매치 사이트에 대해 사용자가 review + apply.

```powershell
.\stage29c\04_column_rename\rename_codemod.ps1 -ProjectRoot . -DryRun
# 검토 후
.\stage29c\04_column_rename\rename_codemod.ps1 -ProjectRoot . -Apply
```

**특수 케이스**: `party_type` (직접 enum) → `party_type_id` (FK to urm.party_types). 단순 rename 으로 안 됨. 별도 JOIN 패턴 적용 — `party_type_join_pattern.ts` 참조.

### Step 5 — Verification (10분)

```sql
-- Supabase SQL Editor 에서
\i 05_urm_verification_sql/verify_urm_schema.sql
\i 05_urm_verification_sql/verify_carry_forward_counts.sql
\i 05_urm_verification_sql/identify_non_urm_data.sql
```

각 결과를 export 해서 보관.

### Step 6 (선택, 그러나 권장) — app residual audit

```sql
\i 06_app_residual_cleanup/app_residual_audit.sql
```

Stage 29-d 의 1-2주 cooldown 이후 drop 대상 list. 지금 실행해서 caller 의존성 사전 파악.

---

## §3. 결정 포인트 (사용자가 wake-up 후 검토)

| # | 결정 필요 사항 | 권장 |
|---|---|---|
| D1 | `app.engagement_type_registry` (52) / `investor_subtype_meta` (10) / `partner_seniority_meta` (6) 의 V2 이전 여부 | **urm.* lookup 으로 이전** (Stage 29-d 전) |
| D2 | `urm.contacts.firm_party_id NOT NULL` 유지 vs ALTER NULL | **유지** (R3 결정 carry, 사람이 firm 떠나면 hard-delete) |
| D3 | app.parties.party_type enum 5값 vs urm.party_types 7값 매핑 | **§4 의 매핑 표 적용** |
| D4 | 0-row 운영 carry 테이블 60+ 의 caller 의존성 audit | **Step 6 결과 보고 판단** |
| D5 | SbClient 2-tier (sbApp + sbUrm) vs single | **2-tier** (점진적 이전 안전) |

---

## §4. app.parties.party_type → urm.party_types 매핑 (사용자 결정 필요)

`app.parties.party_type` enum: `company | organization | individual | fund | government` (5개)
`urm.party_types.code`: `investor | paper_mill | filler_supplier | buyer | customer | partner | government_grant` (7개)

**Stage 29-b §7 의 데이터 분포 후**:
- app.parties.company: 1413 active / 193 soft-deleted
- app.parties.individual: 0 / 118 soft-deleted
- app.parties.fund: 0 (ε hard-delete)
- app.parties.organization: 0 (ε hard-delete)
- app.parties.government: 미측정 → §4-c 의 audit SQL 로 확인 필요

**제안 매핑** (urm.parties 의 party_type_id 결정 logic):

| app enum | urm.party_types 매핑 | 근거 |
|---|---|---|
| `company` | profile 테이블 join → investor / paper_mill / filler_supplier / buyer / customer / partner 중 분류 | profile 존재 여부로 자동 결정 |
| `individual` | (모두 soft-deleted, app 에서만 carry) | urm 측 없음. Stage 29-d 시 drop |
| `fund` | (ε hard-delete 완료) | 부재 |
| `organization` | (ε hard-delete 완료) | 부재 |
| `government` | `government_grant` | 직접 매핑 |

자세한 logic 은 `05_urm_verification_sql/check_party_type_mapping.sql` 산출 결과 확인 후 결정.

---

## §5. 데이터 정합 검증 (Step 5 의 기대 결과)

handoff §7 의 snapshot 과 100% 일치해야 함:

| Table | 기대 | 측정 (SQL 산출) |
|---|---:|---|
| urm.parties active | 1532 | ? |
| urm.contacts active | 217 | ? |
| urm.contacts_history | 109 | ? |
| urm.party_supply_links | 117 | ? |
| urm.plant_supply_links | 0 | ? |
| urm.investor_profile | 101 | ? |
| urm.paper_mill_profile | 1074 | ? |
| urm.filler_supplier_profile | 232 | ? |
| urm.investor_portfolio_companies | 422 | ? |
| urm.deals / stages / pipelines / tasks / engagements | 0 모두 | ? |
| app.parties active | 1738 | ? |
| 9 deprecation profile | 부재 | ? |
| app.portfolio_companies + v_portfolio_with_investors | 부재 | ? |

불일치 시: 변경 이력 추적 (사용자가 별도 작업 했을 가능성).

---

## §6. 산출물 인벤토리

```
outputs/stage29c/
├── STAGE_29C_PLAYBOOK.md (this)
├── 01_caller_audit/
│   ├── audit.ps1 ........................... PowerShell grep 기반 audit
│   ├── audit.sh ............................ Bash 버전 (WSL/Linux)
│   └── EXPECTED_FINDINGS.md ................. 발견 해석 가이드
├── 02_type_regeneration/
│   ├── REGEN_TYPES.md ....................... 재생성 instruction
│   └── urm_schema_typescript_stub.ts ......... fallback 수기 타입 (gen 실패 시)
├── 03_sbclient_cutover/
│   ├── SbClient_cutover_pattern.ts ........... 2-tier client diff
│   └── SBCLIENT_CUTOVER.md ................... 적용 instruction
├── 04_column_rename/
│   ├── rename_codemod.ps1 .................... PowerShell sed-style
│   ├── RENAME_TABLE.md ....................... 매핑 + 적용 안내
│   └── party_type_join_pattern.ts ............ party_type FK 특수 케이스
├── 05_urm_verification_sql/
│   ├── verify_urm_schema.sql ................. urm.* 테이블 + 컬럼 검증
│   ├── verify_carry_forward_counts.sql ....... §7 snapshot 일치 확인
│   ├── identify_non_urm_data.sql ............. URM 외 데이터 식별 (삭제 후보)
│   └── check_party_type_mapping.sql .......... party_type enum↔code 분포
├── 06_app_residual_cleanup/
│   └── app_residual_audit.sql ................ Stage 29-d 대비 audit
└── 07_completion/
    └── completion_criteria.md ................ Definition of Done
```

---

## §7. Definition of Done (Stage 29-c 종료 조건)

- [ ] caller audit report 산출 + 검토 완료
- [ ] `database.ts` 재생성 + `urm` schema 포함 확인
- [ ] SbClient 2-tier cutover 적용 + 빌드 통과 (`npm run build`)
- [ ] 컬럼 rename codemod 적용 + 모든 매치 처리
- [ ] 빌드 + 타입 체크 통과 (`tsc --noEmit`)
- [ ] urm verification SQL 5건 모두 expected 와 일치
- [ ] app residual audit 결과 보관 (Stage 29-d 대비)

이 7 항목 모두 ✅ 되면 Stage 29-c 종결. **1-2주 cooldown** 후 Stage 29-d (app.* drop) 진입.

---

## §8. Known Risk (carry-forward)

| # | 위험 | 완화책 |
|---|---|---|
| R1 | urm types 재생성 실패 (urm schema 가 GraphQL 노출 안 됨 등) | `urm_schema_typescript_stub.ts` 의 수기 타입 fallback |
| R2 | SbClient 2-tier 적용 후 일부 호출 사이트 빠짐 | `tsc --noEmit` 의 error 가 가이드 |
| R3 | party_type enum 매핑 logic 미합의 | §4 의 매핑 표 사용자 검토 필요 |
| R4 | urm.* 의 RLS policy 가 app.* 와 다르게 정의됨 | 사용자가 RLS audit 추가 실시 (Stage 29-c 범위 외) |
| R5 | 일부 view (v_portfolio_with_investors 외) 의 caller 의존성 | `app_residual_audit.sql` 의 view 부분 확인 |

— 끝.
```

### File: `07_completion\completion_criteria.md`

```markdown
# Stage 29-c — Completion Criteria (Definition of Done)

> URM V2 caller code cutover. handoff `SESSION_HANDOFF_2026-05-24_stage29b_complete.md` 기반.
> **사용자 원칙**: URM 기본구조 (Pipeline-Stages-Deals-Deals_Checklist-Tasks-Engagements + Parties-Contacts-Contact_history-Filler_Suppliers_profile) 준수. 정합하지 않는 데이터는 삭제.

---

## §0. Pre-flight (반드시 통과)

| Gate | 검증 방법 | PASS 조건 |
|---|---|---|
| G-0.1 | `05_urm_verification_sql/verify_urm_schema.sql` 실행 | 모든 row status = `OK` 또는 `INFO` |
| G-0.2 | `05_urm_verification_sql/verify_carry_forward_counts.sql` 실행 | 모든 row status = `OK`, delta = 0 (±5 허용) |
| G-0.3 | `05_urm_verification_sql/identify_non_urm_data.sql` 실행 | `*_ORPHAN` 카테고리 모두 sample_count = 0; `APP_ENUM_REMNANT` fund/organization = 0 |
| G-0.4 | `05_urm_verification_sql/check_party_type_mapping.sql` 실행 | Q3 cross-map 의 모든 row note = `OK`; Q4 profile 정합성 = 0 mismatch |

> ⚠️ G-0.1 ~ G-0.4 중 1건이라도 FAIL → STOP. handoff 재점검 후 재진입.

---

## §1. Caller Audit 완료

| 산출물 | DoD |
|---|---|
| `01_caller_audit/audit.ps1` (또는 `audit.sh`) 실행 | exit 0, 10개 카테고리 (A1-A10) 모두 결과 출력 |
| `01_caller_audit/EXPECTED_FINDINGS.md` 와 실제 결과 대조 | unexpected finding 없음 또는 모두 해결됨 |
| A1 (schema cast 'app') 발견 위치 | 모두 'urm' 으로 전환 또는 sbApp/sbUrm 분리 적용 |
| A2 (party_type 직접 참조) | 모두 PARTY_TYPE 상수 + JOIN 패턴으로 전환 |
| A3 (stage_position) | 모두 sort_order 로 rename |
| A4 (org_id) | 모두 organization_id (app), 또는 제거 (urm) |
| A5 (body_text) | 모두 body_plain 으로 rename |
| A6 (joined_at/left_at) | urm.contacts_history 참조는 started_at/ended_at 로 |
| A7 (supply_type/volume_tpy) | urm.party_supply_links 참조는 link_type/volume_estimate |
| A8 (9 deprecated profile) | 모두 제거 (V2 미지원, URM 원칙 위반) |
| A9 (organization_id in urm) | 모두 제거 (urm = single-tenant) |
| A10 ('fund'/'organization' 문자열) | 모두 제거 또는 PARTY_TYPE 상수로 |

---

## §2. Type Regeneration 완료

| 산출물 | DoD |
|---|---|
| `npx supabase gen types typescript ...` 실행 | `database.ts` 의 V1 (14,109 lines) 대체. urm schema 19 테이블 모두 포함 |
| 또는 fallback: `02_type_regeneration/urm_schema_typescript_stub.ts` import | tsc strict mode 통과 |
| TypeScript build (`tsc --noEmit`) | 0 errors. `Database['app']`, `Database['urm']` 모두 정의됨 |
| `Database['urm']['Tables']['parties']['Row']['party_type_id']` 타입 | `number` (not `string`/enum). FK to party_types |
| `Database['urm']['Tables']['stages']['Row']['sort_order']` 존재 | `stage_position` 부재 |

---

## §3. SbClient Cutover 완료

| 산출물 | DoD |
|---|---|
| `03_sbclient_cutover/SbClient_cutover_pattern.ts` 패턴 적용 | 2-tier: `sbApp` (Database, 'app') + `sbUrm` (Database, 'urm') |
| 운영 module 별 분리 적용 | parties/contacts/profile 류 → sbUrm; email/finance/RBAC → sbApp |
| Single-cast site 패턴 (handoff §A3 Gotcha #45) | 모든 caller 가 sbApp/sbUrm 중 정확히 1개 import |
| 잘못된 default schema 참조 0건 | grep `SupabaseClient<Database, 'app'>` 결과 = 의도된 sbApp 사용 위치만 |

---

## §4. Column Rename 완료

| Rename | 위치 | DoD |
|---|---|---|
| `org_id → organization_id` | app.email_whitelist / app.communications | codemod 적용 + tsc 0 error |
| `value → pattern` | app.email_whitelist | codemod 적용 |
| `body_text → body_plain` | app.communications | codemod 적용 |
| `country → country_code` | app.parties (사용 위치만) | codemod 적용 |
| `stage_position → sort_order` | urm.stages caller | codemod 적용 |
| `party_type → party_type_id + JOIN` | urm.parties caller | 수동 적용 (P1-P7 패턴) |
| `joined_at → started_at`, `left_at → ended_at` | urm.contacts_history caller | 수동 적용 + date cast |
| `supply_type → link_type` | urm.party_supply_links caller | 수동 적용 |
| `volume_tpy → volume_estimate` | urm.party_supply_links caller | 수동 적용 + text cast |

---

## §5. 런타임 검증 (E2E)

| 시나리오 | DoD |
|---|---|
| Login + organization 선택 | sbApp 정상 동작 |
| Parties 목록 조회 (urm.parties) | party_type_id JOIN → 한글 display_name 표시 |
| Investor 상세 페이지 (urm.investor_profile) | investor_portfolio_companies 422 row 노출 |
| Paper mill 목록 (urm.paper_mill_profile) | 1074 row 노출 |
| Filler supplier 목록 (urm.filler_supplier_profile) | 232 row 노출 |
| Contact 추가 (urm.contacts INSERT) | firm_party_id NOT NULL 검증 통과 |
| Contact history 자동 기록 (urm.contacts_history) | started_at date cast 정상 |
| Pipeline 신규 생성 (urm.pipelines INSERT) | 신규 row 정상 생성 (0 → 1) |
| Stage 신규 생성 (urm.stages INSERT) | sort_order 컬럼명 정상 |
| Deal 생성 → Task 생성 → Checklist 연결 | URM 흐름 (Pipeline-Stages-Deals-Tasks-Checklist) 정상 |
| Engagement 생성 + attendee 추가 | URM 흐름 (Engagement-attendees-documents) 정상 |
| Email parser ingestion (MailCarrier) | app.communications.body_plain 정상 INSERT |
| Email whitelist match | app.email_whitelist.pattern 정상 매칭 |

---

## §6. 비기능 검증

| 항목 | DoD |
|---|---|
| RLS policy 적용 | sbApp 의 모든 query 가 organization_id 필터링 (urm 은 single-tenant 이므로 RLS 면제 또는 별도 policy) |
| Supabase Auth flow | login/logout/session 영향 없음 |
| Audit log (audit schema) | parties/contacts CRUD 모두 audit log 발생 |
| 기존 testsuite | 0 regression (Stage 29-b 이전 통과한 test 모두 재통과) |
| TypeScript strict mode | 0 error |
| ESM/CJS 호환성 | 빌드 0 error |

---

## §7. URM 원칙 준수 검증

> **사용자 명시 원칙**: URM 구조에 맞지 않는 데이터는 삭제 OK.

| 원칙 | 검증 query | PASS 조건 |
|---|---|---|
| Pipeline → Stages | `identify_non_urm_data.sql` Q12 URM_FLOW_ORPHAN | stages.pipeline_id orphan = 0 |
| Stages → Deals | 동일 | deals.pipeline_id orphan = 0 |
| Deals → Tasks | 동일 | tasks.deal_id orphan = 0 |
| Deals → Deal_Checklists | 동일 | tasks.checklist_id orphan = 0 (또는 SET NULL) |
| Tasks → 모두 통합 | URM 단일 표 | OK |
| Engagements → attendees / documents | URM_FLOW_ORPHAN | 모두 orphan = 0 |
| Parties → Contacts (FK) | CONTACT_ORPHAN | firm_party_id orphan = 0 |
| Parties → Contacts → Contact_history | HISTORY_ORPHAN | contact_id / firm_party_id orphan = 0 |
| Parties → Filler_Suppliers_profile | PROFILE_ORPHAN | party_id orphan = 0 |
| Parties → Investor_profile | PROFILE_ORPHAN | party_id orphan = 0 |
| Parties → Paper_mill_profile | PROFILE_ORPHAN | party_id orphan = 0 |
| 7 정규 party_types 외 코드 부재 | PARTY_TYPE_VIOLATION | sample_count = 0 |
| fund / organization V2 잔재 부재 | APP_ENUM_REMNANT | 모두 0 |

> 위반 row 발견 시 → 사용자 원칙에 따라 **DELETE 후 재검증**.

---

## §8. Stage 29-d 준비 완료

| 항목 | DoD |
|---|---|
| `06_app_residual_cleanup/app_residual_audit.sql` 실행 결과 검토 | UNKNOWN 분류 0건, 모든 테이블 action 결정됨 |
| 1-2주 cooldown 시작일 기록 | (작업 일지에 기재) |
| Production traffic 모니터링 — app schema write 발생 여부 | sbApp 의 write 흐름 모두 의도된 것만 (parties/contacts 등에 write 없어야 함) |
| Stage 29-d 의 DROP 스크립트 사전 작성 | ALREADY_EMPTY_DROP → RESIDUAL_AUTODROP → DROP_AFTER_CUTOVER 순서로 SQL 준비 |
| RESTRICT FK 충돌 확인 | app.invoices/payments/sales_orders 의 0 row 재확인 |

---

## §9. 산출물 패키지

| 파일 | 위치 | 상태 |
|---|---|---|
| `STAGE_29C_PLAYBOOK.md` | `/stage29c/` | ✅ |
| `01_caller_audit/audit.ps1` | | ✅ |
| `01_caller_audit/audit.sh` | | ✅ |
| `01_caller_audit/EXPECTED_FINDINGS.md` | | ✅ |
| `02_type_regeneration/REGEN_TYPES.md` | | ✅ |
| `02_type_regeneration/urm_schema_typescript_stub.ts` | | ✅ |
| `03_sbclient_cutover/SBCLIENT_CUTOVER.md` | | ✅ |
| `03_sbclient_cutover/SbClient_cutover_pattern.ts` | | ✅ |
| `04_column_rename/RENAME_TABLE.md` | | ✅ |
| `04_column_rename/rename_codemod.ps1` | | ✅ |
| `04_column_rename/party_type_join_pattern.ts` | | ✅ |
| `05_urm_verification_sql/verify_urm_schema.sql` | | ✅ |
| `05_urm_verification_sql/verify_carry_forward_counts.sql` | | ✅ |
| `05_urm_verification_sql/identify_non_urm_data.sql` | | ✅ |
| `05_urm_verification_sql/check_party_type_mapping.sql` | | ✅ |
| `06_app_residual_cleanup/app_residual_audit.sql` | | ✅ |
| `07_completion/completion_criteria.md` | (this file) | ✅ |

---

## §10. 실행 순서 요약

```
[Stage 29-c 진입]
  ↓
G-0.* pre-flight (05/ SQL 4건 실행) → PASS
  ↓
§1 caller audit (01/audit.ps1) → A1-A10 발견
  ↓
§2 type regen (npx supabase gen types) → urm types 확보
  ↓
§3 SbClient cutover (sbApp + sbUrm 분리)
  ↓
§4 column rename (04/codemod + party_type 수동)
  ↓
§5 E2E 검증 (런타임 시나리오 13개)
  ↓
§6 비기능 검증 (RLS / Auth / audit / typecheck)
  ↓
§7 URM 원칙 재확인 (identify_non_urm_data.sql 재실행, 0 violation)
  ↓
§8 Stage 29-d 준비 (app_residual_audit.sql 검토, DROP 스크립트 작성)
  ↓
[Stage 29-c 종결] → 1-2주 cooldown
  ↓
[Stage 29-d 진입]
```

---

## §11. Sign-off

| 단계 | 일자 | 비고 |
|---|---|---|
| Stage 29-b 종결 | 2026-05-24 | handoff 작성 완료 |
| Stage 29-c 진입 | 2026-05-24 | caller audit 시작 |
| Stage 29-c 종결 | TBD | 모든 §0-§8 PASS 확인 후 |
| Stage 29-d 진입 | TBD | cooldown 종료 후 |

---

**작성**: Stage 29-c autonomous deliverables session, 2026-05-24
**근거 문서**: `SESSION_HANDOFF_2026-05-24_stage29b_complete.md`
**사용자 원칙**: "URM 기본원칙 준수. URM 구조에 맞지 않는 데이터는 삭제 OK."
```

### File: `02_type_regeneration\REGEN_TYPES.md`

```markdown
# Stage 29-c — Type Regeneration

## §1. 왜 필요한가

현재 `database.ts` 는 `ai`, `app`, `audit`, `public` 4 schema 만 포함. **`urm` schema 부재**. Stage 29-c cutover 가 진행되려면 `urm` 타입이 반드시 있어야 함.

## §2. 1순위: Supabase CLI 로 재생성

### 2-1. 사전 조건
- Supabase project ref / access token 보유
- npx 사용 가능

### 2-2. 명령 (PowerShell)

```powershell
# 환경 변수 설정 (기존 값 사용)
$env:SUPABASE_ACCESS_TOKEN = "sbp_xxx..."  # Supabase Dashboard > Account > Access Tokens

# project ref 확인 (Supabase Dashboard > Settings > General)
$projectRef = "your-project-ref"   # ex: "abcdefghijklmnop"

# 백업
Copy-Item src\lib\supabase\database.ts src\lib\supabase\database.ts.v1_backup -Force

# 재생성 (--schema 에 urm 반드시 포함)
npx supabase gen types typescript `
  --project-id $projectRef `
  --schema app,ai,audit,urm,public `
  | Out-File -FilePath src\lib\supabase\database.ts -Encoding UTF8
```

### 2-3. 검증

```powershell
# urm schema 가 들어왔는지 확인
Select-String -Path src\lib\supabase\database.ts -Pattern "^  urm: " | Format-List
# 1 개 이상 매치되어야 함

# urm 의 테이블 list 확인
Select-String -Path src\lib\supabase\database.ts -Pattern "^      [a-z_]+: \{$" `
  | Where-Object { $_.Context -match "urm:" } `
  | Measure-Object
# Stage 29-b 종결 시점의 urm 테이블 19 개 이상 (parties, contacts, contacts_history, investor_profile, paper_mill_profile, filler_supplier_profile, investor_portfolio_companies, party_supply_links, plant_supply_links, pipelines, stages, deals, deal_stage_history, deal_checklists, tasks, engagements, engagement_attendees, engagement_documents, party_types)
```

## §3. 2순위 (CLI fail 시): GraphQL endpoint 활용

`urm` schema 가 Supabase 의 GraphQL 노출 (Settings > API > Exposed schemas) 에 없으면 CLI 도 fail. 그 경우:

```powershell
# Dashboard 에서 추가
# Settings > API > "Exposed schemas" 에 "urm" 추가 + Save
# 그 후 §2-2 재실행
```

## §4. 3순위 (CLI 도 fail, GraphQL 도 fail): 수기 타입 fallback

`urm_schema_typescript_stub.ts` 사용. 이 파일은 Stage 29-b handoff §7 + §8 의 정보를 기반으로 수기 작성된 type stub. 완전하지 않을 수 있음 (모든 컬럼 커버 안 됨), 컴파일 통과만 보장.

### 사용법

```typescript
// src/lib/supabase/database.ts 가 V1 이라면, 별도 import:
import type { Database as DatabaseV1 } from "./database";
import type { UrmSchema } from "./urm_schema_typescript_stub";

// Merge type
export type Database = DatabaseV1 & {
  urm: UrmSchema;
};
```

이 패턴은 임시방편. 정식 재생성이 가능해지면 즉시 §2 로 전환.

## §5. 재생성 후 검증 SQL

재생성된 타입이 실제 DB 와 sync 인지 확인:

```sql
-- Supabase SQL Editor 에서 실행
SELECT
  table_schema,
  COUNT(*) AS table_count,
  string_agg(table_name, ', ' ORDER BY table_name) AS tables
FROM information_schema.tables
WHERE table_schema = 'urm'
  AND table_type = 'BASE TABLE'
GROUP BY table_schema;

-- 기대: 19 테이블 이상 (handoff §7 + §8 의 list)
```

다른 측면 검증:

```sql
-- urm.parties 의 컬럼 list
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'urm' AND table_name = 'parties'
ORDER BY ordinal_position;

-- 기대 컬럼: id, party_type_id (FK), name, name_normalized,
--           website, domain_normalized, country_code, ... (V2 컬럼)
-- 기대 부재: parent_party_id, party_level (3-tier DROP), party_type (직접 enum, FK 로 대체)
```

## §6. 재생성 실패 시 trouble shooting

| 증상 | 원인 | 해결 |
|---|---|---|
| `gen types` 가 빈 출력 | access token 만료 | Dashboard 에서 재발급 |
| urm schema 누락 | --schema 에 urm 미포함 | --schema 인자 확인 |
| urm schema 부분 누락 | RLS 로 select 권한 없음 | service role token 사용 |
| `column ... does not exist` 빌드 에러 | types 와 DB 비동기 | types 재생성 후 `tsc --noEmit` 재실행 |

## §7. 적용 후 git diff 확인

```powershell
git diff src\lib\supabase\database.ts | Out-File -FilePath stage29c_database_ts_diff.patch -Encoding UTF8
```

이 diff 가 cutover 의 actual scope. 검토 후 commit.
```

---

