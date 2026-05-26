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
