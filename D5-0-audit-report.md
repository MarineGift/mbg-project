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

## 3. Subdirectory contents (small text files inlined)

### Subdir: `01_caller_audit`

#### `audit.ps1` (7826 bytes)

```powershell
# Stage 29-c Caller Code Audit Script (PowerShell)
# 사용법:
#   .\audit.ps1 -ProjectRoot . -OutFile .\stage29c_audit_report.md
#
# 산출: Markdown 보고서 (매치 site list, count, 컨텍스트 라인 포함)
# 의존: PowerShell 5.0+ (기본 Windows 10/11 탑재)

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectRoot,
    [string]$OutFile = ".\stage29c_audit_report.md",
    [string[]]$IncludeDirs = @("src", "app", "pages", "lib", "components", "hooks", "scripts", "workers"),
    [string[]]$ExcludeDirs = @("node_modules", ".next", "dist", "build", ".git", "coverage", "outputs", "stage29c")
)

$ErrorActionPreference = "Stop"
$projectRootFull = (Resolve-Path $ProjectRoot).Path

Write-Host "=== Stage 29-c Caller Audit ===" -ForegroundColor Cyan
Write-Host "Project root: $projectRootFull"
Write-Host "Output: $OutFile"
Write-Host ""

# --- helper: ripgrep 없으면 PowerShell Select-String fallback
function Find-Pattern {
    param(
        [string]$Pattern,
        [string]$Root,
        [string[]]$IncludeExts = @("*.ts", "*.tsx", "*.js", "*.jsx", "*.mts", "*.cts")
    )
    $excludeRegex = ($ExcludeDirs | ForEach-Object { [regex]::Escape($_) }) -join "|"
    Get-ChildItem -Path $Root -Recurse -Include $IncludeExts -ErrorAction SilentlyContinue |
        Where-Object { 
            $_.FullName -notmatch "[\\/]($excludeRegex)[\\/]" -and
            $_.FullName -notmatch "[\\/]($excludeRegex)$"
        } |
        Select-String -Pattern $Pattern -ErrorAction SilentlyContinue
}

# --- Audit categories
$audits = @(
    @{
        Name = "A1. SbClient factory 정의"
        Description = "SupabaseClient<Database, 'app'> 등 generic schema 정의 site"
        Patterns = @(
            "SupabaseClient<Database",
            "createClient<Database",
            "createServerClient<Database",
            "createBrowserClient<Database"
        )
        Critical = $true
    },
    @{
        Name = "A2. schema-prefixed .from() 호출"
        Description = ".from('app.*') 또는 .from('urm.*') 패턴"
        Patterns = @(
            "\.from\(['""]app\.",
            "\.from\(['""]urm\.",
            "\.schema\(['""]app['""]\)",
            "\.schema\(['""]urm['""]\)"
        )
        Critical = $true
    },
    @{
        Name = "A3. 잘못된 컬럼 reference (V1 bug)"
        Description = "DB 에 실재하지 않는 컬럼 이름. caller 의 hard-coded bug"
        Patterns = @(
            "\borg_id\b",
            "\bbody_text\b",
            "['""]country['""]",
            "\.country\s*[=,)]",
            "stage_position"
        )
        Critical = $true
    },
    @{
        Name = "A4. party_type 직접 enum 비교"
        Description = "urm 에서 party_type_id (FK) 로 바뀐 패턴. caller 가 .eq('party_type', 'company') 등 호출"
        Patterns = @(
            "\.eq\(['""]party_type['""]",
            "party_type\s*===",
            "party_type:\s*['""]",
            "PartyType\.",
            "party_type\s*[=:]\s*['""]"
        )
        Critical = $true
    },
    @{
        Name = "A5. RPC 호출 (rpc('...'))"
        Description = "Supabase RPC 호출. V1→V2 함수 매핑 검토"
        Patterns = @(
            "\.rpc\(['""][a-zA-Z_]+",
            "supabase\.rpc"
        )
        Critical = $false
    },
    @{
        Name = "A6. 9 deprecated profile 테이블 reference"
        Description = "Stage 29-b δ 에서 DROP 된 테이블. 남아있으면 빌드 fail"
        Patterns = @(
            "buyer_profile",
            "buyer_partner_profile",
            "customer_profile",
            "govt_grant_profile",
            "govt_grant_contact_profile",
            "partner_profile",
            "partner_audits",
            "partner_capabilities",
            "filler_supplier_contact_profile"
        )
        Critical = $true
    },
    @{
        Name = "A7. portfolio_companies (V1) reference"
        Description = "Stage 29-b δ Port-1 에서 DROP. urm.investor_portfolio_companies 로 이전"
        Patterns = @(
            "\bportfolio_companies\b",
            "v_portfolio_with_investors"
        )
        Critical = $true
    },
    @{
        Name = "A8. parent_party_id / party_level reference"
        Description = "3-tier hierarchy DROP 결정 (handoff §8). carry 안 함"
        Patterns = @(
            "parent_party_id",
            "\bparty_level\b"
        )
        Critical = $false
    },
    @{
        Name = "A9. urm 신규 테이블 references"
        Description = "이미 urm 으로 일부 이전된 코드 (있을 수 있음)"
        Patterns = @(
            "contacts_history",
            "party_supply_links",
            "plant_supply_links",
            "deal_checklists",
            "deal_stage_history",
            "engagement_attendees",
            "engagement_documents",
            "party_types"
        )
        Critical = $false
    },
    @{
        Name = "A10. fund / organization party_type 사용"
        Description = "Stage 29-b ε 에서 hard-delete. caller 가 참조 시 0 row"
        Patterns = @(
            "['""]fund['""]",
            "['""]organization['""]"
        )
        Critical = $false
    }
)

# --- 실행
$report = @()
$report += "# Stage 29-c Caller Audit Report"
$report += ""
$report += "**Project root**: ``$projectRootFull``"
$report += "**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += ""
$report += "---"
$report += ""

# Summary table 자리 (마지막에 채움)
$summaryRows = @()

foreach ($audit in $audits) {
    Write-Host "[$($audit.Name)] $($audit.Description)" -ForegroundColor Yellow
    
    $allMatches = @()
    foreach ($pat in $audit.Patterns) {
        $matches = Find-Pattern -Pattern $pat -Root $projectRootFull
        if ($matches) { $allMatches += $matches }
    }
    
    $count = $allMatches.Count
    $criticalMark = if ($audit.Critical) { "⚠️" } else { "ℹ️" }
    $summaryRows += "| $criticalMark | $($audit.Name) | $count |"
    
    $report += "## $($audit.Name)"
    $report += ""
    $report += "**Description**: $($audit.Description)"
    $report += "**Patterns**: ``$($audit.Patterns -join '`, `')``"
    $report += "**Match count**: **$count**"
    $report += ""
    
    if ($count -eq 0) {
        $report += "(매치 없음)"
        $report += ""
        Write-Host "  -> 0 matches" -ForegroundColor Green
    } else {
        Write-Host "  -> $count matches" -ForegroundColor Red
        $report += "| File | Line | Content |"
        $report += "|---|---:|---|"
        foreach ($m in ($allMatches | Sort-Object Filename, LineNumber)) {
            $relPath = $m.Path.Replace($projectRootFull, "").TrimStart("\", "/")
            $content = $m.Line.Trim() -replace '\|', '\|'
            if ($content.Length -gt 120) { $content = $content.Substring(0, 117) + "..." }
            $report += "| ``$relPath`` | $($m.LineNumber) | ``$content`` |"
        }
        $report += ""
    }
}

# --- summary 삽입
$summary = @()
$summary += "## §0. Summary (critical first)"
$summary += ""
$summary += "| Crit | Audit | Matches |"
$summary += "|---|---|---:|"
$summary += $summaryRows
$summary += ""
$summary += "---"
$summary += ""

# 최종 report 조립 (header + summary + details)
$finalReport = $report[0..3] + $summary + $report[4..($report.Count-1)]
$finalReport | Out-File -FilePath $OutFile -Encoding UTF8

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
Write-Host "Report written: $OutFile"
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
$summaryRows | ForEach-Object { Write-Host "  $_" }
```

#### `audit.sh` (5997 bytes)

```bash
#!/usr/bin/env bash
# Stage 29-c Caller Code Audit Script (Bash / WSL / Linux fallback)
# 사용법:
#   ./audit.sh <project-root> [output-file]
#
# 의존: ripgrep (rg). 없으면: grep -rE fallback.

set -euo pipefail

PROJECT_ROOT="${1:?Usage: $0 <project-root> [output-file]}"
OUT_FILE="${2:-./stage29c_audit_report.md}"
PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

EXCLUDE_DIRS=("node_modules" ".next" "dist" "build" ".git" "coverage" "outputs" "stage29c")
INCLUDE_EXTS=("ts" "tsx" "js" "jsx" "mts" "cts")

if command -v rg >/dev/null 2>&1; then
    USE_RG=1
else
    USE_RG=0
    echo "Warning: ripgrep (rg) not found, using grep fallback (slower)" >&2
fi

rg_exclude_args=()
for d in "${EXCLUDE_DIRS[@]}"; do
    rg_exclude_args+=("--glob" "!**/$d/**")
done

rg_include_args=()
for e in "${INCLUDE_EXTS[@]}"; do
    rg_include_args+=("--glob" "*.$e")
done

find_pattern() {
    local pat="$1"
    if [[ $USE_RG -eq 1 ]]; then
        rg --line-number --no-heading "${rg_exclude_args[@]}" "${rg_include_args[@]}" -e "$pat" "$PROJECT_ROOT" 2>/dev/null || true
    else
        local exclude_args=()
        for d in "${EXCLUDE_DIRS[@]}"; do
            exclude_args+=("--exclude-dir=$d")
        done
        local include_args=()
        for e in "${INCLUDE_EXTS[@]}"; do
            include_args+=("--include=*.$e")
        done
        grep -rEn "${exclude_args[@]}" "${include_args[@]}" "$pat" "$PROJECT_ROOT" 2>/dev/null || true
    fi
}

# --- audit definitions
declare -a AUDIT_NAMES=(
    "A1. SbClient factory 정의"
    "A2. schema-prefixed .from() 호출"
    "A3. 잘못된 컬럼 reference (V1 bug)"
    "A4. party_type 직접 enum 비교"
    "A5. RPC 호출"
    "A6. 9 deprecated profile 테이블 reference"
    "A7. portfolio_companies (V1) reference"
    "A8. parent_party_id / party_level reference"
    "A9. urm 신규 테이블 references"
    "A10. fund / organization party_type 사용"
)

declare -a AUDIT_DESCS=(
    "SupabaseClient<Database, 'app'> 등 generic schema 정의 site"
    ".from('app.*') 또는 .from('urm.*') 패턴"
    "DB 에 실재하지 않는 컬럼 이름. caller 의 hard-coded bug"
    "urm 에서 party_type_id (FK) 로 바뀐 패턴"
    "Supabase RPC 호출. V1→V2 함수 매핑 검토"
    "Stage 29-b δ 에서 DROP 된 테이블"
    "Stage 29-b δ Port-1 에서 DROP"
    "3-tier hierarchy DROP 결정. carry 안 함"
    "이미 urm 으로 일부 이전된 코드"
    "Stage 29-b ε 에서 hard-delete"
)

declare -a AUDIT_PATTERNS=(
    "SupabaseClient<Database|createClient<Database|createServerClient<Database|createBrowserClient<Database"
    "\.from\(['\"]app\.|\.from\(['\"]urm\.|\.schema\(['\"]app['\"]\)|\.schema\(['\"]urm['\"]\)"
    "\\borg_id\\b|\\bbody_text\\b|['\"]country['\"]|\.country[[:space:]]*[=,)]|stage_position"
    "\.eq\(['\"]party_type['\"]|party_type[[:space:]]*===|party_type:[[:space:]]*['\"]|PartyType\.|party_type[[:space:]]*[=:][[:space:]]*['\"]"
    "\.rpc\(['\"][a-zA-Z_]+|supabase\.rpc"
    "buyer_profile|buyer_partner_profile|customer_profile|govt_grant_profile|govt_grant_contact_profile|partner_profile|partner_audits|partner_capabilities|filler_supplier_contact_profile"
    "\\bportfolio_companies\\b|v_portfolio_with_investors"
    "parent_party_id|\\bparty_level\\b"
    "contacts_history|party_supply_links|plant_supply_links|deal_checklists|deal_stage_history|engagement_attendees|engagement_documents|party_types"
    "['\"]fund['\"]|['\"]organization['\"]"
)

declare -a AUDIT_CRITICAL=(1 1 1 1 0 1 1 0 0 0)

# --- run
mkdir -p "$(dirname "$OUT_FILE")"

{
    echo "# Stage 29-c Caller Audit Report"
    echo ""
    echo "**Project root**: \`$PROJECT_ROOT\`"
    echo "**Generated**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "---"
    echo ""
} > "$OUT_FILE"

# summary placeholder
{
    echo "## §0. Summary"
    echo ""
    echo "| Crit | Audit | Matches |"
    echo "|---|---|---:|"
} >> "$OUT_FILE.summary"

{
    echo "---"
    echo ""
} >> "$OUT_FILE.summary"

# detail body
detail_file="$OUT_FILE.details"
: > "$detail_file"

for i in "${!AUDIT_NAMES[@]}"; do
    name="${AUDIT_NAMES[$i]}"
    desc="${AUDIT_DESCS[$i]}"
    pat="${AUDIT_PATTERNS[$i]}"
    crit="${AUDIT_CRITICAL[$i]}"
    
    echo "[$name] $desc" >&2
    matches="$(find_pattern "$pat" || true)"
    count=$(echo -n "$matches" | grep -c "" || true)
    if [[ -z "$matches" ]]; then count=0; fi
    
    mark="ℹ️"
    if [[ $crit -eq 1 ]]; then mark="⚠️"; fi
    
    echo "| $mark | $name | $count |" >> "$OUT_FILE.summary.tmp"
    
    {
        echo "## $name"
        echo ""
        echo "**Description**: $desc"
        echo "**Pattern**: \`$pat\`"
        echo "**Match count**: **$count**"
        echo ""
        
        if [[ $count -eq 0 ]]; then
            echo "(매치 없음)"
        else
            echo "| File | Line | Content |"
            echo "|---|---:|---|"
            echo "$matches" | while IFS=: read -r file line content; do
                rel="${file#$PROJECT_ROOT/}"
                content="$(echo "$content" | sed 's/|/\\|/g' | head -c 120)"
                echo "| \`$rel\` | $line | \`$content\` |"
            done
        fi
        echo ""
    } >> "$detail_file"
    
    if [[ $count -eq 0 ]]; then
        echo "  -> 0 matches"
    else
        echo "  -> $count matches"
    fi
done

# 조립: header + summary + detail
{
    head -n 6 "$OUT_FILE"
    echo "## §0. Summary"
    echo ""
    echo "| Crit | Audit | Matches |"
    echo "|---|---|---:|"
    [[ -f "$OUT_FILE.summary.tmp" ]] && cat "$OUT_FILE.summary.tmp"
    echo ""
    echo "---"
    echo ""
    cat "$detail_file"
} > "$OUT_FILE.new"

mv "$OUT_FILE.new" "$OUT_FILE"
rm -f "$OUT_FILE.summary" "$OUT_FILE.summary.tmp" "$OUT_FILE.details"

echo ""
echo "=== Done ==="
echo "Report: $OUT_FILE"
```

#### `audit_FIXED.ps1` (8132 bytes)

```powershell
# Stage 29-c Caller Code Audit Script (PowerShell) — FIXED
# 사용법:
#   .\audit_FIXED.ps1                              # 현재 디렉토리 audit, 기본 출력
#   .\audit_FIXED.ps1 -ProjectRoot . -OutFile .\report.md
#
# 산출: Markdown 보고서 (매치 site list, count, 컨텍스트 라인 포함)
# 의존: PowerShell 5.0+ (기본 Windows 10/11 탑재)

param(
    [string]$ProjectRoot = ".",
    [string]$OutFile = ".\stage29c_audit_report.md",
    [string[]]$ExcludeDirs = @("node_modules", ".next", "dist", "build", ".git", "coverage", "outputs", "stage29c")
)

$ErrorActionPreference = "Stop"
$projectRootFull = (Resolve-Path $ProjectRoot).Path

Write-Host "=== Stage 29-c Caller Audit ===" -ForegroundColor Cyan
Write-Host "Project root: $projectRootFull"
Write-Host "Output: $OutFile"
Write-Host ""

# --- helper: PowerShell Select-String 으로 패턴 검색
function Find-Pattern {
    param(
        [string]$Pattern,
        [string]$Root,
        [string[]]$IncludeExts = @("*.ts", "*.tsx", "*.js", "*.jsx", "*.mts", "*.cts")
    )
    $excludeRegex = ($ExcludeDirs | ForEach-Object { [regex]::Escape($_) }) -join "|"
    Get-ChildItem -Path $Root -Recurse -Include $IncludeExts -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch "[\\/]($excludeRegex)[\\/]" -and
            $_.FullName -notmatch "[\\/]($excludeRegex)$"
        } |
        Select-String -Pattern $Pattern -ErrorAction SilentlyContinue
}

# --- Audit categories (모든 regex 패턴 single-quoted 으로 안전 처리)
$audits = @(
    @{
        Name        = 'A1. SbClient factory 정의'
        Description = "SupabaseClient<Database, 'app'> generic schema 정의 site"
        Patterns    = @(
            'SupabaseClient<Database',
            'createClient<Database',
            'createServerClient<Database',
            'createBrowserClient<Database'
        )
        Critical    = $true
    },
    @{
        Name        = 'A2. schema-prefixed .from() 호출'
        Description = '.from("app.*") 또는 .from("urm.*") 패턴'
        Patterns    = @(
            '\.from\([''"]app\.',
            '\.from\([''"]urm\.',
            '\.schema\([''"](app|urm)[''"]\)'
        )
        Critical    = $true
    },
    @{
        Name        = 'A3. 잘못된 컬럼 reference (V1 bug)'
        Description = 'DB 에 실재하지 않는 컬럼 이름. caller 의 hard-coded bug'
        Patterns    = @(
            '\borg_id\b',
            '\bbody_text\b',
            '[''"]country[''"]',
            '\.country\s*[=,)]',
            'stage_position'
        )
        Critical    = $true
    },
    @{
        Name        = 'A4. party_type 직접 enum 비교'
        Description = 'urm 에서 party_type_id (FK) 로 바뀐 패턴. JOIN 패턴 필요'
        Patterns    = @(
            '\.eq\([''"]party_type[''"]',
            'party_type\s*===',
            'party_type:\s*[''"]',
            'PartyType\.',
            'party_type\s*[=:]\s*[''"]'
        )
        Critical    = $true
    },
    @{
        Name        = 'A5. RPC 호출'
        Description = 'Supabase RPC 호출. V1→V2 함수 매핑 검토'
        Patterns    = @(
            '\.rpc\([''"][a-zA-Z_]+',
            'supabase\.rpc'
        )
        Critical    = $false
    },
    @{
        Name        = 'A6. 9 deprecated profile 테이블 reference'
        Description = 'Stage 29-b δ 에서 DROP 된 테이블. 남아있으면 빌드 fail'
        Patterns    = @(
            'buyer_profile',
            'buyer_partner_profile',
            'customer_profile',
            'govt_grant_profile',
            'govt_grant_contact_profile',
            'partner_profile',
            'partner_audits',
            'partner_capabilities',
            'filler_supplier_contact_profile'
        )
        Critical    = $true
    },
    @{
        Name        = 'A7. portfolio_companies (V1) reference'
        Description = 'Stage 29-b δ Port-1 에서 DROP. urm.investor_portfolio_companies 로 이전'
        Patterns    = @(
            '\bportfolio_companies\b',
            'v_portfolio_with_investors'
        )
        Critical    = $true
    },
    @{
        Name        = 'A8. parent_party_id / party_level reference'
        Description = '3-tier hierarchy DROP 결정 (handoff §8). carry 안 함'
        Patterns    = @(
            'parent_party_id',
            '\bparty_level\b'
        )
        Critical    = $false
    },
    @{
        Name        = 'A9. urm 신규 테이블 references'
        Description = '이미 urm 으로 일부 이전된 코드'
        Patterns    = @(
            'contacts_history',
            'party_supply_links',
            'plant_supply_links',
            'deal_checklists',
            'deal_stage_history',
            'engagement_attendees',
            'engagement_documents',
            'party_types'
        )
        Critical    = $false
    },
    @{
        Name        = 'A10. fund / organization party_type 사용'
        Description = 'Stage 29-b ε 에서 hard-delete. caller 가 참조 시 0 row'
        Patterns    = @(
            '[''"]fund[''"]',
            '[''"]organization[''"]'
        )
        Critical    = $false
    }
)

# --- 실행
$report = New-Object System.Collections.Generic.List[string]
$report.Add('# Stage 29-c Caller Audit Report')
$report.Add('')
$report.Add(('**Project root**: `' + $projectRootFull + '`'))
$report.Add(('**Generated**: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
$report.Add('')
$report.Add('---')
$report.Add('')

$summaryRows = New-Object System.Collections.Generic.List[string]
$detailReport = New-Object System.Collections.Generic.List[string]

foreach ($audit in $audits) {
    Write-Host ('[' + $audit.Name + '] ' + $audit.Description) -ForegroundColor Yellow

    $allMatches = @()
    foreach ($pat in $audit.Patterns) {
        $foundMatches = Find-Pattern -Pattern $pat -Root $projectRootFull
        if ($foundMatches) { $allMatches += $foundMatches }
    }

    $count = $allMatches.Count
    $criticalMark = if ($audit.Critical) { '[!]' } else { '[i]' }
    $summaryRows.Add(('| ' + $criticalMark + ' | ' + $audit.Name + ' | ' + $count + ' |'))

    $detailReport.Add(('## ' + $audit.Name))
    $detailReport.Add('')
    $detailReport.Add(('**Description**: ' + $audit.Description))
    $detailReport.Add(('**Patterns**: `' + ($audit.Patterns -join '`, `') + '`'))
    $detailReport.Add(('**Match count**: **' + $count + '**'))
    $detailReport.Add('')

    if ($count -eq 0) {
        $detailReport.Add('(매치 없음)')
        $detailReport.Add('')
        Write-Host '  -> 0 matches' -ForegroundColor Green
    }
    else {
        Write-Host ('  -> ' + $count + ' matches') -ForegroundColor Red
        $detailReport.Add('| File | Line | Content |')
        $detailReport.Add('|---|---:|---|')
        foreach ($m in ($allMatches | Sort-Object Filename, LineNumber)) {
            $relPath = $m.Path.Replace($projectRootFull, '').TrimStart('\', '/')
            $content = $m.Line.Trim() -replace '\|', '\|'
            if ($content.Length -gt 120) { $content = $content.Substring(0, 117) + '...' }
            $detailReport.Add(('| `' + $relPath + '` | ' + $m.LineNumber + ' | `' + $content + '` |'))
        }
        $detailReport.Add('')
    }
}

# --- 최종 보고서 조립
$report.Add('## §0. Summary (critical first)')
$report.Add('')
$report.Add('| Crit | Audit | Matches |')
$report.Add('|---|---|---:|')
foreach ($r in $summaryRows) { $report.Add($r) }
$report.Add('')
$report.Add('---')
$report.Add('')
foreach ($r in $detailReport) { $report.Add($r) }

$report | Out-File -FilePath $OutFile -Encoding UTF8

Write-Host ''
Write-Host '=== Done ===' -ForegroundColor Cyan
Write-Host ('Report written: ' + $OutFile)
Write-Host ''
Write-Host 'Summary:' -ForegroundColor Yellow
foreach ($r in $summaryRows) { Write-Host ('  ' + $r) }
```

