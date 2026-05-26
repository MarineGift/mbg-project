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
