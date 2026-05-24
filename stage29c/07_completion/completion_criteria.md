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