#### `audit_v3.ps1` (6217 bytes)

```powershell
# Stage 29-c Caller Code Audit (PowerShell, robust v3)
# All regex patterns single-quoted; quotes use \x27 / \x22 hex escapes.

param(
    [string]$ProjectRoot = ".",
    [string]$OutFile = ".\stage29c_audit_report.md"
)

$ErrorActionPreference = "Stop"
$ExcludeDirs = @("node_modules", ".next", "dist", "build", ".git", "coverage", "outputs", "stage29c")

$projectRootFull = (Resolve-Path $ProjectRoot).Path
Write-Host "=== Stage 29-c Caller Audit v3 ===" -ForegroundColor Cyan
Write-Host ("Project root: " + $projectRootFull)
Write-Host ("Output: " + $OutFile)
Write-Host ""

function Find-Pattern {
    param([string]$Pattern, [string]$Root)
    $exts = @("*.ts", "*.tsx", "*.js", "*.jsx", "*.mts", "*.cts")
    $excludeRegex = "node_modules|\.next|dist|build|\.git|coverage|outputs|stage29c"
    Get-ChildItem -Path $Root -Recurse -Include $exts -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch $excludeRegex } |
        Select-String -Pattern $Pattern -ErrorAction SilentlyContinue
}

# Audit categories. ALL patterns are single-quoted regex.
# Quote chars in regex use \x27 (apostrophe) and \x22 (double-quote) — no quote nesting needed.
$audits = @(
    @{ Name = 'A1. SbClient factory'; Critical = $true; Patterns = @(
        'SupabaseClient<Database',
        'createClient<Database',
        'createServerClient<Database',
        'createBrowserClient<Database'
    )},
    @{ Name = 'A2. schema-prefixed .from()'; Critical = $true; Patterns = @(
        '\.from\([\x27\x22]app\.',
        '\.from\([\x27\x22]urm\.',
        '\.schema\([\x27\x22](app|urm)[\x27\x22]\)'
    )},
    @{ Name = 'A3. wrong column refs (V1 bug)'; Critical = $true; Patterns = @(
        '\borg_id\b',
        '\bbody_text\b',
        '[\x27\x22]country[\x27\x22]',
        '\.country\s*[=,)]',
        'stage_position'
    )},
    @{ Name = 'A4. party_type direct enum'; Critical = $true; Patterns = @(
        '\.eq\([\x27\x22]party_type[\x27\x22]',
        'party_type\s*===',
        'party_type:\s*[\x27\x22]',
        'PartyType\.',
        'party_type\s*[=:]\s*[\x27\x22]'
    )},
    @{ Name = 'A5. RPC calls'; Critical = $false; Patterns = @(
        '\.rpc\([\x27\x22][a-zA-Z_]+',
        'supabase\.rpc'
    )},
    @{ Name = 'A6. 9 deprecated profile refs'; Critical = $true; Patterns = @(
        'buyer_profile',
        'buyer_partner_profile',
        'customer_profile',
        'govt_grant_profile',
        'govt_grant_contact_profile',
        'partner_profile',
        'partner_audits',
        'partner_capabilities',
        'filler_supplier_contact_profile'
    )},
    @{ Name = 'A7. portfolio_companies V1 refs'; Critical = $true; Patterns = @(
        '\bportfolio_companies\b',
        'v_portfolio_with_investors'
    )},
    @{ Name = 'A8. parent_party_id / party_level'; Critical = $false; Patterns = @(
        'parent_party_id',
        '\bparty_level\b'
    )},
    @{ Name = 'A9. urm new table refs'; Critical = $false; Patterns = @(
        'contacts_history',
        'party_supply_links',
        'plant_supply_links',
        'deal_checklists',
        'deal_stage_history',
        'engagement_attendees',
        'engagement_documents',
        'party_types'
    )},
    @{ Name = 'A10. fund / organization literals'; Critical = $false; Patterns = @(
        '[\x27\x22]fund[\x27\x22]',
        '[\x27\x22]organization[\x27\x22]'
    )}
)

$report = New-Object System.Collections.Generic.List[string]
$report.Add('# Stage 29-c Caller Audit Report')
$report.Add('')
$report.Add('**Project root**: `' + $projectRootFull + '`')
$report.Add('**Generated**: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$report.Add('')
$report.Add('---')
$report.Add('')

$summaryRows = New-Object System.Collections.Generic.List[string]
$detail = New-Object System.Collections.Generic.List[string]

foreach ($audit in $audits) {
    Write-Host ('[' + $audit.Name + ']') -ForegroundColor Yellow
    $allMatches = @()
    foreach ($pat in $audit.Patterns) {
        $found = Find-Pattern -Pattern $pat -Root $projectRootFull
        if ($found) { $allMatches += $found }
    }
    $count = $allMatches.Count
    $mark = if ($audit.Critical) { '[!]' } else { '[i]' }
    $summaryRows.Add('| ' + $mark + ' | ' + $audit.Name + ' | ' + $count + ' |')

    $detail.Add('## ' + $audit.Name)
    $detail.Add('')
    $detail.Add('**Patterns**: `' + ($audit.Patterns -join '`, `') + '`')
    $detail.Add('**Match count**: **' + $count + '**')
    $detail.Add('')

    if ($count -eq 0) {
        $detail.Add('(no matches)')
        $detail.Add('')
        Write-Host '  -> 0 matches' -ForegroundColor Green
    } else {
        Write-Host ('  -> ' + $count + ' matches') -ForegroundColor Red
        $detail.Add('| File | Line | Content |')
        $detail.Add('|---|---:|---|')
        foreach ($m in ($allMatches | Sort-Object Filename, LineNumber)) {
            $relPath = $m.Path.Replace($projectRootFull, '').TrimStart('\', '/')
            $content = $m.Line.Trim() -replace '\|', '\|'
            if ($content.Length -gt 120) { $content = $content.Substring(0, 117) + '...' }
            $detail.Add('| `' + $relPath + '` | ' + $m.LineNumber + ' | `' + $content + '` |')
        }
        $detail.Add('')
    }
}

$report.Add('## Summary')
$report.Add('')
$report.Add('| Crit | Audit | Matches |')
$report.Add('|---|---|---:|')
foreach ($r in $summaryRows) { $report.Add($r) }
$report.Add('')
$report.Add('---')
$report.Add('')
foreach ($d in $detail) { $report.Add($d) }

# Write file as UTF-8 with BOM (Windows PowerShell 5.x friendly), CRLF line endings
$content = ($report -join "`r`n")
$utf8BomEnc = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath (Split-Path $OutFile -Parent)).Path + '\' + (Split-Path $OutFile -Leaf), $content, $utf8BomEnc)

Write-Host ''
Write-Host '=== Done ===' -ForegroundColor Cyan
Write-Host ('Report: ' + $OutFile)
Write-Host ''
Write-Host 'Summary:' -ForegroundColor Yellow
foreach ($r in $summaryRows) { Write-Host ('  ' + $r) }
```

#### `EXPECTED_FINDINGS.md` (7758 bytes)

```markdown
# Stage 29-c Caller Audit — Expected Findings

audit 결과 해석 가이드. 각 카테고리별로 "정상 / 주의 / 위험" 기준.

---

## A1. SbClient factory 정의 — **CRITICAL**

**기대**: 1–3 개 매치 (`src/lib/supabase/server.ts`, `client.ts`, `service.ts` 등)

| 결과 | 해석 |
|---|---|
| 0 매치 | ⚠️ SbClient 정의 site 못 찾음. `Database` 타입 import 경로 다를 가능성. `Database` 만으로 다시 grep. |
| 1–3 매치 | ✅ 정상. 03_sbclient_cutover 적용 대상 |
| 4+ 매치 | ℹ️ 다수 site. 모두 일관되게 cutover 필요 |

**조치**: 매치된 site 모두 `<Database, 'app'>` 또는 비-generic 확인 후 `03_sbclient_cutover/SbClient_cutover_pattern.ts` 적용.

---

## A2. schema-prefixed .from() 호출 — **CRITICAL**

**기대**: 0 매치 (Supabase JS client 는 `.from('table')` 만 받음, schema prefix 안 됨)

| 결과 | 해석 |
|---|---|
| 0 매치 | ✅ 정상. schema 는 client default 로 처리 |
| 1+ 매치 | 🚨 **잘못된 호출**. Supabase 는 `.from('table_name')` 만 받음. `.from('app.parties')` 같은 호출은 fail. 즉시 수정. 정상 패턴은 `client.schema('urm').from('parties')` 또는 default schema cast. |

**조치**: 매치된 호출 분해. 

---

## A3. 잘못된 컬럼 reference (V1 bug) — **CRITICAL**

검색 컬럼: `org_id`, `body_text`, `country` (literal 또는 `.country`), `stage_position`

| 매치 | 실제 DB 컬럼 | 위치 | 조치 |
|---|---|---|---|
| `org_id` | `organization_id` | app.* 모든 테이블 | 단순 rename |
| `body_text` | `body_plain` | app.communications | 단순 rename |
| `'country'` literal | `'country_code'` | app.parties | 단순 rename |
| `.country` accessor | `.country_code` | 동상 | 단순 rename |
| `stage_position` | `sort_order` | urm.stages | 단순 rename (cutover 후) |

**기대**: 0 매치가 이상적. 1+ 매치 시 **runtime fail bug** — 즉시 수정.

**False positive 주의**: 
- `'country'` 가 외부 API 응답 파싱 코드에 있으면 그건 정상 (외부 표준 ISO 필드). DB 호출 컨텍스트인지 확인.
- `body_text` 가 외부 API response 필드면 정상.
- `org_id` 는 외부 서비스 API 컨텍스트일 수 있음.

→ 모든 매치 line 의 컨텍스트 확인 후 결정.

---

## A4. party_type 직접 enum 비교 — **CRITICAL**

**기대**: 매치는 있을 것 (app.parties 는 enum 컬럼 직접 사용). 단, **urm.parties cutover 후엔 변경 필요**.

### 패턴별 대응

| 패턴 | 의미 | 조치 (urm cutover 후) |
|---|---|---|
| `.eq('party_type', 'company')` | filter | `party_type_id` (FK) 로 변경 + JOIN 또는 hardcoded UUID |
| `party_type === 'fund'` | TS 비교 | type 자체가 사라짐 (urm 측). 대안: `party_type_code === 'investor'` |
| `party_type: 'paper_mill'` | object literal | INSERT 시 `party_type_id` 로 변경 |
| `PartyType.Fund` | enum import | 새 union `PartyTypeCode` 로 |

**상세 패턴**: `04_column_rename/party_type_join_pattern.ts` 참조.

---

## A5. RPC 호출 — **NON-CRITICAL**

**기대**: 매치 있음 (RPC wrapper `typed-rpc.ts` 가 다수 호출).

| 결과 | 해석 |
|---|---|
| 0 매치 | ✅ RPC 미사용 (PostgREST + .from 만) |
| 1–10 매치 | ℹ️ 일반. RPC 함수의 V1→V2 시그니처 변경 여부 개별 확인 |
| 10+ 매치 | ⚠️ RPC heavy. 함수 list 추출 후 DB 측 `public.*` 함수와 대조 |

**조치**: 매치된 RPC name list 만들고, 각 함수가 V2 schema 와 호환되는지 SQL 측 검증 (`pg_proc` query).

---

## A6. 9 deprecated profile 테이블 reference — **CRITICAL**

테이블: `buyer_profile`, `buyer_partner_profile`, `customer_profile`, `govt_grant_profile`, `govt_grant_contact_profile`, `partner_profile`, `partner_audits`, `partner_capabilities`, `filler_supplier_contact_profile`

**기대**: **0 매치**. 모두 Stage 29-b δ 에서 DROP 됨.

| 결과 | 해석 |
|---|---|
| 0 매치 | ✅ 정상 |
| 1+ 매치 | 🚨 **runtime fail**. 빌드 시점에 type error 발생할 수도 있음 (database.ts 재생성 후). 즉시 제거 또는 urm 측 대체 테이블로 변경 |

**대체 매핑** (있다면):
- `buyer_profile` → ❌ urm 측 부재 (handoff §6 #5: party_types 에 buyer 만 있음, profile 테이블 없음)
- `customer_profile` → ❌ 동상
- `partner_profile` / `partner_audits` / `partner_capabilities` → ❌
- `govt_grant_profile` / `govt_grant_contact_profile` → ❌
- `buyer_partner_profile` → ❌
- `filler_supplier_contact_profile` → ❌ (단 `urm.filler_supplier_profile` 은 별개)

→ 이 9 테이블에 의존하던 caller 는 **삭제 또는 URM 측 대체 logic 으로 재작성**. 사용자가 URM 원칙 명시: "URM 구조에 맞지 않는 데이터는 삭제를 해도 된다".

---

## A7. portfolio_companies (V1) reference — **CRITICAL**

**기대**: 0 매치. 422 row 가 urm.investor_portfolio_companies 로 이전 + V1 테이블 DROP.

| 결과 | 해석 |
|---|---|
| 0 매치 | ✅ 정상 |
| 1+ 매치 | 🚨 V1 reference 잔존. `urm.investor_portfolio_companies` 로 cutover. **컬럼 매핑**: `portfolio_company_id` (V1) → `module_data._app_portfolio_company_id` (V2 jsonb) + `portfolio_company_name_normalized` (V2 신규 컬럼) |

---

## A8. parent_party_id / party_level reference — **NON-CRITICAL**

**기대**: 매치는 있을 수 있음 (V1 carry 코드). Stage 29-d 까지 app.* 에 컬럼 carry.

| 결과 | 해석 |
|---|---|
| 0 매치 | ✅ 깔끔. 3-tier hierarchy 안 씀 |
| 1+ 매치 | ℹ️ V1 logic 잔존. urm 에는 컬럼 자체가 없음 (handoff §8 "3-tier hierarchy DROP"). 해당 caller 의 의도 확인 후 (a) 제거 또는 (b) app.* 로 격리 (Stage 29-d 시 함께 drop) |

---

## A9. urm 신규 테이블 references — **INFO**

**기대**: 매치 0 또는 소량. Stage 29-c 가 첫 번째 caller cutover.

| 매치 테이블 | 의미 |
|---|---|
| `contacts_history` | γ 신설 (118 row). caller 이미 작성됐을 수 있음 |
| `party_supply_links` | γ 신설 (117 row) |
| `plant_supply_links` | γ 신설 (0 row, skip) |
| `deal_checklists` | stage29a 신설 |
| `deal_stage_history` | stage29a 신설 |
| `engagement_attendees` | V2 신설 컨셉 |
| `engagement_documents` | V2 신설 컨셉 |
| `party_types` | lookup (7 row) |

**조치**: 이미 작성된 caller 가 있으면 cutover 일관성 확인.

---

## A10. fund / organization party_type 사용 — **INFO**

**기대**: 매치 있을 수 있음 (V1 enum 가 5값).

| 결과 | 해석 |
|---|---|
| 0 매치 | ✅ 깔끔 |
| 1+ 매치 | ℹ️ urm.parties 에는 fund/organization 0 row (ε hard-delete). caller 가 검색해도 빈 결과. 코드 단순화 후보 (logic 자체 제거 가능) |

---

## 종합 판정

### 0. App residual은 Stage 29-d 까지 carry

A3, A6, A7, A8 의 V1 잔존 reference 가 모두 0 이면 Stage 29-c 의 가장 큰 위험 (runtime fail) 제거됨.

### 1. urm cutover scope 결정

A4 (party_type) 의 매치 수 = cutover 작업량 의 일차 추정치. 매치가 50+ 면 SbClient 2-tier (sbApp + sbUrm) 패턴 권장.

### 2. RPC re-audit 필요 여부

A5 의 RPC name list 추출 → V2 schema 와 호환 검증. RPC wrapper (`typed-rpc.ts`) 의 시그니처도 함께.

### 3. 다음 step trigger

```
A1 매치 >= 1  →  03_sbclient_cutover 진행
A3 매치 = 0   →  04_column_rename 의 V1 bug 부분 skip
A4 매치 >= 1  →  04_column_rename 의 party_type JOIN 패턴 진행
A6 매치 = 0   →  Stage 29-d 의 9 테이블 drop 안전
A7 매치 = 0   →  portfolio cutover 종결
```
```

### Subdir: `02_type_regeneration`

#### `REGEN_TYPES.md` (4438 bytes)

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

#### `urm_schema_typescript_stub.ts` (23016 bytes)

