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