```typescript
/**
 * urm schema TypeScript stub
 *
 * 출처: SESSION_HANDOFF_2026-05-24_stage29b_complete.md
 * 작성: Stage 29-c 진입 시점 (2026-05-24)
 *
 * 용도: `npx supabase gen types` 가 urm schema 를 못 잡을 때의 fallback.
 *       이 파일은 handoff §7, §8 의 정보만으로 작성. 모든 컬럼이 완벽히 정확하진 않음.
 *       정식 gen types 가 가능해지면 즉시 deprecate.
 *
 * 사용 패턴:
 *   import type { Database as V1Database } from "./database";
 *   import type { UrmSchema } from "./urm_schema_typescript_stub";
 *
 *   export type Database = V1Database & { urm: UrmSchema };
 *
 *   // SbClient
 *   const sbUrm = createClient(url, key, { db: { schema: "urm" } }) as
 *     SupabaseClient<Database, "urm">;
 */

import type { Json } from "./database"; // V1 의 Json 타입 재사용

// ============================================================================
// Enums (urm-side)
// ============================================================================

// handoff §6 #5: 7 party_types codes (lookup row 값)
export type UrmPartyTypeCode =
  | "investor"
  | "paper_mill"
  | "filler_supplier"
  | "buyer"
  | "customer"
  | "partner"
  | "government_grant";

// γ 의 supply_type→link_type cast 결과 (handoff §8 매핑 logic)
export type UrmSupplyLinkType =
  | "potential"
  | "active"
  | "historical";

// 추정 — 실제 DB 에서 확인 필요
export type UrmContactSeniority = string; // text (γ 에서 enum→text cast)

// ============================================================================
// urm.party_types (lookup)
// ============================================================================

export interface UrmPartyType {
  id: number;             // 1..7
  code: UrmPartyTypeCode;
  display_name_ko: string;
  display_name_en?: string | null;
  sort_order?: number | null;
}

// ============================================================================
// urm.parties (1532 active, handoff §7)
// ============================================================================

export interface UrmPartyRow {
  id: string;                              // uuid (V1 id 보존)
  party_type_id: number;                   // FK to urm.party_types (handoff §6 #2)
  name: string;
  name_normalized: string | null;
  legal_name: string | null;
  website: string | null;
  domain_normalized: string | null;
  country_code: string | null;             // handoff §A4: country → country_code
  city: string | null;
  region: string | null;
  timezone: string | null;
  phone_e164: string | null;
  phone_normalized: string | null;
  linkedin_url: string | null;
  industry_tags: string[];
  interest_tags: string[];
  employee_count: number | null;
  annual_revenue_usd: number | null;
  founded_year: number | null;
  tier: string | null;                     // text (urm) — V2 enum 여부 불명
  status: string;                          // text (active/inactive/...)
  relationship_score: number | null;
  notes: string | null;
  source: string | null;
  source_external_id: string | null;
  module_data: Json;                       // _app_* prefix 로 V1 데이터 보존
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
  deleted_at: string | null;
  // 부재 (handoff §8 "3-tier hierarchy DROP"):
  // - parent_party_id, party_level
  // 부재 (urm single-tenant, handoff §8):
  // - organization_id
}

export interface UrmPartyInsert extends Partial<UrmPartyRow> {
  party_type_id: number;
  name: string;
}

export type UrmPartyUpdate = Partial<UrmPartyRow>;

// ============================================================================
// urm.contacts (217 active, handoff §7)
// ============================================================================

export interface UrmContactRow {
  id: string;                              // uuid (V1 id 보존)
  firm_party_id: string;                   // FK to urm.parties — NOT NULL (handoff §6 #4)
  full_name: string;
  given_name: string | null;
  family_name: string | null;
  email: string | null;
  email_secondary: string | null;
  phone: string | null;
  phone_mobile: string | null;
  title: string | null;
  department: string | null;
  seniority_level: UrmContactSeniority | null;  // text (γ cast)
  linkedin_url: string | null;
  preferred_language: string | null;
  timezone: string | null;
  is_primary: boolean;                     // stage29a 신설 (handoff §6 #7), default false
  is_decision_maker: boolean | null;       // module_data._app_is_decision_maker 로 보존된 케이스도
  do_not_contact: boolean;
  do_not_contact_reason: string | null;
  notes: string | null;
  module_data: Json;                       // _app_* prefix 로 V1 데이터 보존
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
  deleted_at: string | null;
}

export interface UrmContactInsert extends Partial<UrmContactRow> {
  firm_party_id: string;
  full_name: string;
}

export type UrmContactUpdate = Partial<UrmContactRow>;

// ============================================================================
// urm.contacts_history (109 row, handoff §7 - γ INSERT 118 - ε DELETE 9)
// ============================================================================

export interface UrmContactsHistoryRow {
  id: string;                              // uuid
  contact_id: string;                      // FK to urm.contacts (V1 person_party_id rename, γ)
  firm_party_id: string;                   // FK to urm.parties (V1 firm_party_id 보존)
  role_title: string | null;
  started_at: string | null;               // date (V1 joined_at::date)
  ended_at: string | null;                 // date (V1 left_at::date)
  is_current: boolean;
  notes: string | null;
  module_data: Json;
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
}

export interface UrmContactsHistoryInsert extends Partial<UrmContactsHistoryRow> {
  contact_id: string;
  firm_party_id: string;
}

export type UrmContactsHistoryUpdate = Partial<UrmContactsHistoryRow>;

// ============================================================================
// urm.party_supply_links (117 row, handoff §7)
// ============================================================================

export interface UrmPartySupplyLinkRow {
  id: string;                              // uuid
  supplier_party_id: string;               // FK to urm.parties
  buyer_party_id: string;                  // FK to urm.parties
  link_type: UrmSupplyLinkType;            // text (V1 supply_type::text cast)
  product_grade: string | null;
  volume_estimate: string | null;          // text (V1 volume_tpy + ' tpy')
  contracted_at: string | null;
  contract_end_at: string | null;
  confidence_grade: string | null;
  source: string | null;
  notes: string | null;
  module_data: Json;
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
}

export interface UrmPartySupplyLinkInsert extends Partial<UrmPartySupplyLinkRow> {
  supplier_party_id: string;
  buyer_party_id: string;
  link_type: UrmSupplyLinkType;
}

export type UrmPartySupplyLinkUpdate = Partial<UrmPartySupplyLinkRow>;

// ============================================================================
// urm.plant_supply_links (0 row, handoff §7 skip)
// ============================================================================

export interface UrmPlantSupplyLinkRow {
  id: string;
  plant_party_id: string;
  supplier_party_id: string;
  link_type: UrmSupplyLinkType;
  product_grade: string | null;
  volume_estimate: string | null;
  contracted_at: string | null;
  contract_end_at: string | null;
  confidence_grade: string | null;
  source: string | null;
  notes: string | null;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.investor_profile (101 row, handoff §7 - 106 - 5 fund)
// ============================================================================

export interface UrmInvestorProfileRow {
  id: string;
  party_id: string;                        // FK to urm.parties (1:1)
  fund_type: string | null;
  stage_focus: string[];
  sector_focus: string[];
  geo_focus: string[];
  aum_usd: number | null;
  fund_size_usd: number | null;
  ticket_size_min: number | null;
  ticket_size_max: number | null;
  notes: string | null;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.paper_mill_profile (1074 row, handoff §7 - 변동 없음)
// ============================================================================

export interface UrmPaperMillProfileRow {
  id: string;
  party_id: string;
  mill_capacity_tpy: number | null;
  grades_produced: string[];
  segments: string[];                      // P&W / Packaging / Specialty / Tissue
  filler_usage_pct: number | null;
  preferred_fillers: string[];
  current_filler_supplier_party_ids: string[];
  notes: string | null;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.filler_supplier_profile (232 row, 3 HQ 포함 - handoff §7)
// ============================================================================

export interface UrmFillerSupplierProfileRow {
  id: string;
  party_id: string;
  filler_types: string[];                  // GCC / PCC / HFCC / FCC / talc / kaolin
  product_grades: string[];
  capacity_tpy: number | null;
  hq_location: string | null;
  is_hq: boolean;                          // Carmeuse/Schaefer Kalk/Sibelco/Omya HQ flag
  technical_capabilities: string[];
  certifications: string[];
  notes: string | null;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.investor_portfolio_companies (422 row, δ Port-1 신설)
// handoff §7: "18 columns, 5 indexes, FK to urm.parties CASCADE"
// ============================================================================

export interface UrmInvestorPortfolioCompanyRow {
  id: string;                                       // uuid (V1 id 보존)
  investor_party_id: string;                        // FK to urm.parties (investor)
  portfolio_company_name: string;
  portfolio_company_name_normalized: string | null; // δ 신설 컬럼 (LEFT JOIN result)
  portfolio_company_party_id: string | null;        // FK to urm.parties (만약 portfolio company 자체도 party 인 경우)
  investment_round: string | null;
  investment_year: number | null;
  investment_amount_usd: number | null;
  ownership_pct: number | null;
  status: string;                                   // active / exited / written_off
  exit_year: number | null;
  exit_type: string | null;
  notes: string | null;
  source: string | null;
  module_data: Json;                                // _app_portfolio_company_id 보존
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
}

export interface UrmInvestorPortfolioCompanyInsert extends Partial<UrmInvestorPortfolioCompanyRow> {
  investor_party_id: string;
  portfolio_company_name: string;
}

export type UrmInvestorPortfolioCompanyUpdate = Partial<UrmInvestorPortfolioCompanyRow>;

// ============================================================================
// urm.pipelines (0 row, α+β TRUNCATE)
// ============================================================================

export interface UrmPipelineRow {
  id: string;
  name: string;
  module: string;                          // text (V1 module_type::text)
  description: string | null;
  is_default: boolean;
  is_active: boolean;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.stages (0 row, α+β TRUNCATE)
// handoff §6 #3: 정렬 컬럼명 = sort_order (NOT stage_position)
// ============================================================================

export interface UrmStageRow {
  id: string;
  pipeline_id: string;                     // FK to urm.pipelines
  code: string;
  name: string;
  sort_order: number;                      // ← 핵심: stage_position 아님
  color_hex: string | null;
  stage_type: string;                      // text
  default_probability_pct: number;
  is_won: boolean;
  is_lost: boolean;
  is_terminal: boolean;
  description: string | null;
  auto_actions: Json;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.deals (0 row, V2 신설 컨셉, α+β TRUNCATE)
// handoff §6 #1: app 에 deals 부재. urm 가 정식 위치.
// ============================================================================

export interface UrmDealRow {
  id: string;
  pipeline_id: string;                     // FK to urm.pipelines
  current_stage_id: string | null;         // FK to urm.stages
  name: string;
  party_id: string;                        // FK to urm.parties (counterparty)
  primary_contact_id: string | null;       // FK to urm.contacts
  owner_user_id: string | null;
  status: string;                          // open / won / lost / paused
  value_amount: number | null;
  value_currency: string;
  weighted_amount: number | null;
  probability_pct: number;
  expected_close_date: string | null;
  actual_close_date: string | null;
  last_activity_at: string | null;
  next_action_at: string | null;
  priority: string;                        // low / medium / high / urgent
  source: string | null;
  won_lost_reason: string | null;
  description: string | null;
  module: string;
  module_data: Json;
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
  deleted_at: string | null;
}

// ============================================================================
// urm.deal_stage_history (0 row, stage29a 신설)
// ============================================================================

export interface UrmDealStageHistoryRow {
  id: string;
  deal_id: string;
  from_stage_id: string | null;
  to_stage_id: string;
  changed_at: string;
  changed_by: string | null;
  duration_in_prev_stage_days: number | null;
  reason: string | null;
  notes: string | null;
}

// ============================================================================
// urm.deal_checklists (0 row, stage29a 신설)
// ============================================================================

export interface UrmDealChecklistRow {
  id: string;
  deal_id: string;
  name: string;
  is_completed: boolean;
  completed_at: string | null;
  sort_order: number;
  description: string | null;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.tasks (0 row, α+β TRUNCATE)
// handoff §6 #8: checklist_id 컬럼 신설 (FK to urm.deal_checklists ON DELETE SET NULL)
// ============================================================================

export interface UrmTaskRow {
  id: string;
  title: string;
  description: string | null;
  status: string;                          // open / in_progress / done / cancelled
  priority: string;
  assigned_to_user_id: string | null;
  assigned_to_team_id: string | null;
  due_at: string | null;
  reminder_at: string | null;
  started_at: string | null;
  completed_at: string | null;
  estimated_minutes: number | null;
  actual_minutes: number | null;
  party_id: string | null;
  contact_id: string | null;
  deal_id: string | null;                  // V2 신규 (V1 의 engagement_id 일부 흡수)
  engagement_id: string | null;
  checklist_id: string | null;             // FK to urm.deal_checklists (stage29a)
  parent_task_id: string | null;
  module: string | null;
  module_data: Json;
  tags: string[];
  completion_notes: string | null;
  blocked_reason: string | null;
  created_at: string;
  created_by: string | null;
  updated_at: string;
  updated_by: string | null;
  deleted_at: string | null;
}

// ============================================================================
// urm.engagements (0 row, α+β TRUNCATE)
// ============================================================================

export interface UrmEngagementRow {
  id: string;
  name: string;
  type: string;                            // meeting / call / email / event / ...
  status: string;
  scheduled_at: string | null;
  started_at: string | null;
  ended_at: string | null;
  duration_minutes: number | null;
  location: string | null;
  meeting_link: string | null;
  party_id: string | null;
  deal_id: string | null;
  primary_contact_id: string | null;
  owner_user_id: string | null;
  description: string | null;
  notes: string | null;
  module: string | null;
  module_data: Json;
  created_at: string;
  updated_at: string;
}

// ============================================================================
// urm.engagement_attendees (0 row, V2 신설 컨셉)
// ============================================================================

export interface UrmEngagementAttendeeRow {
  id: string;
  engagement_id: string;
  contact_id: string | null;
  user_id: string | null;
  party_id: string | null;
  role: string | null;                     // attendee / organizer / optional
  rsvp_status: string | null;
  attended: boolean | null;
  notes: string | null;
  created_at: string;
}

// ============================================================================
// urm.engagement_documents (0 row, V2 신설 컨셉)
// ============================================================================

export interface UrmEngagementDocumentRow {
  id: string;
  engagement_id: string;
  attachment_id: string | null;
  document_type: string | null;            // agenda / minutes / slides / contract
  title: string;
  description: string | null;
  created_at: string;
}

// ============================================================================
// Aggregate: UrmSchema (Database 합치기용)
// ============================================================================

export type UrmSchema = {
  Tables: {
    parties: {
      Row: UrmPartyRow;
      Insert: UrmPartyInsert;
      Update: UrmPartyUpdate;
      Relationships: [];
    };
    contacts: {
      Row: UrmContactRow;
      Insert: UrmContactInsert;
      Update: UrmContactUpdate;
      Relationships: [];
    };
    contacts_history: {
      Row: UrmContactsHistoryRow;
      Insert: UrmContactsHistoryInsert;
      Update: UrmContactsHistoryUpdate;
      Relationships: [];
    };
    party_supply_links: {
      Row: UrmPartySupplyLinkRow;
      Insert: UrmPartySupplyLinkInsert;
      Update: UrmPartySupplyLinkUpdate;
      Relationships: [];
    };
    plant_supply_links: {
      Row: UrmPlantSupplyLinkRow;
      Insert: Partial<UrmPlantSupplyLinkRow>;
      Update: Partial<UrmPlantSupplyLinkRow>;
      Relationships: [];
    };
    investor_profile: {
      Row: UrmInvestorProfileRow;
      Insert: Partial<UrmInvestorProfileRow> & { party_id: string };
      Update: Partial<UrmInvestorProfileRow>;
      Relationships: [];
    };
    paper_mill_profile: {
      Row: UrmPaperMillProfileRow;
      Insert: Partial<UrmPaperMillProfileRow> & { party_id: string };
      Update: Partial<UrmPaperMillProfileRow>;
      Relationships: [];
    };
    filler_supplier_profile: {
      Row: UrmFillerSupplierProfileRow;
      Insert: Partial<UrmFillerSupplierProfileRow> & { party_id: string };
      Update: Partial<UrmFillerSupplierProfileRow>;
      Relationships: [];
    };
    investor_portfolio_companies: {
      Row: UrmInvestorPortfolioCompanyRow;
      Insert: UrmInvestorPortfolioCompanyInsert;
      Update: UrmInvestorPortfolioCompanyUpdate;
      Relationships: [];
    };
    pipelines: {
      Row: UrmPipelineRow;
      Insert: Partial<UrmPipelineRow> & { name: string; module: string };
      Update: Partial<UrmPipelineRow>;
      Relationships: [];
    };
    stages: {
      Row: UrmStageRow;
      Insert: Partial<UrmStageRow> & {
        pipeline_id: string;
        code: string;
        name: string;
        sort_order: number;
        stage_type: string;
      };
      Update: Partial<UrmStageRow>;
      Relationships: [];
    };
    deals: {
      Row: UrmDealRow;
      Insert: Partial<UrmDealRow> & { pipeline_id: string; name: string; party_id: string };
      Update: Partial<UrmDealRow>;
      Relationships: [];
    };
    deal_stage_history: {
      Row: UrmDealStageHistoryRow;
      Insert: Partial<UrmDealStageHistoryRow> & { deal_id: string; to_stage_id: string };
      Update: Partial<UrmDealStageHistoryRow>;
      Relationships: [];
    };
    deal_checklists: {
      Row: UrmDealChecklistRow;
      Insert: Partial<UrmDealChecklistRow> & { deal_id: string; name: string };
      Update: Partial<UrmDealChecklistRow>;
      Relationships: [];
    };
    tasks: {
      Row: UrmTaskRow;
      Insert: Partial<UrmTaskRow> & { title: string };
      Update: Partial<UrmTaskRow>;
      Relationships: [];
    };
    engagements: {
      Row: UrmEngagementRow;
      Insert: Partial<UrmEngagementRow> & { name: string; type: string };
      Update: Partial<UrmEngagementRow>;
      Relationships: [];
    };
    engagement_attendees: {
      Row: UrmEngagementAttendeeRow;
      Insert: Partial<UrmEngagementAttendeeRow> & { engagement_id: string };
      Update: Partial<UrmEngagementAttendeeRow>;
      Relationships: [];
    };
    engagement_documents: {
      Row: UrmEngagementDocumentRow;
      Insert: Partial<UrmEngagementDocumentRow> & { engagement_id: string; title: string };
      Update: Partial<UrmEngagementDocumentRow>;
      Relationships: [];
    };
    party_types: {
      Row: UrmPartyType;
      Insert: UrmPartyType;
      Update: Partial<UrmPartyType>;
      Relationships: [];
    };
  };
  Views: Record<string, never>;
  Functions: Record<string, never>;
  Enums: Record<string, never>;
  CompositeTypes: Record<string, never>;
};
```

### Subdir: `03_sbclient_cutover`

#### `SBCLIENT_CUTOVER.md` (4458 bytes)

```markdown
# SbClient Cutover Instruction

## §1. 적용 순서

### Step 3-1. 파일 위치 확인

audit script A1 의 결과로 SbClient factory 위치 확인. 일반적 경로:
```
src/lib/supabase/server.ts
src/lib/supabase/client.ts
src/lib/supabase/service.ts
src/lib/supabase/middleware.ts  (있을 경우)
```

### Step 3-2. 백업

```powershell
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item src\lib\supabase\server.ts "src\lib\supabase\server.ts.bak_$timestamp"
Copy-Item src\lib\supabase\client.ts "src\lib\supabase\client.ts.bak_$timestamp"
Copy-Item src\lib\supabase\service.ts "src\lib\supabase\service.ts.bak_$timestamp"
```

### Step 3-3. `SbClient_cutover_pattern.ts` 의 패턴 적용

각 파일에 대해:
1. `SbAppClient` / `SbUrmClient` type alias 추가
2. `createAppClient()` / `createUrmClient()` 신설 함수 작성
3. 기존 `createClient` 는 `createAppClient` 의 alias 로 유지 (`@deprecated` JSDoc)

### Step 3-4. 빌드 검증

```powershell
npm run build 2>&1 | Tee-Object -FilePath stage29c_build_step3.log
```

**기대**: 빌드 통과. 기존 caller 모두 `createClient` 사용 → `createAppClient` 의 alias 라 호환.

**실패 시**:
- type error → `database.ts` 재생성 필요 (02_type_regeneration 의 Step 2)
- import error → import 경로 확인

### Step 3-5. type 체크

```powershell
npx tsc --noEmit 2>&1 | Tee-Object -FilePath stage29c_tsc_step3.log
```

기대: 0 error.

---

## §2. 2-tier vs 단일 schema 결정 매트릭스

| 기준 | 단일 (app→urm 일괄) | 2-tier (현재 권장) |
|---|---|---|
| 변경 영향 범위 | 전체 caller 동시 | 점진적 (도메인별) |
| Rollback 난이도 | 어려움 (전체 되돌리기) | 쉬움 (도메인별 revert) |
| Stage 29-d 까지의 app.* 잔존 영역 | 깨짐 (caller 가 schema 명시 안 함) | 안전 (sbApp 으로 명시 호출) |
| 권장 시점 | Stage 29-d 종료 후 | **Stage 29-c (현재)** |

→ 현재는 **2-tier 채택**. Stage 29-d 종료 시 sbApp 제거 + sbUrm 만 남김.

---

## §3. Edge case 처리

### EC1. ai schema / audit schema 의 client 필요한 경우

```typescript
// 같은 패턴으로 추가
export type SbAiClient = SupabaseClient<Database, "ai">;
export type SbAuditClient = SupabaseClient<Database, "audit">;

export async function createAiClient(): Promise<SbAiClient> { /* ... */ }
export async function createAuditClient(): Promise<SbAuditClient> { /* ... */ }
```

### EC2. RPC 호출 (public schema)

PostgREST RPC 는 항상 public schema 의 함수. 별도 client 필요:

```typescript
export type SbPublicClient = SupabaseClient<Database>;  // default schema = public

export async function createPublicClient(): Promise<SbPublicClient> {
  // db: { schema: ... } 옵션 생략 → default public
}
```

RPC 호출:
```typescript
const sb = await createPublicClient();
await sb.rpc("save_manual_email", { ... });
```

### EC3. multi-schema query (drill-through)

한 query 가 app + urm 양쪽을 JOIN 해야 하면 → **RPC 로 옮김**. PostgREST 의 schema-prefix .from() 미지원.

```sql
-- public.<function_name> 신설, SQL 내에서 app.x JOIN urm.y
CREATE OR REPLACE FUNCTION public.get_party_with_email_history(p_party_id uuid)
RETURNS TABLE (...) ...
```

caller:
```typescript
const sb = await createPublicClient();
const { data } = await sb.rpc("get_party_with_email_history", { p_party_id: id });
```

---

## §4. 적용 후 검증 (수동)

다음 항목 manual 확인:

- [ ] `createAppClient()` 호출 → app 측 테이블 select 동작
- [ ] `createUrmClient()` 호출 → urm 측 테이블 select 동작
- [ ] 기존 `createClient()` 호출도 동작 (`createAppClient` alias)
- [ ] `tsc --noEmit` 통과
- [ ] `npm run build` 통과
- [ ] dev server 기동 (`npm run dev`) → 임의 API route 1개 호출 정상

---

## §5. Rollback 절차

문제 발생 시:

```powershell
# 백업 복원
Copy-Item "src\lib\supabase\server.ts.bak_$timestamp" src\lib\supabase\server.ts -Force
Copy-Item "src\lib\supabase\client.ts.bak_$timestamp" src\lib\supabase\client.ts -Force
Copy-Item "src\lib\supabase\service.ts.bak_$timestamp" src\lib\supabase\service.ts -Force

# 빌드 재확인
npm run build
```

---

## §6. 다음 step trigger

§4 의 6 항목 모두 ✅ → **Step 4 (column rename codemod) 진입**.
```

#### `SbClient_cutover_pattern.ts` (12245 bytes)

```typescript
/**
 * SbClient Cutover Pattern (Stage 29-c)
 *
 * 출처: handoff §A3 Gotcha #45 + §8 "SbClient default schema: 'app' → 'urm' 단일 cast site"
 * 작성: 2026-05-24
 *
 * ===========================================================================
 * 핵심 전략: 2-tier client (sbApp + sbUrm) 단일 schema cutover 보다 안전
 * ===========================================================================
 *
 * 이유:
 *   - app.* 의 잔존 운영 데이터 (email/sales/finance/communications 등)
 *     는 Stage 29-d 까지 1-2주 carry. 그 동안 caller 는 app + urm 양쪽 다 접근 필요.
 *   - 단일 schema cast (app → urm) 로 일괄 cutover 하면, app 측 호출이 모두 깨짐.
 *   - 2-tier 로 가면 caller 가 의도적으로 sbUrm.from(...) / sbApp.from(...) 선택.
 *     점진적 이전 가능, rollback 안전.
 *
 * Stage 29-d 종료 후 sbApp 은 deprecate, sbUrm 만 남김.
 *
 * ===========================================================================
 * 파일 위치 (추정 — 실제 프로젝트에서 audit script A1 결과로 확인)
 * ===========================================================================
 *
 * 변경 대상:
 *   - src/lib/supabase/server.ts        (Server Components / API Routes)
 *   - src/lib/supabase/client.ts        (Client Components / Browser)
 *   - src/lib/supabase/service.ts       (service-role / admin)
 *   - src/lib/supabase/middleware.ts    (Next.js middleware, 있을 경우)
 *
 * 변경 패턴:
 *   기존:  createServerClient<Database>(...)
 *   기존:  createServerClient<Database, 'app'>(...)
 *   변경:  export const sbApp = ... <Database, 'app'>(...)
 *   변경:  export const sbUrm = ... <Database, 'urm'>(...) // 신규
 *
 * ===========================================================================
 * BEFORE — 예시 (src/lib/supabase/server.ts)
 * ===========================================================================
 */

// import { createServerClient, type CookieOptions } from "@supabase/ssr";
// import { cookies } from "next/headers";
// import type { Database } from "./database";
//
// export type SbClient = SupabaseClient<Database, "app">;
//
// export async function createClient(): Promise<SbClient> {
//   const cookieStore = await cookies();
//   return createServerClient<Database, "app">(
//     process.env.NEXT_PUBLIC_SUPABASE_URL!,
//     process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
//     {
//       cookies: {
//         get(name: string) { return cookieStore.get(name)?.value; },
//         set(name: string, value: string, options: CookieOptions) {
//           try { cookieStore.set({ name, value, ...options }); }
//           catch { /* Server Component */ }
//         },
//         remove(name: string, options: CookieOptions) {
//           try { cookieStore.set({ name, value: "", ...options }); }
//           catch {}
//         },
//       },
//       db: { schema: "app" },
//     }
//   );
// }

/*
 * ===========================================================================
 * AFTER — 2-tier (server.ts)
 * ===========================================================================
 */

import {
  createServerClient,
  type CookieOptions,
} from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";
import { cookies } from "next/headers";
import type { Database } from "./database";

// ─── Type aliases ──────────────────────────────────────────────────────────
export type SbAppClient = SupabaseClient<Database, "app">;
export type SbUrmClient = SupabaseClient<Database, "urm">;

/** @deprecated Stage 29-d 종료 후 제거. 점진적으로 sbUrm 으로 이전 */
export type SbClient = SbAppClient;

// ─── Common cookie handler ─────────────────────────────────────────────────
async function getCookieHandler() {
  const cookieStore = await cookies();
  return {
    get(name: string) {
      return cookieStore.get(name)?.value;
    },
    set(name: string, value: string, options: CookieOptions) {
      try {
        cookieStore.set({ name, value, ...options });
      } catch {
        /* Server Component context — Next.js 가 set 막음 */
      }
    },
    remove(name: string, options: CookieOptions) {
      try {
        cookieStore.set({ name, value: "", ...options });
      } catch {}
    },
  };
}

// ─── App client (legacy carry, Stage 29-d 까지) ────────────────────────────
export async function createAppClient(): Promise<SbAppClient> {
  return createServerClient<Database, "app">(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: await getCookieHandler(),
      db: { schema: "app" },
    }
  );
}

// ─── URM client (V2 primary) ────────────────────────────────────────────────
export async function createUrmClient(): Promise<SbUrmClient> {
  return createServerClient<Database, "urm">(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: await getCookieHandler(),
      db: { schema: "urm" },
    }
  );
}

// ─── Backward-compat (Stage 29-d 종료 후 제거) ──────────────────────────────
/** @deprecated Stage 29-d 종료 후 제거. createAppClient() 또는 createUrmClient() 사용 */
export const createClient = createAppClient;

/*
 * ===========================================================================
 * AFTER — 2-tier (src/lib/supabase/client.ts, Browser)
 * ===========================================================================
 */

// import { createBrowserClient } from "@supabase/ssr";
// import type { SupabaseClient } from "@supabase/supabase-js";
// import type { Database } from "./database";
//
// export type SbAppClient = SupabaseClient<Database, "app">;
// export type SbUrmClient = SupabaseClient<Database, "urm">;
//
// export function createAppBrowserClient(): SbAppClient {
//   return createBrowserClient<Database, "app">(
//     process.env.NEXT_PUBLIC_SUPABASE_URL!,
//     process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
//     { db: { schema: "app" } }
//   );
// }
//
// export function createUrmBrowserClient(): SbUrmClient {
//   return createBrowserClient<Database, "urm">(
//     process.env.NEXT_PUBLIC_SUPABASE_URL!,
//     process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
//     { db: { schema: "urm" } }
//   );
// }
//
// /** @deprecated Stage 29-d 종료 후 제거 */
// export const createClient = createAppBrowserClient;

/*
 * ===========================================================================
 * AFTER — 2-tier (src/lib/supabase/service.ts, Service Role)
 * ===========================================================================
 *
 * service-role client 는 RLS 우회. urm/app 모두 동일 token 으로 접근 가능.
 */

// import { createClient as createSupabaseClient } from "@supabase/supabase-js";
// import type { SupabaseClient } from "@supabase/supabase-js";
// import type { Database } from "./database";
//
// export type SbAppServiceClient = SupabaseClient<Database, "app">;
// export type SbUrmServiceClient = SupabaseClient<Database, "urm">;
//
// export function createAppServiceClient(): SbAppServiceClient {
//   return createSupabaseClient<Database, "app">(
//     process.env.NEXT_PUBLIC_SUPABASE_URL!,
//     process.env.SUPABASE_SERVICE_ROLE_KEY!,
//     {
//       auth: { persistSession: false, autoRefreshToken: false },
//       db: { schema: "app" },
//     }
//   );
// }
//
// export function createUrmServiceClient(): SbUrmServiceClient {
//   return createSupabaseClient<Database, "urm">(
//     process.env.NEXT_PUBLIC_SUPABASE_URL!,
//     process.env.SUPABASE_SERVICE_ROLE_KEY!,
//     {
//       auth: { persistSession: false, autoRefreshToken: false },
//       db: { schema: "urm" },
//     }
//   );
// }
//
// /** @deprecated Stage 29-d 종료 후 제거 */
// export const createServiceClient = createAppServiceClient;

/*
 * ===========================================================================
 * Caller 측 호출 패턴 (변경 예시)
 * ===========================================================================
 *
 * BEFORE:
 *   const sb = await createClient();
 *   const { data } = await sb.from("parties").select("*");
 *   // → app.parties select
 *
 * AFTER (urm 으로 이전):
 *   const sb = await createUrmClient();
 *   const { data } = await sb.from("parties").select("*");
 *   // → urm.parties select
 *
 * AFTER (app 잔존 영역, 예: communications, sales_orders):
 *   const sb = await createAppClient();
 *   const { data } = await sb.from("communications").select("*");
 *   // → app.communications select
 *
 * AFTER (혼합 — 한 함수에서 양쪽 필요):
 *   const [sbApp, sbUrm] = await Promise.all([
 *     createAppClient(),
 *     createUrmClient(),
 *   ]);
 *   const [comms, parties] = await Promise.all([
 *     sbApp.from("communications").select("*"),
 *     sbUrm.from("parties").select("*"),
 *   ]);
 */

/*
 * ===========================================================================
 * 호출 분기 (어느 쪽 client 를 쓸지)
 * ===========================================================================
 *
 * URM (sbUrm) 이 1차 선택지인 테이블:
 *   - parties, contacts, contacts_history, party_supply_links, plant_supply_links
 *   - investor_profile, paper_mill_profile, filler_supplier_profile
 *   - investor_portfolio_companies
 *   - pipelines, stages, deals, deal_stage_history, deal_checklists
 *   - tasks, engagements, engagement_attendees, engagement_documents
 *   - party_types
 *
 * APP (sbApp) carry 영역 (Stage 29-d 까지):
 *   - email_whitelist, communications, drafts, email_tracking, email_templates, ...
 *   - sales_orders, sales_order_items, invoices, payments, shipments, quotations
 *   - mailcarrier_state, scraping_jobs, scraping_raw, scraping_sources, scraping_targets
 *   - users, roles, permissions, role_permissions, user_roles, teams, team_members
 *   - organizations  (urm 은 single-tenant 라 organization_id 없음)
 *   - meetings, meeting_attendees, calendar_events, calendar_connections, ...
 *   - tags, entity_tags, custom_field_definitions, custom_field_values
 *   - response_strategies, strategy_actions, strategy_outcomes
 *   - templates_* (email_templates 외 다수)
 *   - lookup: investor_subtype_meta, partner_seniority_meta, engagement_type_registry
 *   - 잔재: investor_partner_profile (108), person_firm_history (109), investor_portfolio_companies (422)
 *           ← Stage 29-d 시 자동 drop, 그동안 read-only carry
 *
 * 결정 시 의문 발생할 때: handoff §8 의 schema 정의 참조.
 */

/*
 * ===========================================================================
 * 마이그레이션 안내 (caller 측, 단계적)
 * ===========================================================================
 *
 * 1. 본 cutover 적용 후 build (npm run build) 통과 확인 (기존 caller 는 sbApp 유지하므로 무손실)
 * 2. caller code 를 한 도메인씩 sbUrm 으로 이전 (예: parties 도메인 먼저)
 * 3. 각 도메인 이전 시:
 *    a. 해당 호출 사이트 list (audit script A1, A2 매치)
 *    b. createClient → createUrmClient 또는 createAppClient 명시
 *    c. 컬럼 rename (party_type → party_type_id 등) 적용
 *    d. 빌드 + 테스트
 * 4. 모든 URM 도메인 이전 완료 후 sbApp 사용 사이트 list 가 §결정 표의 "APP carry 영역" 과 일치하는지 검증
 * 5. Stage 29-d 진입 시 sbApp 도 deprecate
 */
```

### Subdir: `04_column_rename`

#### `party_type_join_pattern.ts` (10709 bytes)

```typescript
/**
 * party_type → party_type_id (FK) Migration Patterns
 *
 * 출처: handoff §6 #2, §A4 의 매핑 표
 * 작성: Stage 29-c (2026-05-24)
 *
 * 배경:
 *   V1: app.parties.party_type (enum) — "company" | "organization" | "individual" | "fund" | "government"
 *   V2: urm.parties.party_type_id (FK to urm.party_types) — 1..7
 *
 *   urm.party_types lookup:
 *     1 investor
 *     2 paper_mill
 *     3 filler_supplier
 *     4 buyer
 *     5 customer
 *     6 partner
 *     7 government_grant
 *
 * 핵심 변경:
 *   - app enum 값 ('company') 와 urm code ('investor') 가 1:1 매핑 안 됨
 *   - urm 측에서 "어떤 종류의 party 인지" 는 profile 테이블의 존재로 판별
 *   - caller 가 사용한 'company' 분류는 6 가지 sub-type (investor/paper_mill/filler_supplier/buyer/customer/partner) 중 하나로 정밀화됨
 *
 * 이 파일은 caller code 의 수동 변환 패턴을 예시로 제공.
 * 실제 코드 적용 시: audit script A4 결과의 매치 사이트 case-by-case 처리.
 */

import type { SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "./database";

type SbUrm = SupabaseClient<Database, "urm">;
type SbApp = SupabaseClient<Database, "app">;

// =============================================================================
// §1. party_types lookup 상수 (한 번만 정의, caller 전역 사용)
// =============================================================================

/**
 * urm.party_types 의 7 코드. id 는 실제 DB row 확인 후 채울 것.
 *
 * 측정 SQL:
 *   SELECT id, code FROM urm.party_types ORDER BY id;
 */
export const PARTY_TYPE = {
  INVESTOR: 1,
  PAPER_MILL: 2,
  FILLER_SUPPLIER: 3,
  BUYER: 4,
  CUSTOMER: 5,
  PARTNER: 6,
  GOVERNMENT_GRANT: 7,
} as const;

export type PartyTypeCode =
  | "investor"
  | "paper_mill"
  | "filler_supplier"
  | "buyer"
  | "customer"
  | "partner"
  | "government_grant";

export const PARTY_TYPE_CODE_TO_ID: Record<PartyTypeCode, number> = {
  investor: PARTY_TYPE.INVESTOR,
  paper_mill: PARTY_TYPE.PAPER_MILL,
  filler_supplier: PARTY_TYPE.FILLER_SUPPLIER,
  buyer: PARTY_TYPE.BUYER,
  customer: PARTY_TYPE.CUSTOMER,
  partner: PARTY_TYPE.PARTNER,
  government_grant: PARTY_TYPE.GOVERNMENT_GRANT,
};

export const PARTY_TYPE_ID_TO_CODE: Record<number, PartyTypeCode> =
  Object.entries(PARTY_TYPE_CODE_TO_ID).reduce<Record<number, PartyTypeCode>>(
    (acc, [code, id]) => {
      acc[id] = code as PartyTypeCode;
      return acc;
    },
    {}
  );

// =============================================================================
// §2. 변환 패턴 (각 V1 → V2)
// =============================================================================

// -----------------------------------------------------------------------------
// 패턴 P1: .eq('party_type', '<enum>') 단일 filter
// -----------------------------------------------------------------------------

// V1:
//   const { data } = await sbApp
//     .from('parties')
//     .select('*')
//     .eq('party_type', 'company');

// V2 (urm):
async function p1_filter_by_type(sbUrm: SbUrm) {
  // 1. 단순 변환 (만약 'company' 가 다 investor 라면)
  const { data: investors } = await sbUrm
    .from("parties")
    .select("*")
    .eq("party_type_id", PARTY_TYPE.INVESTOR);

  // 2. 더 정확: profile 테이블 join 으로 "company 가 어느 sub-type 인지" 판별
  //    예) investor 만 추출
  const { data: investorsWithProfile } = await sbUrm
    .from("parties")
    .select("*, investor_profile!inner(*)")
    .order("name");

  // 3. 또는 여러 sub-type 한꺼번에 (만약 'company' 가 6 sub-type 모두 포함이라면)
  const { data: allCorporateParties } = await sbUrm
    .from("parties")
    .select("*")
    .in("party_type_id", [
      PARTY_TYPE.INVESTOR,
      PARTY_TYPE.PAPER_MILL,
      PARTY_TYPE.FILLER_SUPPLIER,
      PARTY_TYPE.BUYER,
      PARTY_TYPE.CUSTOMER,
      PARTY_TYPE.PARTNER,
    ]);

  return { investors, investorsWithProfile, allCorporateParties };
}

// -----------------------------------------------------------------------------
// 패턴 P2: .in('party_type', ['fund', 'individual']) — 매핑 없는 enum
// -----------------------------------------------------------------------------

// V1:
//   const { data } = await sbApp
//     .from('parties')
//     .select('*')
//     .in('party_type', ['fund', 'individual']);

// V2 (urm):
//   urm.party_types 에 fund / individual 부재.
//   - fund: ε hard-delete 완료 (0 row)
//   - individual: 모두 soft-deleted (urm 측 0 row)
//   → 이 query 자체가 빈 결과 반환. 코드 제거 후보.
//
//   만약 어쩔 수 없이 carry 해야 한다면 app.* 로 격리:
async function p2_dead_filter(sbApp: SbApp) {
  // Stage 29-d 까지의 app.* carry. soft-deleted 까지 포함 필요한 경우만.
  const { data } = await sbApp
    .from("parties")
    .select("*")
    .in("party_type", ["fund", "individual"]); // app enum (V1 carry)
  // 운영상 0~118 row (모두 soft-deleted)
  return data;
}

// -----------------------------------------------------------------------------
// 패턴 P3: object property 비교 (TS code, runtime check)
// -----------------------------------------------------------------------------

interface PartyV1 {
  party_type: "company" | "organization" | "individual" | "fund" | "government";
}

interface PartyV2 {
  party_type_id: number;
}

// V1:
//   if (party.party_type === 'fund') { ... }

// V2:
function p3_runtime_check_v2(party: PartyV2) {
  const code = PARTY_TYPE_ID_TO_CODE[party.party_type_id];
  if (code === "investor") {
    // investor 처리
  }
  // fund / individual / organization 는 V2 에 없음. 분기 자체 제거 가능.
}

// =============================================================================
// §3. select() 의 join 패턴 (party_types.code 함께 가져오기)
// =============================================================================

// V1:
//   const { data } = await sbApp.from('parties').select('id, name, party_type');
//   // data: { id, name, party_type: 'company' }[]

// V2 (PostgREST 의 nested select):
async function v2_select_with_type_code(sbUrm: SbUrm) {
  const { data } = await sbUrm
    .from("parties")
    .select(`
      id,
      name,
      party_type_id,
      party_type:party_types(code)
    `);
  // data 의 row 형태:
  //   { id, name, party_type_id: 1, party_type: { code: 'investor' } }

  // 만약 caller 가 flat 한 'party_type' 문자열을 원하면 매핑:
  const flat = data?.map((row) => ({
    id: row.id,
    name: row.name,
    party_type_id: row.party_type_id,
    party_type: PARTY_TYPE_ID_TO_CODE[row.party_type_id],
  }));

  return flat;
}

// =============================================================================
// §4. INSERT 패턴
// =============================================================================

// V1:
//   await sbApp.from('parties').insert({
//     name: 'Acme',
//     party_type: 'company',
//     module: 'investor',
//     organization_id: ORG_ID,
//   });

// V2 (urm — organization_id 없음, party_type_id 사용):
async function v2_insert(sbUrm: SbUrm) {
  await sbUrm.from("parties").insert({
    name: "Acme",
    party_type_id: PARTY_TYPE.INVESTOR, // 직접 ID
    // organization_id: 없음 (urm 은 single-tenant, handoff §8)
  } as Database["urm"]["Tables"]["parties"]["Insert"]);
}

// =============================================================================
// §5. UPDATE 패턴
// =============================================================================

// V1:
//   await sbApp.from('parties').update({ party_type: 'fund' }).eq('id', id);

// V2:
//   urm 에 'fund' 없음. update 자체 제거 또는 다른 sub-type 으로:
async function v2_update_avoid_fund(sbUrm: SbUrm, id: string) {
  // 잘못된 V1 패턴 ('fund' 로 변경) 은 V2 에서 의미 없음.
  // 만약 의도가 "다른 분류로 reclassify" 라면 명확히 6 sub-type 중 하나:
  await sbUrm
    .from("parties")
    .update({ party_type_id: PARTY_TYPE.PARTNER })
    .eq("id", id);
}

// =============================================================================
// §6. RPC 호출에서의 party_type
// =============================================================================

// V1 RPC 시그니처:
//   public.get_parties_by_type(p_party_type text)
//   → 내부에서 WHERE party_type = p_party_type::party_type_enum

// V2 RPC 시그니처 (DB 측 함수 V2 재작성 필요):
//   public.get_parties_by_type(p_party_type_id int)
//   또는
//   public.get_parties_by_type(p_party_type_code text)
//   → 내부에서 JOIN urm.party_types ON code = p_party_type_code

// caller 측:
async function v2_rpc(sbUrm: SbUrm) {
  // 만약 V2 RPC 가 code 받음
  const { data } = await sbUrm.rpc("get_parties_by_type", {
    p_party_type_code: "investor",
  } as never); // 타입 확정 후 as never 제거

  // 또는 id 받음
  const { data: data2 } = await sbUrm.rpc("get_parties_by_type", {
    p_party_type_id: PARTY_TYPE.INVESTOR,
  } as never);

  return { data, data2 };
}

// =============================================================================
// §7. helper functions (caller 가 자주 쓰는 분류 logic)
// =============================================================================

/** party 가 investor 인지 (urm 기반) */
export async function isInvestor(sbUrm: SbUrm, partyId: string): Promise<boolean> {
  const { data } = await sbUrm
    .from("investor_profile")
    .select("party_id")
    .eq("party_id", partyId)
    .maybeSingle();
  return !!data;
}

/** party 의 sub-type 코드 추출 (profile 테이블 join) */
export async function getPartyTypeCode(
  sbUrm: SbUrm,
  partyId: string
): Promise<PartyTypeCode | null> {
  const { data: party } = await sbUrm
    .from("parties")
    .select("party_type_id")
    .eq("id", partyId)
    .maybeSingle();
  if (!party) return null;
  return PARTY_TYPE_ID_TO_CODE[party.party_type_id] ?? null;
}

/** 사용자에게 표시할 party_type 한국어 라벨 */
export const PARTY_TYPE_DISPLAY_KO: Record<PartyTypeCode, string> = {
  investor: "투자자",
  paper_mill: "제지사",
  filler_supplier: "충전제 공급사",
  buyer: "구매자",
  customer: "고객",
  partner: "파트너",
  government_grant: "정부지원",
};
```

#### `rename_codemod.ps1` (11060 bytes)

```powershell
# Stage 29-c Column Rename Codemod (PowerShell)
#
# 사용법:
#   .\rename_codemod.ps1 -ProjectRoot . -DryRun         # 미리보기만
#   .\rename_codemod.ps1 -ProjectRoot . -Apply          # 실제 적용
#   .\rename_codemod.ps1 -ProjectRoot . -Apply -Confirm # 각 매치 별로 y/n 물음
#
# 주의:
#   1. -DryRun 으로 먼저 검토 필수
#   2. git working tree clean 상태에서 실행 (revert 용이)
#   3. party_type → party_type_id 는 단순 rename 안 됨. 별도 처리 (party_type_join_pattern.ts)

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectRoot,
    [switch]$DryRun,
    [switch]$Apply,
    [switch]$Confirm,
    [string[]]$IncludeExts = @("*.ts", "*.tsx", "*.js", "*.jsx", "*.mts", "*.cts"),
    [string[]]$ExcludeDirs = @("node_modules", ".next", "dist", "build", ".git", "coverage", "outputs", "stage29c")
)

if (-not $DryRun -and -not $Apply) {
    Write-Host "ERROR: -DryRun 또는 -Apply 중 하나 필수" -ForegroundColor Red
    exit 1
}

$ErrorActionPreference = "Stop"
$projectRootFull = (Resolve-Path $ProjectRoot).Path

Write-Host "=== Stage 29-c Column Rename Codemod ===" -ForegroundColor Cyan
Write-Host "Mode: $(if ($DryRun) { 'DRY RUN' } else { 'APPLY' })" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' })
Write-Host "Project root: $projectRootFull"
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────
# 매핑 정의
# 각 entry: { Pattern, Replacement, Description, Scope }
#   Scope: "app" | "urm" | "both" | "code" — caller 호출 컨텍스트 힌트
# ─────────────────────────────────────────────────────────────────────────

$renames = @(
    # === A3 의 V1 caller bug (실재 컬럼명 불일치) ===
    @{
        Pattern     = '(?<![a-zA-Z0-9_])org_id(?![a-zA-Z0-9_])'
        Replacement = 'organization_id'
        Description = 'org_id → organization_id (app.* 모든 테이블)'
        Scope       = "both"
    },
    @{
        Pattern     = '(?<![a-zA-Z0-9_])body_text(?![a-zA-Z0-9_])'
        Replacement = 'body_plain'
        Description = 'body_text → body_plain (app.communications)'
        Scope       = "app"
    },
    @{
        Pattern     = "(?<![a-zA-Z0-9_])'country'(?![a-zA-Z0-9_])"
        Replacement = "'country_code'"
        Description = "'country' literal → 'country_code' (app.parties)"
        Scope       = "app"
    },
    @{
        Pattern     = '(?<![a-zA-Z0-9_])"country"(?![a-zA-Z0-9_])'
        Replacement = '"country_code"'
        Description = '"country" literal → "country_code" (app.parties)'
        Scope       = "app"
    },
    @{
        Pattern     = '(?<![a-zA-Z0-9_])\.country(?![a-zA-Z0-9_])'
        Replacement = '.country_code'
        Description = '.country accessor → .country_code'
        Scope       = "both"
    },

    # === A3 의 stage_position (urm.stages 의 실재 컬럼은 sort_order) ===
    @{
        Pattern     = '(?<![a-zA-Z0-9_])stage_position(?![a-zA-Z0-9_])'
        Replacement = 'sort_order'
        Description = 'stage_position → sort_order (urm.stages)'
        Scope       = "urm"
    },

    # === Stage 29-b δ 의 9 deprecated profile 테이블 reference (caller 가 .from() 에 쓰면 실패) ===
    # 이건 단순 rename 이 아니라 "코드 제거 또는 다른 logic 으로 대체" 가 정답.
    # 여기선 검색만 (실제 적용 안 함). audit script 의 A6 와 중복되므로 skip.

    # === handoff §A5 의 module_data 이전 패턴 ===
    # caller 가 .module_data._app_* 접근하는 경우 그대로 두기 (V2 jsonb 보존 logic)
    # 이건 자동 변환 대상 아님.

    # === V1 의 portfolio_company_id (FK) 를 V2 의 module_data._app_portfolio_company_id 로 ===
    # 이것도 단순 rename 어려움 — caller 측 query 패턴 자체가 달라짐.
    # 별도 manual review 후보.
)

# ─────────────────────────────────────────────────────────────────────────
# 파일 list
# ─────────────────────────────────────────────────────────────────────────

$excludeRegex = ($ExcludeDirs | ForEach-Object { [regex]::Escape($_) }) -join "|"

$allFiles = Get-ChildItem -Path $projectRootFull -Recurse -Include $IncludeExts -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -notmatch "[\\/]($excludeRegex)[\\/]" -and
        $_.FullName -notmatch "[\\/]($excludeRegex)$"
    }

Write-Host "Scanning $($allFiles.Count) files" -ForegroundColor Gray
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────
# 실행
# ─────────────────────────────────────────────────────────────────────────

$grandTotalMatches = 0
$grandTotalFilesChanged = 0
$logEntries = @()

foreach ($rename in $renames) {
    Write-Host "[$($rename.Description)] (scope: $($rename.Scope))" -ForegroundColor Yellow
    Write-Host "  Pattern: $($rename.Pattern)" -ForegroundColor Gray
    Write-Host "  Replace: $($rename.Replacement)" -ForegroundColor Gray

    $patternMatchCount = 0
    $patternFilesChangedCount = 0

    foreach ($file in $allFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        } catch {
            continue
        }
        if (-not $content) { continue }

        $matches = [regex]::Matches($content, $rename.Pattern)
        if ($matches.Count -eq 0) { continue }

        $patternMatchCount += $matches.Count
        $patternFilesChangedCount += 1

        $relPath = $file.FullName.Replace($projectRootFull, "").TrimStart("\", "/")

        Write-Host "  -> $relPath ($($matches.Count) matches)" -ForegroundColor Cyan
        # 매치 라인 sample (앞 3개)
        $lines = $content -split "`n"
        $matchedLineNumbers = @()
        $cursor = 0
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $lineStart = $cursor
            $lineEnd = $cursor + $lines[$i].Length
            foreach ($m in $matches) {
                if ($m.Index -ge $lineStart -and $m.Index -lt $lineEnd) {
                    $matchedLineNumbers += $i + 1
                }
            }
            $cursor = $lineEnd + 1  # +1 for newline
        }
        $matchedLineNumbers = $matchedLineNumbers | Select-Object -Unique | Sort-Object
        $sampleLines = $matchedLineNumbers | Select-Object -First 3
        foreach ($ln in $sampleLines) {
            $lineContent = $lines[$ln - 1].Trim()
            if ($lineContent.Length -gt 100) { $lineContent = $lineContent.Substring(0, 97) + "..." }
            Write-Host "     L$ln`: $lineContent" -ForegroundColor DarkGray
        }
        if ($matchedLineNumbers.Count -gt 3) {
            Write-Host "     ... ($($matchedLineNumbers.Count - 3) more)" -ForegroundColor DarkGray
        }

        $logEntries += [PSCustomObject]@{
            File         = $relPath
            Pattern      = $rename.Description
            Matches      = $matches.Count
            LineNumbers  = ($matchedLineNumbers -join ", ")
        }

        # 적용
        if ($Apply) {
            $proceed = $true
            if ($Confirm) {
                $answer = Read-Host "  Apply to $relPath? (y/N)"
                if ($answer -notmatch '^[Yy]') { $proceed = $false }
            }
            if ($proceed) {
                $newContent = [regex]::Replace($content, $rename.Pattern, $rename.Replacement)
                Set-Content -Path $file.FullName -Value $newContent -NoNewline -Encoding UTF8
                Write-Host "     ✓ Applied" -ForegroundColor Green
            } else {
                Write-Host "     - Skipped" -ForegroundColor Yellow
            }
        }
    }

    Write-Host "  ## Sub-total: $patternMatchCount matches in $patternFilesChangedCount files" -ForegroundColor White
    Write-Host ""

    $grandTotalMatches += $patternMatchCount
    $grandTotalFilesChanged += $patternFilesChangedCount
}

# ─────────────────────────────────────────────────────────────────────────
# 결과
# ─────────────────────────────────────────────────────────────────────────

Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Total matches  : $grandTotalMatches"
Write-Host "Files affected : $grandTotalFilesChanged"
Write-Host ""

# 로그 저장
$logFile = Join-Path -Path $projectRootFull -ChildPath "stage29c_rename_log.csv"
$logEntries | Export-Csv -Path $logFile -NoTypeInformation -Encoding UTF8
Write-Host "Log: $logFile"
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN — 실제 변경 없음. -Apply 로 재실행 시 적용." -ForegroundColor Yellow
}
if ($Apply) {
    Write-Host "APPLIED — git diff 로 변경 검토 + 빌드 확인 후 commit." -ForegroundColor Green
    Write-Host "  git diff > stage29c_rename.patch"
    Write-Host "  npm run build"
    Write-Host "  npx tsc --noEmit"
}

# party_type 특수 케이스 안내
Write-Host ""
Write-Host "──────────────────────────────────────────────────────────────────" -ForegroundColor DarkYellow
Write-Host "특수 케이스: party_type → party_type_id" -ForegroundColor DarkYellow
Write-Host "──────────────────────────────────────────────────────────────────" -ForegroundColor DarkYellow
Write-Host "이 codemod 는 party_type 자동 변경 안 함 (단순 rename 으로 해결 안 되는 FK 매핑)."
Write-Host "별도 manual review: party_type_join_pattern.ts 참조."
Write-Host "audit script 의 A4 결과 사용해서 호출 사이트 list 만들고 case-by-case 처리."
```

#### `RENAME_TABLE.md` (7009 bytes)

```markdown
# Stage 29-c Column Rename Table

handoff §A4 + §6 + 본 chat 의 V1 database.ts 검증 결과 통합.

---

## §1. 자동 변환 가능 (rename_codemod.ps1 처리)

### 1-1. V1 caller bug (DB 컬럼명 불일치)

| 패턴 (V1 caller) | 실재 DB 컬럼 | 위치 | 영향 |
|---|---|---|---|
| `org_id` | `organization_id` | app.* 다수 (email_whitelist, communications, parties 등) | runtime fail |
| `body_text` | `body_plain` | app.communications | runtime fail |
| `'country'` literal | `'country_code'` | app.parties | runtime fail |
| `.country` accessor | `.country_code` | app.parties (객체 속성) | runtime fail |
| `email_whitelist.value` | `email_whitelist.pattern` | app.email_whitelist | runtime fail |

→ 모두 단순 string replace. `rename_codemod.ps1` 가 처리.

⚠️ **`email_whitelist.value` 케이스**: codemod 가 자동 처리 안 함 (너무 일반적 단어 `value`). audit script A3 에 명시적 패턴 미포함. 별도 grep:
```powershell
Select-String -Path src -Recurse -Include *.ts,*.tsx -Pattern "email_whitelist.*value|value.*email_whitelist"
```
매치된 site case-by-case manual review.

### 1-2. urm.stages 의 정렬 컬럼

| 패턴 (V1 caller) | 실재 DB 컬럼 | 위치 |
|---|---|---|
| `stage_position` | `sort_order` | urm.stages |

→ 단순 rename. (단 `app.pipeline_stages` 의 컬럼명도 이미 `sort_order` 임 — V1 에서도 stage_position 은 caller bug)

---

## §2. 수동 처리 필요 (codemod 안 함)

### 2-1. party_type → party_type_id (FK)

**가장 영향 큰 변경**. 단순 rename 으로 해결 안 됨.

| V1 패턴 | V2 (urm) 변환 |
|---|---|
| `.eq('party_type', 'company')` | `.eq('party_type_id', <FK_UUID>)` + 별도 JOIN 또는 lookup table mapping |
| `.in('party_type', ['fund', 'individual'])` | (urm 에 fund/individual 없음, hard-delete 완료) → 코드 제거 또는 다른 조건 |
| `party_type === 'paper_mill'` | `party_type_id === <PAPER_MILL_ID>` 또는 `party_type_code === 'paper_mill'` (JOIN 후 alias) |
| `select('party_type')` | `select('party_type:party_types(code)')` (PostgREST JOIN), 또는 raw id 만 |
| INSERT/UPDATE 의 `party_type: 'company'` | `party_type_id: <ID>` |

상세 패턴: `party_type_join_pattern.ts`.

### 2-2. urm.parties.party_type enum (app) → urm.party_types code (urm)

**enum 매핑** (handoff §6 #5 + §4 의 app.parties.party_type enum 5값):

| app enum 값 | urm.party_types.code | 처리 |
|---|---|---|
| `company` | (없음) | profile 테이블 (investor / paper_mill / filler_supplier / buyer / customer / partner) join 으로 결정 |
| `individual` | (없음) | urm.parties 에 0 row (모두 soft-deleted, Stage 29-d 시 drop) |
| `fund` | (없음) | urm.parties 에 0 row (ε hard-delete) |
| `organization` | (없음) | 동상 |
| `government` | `government_grant` | 직접 매핑 |

→ caller logic 이 `party_type === 'fund'` 같은 비교를 하면 → 거의 dead code. 검토 후 제거.

→ `party_type === 'company'` 가장 흔함. urm 측에선 **profile 테이블 존재로 판별**. 예:
```typescript
// V1
const isInvestor = party.party_type === 'company' && /* ... */;

// V2 (urm)
const isInvestor = party.party_type_id === PARTY_TYPE.INVESTOR;
// 또는
const isInvestor = !!(await sbUrm
  .from('investor_profile')
  .select('id')
  .eq('party_id', party.id)
  .maybeSingle()).data;
```

### 2-3. portfolio_company_id (V1) → V2 module_data 보존

handoff §8: `portfolio_company_id (app.ipc)` → drop → `module_data._app_portfolio_company_id` (V2 jsonb)

| V1 (caller) | V2 (urm.investor_portfolio_companies) |
|---|---|
| `.select('portfolio_company_id')` | `.select('module_data')` + `data.module_data._app_portfolio_company_id` |
| `.eq('portfolio_company_id', id)` | 신규 컬럼 `portfolio_company_party_id` 또는 `portfolio_company_name_normalized` 사용 |
| INSERT `{ portfolio_company_id: ... }` | 별도 신설 컬럼 또는 module_data 에 직접 |

→ caller code 의 의도에 따라 다름. case-by-case.

### 2-4. parent_party_id / party_level (3-tier hierarchy)

**Stage 29-b handoff §8: "3-tier hierarchy DROP. parent_party_id, party_level carry 안 함".**

urm.parties 에는 이 컬럼 없음. V1 caller 가 사용한다면:
- (a) 코드 제거 (가장 흔함)
- (b) app.parties carry 영역으로 격리 (Stage 29-d 시 drop)

audit script A8 결과로 site list 확보 후 검토.

---

## §3. 코드 안 건드리는 케이스

### 3-1. module_data._app_* 접근

V1 의 일부 컬럼이 urm 측에서 `module_data` jsonb 의 `_app_*` prefix 키로 보존됨. caller 가 직접 접근하면 그대로 동작.

예: `_app_is_decision_maker`, `_app_module`, `_app_source`, `_app_product_grade`, `_app_organization_id`, `_app_portfolio_company_id`

→ codemod 처리 안 함. (caller 의 의도된 정상 패턴)

### 3-2. 외부 API response 의 필드명

caller code 에 `body_text`, `org_id` 등이 있을 때 외부 API response 파싱 컨텍스트면 정상 — DB call 아님.

→ rename_codemod.ps1 은 false positive 발생 가능. -DryRun + 수동 검토 필수.

대표 false positive 패턴:
- LinkedIn API: `country` (ISO 코드)
- Gmail API: `body` 내부 sub-field
- Slack API: `text` (body_text 아님)

검토 시 line context 확인. import 또는 함수 호출 컨텍스트로 판별.

---

## §4. 적용 순서

1. **dry run 으로 매치 site list 확보**:
   ```powershell
   .\rename_codemod.ps1 -ProjectRoot . -DryRun | Tee-Object stage29c_rename_dryrun.log
   ```

2. **stage29c_rename_log.csv 검토**. false positive 식별.

3. **자동 적용 (확신되는 패턴부터)**:
   ```powershell
   .\rename_codemod.ps1 -ProjectRoot . -Apply
   ```

4. **빌드 + tsc 확인**:
   ```powershell
   npm run build
   npx tsc --noEmit
   ```

5. **수동 처리 항목 (§2) 별도 작업**:
   - audit script A4 결과의 party_type 호출 사이트 → `party_type_join_pattern.ts` 패턴 적용
   - audit script A7 결과의 portfolio_companies → V2 패턴
   - audit script A8 결과의 parent_party_id → 제거 또는 격리

6. **다시 빌드 + tsc**:
   ```powershell
   npm run build
   npx tsc --noEmit
   ```

7. **git diff 검토 + commit**:
   ```powershell
   git diff --stat
   git diff > stage29c_rename.patch
   ```

---

## §5. 통계 추정 (audit script A3 결과로 정확화)

| 카테고리 | 예상 매치 수 (typical project) | 자동 처리 |
|---|---:|---|
| org_id | 5–20 | ✅ |
| body_text | 1–5 | ✅ |
| 'country' literal | 1–3 | ✅ |
| .country accessor | 1–10 | ✅ |
| stage_position | 0–5 | ✅ |
| party_type (직접) | 10–50 | ❌ 수동 |
| portfolio_companies (V1) | 1–10 | ❌ 수동 |
| parent_party_id / party_level | 0–5 | ❌ 수동 |

총 자동 처리 추정: 10–40 매치. 수동 처리 추정: 10–60 매치.
```

### Subdir: `05_urm_verification_sql`

#### `check_party_type_mapping.sql` (10328 bytes)

```sql
-- ============================================================================
-- Stage 29-c · 05 · check_party_type_mapping.sql
-- ============================================================================
-- 목적: app.parties.party_type (enum) 에서 urm.parties.party_type_id (FK) 로의
--       매핑 분포 분석 및 누락/불일치 식별.
--
-- 배경:
--   app.parties.party_type enum 값: company | organization | individual | fund | government
--   urm.party_types 7 코드: investor | paper_mill | filler_supplier | buyer |
--                             customer | partner | government_grant
--
--   매핑 logic (Stage 29-b 의 ε / 일반 migration):
--     - fund            → 삭제 (V2 미지원)
--     - organization    → 삭제 (단 3 HQ 는 filler_supplier 로)
--     - individual      → 미이전 (contacts 로 분리)
--     - government      → government_grant
--     - company         → 6 sub-type (profile 테이블 존재 여부로 결정):
--         * investor_profile  있음 → investor
--         * paper_mill_profile 있음 → paper_mill
--         * filler_supplier_profile 있음 → filler_supplier
--         * 그 외 → buyer / customer / partner (module_data 로 판단)
--
-- 실행 환경: Supabase SQL Editor (single SELECT)
--
-- 출력: 4개 섹션 (Q1-Q4) 의 UNION ALL 결과셋
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- Q1: app.parties enum 분포 (handoff §7 D group 확인)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'Q1-APP-DIST'::text AS section,
  COALESCE(party_type::text, 'NULL') AS key,
  COUNT(*)::int AS active_cnt,
  SUM(CASE WHEN deleted_at IS NULL THEN 0 ELSE 1 END)::int AS soft_deleted_cnt,
  ''::text AS note
FROM app.parties
GROUP BY party_type
HAVING TRUE  -- placeholder, all groups

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Q2: urm.parties → party_types code 분포 (현재 매핑 결과)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'Q2-URM-DIST'::text AS section,
  COALESCE(pt.code, '<NULL party_type_id>') AS key,
  COUNT(*)::int AS active_cnt,
  0::int AS soft_deleted_cnt,
  CASE
    WHEN pt.code IS NULL THEN 'URM 원칙 위반 — DELETE 후보'
    ELSE 'OK — 7 정규 코드'
  END AS note
FROM urm.parties p
LEFT JOIN urm.party_types pt ON pt.id = p.party_type_id
WHERE p.deleted_at IS NULL
GROUP BY pt.code

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Q3: cross-tab — app enum × urm code 매핑 매트릭스
-- ────────────────────────────────────────────────────────────────────────
-- app.party_type 별로 urm 측에 어떤 code 로 매핑되었는지 (id 기준 JOIN)
SELECT
  'Q3-CROSS-MAP'::text AS section,
  (COALESCE(ap.party_type::text, 'NULL_app') || ' → ' || COALESCE(pt.code, 'NULL_urm'))::text AS key,
  COUNT(*)::int AS active_cnt,
  0::int AS soft_deleted_cnt,
  CASE
    WHEN ap.party_type::text = 'company' AND pt.code IN ('investor','paper_mill','filler_supplier','buyer','customer','partner')
      THEN 'OK — company sub-type 매핑'
    WHEN ap.party_type::text = 'government' AND pt.code = 'government_grant'
      THEN 'OK — government → government_grant'
    WHEN ap.party_type::text = 'individual'
      THEN 'INVESTIGATE — individual 은 urm 이전 안 됐어야 함'
    WHEN pt.code IS NULL
      THEN 'INVALID — URM 원칙 위반'
    ELSE 'UNUSUAL — 매핑 규칙 외'
  END AS note
FROM app.parties ap
JOIN urm.parties up ON up.id = ap.id
LEFT JOIN urm.party_types pt ON pt.id = up.party_type_id
WHERE ap.deleted_at IS NULL
  AND up.deleted_at IS NULL
GROUP BY ap.party_type, pt.code

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Q4: profile 테이블 존재 여부로 검증 — urm.parties 의 sub-type 정합성
-- ────────────────────────────────────────────────────────────────────────
-- party_type=investor 이지만 investor_profile 없음
SELECT
  'Q4-PROFILE-CHECK'::text,
  'investor 인데 investor_profile 없음'::text,
  (SELECT COUNT(*)::int FROM urm.parties p
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code = 'investor'
     AND p.deleted_at IS NULL
     AND NOT EXISTS (
       SELECT 1 FROM urm.investor_profile ip WHERE ip.party_id = p.id
     )),
  0,
  'DATA QUALITY — investor 인데 profile 부재'

UNION ALL

SELECT
  'Q4-PROFILE-CHECK',
  'investor_profile 있는데 party_type ≠ investor',
  (SELECT COUNT(*)::int FROM urm.investor_profile ip
   JOIN urm.parties p ON p.id = ip.party_id
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code <> 'investor'),
  0,
  'DATA QUALITY — 역방향 mismatch'

UNION ALL

SELECT
  'Q4-PROFILE-CHECK',
  'paper_mill 인데 paper_mill_profile 없음',
  (SELECT COUNT(*)::int FROM urm.parties p
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code = 'paper_mill'
     AND p.deleted_at IS NULL
     AND NOT EXISTS (
       SELECT 1 FROM urm.paper_mill_profile pmp WHERE pmp.party_id = p.id
     )),
  0,
  'DATA QUALITY — paper_mill 인데 profile 부재'

UNION ALL

SELECT
  'Q4-PROFILE-CHECK',
  'paper_mill_profile 있는데 party_type ≠ paper_mill',
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile pmp
   JOIN urm.parties p ON p.id = pmp.party_id
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code <> 'paper_mill'),
  0,
  'DATA QUALITY — 역방향 mismatch'

UNION ALL

SELECT
  'Q4-PROFILE-CHECK',
  'filler_supplier 인데 filler_supplier_profile 없음',
  (SELECT COUNT(*)::int FROM urm.parties p
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code = 'filler_supplier'
     AND p.deleted_at IS NULL
     AND NOT EXISTS (
       SELECT 1 FROM urm.filler_supplier_profile fsp WHERE fsp.party_id = p.id
     )),
  0,
  'DATA QUALITY — filler_supplier 인데 profile 부재'

UNION ALL

SELECT
  'Q4-PROFILE-CHECK',
  'filler_supplier_profile 있는데 party_type ≠ filler_supplier',
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile fsp
   JOIN urm.parties p ON p.id = fsp.party_id
   JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE pt.code <> 'filler_supplier'),
  0,
  'INFO — 3 HQ 예외 가능 (handoff §5 ε)'

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Q5: handoff §7 의 expected 7 코드별 카운트 (참조 자료)
-- ────────────────────────────────────────────────────────────────────────
-- urm.investor_profile 101  → investor 코드 약 101
-- urm.paper_mill_profile 1074 → paper_mill 코드 약 1074
-- urm.filler_supplier_profile 232 → filler_supplier 코드 약 232
-- buyer / customer / partner / government_grant → 잔여 분배
-- total active 1532 = 101 + 1074 + 232 + (buyer/customer/partner/govt 합 ≈ 125)

SELECT
  'Q5-EXPECTED'::text,
  pt.code,
  (SELECT COUNT(*)::int FROM urm.parties p
    WHERE p.party_type_id = pt.id
      AND p.deleted_at IS NULL),
  0,
  CASE pt.code
    WHEN 'investor' THEN 'expect ~101 (investor_profile 카운트와 일치)'
    WHEN 'paper_mill' THEN 'expect ~1074 (paper_mill_profile 카운트와 일치)'
    WHEN 'filler_supplier' THEN 'expect ~232 (filler_supplier_profile 카운트와 일치)'
    WHEN 'buyer' THEN 'expect — 분포 분석 필요'
    WHEN 'customer' THEN 'expect — 분포 분석 필요'
    WHEN 'partner' THEN 'expect — 분포 분석 필요'
    WHEN 'government_grant' THEN 'expect — government enum migration 결과'
    ELSE ''
  END
FROM urm.party_types pt
WHERE pt.code IN ('investor','paper_mill','filler_supplier','buyer','customer','partner','government_grant')

) results
ORDER BY section, key;

-- ============================================================================
-- 사용:
-- 1. Supabase SQL Editor 통째 실행
-- 2. Q1 — app.parties enum 분포 (handoff §7 와 대조)
--    - fund / organization 행 발견 시 정리 미완료 → 즉시 정리
-- 3. Q2 — urm.parties code 분포 (7 코드 외 0 기대)
-- 4. Q3 — app × urm 매핑 cross-tab. note 가 OK 아닌 row 모두 검토.
-- 5. Q4 — profile 무결성 (party_type ↔ profile 테이블 양방향 검증)
-- 6. Q5 — handoff §7 expected 카운트와 대조
--
-- ⚠️  caller code 의 party_type 참조는 모두 JOIN to urm.party_types 패턴 필요.
--     04_column_rename/party_type_join_pattern.ts 참조.
-- ============================================================================
```

#### `cleanup_non_urm_data.sql` (14951 bytes)

```sql
-- ============================================================================
-- Stage 29-c · 05 · cleanup_non_urm_data.sql
-- ============================================================================
-- 목적: 사용자 명시 원칙 "URM 구조에 맞지 않는 데이터는 삭제 OK" 의 실행 SQL.
--       identify_non_urm_data.sql 로 위반 row 확인 후 본 파일의 statement 들을
--       하나씩 실행.
--
-- 실행 환경: Supabase SQL Editor (single statement only, no BEGIN/COMMIT)
--
-- ⚠️ 주의:
--   - 각 statement 는 독립 실행. 반드시 [PRE] / [DELETE] / [POST] 순서.
--   - [PRE] 로 영향 row 개수 확인 → 0 이면 [DELETE] skip 가능
--   - [POST] 로 결과 검증 → 0 이어야 정상
--   - 본 SQL 의 모든 DELETE 는 사용자 원칙으로 정당화됨. 별도 승인 불요.
-- ============================================================================


-- ============================================================================
-- §A. urm.parties.party_type_id IS NULL 또는 7 코드 외 — DELETE
-- ============================================================================
-- 위반: URM 원칙 — Parties 는 반드시 7 정규 코드 중 하나.

-- [A-PRE] 영향 row 확인
SELECT 'A-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.parties WHERE party_type_id IS NULL) AS null_count,
  (SELECT COUNT(*) FROM urm.parties p
   WHERE p.party_type_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM urm.party_types pt
       WHERE pt.id = p.party_type_id
         AND pt.code IN ('investor','paper_mill','filler_supplier','buyer','customer','partner','government_grant')
     )) AS invalid_code_count;

-- [A-DELETE-1] NULL party_type_id row 삭제
-- ⚠️ 실행 전 [A-PRE] 의 null_count 확인. 0 이면 skip.
DELETE FROM urm.parties
WHERE party_type_id IS NULL;

-- [A-DELETE-2] 7 정규 코드 외 row 삭제
DELETE FROM urm.parties
WHERE party_type_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM urm.party_types pt
    WHERE pt.id = urm.parties.party_type_id
      AND pt.code IN ('investor','paper_mill','filler_supplier','buyer','customer','partner','government_grant')
  );

-- [A-POST] 검증
SELECT 'A-POST' AS stage,
  (SELECT COUNT(*) FROM urm.parties WHERE party_type_id IS NULL) AS null_count_after,
  (SELECT COUNT(*) FROM urm.parties p
   WHERE p.party_type_id IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM urm.party_types pt
       WHERE pt.id = p.party_type_id
         AND pt.code IN ('investor','paper_mill','filler_supplier','buyer','customer','partner','government_grant')
     )) AS invalid_code_count_after;
-- expect: 0 / 0


-- ============================================================================
-- §B. app.parties.party_type IN ('fund', 'organization') — DELETE
-- ============================================================================
-- 위반: handoff §8 carry-forward — V2 미지원. ε hard-delete 후 잔재.
-- ⚠️ 단 3 HQ (Carmeuse / Schaefer Kalk / Sibelco) 의 urm.filler_supplier_profile 은
--    유지. app.parties 측만 삭제.

-- [B-PRE]
SELECT 'B-PRE' AS stage,
  (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'fund') AS fund_count,
  (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'organization') AS org_count;

-- [B-DELETE-1] fund
DELETE FROM app.parties WHERE party_type::text = 'fund';

-- [B-DELETE-2] organization
-- 단 3 HQ id 보존이 urm.filler_supplier_profile 에 있는지 확인 (FK CASCADE 없음 — single direction)
DELETE FROM app.parties WHERE party_type::text = 'organization';

-- [B-POST]
SELECT 'B-POST' AS stage,
  (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'fund') AS fund_count_after,
  (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'organization') AS org_count_after;
-- expect: 0 / 0


-- ============================================================================
-- §C. urm.contacts.firm_party_id orphan — DELETE
-- ============================================================================
-- 위반: URM 원칙 — Contacts → Parties FK 무결성.
-- FK constraint 가 있으면 정상 0. 만약 있다면 FK 가 deferred 였거나 누락된 상태.

-- [C-PRE]
SELECT 'C-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.contacts c
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = c.firm_party_id
   )) AS orphan_count;

-- [C-DELETE]
DELETE FROM urm.contacts
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.contacts.firm_party_id
);

-- [C-POST]
SELECT 'C-POST' AS stage,
  (SELECT COUNT(*) FROM urm.contacts c
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = c.firm_party_id
   )) AS orphan_count_after;
-- expect: 0


-- ============================================================================
-- §D. urm.contacts_history orphan — DELETE
-- ============================================================================
-- 위반: URM 원칙 — Contact_history → Contacts FK + Parties FK 무결성.

-- [D-PRE]
SELECT 'D-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.contacts_history ch
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.contacts c WHERE c.id = ch.contact_id
   )) AS contact_orphan_count,
  (SELECT COUNT(*) FROM urm.contacts_history ch
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = ch.firm_party_id
   )) AS firm_orphan_count;

-- [D-DELETE-1] contact_id orphan
DELETE FROM urm.contacts_history
WHERE NOT EXISTS (
  SELECT 1 FROM urm.contacts c WHERE c.id = urm.contacts_history.contact_id
);

-- [D-DELETE-2] firm_party_id orphan
DELETE FROM urm.contacts_history
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.contacts_history.firm_party_id
);

-- [D-POST]
SELECT 'D-POST' AS stage,
  (SELECT COUNT(*) FROM urm.contacts_history ch
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.contacts c WHERE c.id = ch.contact_id
   )) AS contact_orphan_count_after,
  (SELECT COUNT(*) FROM urm.contacts_history ch
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = ch.firm_party_id
   )) AS firm_orphan_count_after;
-- expect: 0 / 0


-- ============================================================================
-- §E. urm.party_supply_links orphan — DELETE
-- ============================================================================

-- [E-PRE]
SELECT 'E-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.party_supply_links psl
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = psl.buyer_party_id
   )) AS buyer_orphan,
  (SELECT COUNT(*) FROM urm.party_supply_links psl
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = psl.supplier_party_id
   )) AS supplier_orphan;

-- [E-DELETE-1]
DELETE FROM urm.party_supply_links
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.party_supply_links.buyer_party_id
);

-- [E-DELETE-2]
DELETE FROM urm.party_supply_links
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.party_supply_links.supplier_party_id
);

-- [E-POST]
SELECT 'E-POST' AS stage,
  (SELECT COUNT(*) FROM urm.party_supply_links psl
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = psl.buyer_party_id
   )) AS buyer_orphan_after,
  (SELECT COUNT(*) FROM urm.party_supply_links psl
   WHERE NOT EXISTS (
     SELECT 1 FROM urm.parties p WHERE p.id = psl.supplier_party_id
   )) AS supplier_orphan_after;


-- ============================================================================
-- §F. urm.* profile.party_id orphan — DELETE
-- ============================================================================

-- [F-PRE]
SELECT 'F-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.investor_profile ip
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ip.party_id)) AS investor_orphan,
  (SELECT COUNT(*) FROM urm.paper_mill_profile pmp
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = pmp.party_id)) AS paper_mill_orphan,
  (SELECT COUNT(*) FROM urm.filler_supplier_profile fsp
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = fsp.party_id)) AS filler_orphan;

-- [F-DELETE-1] investor_profile orphan
DELETE FROM urm.investor_profile
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.investor_profile.party_id
);

-- [F-DELETE-2] paper_mill_profile orphan
DELETE FROM urm.paper_mill_profile
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.paper_mill_profile.party_id
);

-- [F-DELETE-3] filler_supplier_profile orphan
DELETE FROM urm.filler_supplier_profile
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.filler_supplier_profile.party_id
);

-- [F-POST]
SELECT 'F-POST' AS stage,
  (SELECT COUNT(*) FROM urm.investor_profile ip
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ip.party_id)) AS investor_orphan_after,
  (SELECT COUNT(*) FROM urm.paper_mill_profile pmp
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = pmp.party_id)) AS paper_mill_orphan_after,
  (SELECT COUNT(*) FROM urm.filler_supplier_profile fsp
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = fsp.party_id)) AS filler_orphan_after;


-- ============================================================================
-- §G. urm.investor_portfolio_companies.investor_party_id orphan — DELETE
-- ============================================================================

-- [G-PRE]
SELECT 'G-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.investor_portfolio_companies ipc
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ipc.investor_party_id)) AS orphan_count;

-- [G-DELETE]
DELETE FROM urm.investor_portfolio_companies
WHERE NOT EXISTS (
  SELECT 1 FROM urm.parties p WHERE p.id = urm.investor_portfolio_companies.investor_party_id
);

-- [G-POST]
SELECT 'G-POST' AS stage,
  (SELECT COUNT(*) FROM urm.investor_portfolio_companies ipc
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ipc.investor_party_id)) AS orphan_count_after;


-- ============================================================================
-- §H. URM 흐름 orphan — Pipeline / Stage / Deal / Task / Engagement
-- ============================================================================
-- 정상 상태: 모두 0 row (handoff §7 α+β TRUNCATE).
-- caller cutover 후 신규 row 생성 시작. orphan 발생하면 즉시 정리.

-- [H-PRE]
SELECT 'H-PRE' AS stage,
  (SELECT COUNT(*) FROM urm.stages s
   WHERE NOT EXISTS (SELECT 1 FROM urm.pipelines p WHERE p.id = s.pipeline_id)) AS stage_orphan,
  (SELECT COUNT(*) FROM urm.deals d
   WHERE NOT EXISTS (SELECT 1 FROM urm.pipelines p WHERE p.id = d.pipeline_id)) AS deal_orphan,
  (SELECT COUNT(*) FROM urm.tasks t
   WHERE t.deal_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM urm.deals d WHERE d.id = t.deal_id)) AS task_orphan,
  (SELECT COUNT(*) FROM urm.engagement_attendees ea
   WHERE NOT EXISTS (SELECT 1 FROM urm.engagements e WHERE e.id = ea.engagement_id)) AS attendee_orphan,
  (SELECT COUNT(*) FROM urm.engagement_documents ed
   WHERE NOT EXISTS (SELECT 1 FROM urm.engagements e WHERE e.id = ed.engagement_id)) AS document_orphan;

-- [H-DELETE-1] stage orphan
DELETE FROM urm.stages
WHERE NOT EXISTS (
  SELECT 1 FROM urm.pipelines p WHERE p.id = urm.stages.pipeline_id
);

-- [H-DELETE-2] deal orphan
DELETE FROM urm.deals
WHERE NOT EXISTS (
  SELECT 1 FROM urm.pipelines p WHERE p.id = urm.deals.pipeline_id
);

-- [H-DELETE-3] task orphan
DELETE FROM urm.tasks
WHERE deal_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM urm.deals d WHERE d.id = urm.tasks.deal_id
  );

-- [H-DELETE-4] engagement_attendees orphan
DELETE FROM urm.engagement_attendees
WHERE NOT EXISTS (
  SELECT 1 FROM urm.engagements e WHERE e.id = urm.engagement_attendees.engagement_id
);

-- [H-DELETE-5] engagement_documents orphan
DELETE FROM urm.engagement_documents
WHERE NOT EXISTS (
  SELECT 1 FROM urm.engagements e WHERE e.id = urm.engagement_documents.engagement_id
);

-- [H-POST]
SELECT 'H-POST' AS stage,
  (SELECT COUNT(*) FROM urm.stages s
   WHERE NOT EXISTS (SELECT 1 FROM urm.pipelines p WHERE p.id = s.pipeline_id)) AS stage_orphan_after,
  (SELECT COUNT(*) FROM urm.deals d
   WHERE NOT EXISTS (SELECT 1 FROM urm.pipelines p WHERE p.id = d.pipeline_id)) AS deal_orphan_after,
  (SELECT COUNT(*) FROM urm.tasks t
   WHERE t.deal_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM urm.deals d WHERE d.id = t.deal_id)) AS task_orphan_after,
  (SELECT COUNT(*) FROM urm.engagement_attendees ea
   WHERE NOT EXISTS (SELECT 1 FROM urm.engagements e WHERE e.id = ea.engagement_id)) AS attendee_orphan_after,
  (SELECT COUNT(*) FROM urm.engagement_documents ed
   WHERE NOT EXISTS (SELECT 1 FROM urm.engagements e WHERE e.id = ed.engagement_id)) AS document_orphan_after;


-- ============================================================================
-- §I. 최종 검증 — identify_non_urm_data.sql 재실행 권장
-- ============================================================================
-- 본 cleanup 완료 후 identify_non_urm_data.sql 통째 재실행.
-- 모든 카테고리의 sample_count = 0 인 것이 정상.

-- 빠른 요약 query:
SELECT 'I-SUMMARY' AS stage,
  (SELECT COUNT(*) FROM urm.parties WHERE party_type_id IS NULL) AS urm_parties_null_type,
  (SELECT COUNT(*) FROM app.parties WHERE party_type::text IN ('fund','organization')) AS app_deprecated_enum,
  (SELECT COUNT(*) FROM urm.contacts c
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = c.firm_party_id)) AS contact_orphan,
  (SELECT COUNT(*) FROM urm.contacts_history ch
   WHERE NOT EXISTS (SELECT 1 FROM urm.contacts c WHERE c.id = ch.contact_id)
      OR NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ch.firm_party_id)) AS history_orphan,
  (SELECT COUNT(*) FROM urm.investor_profile ip
   WHERE NOT EXISTS (SELECT 1 FROM urm.parties p WHERE p.id = ip.party_id)) AS investor_profile_orphan;
-- expect: 모두 0

-- ============================================================================
-- 실행 순서:
--   1. §A-PRE 실행 → null_count + invalid_code_count 확인
--   2. 두 값 모두 0 이면 §A skip. 1 이상이면 §A-DELETE 실행
--   3. §A-POST 로 검증 (모두 0 확인)
--   4. §B, §C, ..., §H 동일 패턴 반복
--   5. §I 로 전체 요약 확인
--
-- ⚠️ 모든 DELETE 는 사용자 명시 원칙으로 정당화됨:
--    "URM 구조에 맞지 않는 데이터는 삭제 OK"
--
-- ⚠️ 본 SQL 실행 전 verify_carry_forward_counts.sql 결과를 기록해 두면
--    삭제 영향 추적에 유리.
-- ============================================================================
```

#### `identify_non_urm_data.sql` (18087 bytes)

```sql
-- ============================================================================
-- Stage 29-c · 05 · identify_non_urm_data.sql
-- ============================================================================
-- 목적: 사용자 원칙 "URM 구조에 맞지 않는 데이터는 삭제 OK" 에 따라
--       URM V2 구조와 정합하지 않는 잔존 데이터 탐지.
--
-- URM 기본원칙 (사용자 명시):
--   Pipeline → Stages → Deals → Deals_Checklist → Tasks → Engagements
--   Parties → Contacts → Contact_history → Filler_Suppliers_profile (+investor/paper_mill)
--
-- 실행 환경: Supabase SQL Editor (single SELECT, no BEGIN/COMMIT)
--
-- 출력: (category, finding, table_fqdn, sample_count, action_hint)
--       이 query 는 READ-ONLY. 실제 DELETE 는 caller cutover 종결 후 별도 실행.
--
-- ⚠️  Stage 29-d (app.* drop) 의 사전 분석 자료로도 활용.
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- 1. urm.parties 잔존 fund/organization (handoff §5 ε hard-delete 후 잔재)
-- ────────────────────────────────────────────────────────────────────────
-- urm.party_types 에는 fund/organization 코드 없음 → party_type_id NULL 인 row 가
-- URM 원칙 위반. 이런 row 발견되면 삭제 후보.

SELECT
  'PARTY_TYPE_VIOLATION'::text AS category,
  'urm.parties.party_type_id IS NULL (URM 원칙 위반)'::text AS finding,
  'urm.parties'::text AS table_fqdn,
  (SELECT COUNT(*)::int FROM urm.parties WHERE party_type_id IS NULL) AS sample_count,
  'DELETE 후보 — URM 7 코드 (investor/paper_mill/filler_supplier/buyer/customer/partner/government_grant) 외'::text AS action_hint

UNION ALL

-- 2. urm.parties 가 7 코드 중 하나에도 매핑되지 않은 row
SELECT
  'PARTY_TYPE_VIOLATION'::text,
  'urm.parties 가 7 정규 코드 외 party_type_id 참조'::text,
  'urm.parties'::text,
  (SELECT COUNT(*)::int FROM urm.parties p
    WHERE p.party_type_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM urm.party_types pt
        WHERE pt.id = p.party_type_id
          AND pt.code IN ('investor','paper_mill','filler_supplier',
                          'buyer','customer','partner','government_grant')
      ))::int,
  'DELETE 후보 — FK 무효값 또는 deprecated code 참조'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 3. urm.contacts 의 firm_party_id orphan (URM Parties-Contacts 원칙 위반)
-- ────────────────────────────────────────────────────────────────────────
-- URM 원칙: Contacts 는 Parties 에 종속. firm_party_id 가 가리키는 parties 가
-- 부재하면 URM 원칙 위반.

SELECT
  'CONTACT_ORPHAN'::text,
  'urm.contacts.firm_party_id orphan (Parties 부재)'::text,
  'urm.contacts'::text,
  (SELECT COUNT(*)::int FROM urm.contacts c
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = c.firm_party_id
    ))::int,
  'DELETE 후보 — FK constraint 으로 막혀있어야 정상 (0 기대)'::text

UNION ALL

-- 4. urm.contacts_history orphan (URM Contacts-Contact_history 원칙)
SELECT
  'HISTORY_ORPHAN'::text,
  'urm.contacts_history.contact_id orphan'::text,
  'urm.contacts_history'::text,
  (SELECT COUNT(*)::int FROM urm.contacts_history ch
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.contacts c WHERE c.id = ch.contact_id
    ))::int,
  'DELETE 후보 — Contact 삭제 시 history 도 동행 (CASCADE 기대)'::text

UNION ALL

SELECT
  'HISTORY_ORPHAN'::text,
  'urm.contacts_history.firm_party_id orphan'::text,
  'urm.contacts_history'::text,
  (SELECT COUNT(*)::int FROM urm.contacts_history ch
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = ch.firm_party_id
    ))::int,
  'DELETE 후보 — firm party 가 사라진 history'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 5. urm.party_supply_links orphan
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'SUPPLY_ORPHAN'::text,
  'urm.party_supply_links.buyer_party_id orphan'::text,
  'urm.party_supply_links'::text,
  (SELECT COUNT(*)::int FROM urm.party_supply_links psl
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = psl.buyer_party_id
    ))::int,
  'DELETE 후보 — buyer party 부재'::text

UNION ALL

SELECT
  'SUPPLY_ORPHAN'::text,
  'urm.party_supply_links.supplier_party_id orphan'::text,
  'urm.party_supply_links'::text,
  (SELECT COUNT(*)::int FROM urm.party_supply_links psl
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = psl.supplier_party_id
    ))::int,
  'DELETE 후보 — supplier party 부재'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 6. urm.* profile 의 party_id orphan (Parties-Profile 원칙)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'PROFILE_ORPHAN'::text,
  'urm.investor_profile.party_id orphan'::text,
  'urm.investor_profile'::text,
  (SELECT COUNT(*)::int FROM urm.investor_profile ip
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = ip.party_id
    ))::int,
  'DELETE 후보 — investor party 부재'::text

UNION ALL

SELECT
  'PROFILE_ORPHAN'::text,
  'urm.paper_mill_profile.party_id orphan'::text,
  'urm.paper_mill_profile'::text,
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile pmp
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = pmp.party_id
    ))::int,
  'DELETE 후보 — paper mill party 부재'::text

UNION ALL

SELECT
  'PROFILE_ORPHAN'::text,
  'urm.filler_supplier_profile.party_id orphan'::text,
  'urm.filler_supplier_profile'::text,
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile fsp
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = fsp.party_id
    ))::int,
  'DELETE 후보 — filler supplier party 부재'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 7. profile type mismatch (Parties-Profile 무결성)
-- ────────────────────────────────────────────────────────────────────────
-- urm.investor_profile.party_id 가 가리키는 party 의 party_type_id 가 'investor' 아님
SELECT
  'PROFILE_TYPE_MISMATCH'::text,
  'urm.investor_profile party_type ≠ investor'::text,
  'urm.investor_profile'::text,
  (SELECT COUNT(*)::int FROM urm.investor_profile ip
   JOIN urm.parties p ON p.id = ip.party_id
   LEFT JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE COALESCE(pt.code, '') <> 'investor')::int,
  'DATA QUALITY — investor_profile 인데 party_type 이 investor 아님'::text

UNION ALL

SELECT
  'PROFILE_TYPE_MISMATCH'::text,
  'urm.paper_mill_profile party_type ≠ paper_mill'::text,
  'urm.paper_mill_profile'::text,
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile pmp
   JOIN urm.parties p ON p.id = pmp.party_id
   LEFT JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE COALESCE(pt.code, '') <> 'paper_mill')::int,
  'DATA QUALITY — paper_mill_profile 인데 party_type 이 paper_mill 아님'::text

UNION ALL

SELECT
  'PROFILE_TYPE_MISMATCH'::text,
  'urm.filler_supplier_profile party_type ≠ filler_supplier'::text,
  'urm.filler_supplier_profile'::text,
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile fsp
   JOIN urm.parties p ON p.id = fsp.party_id
   LEFT JOIN urm.party_types pt ON pt.id = p.party_type_id
   WHERE COALESCE(pt.code, '') <> 'filler_supplier')::int,
  'DATA QUALITY — filler_supplier_profile 인데 party_type 이 filler_supplier 아님. 단 3 HQ 보존은 예외'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 8. urm.investor_portfolio_companies orphan
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'IPC_ORPHAN'::text,
  'urm.investor_portfolio_companies.investor_party_id orphan'::text,
  'urm.investor_portfolio_companies'::text,
  (SELECT COUNT(*)::int FROM urm.investor_portfolio_companies ipc
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.parties p WHERE p.id = ipc.investor_party_id
    ))::int,
  'DELETE 후보 — investor party 부재'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 9. app.parties 의 사라진 V2 enum 값 잔재 (반드시 0 — ε 결과)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'APP_ENUM_REMNANT'::text,
  'app.parties.party_type=fund (deprecated)'::text,
  'app.parties'::text,
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'fund')::int,
  'DELETE 즉시 — fund V2 미지원 (handoff §8)'::text

UNION ALL

SELECT
  'APP_ENUM_REMNANT'::text,
  'app.parties.party_type=organization (deprecated)'::text,
  'app.parties'::text,
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'organization')::int,
  'DELETE 즉시 — organization V2 미지원 (단 3 HQ 는 urm.filler_supplier_profile 보존)'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 10. app.parties 가 urm.parties 로 이전 안 된 row (cutover 누락)
-- ────────────────────────────────────────────────────────────────────────
-- 사용자 원칙: URM 에 없는 데이터는 삭제 OK. 단 company/individual 보존 의도 확인
SELECT
  'APP_NOT_IN_URM'::text,
  'app.parties.party_type=company 가 urm.parties 에 없음'::text,
  'app.parties'::text,
  (SELECT COUNT(*)::int FROM app.parties ap
    WHERE ap.deleted_at IS NULL
      AND ap.party_type::text = 'company'
      AND NOT EXISTS (
        SELECT 1 FROM urm.parties up WHERE up.id = ap.id
      ))::int,
  'INVESTIGATE — Stage 29-b 의 매핑 누락? (id 보존 원칙)'::text

UNION ALL

SELECT
  'APP_NOT_IN_URM'::text,
  'app.parties.party_type=individual 활성 (모두 soft-deleted 기대)'::text,
  'app.parties'::text,
  (SELECT COUNT(*)::int FROM app.parties
    WHERE deleted_at IS NULL AND party_type::text = 'individual')::int,
  'EXPECT 0 — handoff §7 D group: 0/118 (모두 soft-deleted)'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 11. urm.parties 가 app.parties 에 없는 row (역방향 — 신규 추가 의심)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'URM_NOT_IN_APP'::text,
  'urm.parties 가 app.parties 에 없음 (신규 row 의심)'::text,
  'urm.parties'::text,
  (SELECT COUNT(*)::int FROM urm.parties up
    WHERE NOT EXISTS (
      SELECT 1 FROM app.parties ap WHERE ap.id = up.id
    ))::int,
  'INVESTIGATE — Stage 29-b 후 신규 insert? caller writer 추적'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 12. URM 핵심 흐름 (Pipeline → Stages → Deals → Tasks) 의 무결성
-- ────────────────────────────────────────────────────────────────────────
-- 모두 0 expected. row 발견 시 = α+β TRUNCATE 후 신규 traffic 발생
SELECT
  'URM_FLOW_NEW_TRAFFIC'::text,
  'urm.pipelines 에 row 발생'::text,
  'urm.pipelines'::text,
  (SELECT COUNT(*)::int FROM urm.pipelines),
  'INFO — 0 이면 OK. row 있으면 caller cutover 시 의도된 신규 작성 확인'::text

UNION ALL

SELECT
  'URM_FLOW_NEW_TRAFFIC'::text,
  'urm.stages 에 row 발생'::text,
  'urm.stages'::text,
  (SELECT COUNT(*)::int FROM urm.stages),
  'INFO — pipeline_id 가 부재한 stage 가 있으면 orphan'::text

UNION ALL

SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.stages.pipeline_id orphan'::text,
  'urm.stages'::text,
  (SELECT COUNT(*)::int FROM urm.stages s
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.pipelines p WHERE p.id = s.pipeline_id
    )),
  'DELETE 후보 — orphan stage'::text

UNION ALL

SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.deals.pipeline_id orphan'::text,
  'urm.deals'::text,
  (SELECT COUNT(*)::int FROM urm.deals d
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.pipelines p WHERE p.id = d.pipeline_id
    )),
  'DELETE 후보 — orphan deal'::text

UNION ALL

SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.tasks.deal_id orphan (있으면)'::text,
  'urm.tasks'::text,
  (SELECT COUNT(*)::int FROM urm.tasks t
    WHERE t.deal_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM urm.deals d WHERE d.id = t.deal_id
      )),
  'DELETE 후보 — deal 부재 task'::text

UNION ALL

SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.tasks.checklist_id orphan (있으면)'::text,
  'urm.tasks'::text,
  (SELECT COUNT(*)::int FROM urm.tasks t
    WHERE t.checklist_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM urm.deal_checklists dc WHERE dc.id = t.checklist_id
      )),
  'INFO — checklist FK 는 ON DELETE SET NULL. 정상이면 항상 0'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- 13. urm.engagements 흐름 (Engagements → attendees / documents)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.engagement_attendees.engagement_id orphan'::text,
  'urm.engagement_attendees'::text,
  (SELECT COUNT(*)::int FROM urm.engagement_attendees ea
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.engagements e WHERE e.id = ea.engagement_id
    )),
  'DELETE 후보'::text

UNION ALL

SELECT
  'URM_FLOW_ORPHAN'::text,
  'urm.engagement_documents.engagement_id orphan'::text,
  'urm.engagement_documents'::text,
  (SELECT COUNT(*)::int FROM urm.engagement_documents ed
    WHERE NOT EXISTS (
      SELECT 1 FROM urm.engagements e WHERE e.id = ed.engagement_id
    )),
  'DELETE 후보'::text

) results
ORDER BY category, finding;

-- ============================================================================
-- 사용:
-- 1. Supabase SQL Editor 통째 실행
-- 2. sample_count 컬럼 = 위반 row 개수
-- 3. action_hint 가 'DELETE 즉시' → 정리 SQL 즉시 실행
-- 4. action_hint 가 'DELETE 후보' → 표본 SELECT 로 확인 후 정리
-- 5. action_hint 가 'INVESTIGATE' → 원인 조사 후 결정
-- 6. action_hint 가 'INFO' → 정보성, 0 정상
--
-- ⚠️  이 query 는 READ-ONLY. 실제 DELETE 는 별도 cleanup script 작성 필요.
--     사용자 원칙 "URM 구조에 맞지 않는 데이터는 삭제 OK" 에 따라
--     PARTY_TYPE_VIOLATION, *_ORPHAN, APP_ENUM_REMNANT 카테고리 모두 정리 대상.
-- ============================================================================
```

#### `verify_carry_forward_counts.sql` (12850 bytes)

```sql
-- ============================================================================
-- Stage 29-c · 05 · verify_carry_forward_counts.sql
-- ============================================================================
-- 목적: handoff §7 의 "Stage 29-b 종결 시점 데이터 snapshot" 과 실제 DB 의
--       row count 일치 여부 검증.
--
-- 실행 환경: Supabase SQL Editor (single SELECT, no BEGIN/COMMIT)
--
-- 출력: (group, table_fqdn, expected, actual, delta, status)
--       status: OK / MISMATCH / TABLE_MISSING
--
-- ⚠️  delta ≠ 0 인 row 발견 시 → handoff §7 와 실제 DB drift. 원인 조사.
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- Group A: urm.* 핵심 master (handoff §7)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'A'::text AS grp,
  'urm.parties (active)'::text AS table_fqdn,
  1532::int AS expected,
  (SELECT COUNT(*)::int FROM urm.parties WHERE deleted_at IS NULL) AS actual,
  (SELECT COUNT(*)::int FROM urm.parties WHERE deleted_at IS NULL) - 1532 AS delta,
  CASE WHEN (SELECT COUNT(*) FROM urm.parties WHERE deleted_at IS NULL) = 1532
       THEN 'OK' ELSE 'MISMATCH' END AS status

UNION ALL

SELECT 'A', 'urm.parties (total inc. soft-deleted)', NULL,
  (SELECT COUNT(*)::int FROM urm.parties),
  NULL, 'INFO'

UNION ALL

SELECT 'A', 'urm.contacts (active)', 217,
  (SELECT COUNT(*)::int FROM urm.contacts WHERE deleted_at IS NULL),
  (SELECT COUNT(*)::int FROM urm.contacts WHERE deleted_at IS NULL) - 217,
  CASE WHEN (SELECT COUNT(*) FROM urm.contacts WHERE deleted_at IS NULL) = 217
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'A', 'urm.contacts_history', 109,
  (SELECT COUNT(*)::int FROM urm.contacts_history),
  (SELECT COUNT(*)::int FROM urm.contacts_history) - 109,
  CASE WHEN (SELECT COUNT(*) FROM urm.contacts_history) = 109
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'A', 'urm.party_supply_links', 117,
  (SELECT COUNT(*)::int FROM urm.party_supply_links),
  (SELECT COUNT(*)::int FROM urm.party_supply_links) - 117,
  CASE WHEN (SELECT COUNT(*) FROM urm.party_supply_links) = 117
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'A', 'urm.plant_supply_links', 0,
  (SELECT COUNT(*)::int FROM urm.plant_supply_links),
  (SELECT COUNT(*)::int FROM urm.plant_supply_links) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.plant_supply_links) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group B: urm.* profile tables
-- ────────────────────────────────────────────────────────────────────────
SELECT 'B', 'urm.investor_profile', 101,
  (SELECT COUNT(*)::int FROM urm.investor_profile),
  (SELECT COUNT(*)::int FROM urm.investor_profile) - 101,
  CASE WHEN (SELECT COUNT(*) FROM urm.investor_profile) = 101
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'B', 'urm.paper_mill_profile', 1074,
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile),
  (SELECT COUNT(*)::int FROM urm.paper_mill_profile) - 1074,
  CASE WHEN (SELECT COUNT(*) FROM urm.paper_mill_profile) = 1074
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'B', 'urm.filler_supplier_profile', 232,
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile),
  (SELECT COUNT(*)::int FROM urm.filler_supplier_profile) - 232,
  CASE WHEN (SELECT COUNT(*) FROM urm.filler_supplier_profile) = 232
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'B', 'urm.investor_portfolio_companies', 422,
  (SELECT COUNT(*)::int FROM urm.investor_portfolio_companies),
  (SELECT COUNT(*)::int FROM urm.investor_portfolio_companies) - 422,
  CASE WHEN (SELECT COUNT(*) FROM urm.investor_portfolio_companies) = 422
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group C: urm.* pipeline/deal/task/engagement (모두 0 — α+β TRUNCATE)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'C', 'urm.pipelines', 0,
  (SELECT COUNT(*)::int FROM urm.pipelines),
  (SELECT COUNT(*)::int FROM urm.pipelines) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.pipelines) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.stages', 0,
  (SELECT COUNT(*)::int FROM urm.stages),
  (SELECT COUNT(*)::int FROM urm.stages) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.stages) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.deals', 0,
  (SELECT COUNT(*)::int FROM urm.deals),
  (SELECT COUNT(*)::int FROM urm.deals) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.deals) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.deal_stage_history', 0,
  (SELECT COUNT(*)::int FROM urm.deal_stage_history),
  (SELECT COUNT(*)::int FROM urm.deal_stage_history) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.deal_stage_history) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.deal_checklists', 0,
  (SELECT COUNT(*)::int FROM urm.deal_checklists),
  (SELECT COUNT(*)::int FROM urm.deal_checklists) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.deal_checklists) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.tasks', 0,
  (SELECT COUNT(*)::int FROM urm.tasks),
  (SELECT COUNT(*)::int FROM urm.tasks) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.tasks) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.engagements', 0,
  (SELECT COUNT(*)::int FROM urm.engagements),
  (SELECT COUNT(*)::int FROM urm.engagements) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.engagements) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.engagement_attendees', 0,
  (SELECT COUNT(*)::int FROM urm.engagement_attendees),
  (SELECT COUNT(*)::int FROM urm.engagement_attendees) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.engagement_attendees) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'C', 'urm.engagement_documents', 0,
  (SELECT COUNT(*)::int FROM urm.engagement_documents),
  (SELECT COUNT(*)::int FROM urm.engagement_documents) - 0,
  CASE WHEN (SELECT COUNT(*) FROM urm.engagement_documents) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group D: app.* 잔존 (handoff §7 carry — Stage 29-d 까지 보존)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'D', 'app.parties (active)', 1738,
  (SELECT COUNT(*)::int FROM app.parties WHERE deleted_at IS NULL),
  (SELECT COUNT(*)::int FROM app.parties WHERE deleted_at IS NULL) - 1738,
  CASE WHEN (SELECT COUNT(*) FROM app.parties WHERE deleted_at IS NULL) = 1738
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'D', 'app.parties.party_type=company (active)', 1413,
  (SELECT COUNT(*)::int FROM app.parties
   WHERE deleted_at IS NULL AND party_type::text = 'company'),
  (SELECT COUNT(*)::int FROM app.parties
   WHERE deleted_at IS NULL AND party_type::text = 'company') - 1413,
  CASE WHEN (SELECT COUNT(*) FROM app.parties
             WHERE deleted_at IS NULL AND party_type::text = 'company') = 1413
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'D', 'app.parties.party_type=fund (must be 0)', 0,
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'fund'),
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'fund') - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'fund') = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'D', 'app.parties.party_type=organization (must be 0)', 0,
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'organization'),
  (SELECT COUNT(*)::int FROM app.parties WHERE party_type::text = 'organization') - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.parties WHERE party_type::text = 'organization') = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group E: ε 잔재 (Stage 29-d 자동 drop)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'E', 'app.investor_partner_profile (ε 잔재)', 108,
  (SELECT COUNT(*)::int FROM app.investor_partner_profile),
  (SELECT COUNT(*)::int FROM app.investor_partner_profile) - 108,
  CASE WHEN (SELECT COUNT(*) FROM app.investor_partner_profile) = 108
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'E', 'app.person_firm_history (ε 잔재)', 109,
  (SELECT COUNT(*)::int FROM app.person_firm_history),
  (SELECT COUNT(*)::int FROM app.person_firm_history) - 109,
  CASE WHEN (SELECT COUNT(*) FROM app.person_firm_history) = 109
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'E', 'app.investor_portfolio_companies (ε 잔재)', 422,
  (SELECT COUNT(*)::int FROM app.investor_portfolio_companies),
  (SELECT COUNT(*)::int FROM app.investor_portfolio_companies) - 422,
  CASE WHEN (SELECT COUNT(*) FROM app.investor_portfolio_companies) = 422
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Group F: app.* TRUNCATE 확인 (handoff §5 α+β)
-- ────────────────────────────────────────────────────────────────────────
SELECT 'F', 'app.pipelines (TRUNCATE)', 0,
  (SELECT COUNT(*)::int FROM app.pipelines),
  (SELECT COUNT(*)::int FROM app.pipelines) - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.pipelines) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'F', 'app.pipeline_stages (TRUNCATE)', 0,
  (SELECT COUNT(*)::int FROM app.pipeline_stages),
  (SELECT COUNT(*)::int FROM app.pipeline_stages) - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.pipeline_stages) = 0
       THEN 'OK' ELSE 'MISMATCH' END

UNION ALL

SELECT 'F', 'app.tasks (TRUNCATE)', 0,
  (SELECT COUNT(*)::int FROM app.tasks),
  (SELECT COUNT(*)::int FROM app.tasks) - 0,
  CASE WHEN (SELECT COUNT(*) FROM app.tasks) = 0
       THEN 'OK' ELSE 'MISMATCH' END

) results
ORDER BY grp, table_fqdn;

-- ============================================================================
-- 사용:
-- 1. Supabase SQL Editor 통째 실행
-- 2. status = OK 모두 → handoff §7 snapshot 과 일치, Stage 29-c 진입 안전
-- 3. MISMATCH 1건이라도 → STOP. delta 컬럼으로 drift 방향 파악
--    - delta > 0 : Stage 29-b 종결 후 신규 row 추가됨 (불법 writer 의심)
--    - delta < 0 : 누군가 row 삭제함 (사고? 정상?)
-- 4. TABLE_MISSING → 테이블 자체 부재 (verify_urm_schema.sql 우선 실행)
--
-- ⚠️  운영 traffic 진행 중이면 작은 drift 발생 가능. ±5 row 이내는 WARN.
--     단 fund/organization 카운트는 절대 0 여야 함 (D group).
-- ============================================================================
```

#### `verify_urm_schema.sql` (16234 bytes)

```sql
-- ============================================================================
-- Stage 29-c · 05 · verify_urm_schema.sql
-- ============================================================================
-- 목적: Stage 29-b 종결 시점의 urm.* 스키마 구조가 caller cutover 기대치와
--       일치하는지 확인. handoff §3 / §6 / §8 의 모든 carry-forward 컬럼명을
--       information_schema 로 검증.
--
-- 실행 환경: Supabase SQL Editor (single statement, no BEGIN/COMMIT)
--
-- 출력: 1개 SELECT 결과셋. 각 row 는 (check_id, check_name, status, detail).
--       status 'OK' / 'FAIL' / 'WARN' / 'INFO'
--
-- ⚠️  caller cutover 진입 전 반드시 실행. FAIL 1건이라도 있으면 stop.
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- Block 1: urm schema 존재
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S01'::text AS check_id,
  'urm schema 존재'::text AS check_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.schemata WHERE schema_name = 'urm'
  ) THEN 'OK' ELSE 'FAIL' END AS status,
  'expected: urm schema 정의됨'::text AS detail

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 2: 19개 urm 핵심 테이블 존재 검증
-- ────────────────────────────────────────────────────────────────────────
SELECT
  ('S02-' || lpad(rn::text, 2, '0'))::text,
  ('urm.' || tname || ' 존재')::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'urm' AND table_name = tname
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 V2 schema'::text
FROM (
  VALUES
    (1, 'parties'),
    (2, 'contacts'),
    (3, 'contacts_history'),
    (4, 'party_types'),
    (5, 'party_supply_links'),
    (6, 'plant_supply_links'),
    (7, 'investor_profile'),
    (8, 'paper_mill_profile'),
    (9, 'filler_supplier_profile'),
    (10, 'investor_portfolio_companies'),
    (11, 'pipelines'),
    (12, 'stages'),
    (13, 'deals'),
    (14, 'deal_stage_history'),
    (15, 'deal_checklists'),
    (16, 'tasks'),
    (17, 'engagements'),
    (18, 'engagement_attendees'),
    (19, 'engagement_documents')
) AS t(rn, tname)

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 3: 핵심 컬럼명 검증 (handoff §3 rename 표)
-- ────────────────────────────────────────────────────────────────────────

-- S03-01: urm.parties.party_type_id 존재 (FK, NOT party_type column)
SELECT
  'S03-01'::text,
  'urm.parties.party_type_id 존재 (FK)'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'party_type_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'caller code 가 party_type 직접 컬럼 참조하면 fail. JOIN to urm.party_types 필요'::text

UNION ALL

-- S03-02: urm.parties.party_type 직접 컬럼 부재 (반대 검증)
SELECT
  'S03-02'::text,
  'urm.parties.party_type 직접 컬럼 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'party_type'
  ) THEN 'OK' ELSE 'FAIL' END,
  'expected: party_type 컬럼 없음 (FK lookup 으로 대체)'::text

UNION ALL

-- S03-03: urm.stages.sort_order (NOT stage_position)
SELECT
  'S03-03'::text,
  'urm.stages.sort_order 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'stages'
      AND column_name = 'sort_order'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §3 rename: stage_position → sort_order'::text

UNION ALL

-- S03-04: urm.stages.stage_position 부재
SELECT
  'S03-04'::text,
  'urm.stages.stage_position 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'stages'
      AND column_name = 'stage_position'
  ) THEN 'OK' ELSE 'FAIL' END,
  'expected: 이전 컬럼명 부재'::text

UNION ALL

-- S03-05: urm.contacts.firm_party_id NOT NULL
SELECT
  'S03-05'::text,
  'urm.contacts.firm_party_id NOT NULL'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'contacts'
      AND column_name = 'firm_party_id'
      AND is_nullable = 'NO'
  ) THEN 'OK' ELSE 'FAIL' END,
  'R3 결정: NOT NULL 유지 (handoff §5 ε)'::text

UNION ALL

-- S03-06: urm.contacts_history (1:1 from app.person_firm_history)
SELECT
  'S03-06'::text,
  'urm.contacts_history.contact_id 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'contacts_history'
      AND column_name = 'contact_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ rename: person_party_id → contact_id'::text

UNION ALL

-- S03-07: urm.contacts_history.started_at (date, NOT joined_at timestamptz)
SELECT
  'S03-07'::text,
  'urm.contacts_history.started_at (date)'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'contacts_history'
      AND column_name = 'started_at'
      AND data_type = 'date'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ cast: joined_at::date → started_at'::text

UNION ALL

-- S03-08: urm.party_supply_links.link_type (NOT supply_type)
SELECT
  'S03-08'::text,
  'urm.party_supply_links.link_type 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'party_supply_links'
      AND column_name = 'link_type'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ rename: supply_type → link_type (text)'::text

UNION ALL

-- S03-09: urm.party_supply_links.volume_estimate (text, NOT volume_tpy)
SELECT
  'S03-09'::text,
  'urm.party_supply_links.volume_estimate (text)'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'party_supply_links'
      AND column_name = 'volume_estimate'
      AND data_type = 'text'
  ) THEN 'OK' ELSE 'FAIL' END,
  'γ cast: volume_tpy::text || tpy → volume_estimate'::text

UNION ALL

-- S03-10: urm.tasks.checklist_id (handoff §6 신설 컬럼)
SELECT
  'S03-10'::text,
  'urm.tasks.checklist_id 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'tasks'
      AND column_name = 'checklist_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §6 신설: FK to deal_checklists ON DELETE SET NULL'::text

UNION ALL

-- S03-11: urm.investor_portfolio_companies.portfolio_company_name_normalized
SELECT
  'S03-11'::text,
  'urm.ipc.portfolio_company_name_normalized 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'investor_portfolio_companies'
      AND column_name = 'portfolio_company_name_normalized'
  ) THEN 'OK' ELSE 'FAIL' END,
  'δ Port-1: portfolio_companies 의 name_normalized 보존 컬럼'::text

UNION ALL

-- S03-12: urm.parties 의 organization_id 컬럼 부재 (single-tenant 검증)
SELECT
  'S03-12'::text,
  'urm.parties.organization_id 부재 (single-tenant)'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'organization_id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 carry-forward: urm = single-tenant'::text

UNION ALL

-- S03-13: urm.parties.module_data jsonb 존재 (legacy 보존)
SELECT
  'S03-13'::text,
  'urm.parties.module_data (jsonb) 존재'::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name = 'module_data'
      AND data_type = 'jsonb'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8: _app_* legacy 필드 jsonb 보존소'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 4: party_types lookup 7개 코드 확인
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S04-01'::text,
  'urm.party_types 7개 코드 존재'::text,
  CASE WHEN (
    SELECT COUNT(*) FROM urm.party_types
    WHERE code IN (
      'investor','paper_mill','filler_supplier',
      'buyer','customer','partner','government_grant'
    )
  ) = 7 THEN 'OK' ELSE 'FAIL' END,
  ('handoff §5 ε: 7개 코드 (' ||
   (SELECT string_agg(code, ',' ORDER BY id) FROM urm.party_types)
   || ')')::text

UNION ALL

SELECT
  'S04-02'::text,
  'urm.party_types 에 fund 코드 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM urm.party_types WHERE code = 'fund'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 carry-forward: fund V2 미지원'::text

UNION ALL

SELECT
  'S04-03'::text,
  'urm.party_types 에 organization 코드 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM urm.party_types WHERE code = 'organization'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §8 carry-forward: organization V2 미지원'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 5: FK 무결성 (party_type_id FK 가 urm.party_types.id 참조)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S05-01'::text,
  'urm.parties.party_type_id FK → urm.party_types.id'::text,
  CASE WHEN EXISTS (
    SELECT 1
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
     AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage ccu
      ON ccu.constraint_name = tc.constraint_name
     AND ccu.constraint_schema = tc.constraint_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'urm'
      AND tc.table_name = 'parties'
      AND kcu.column_name = 'party_type_id'
      AND ccu.table_schema = 'urm'
      AND ccu.table_name = 'party_types'
      AND ccu.column_name = 'id'
  ) THEN 'OK' ELSE 'FAIL' END,
  'FK 강제: party_type_id 무효값 차단'::text

UNION ALL

-- S05-02: orphan party_type_id 검증
SELECT
  'S05-02'::text,
  'urm.parties.party_type_id orphan row 부재'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM urm.parties p
    WHERE p.party_type_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM urm.party_types pt WHERE pt.id = p.party_type_id
      )
  ) THEN 'OK' ELSE 'FAIL' END,
  'expected: 0 orphan (FK constraint 으로 보장)'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 6: urm.parties.name 컬럼 확인 (handoff §13 의 ε ERROR 자취)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S06-01'::text,
  ('urm.parties name 컬럼 = ' ||
    COALESCE(
      (SELECT string_agg(column_name, ', ')
       FROM information_schema.columns
       WHERE table_schema = 'urm' AND table_name = 'parties'
         AND column_name IN ('name','display_name','party_name','legal_name')
      ), 'NONE'
    ))::text,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'urm' AND table_name = 'parties'
      AND column_name IN ('name','display_name','party_name','legal_name')
  ) THEN 'INFO' ELSE 'WARN' END,
  'handoff §13: 실제 컬럼명 확인 필요. caller code 의 이름 참조 일관성 검증'::text

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 7: 9개 deprecation profile 부재 확인 (Stage 29-b δ 결과)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  ('S07-' || lpad(rn::text, 2, '0'))::text,
  ('app.' || tname || ' DROP 확인')::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'app' AND table_name = tname
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §5 δ: 9 deprecation profile DROP 완료'::text
FROM (
  VALUES
    (1, 'buyer_profile'),
    (2, 'buyer_partner_profile'),
    (3, 'customer_profile'),
    (4, 'govt_grant_profile'),
    (5, 'govt_grant_contact_profile'),
    (6, 'partner_profile'),
    (7, 'partner_audits'),
    (8, 'partner_capabilities'),
    (9, 'filler_supplier_contact_profile')
) AS t(rn, tname)

UNION ALL

-- ────────────────────────────────────────────────────────────────────────
-- Block 8: app.portfolio_companies DROP 확인 (δ Port-1 cleanup)
-- ────────────────────────────────────────────────────────────────────────
SELECT
  'S08-01'::text,
  'app.portfolio_companies DROP 확인'::text,
  CASE WHEN NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'app' AND table_name = 'portfolio_companies'
  ) THEN 'OK' ELSE 'FAIL' END,
  'handoff §5 δ Port-1: 342 row → ipc.portfolio_company_name_normalized 보존 후 DROP'::text

) results
ORDER BY check_id;

-- ============================================================================
-- 사용:
-- 1. Supabase SQL Editor 에 통째로 붙여넣기 → Run
-- 2. 모든 row 의 status = 'OK' 또는 'INFO' 인지 확인
-- 3. FAIL 1건이라도 있으면 → caller cutover STOP, handoff 재점검
-- 4. WARN 은 정보성. detail 컬럼 읽고 caller cutover 시 주의
-- ============================================================================
```

### Subdir: `06_app_residual_cleanup`

#### `app_residual_audit.sql` (11095 bytes)

```sql
-- ============================================================================
-- Stage 29-c · 06 · app_residual_audit.sql
-- ============================================================================
-- 목적: Stage 29-d (app.* drop) 진입 전 사전 분석.
--       1) 모든 app.* 테이블 목록 + row count
--       2) 분류: PRESERVE / DROP_AFTER_CUTOVER / RESIDUAL_AUTODROP / ALREADY_EMPTY
--       3) FK 의존성 그래프 (in/out)
--
-- 실행 환경: Supabase SQL Editor (single SELECT)
--
-- 출력: (action, table_name, row_count, fk_in, fk_out, note)
-- ============================================================================

SELECT * FROM (

-- ────────────────────────────────────────────────────────────────────────
-- Section A: 전체 app.* 테이블 목록 + row count + 분류
-- ────────────────────────────────────────────────────────────────────────
-- 동적 row count 가 필요하므로 DO block + temp 결과는 불가 (Supabase SQL Editor).
-- 대신 LATERAL JOIN 으로 information_schema 와 동적 카운트 결합.
-- 단 동적 카운트는 PL/pgSQL 함수 또는 사전 정의된 view 필요.
-- → 여기서는 known 테이블 리스트를 명시적으로 지정. (Stage 29-b 종결 시점 기준)

SELECT
  CASE tname
    -- DROP_AFTER_CUTOVER: caller cutover 완료 후 drop. urm 에 완전 이전됨.
    WHEN 'parties' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'contacts' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'party_supply_links' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'plant_supply_links' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'investor_profile' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'paper_mill_profile' THEN 'DROP_AFTER_CUTOVER'
    WHEN 'filler_supplier_profile' THEN 'DROP_AFTER_CUTOVER'
    -- RESIDUAL_AUTODROP: ε 잔재. handoff §7 의 명시 — Stage 29-d 자동 drop
    WHEN 'investor_partner_profile' THEN 'RESIDUAL_AUTODROP'
    WHEN 'person_firm_history' THEN 'RESIDUAL_AUTODROP'
    WHEN 'investor_portfolio_companies' THEN 'RESIDUAL_AUTODROP'
    -- ALREADY_EMPTY: α+β TRUNCATE 후 0 row. cutover 후 drop 안전
    WHEN 'pipelines' THEN 'ALREADY_EMPTY_DROP'
    WHEN 'pipeline_stages' THEN 'ALREADY_EMPTY_DROP'
    WHEN 'tasks' THEN 'ALREADY_EMPTY_DROP'
    WHEN 'engagements' THEN 'ALREADY_EMPTY_DROP'
    WHEN 'engagement_stage_history' THEN 'ALREADY_EMPTY_DROP'
    -- PRESERVE: V2 에서도 운영 carry. column rename 만 필요.
    WHEN 'email_whitelist' THEN 'PRESERVE_RENAME'
    WHEN 'communications' THEN 'PRESERVE_RENAME'
    -- PRESERVE: 운영 carry, 변경 없음
    WHEN 'invoices' THEN 'PRESERVE'
    WHEN 'payments' THEN 'PRESERVE'
    WHEN 'sales_orders' THEN 'PRESERVE'
    WHEN 'organizations' THEN 'PRESERVE'
    WHEN 'users' THEN 'PRESERVE'
    WHEN 'memberships' THEN 'PRESERVE'
    WHEN 'roles' THEN 'PRESERVE'
    WHEN 'permissions' THEN 'PRESERVE'
    WHEN 'role_permissions' THEN 'PRESERVE'
    WHEN 'sessions' THEN 'PRESERVE'
    WHEN 'api_keys' THEN 'PRESERVE'
    WHEN 'audit_log' THEN 'PRESERVE'
    WHEN 'feature_flags' THEN 'PRESERVE'
    WHEN 'scraping_jobs' THEN 'PRESERVE'
    WHEN 'scraping_results' THEN 'PRESERVE'
    ELSE 'UNKNOWN'
  END::text AS action,
  tname AS table_name,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'app' AND table_name = tname
  ) THEN 'EXISTS' ELSE 'MISSING' END AS table_status,
  ''::text AS placeholder_count,
  CASE tname
    -- urm 이전 완료 + caller cutover 후 drop
    WHEN 'parties' THEN 'urm.parties 로 이전 (id 보존). caller cutover 후 DROP CASCADE'
    WHEN 'contacts' THEN 'urm.contacts 로 이전 (id 보존, R3 결정 hard-delete 19)'
    WHEN 'party_supply_links' THEN 'urm.party_supply_links 로 이전 117 row'
    WHEN 'plant_supply_links' THEN '0 row, urm 동일'
    WHEN 'investor_profile' THEN 'urm.investor_profile 101 row (-5 fund)'
    WHEN 'paper_mill_profile' THEN 'urm.paper_mill_profile 1074 row'
    WHEN 'filler_supplier_profile' THEN 'urm.filler_supplier_profile 232 row (3 HQ 보존)'
    -- ε 잔재
    WHEN 'investor_partner_profile' THEN 'ε 잔재 108 (117-9). urm.contacts_history 로 대체 완료'
    WHEN 'person_firm_history' THEN 'ε 잔재 109 (118-9). urm.contacts_history 로 대체 완료'
    WHEN 'investor_portfolio_companies' THEN 'ε 잔재 422. urm.investor_portfolio_companies (δ Port-1)'
    -- TRUNCATE 결과
    WHEN 'pipelines' THEN 'α+β TRUNCATE (sample 폐기). urm.pipelines 로 신규 시작'
    WHEN 'pipeline_stages' THEN 'α+β TRUNCATE. urm.stages 로 이전 (이름 변경 sort_order)'
    WHEN 'tasks' THEN 'α+β TRUNCATE. urm.tasks 로 신규 시작'
    WHEN 'engagements' THEN 'α+β TRUNCATE (원래 0 row). urm.engagements'
    WHEN 'engagement_stage_history' THEN 'α+β TRUNCATE (원래 0 row)'
    -- PRESERVE
    WHEN 'email_whitelist' THEN '운영 carry. RENAME: org_id→organization_id, value→pattern'
    WHEN 'communications' THEN '운영 carry. RENAME: org_id→organization_id, body_text→body_plain'
    WHEN 'invoices' THEN 'finance carry. RESTRICT FK to app.parties 안전 (0 row 확인됨)'
    WHEN 'payments' THEN 'finance carry'
    WHEN 'sales_orders' THEN 'finance carry'
    WHEN 'organizations' THEN 'multi-tenant root. urm 은 single-tenant'
    WHEN 'users' THEN 'auth carry'
    WHEN 'memberships' THEN 'RBAC carry'
    WHEN 'roles' THEN 'RBAC carry'
    WHEN 'permissions' THEN 'RBAC carry'
    WHEN 'role_permissions' THEN 'RBAC carry'
    WHEN 'sessions' THEN 'auth carry'
    WHEN 'api_keys' THEN 'auth carry'
    WHEN 'audit_log' THEN 'audit carry (audit schema 와 별도)'
    WHEN 'feature_flags' THEN 'ops carry'
    WHEN 'scraping_jobs' THEN 'data acquisition carry'
    WHEN 'scraping_results' THEN 'data acquisition carry'
    ELSE '확인 필요 — known 리스트에 없음'
  END::text AS note
FROM (
  VALUES
    -- DROP_AFTER_CUTOVER
    ('parties'),('contacts'),('party_supply_links'),('plant_supply_links'),
    ('investor_profile'),('paper_mill_profile'),('filler_supplier_profile'),
    -- RESIDUAL_AUTODROP
    ('investor_partner_profile'),('person_firm_history'),('investor_portfolio_companies'),
    -- ALREADY_EMPTY_DROP
    ('pipelines'),('pipeline_stages'),('tasks'),('engagements'),('engagement_stage_history'),
    -- PRESERVE_RENAME
    ('email_whitelist'),('communications'),
    -- PRESERVE
    ('invoices'),('payments'),('sales_orders'),
    ('organizations'),('users'),('memberships'),
    ('roles'),('permissions'),('role_permissions'),
    ('sessions'),('api_keys'),('audit_log'),
    ('feature_flags'),('scraping_jobs'),('scraping_results')
) AS t(tname)

) classified
ORDER BY action, table_name;

-- ============================================================================
-- 부록 query 1: 실제 app.* 모든 테이블 (위의 known list 와 비교)
-- ============================================================================
-- 실행: 별도 query 로 (single statement 정책)

-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema = 'app'
-- ORDER BY table_name;

-- ============================================================================
-- 부록 query 2: app.* row count (테이블별 카운트가 필요할 때)
-- ============================================================================
-- 1개 SELECT 로 모두 합칠 수 없으니 (table 이름이 dynamic),
-- 아래 DO block 사용. ⚠️ Supabase SQL Editor 에서 RAISE NOTICE 출력 안 보임.
-- 대안: pg_stat_user_tables.n_live_tup 사용 (근사값)

-- SELECT
--   schemaname || '.' || relname AS table_fqdn,
--   n_live_tup AS approx_row_count,
--   n_dead_tup AS approx_dead_count,
--   last_vacuum,
--   last_analyze
-- FROM pg_stat_user_tables
-- WHERE schemaname = 'app'
-- ORDER BY n_live_tup DESC;

-- ============================================================================
-- 부록 query 3: app.* 의 FK 의존성 (in-bound + out-bound)
-- ============================================================================
-- DROP 순서 결정용. RESTRICT FK 가 가리키는 테이블 먼저 정리.

-- SELECT
--   tc.table_schema || '.' || tc.table_name AS from_table,
--   kcu.column_name AS from_column,
--   ccu.table_schema || '.' || ccu.table_name AS to_table,
--   ccu.column_name AS to_column,
--   rc.delete_rule
-- FROM information_schema.table_constraints tc
-- JOIN information_schema.key_column_usage kcu
--   ON tc.constraint_name = kcu.constraint_name
--   AND tc.table_schema = kcu.table_schema
-- JOIN information_schema.constraint_column_usage ccu
--   ON ccu.constraint_name = tc.constraint_name
--   AND ccu.constraint_schema = tc.constraint_schema
-- JOIN information_schema.referential_constraints rc
--   ON rc.constraint_name = tc.constraint_name
--   AND rc.constraint_schema = tc.constraint_schema
-- WHERE tc.constraint_type = 'FOREIGN KEY'
--   AND (tc.table_schema = 'app' OR ccu.table_schema = 'app')
-- ORDER BY from_table, from_column;

-- ============================================================================
-- 부록 query 4: 실제 row count (수동 verification)
-- ============================================================================
-- Stage 29-d 진입 전 마지막 확인. 모두 0 row 인지 확인.

-- SELECT 'app.pipelines' AS t, COUNT(*) FROM app.pipelines
-- UNION ALL SELECT 'app.pipeline_stages', COUNT(*) FROM app.pipeline_stages
-- UNION ALL SELECT 'app.tasks', COUNT(*) FROM app.tasks
-- UNION ALL SELECT 'app.engagements', COUNT(*) FROM app.engagements
-- UNION ALL SELECT 'app.engagement_stage_history', COUNT(*) FROM app.engagement_stage_history
-- UNION ALL SELECT 'app.plant_supply_links', COUNT(*) FROM app.plant_supply_links;
-- → 모두 0 면 ALREADY_EMPTY_DROP 즉시 가능

-- ============================================================================
-- 사용:
-- 1. 메인 SELECT 통째 실행 → 전체 분류 결과
-- 2. UNKNOWN 행 있으면 → app schema 에 known 외 테이블 존재. 부록 query 1 로 확인
-- 3. 부록 query 2 (pg_stat) 로 근사 row count 확보
-- 4. 부록 query 4 로 ALREADY_EMPTY_DROP 카테고리 0 row 재확인
-- 5. 부록 query 3 으로 FK 의존성 그래프 그려 DROP 순서 결정
--
-- ⚠️  Stage 29-d 의 DROP 순서:
--    Step 1: ALREADY_EMPTY_DROP (의존성 없음 → 안전)
--    Step 2: RESIDUAL_AUTODROP (FK 가 DROP_AFTER_CUTOVER 가리킬 수 있음 — 순서 주의)
--    Step 3: DROP_AFTER_CUTOVER (의존성 끊긴 뒤)
--    Step 4: PRESERVE_RENAME 의 컬럼 rename 만 (테이블 자체는 유지)
-- ============================================================================
```

### Subdir: `07_completion`

#### `completion_criteria.md` (10261 bytes)

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

---

## 4. Stats

- Total files: 21
- Total size: 219789 bytes
- By extension:
  - .md : 7 files
  - .sql : 6 files
  - .ps1 : 4 files
  - .ts : 3 files
  - .sh : 1 files

