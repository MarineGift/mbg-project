# NEXT_SESSION_KICKOFF — 새 Claude 세션 시작 가이드

> **목적:** 새 세션이 첫 메시지에서 즉시 생산성 발휘하도록.
> **이 문서의 위치:** 새 세션 시작 시 사용자가 5개 파일을 첨부하면 Claude 가 이걸 먼저 읽고 다른 4개를 reference 로 활용.

---

## 0. 첨부 파일 6개 (이게 전체 starter kit)

| 순서 | 파일 | 역할 |
|------|------|------|
| 1 | **NEXT_SESSION_KICKOFF.md** (이 문서) | 시작 가이드 + 직전 상태 + 환경 검증 |
| 2 | **PROJECT_CONTEXT.md** | 사업 맥락 + fit 기준 + 컨벤션 + Outreach scoring + module_type 결정 |
| 3 | **DB_SCHEMA_REFERENCE.md** | DB 구조 (테이블, 컬럼, enum, FK, 함수) |
| 4 | **SCHEMA_GOTCHAS.md** | DB 함정 + helper 함수 활용 + partial rollback |
| 5 | **safe_insert_templates.sql** | INSERT/UPSERT 표준 패턴 + diagnostic 쿼리 |
| 6 | **db_schema_introspect_v2.sql** | Phase 2 introspection (RLS/views/triggers/indexes 미수집 시) |

읽기 순서: **1 → 2 → 3 → 4 → 5** (`db_schema_introspect_v2.sql` 은 reference)

---

## 1. 직전 세션 상태 (2026-05-19)

### 1.1 완료된 일
- ✅ Portfolio depth 작업 — Closed Loop (16 portfolio, 15 link) + Generate Capital (15 + 15)
- ✅ a16z American Dynamism RUN 7 — Erin Price-Wright + Ryan McEntush 적재
- ✅ DB Schema 영구 문서 4종 완성 (이 문서들)
- ✅ 함수 카탈로그 발견 — `ingest.upsert_portfolio_company`, `rollback_run`, `infer_seniority` 등 helper 13개 식별

### 1.2 DB 현재 카운트
```
app.parties                       1,764
app.investor_profile                111
app.investor_partner_profile        119
app.portfolio_companies             342
app.investor_portfolio_companies    445
ingest.runs                          15
```

### 1.3 직전 세션의 핵심 발견
1. **Earthodic** (Closed Loop portfolio) — 호주 biotech, lignin 으로 paper packaging coating. 본 사업과 거의 완벽한 인접 fit.
2. **`module_type` enum 에 `investor_partner` 없음** — HANDOFF.md 의 일부 SQL 패턴이 잘못된 표기 가능성 (확인 필요)
3. **`investor_portfolio_companies`** 는 denormalized hybrid — `portfolio_company_name` NOT NULL
4. **`parties_set_normalized()` trigger** 가 `name_normalized` 자동 처리 (수동 set 불필요)
5. **`ingest.upsert_portfolio_company()` helper** 존재 — 직접 CTE 작성 불필요

---

## 2. 새 세션 첫 작업 — 환경 검증 (5분, 필수)

새 세션의 안전한 시작 패턴 — **모두 실행 후 결과 공유**:

### Step 1. DB 카운트 변경 여부 (±5 이내면 OK)
```sql
SELECT 'parties' t, COUNT(*) FROM app.parties
UNION ALL SELECT 'investor_profile',           COUNT(*) FROM app.investor_profile
UNION ALL SELECT 'investor_partner_profile',   COUNT(*) FROM app.investor_partner_profile
UNION ALL SELECT 'portfolio_companies',        COUNT(*) FROM app.portfolio_companies
UNION ALL SELECT 'investor_portfolio_companies', COUNT(*) FROM app.investor_portfolio_companies
ORDER BY 1;
```

### Step 2. 🔴 `module_type` enum 의 실제 값 (6 AI 검증자 만장일치 강조)
```sql
SELECT unnest(enum_range(NULL::app.module_type)) AS module_value;
```
**기대 결과:** 9개 값 (investor, paper_mill, partner, customer, crowdfunding, product_launch, sales, filler, filler_supplier).
- 만약 `investor_partner` 가 **있으면** → HANDOFF.md 패턴 그대로 사용 가능 (enum 확장 적용된 상태)
- 만약 **없으면** → `'partner'::app.module_type` 사용 (PROJECT_CONTEXT Section 10 참고)

### Step 3. 🔴 `ingest.failed_rows` view 의 실제 컬럼 (이전 doc 의 깨진 쿼리 검증)
```sql
SELECT column_name FROM information_schema.columns
 WHERE table_schema = 'ingest' AND table_name = 'failed_rows'
 ORDER BY ordinal_position;
```
**기대:** `run_label, seq, name, dedup_key, error_message, payload, created_at` — `run_id` 없음.
조회 시 `WHERE run_label = '...'` 사용 (이전 doc 의 `WHERE run_id = (...)` 는 깨진 쿼리).

### Step 4. parties.module 실제 분포
```sql
SELECT module, COUNT(*) FROM app.parties GROUP BY module ORDER BY COUNT(*) DESC;
```

### Step 5. 최근 ingest run 확인
```sql
SELECT label, started_at, rows_promoted, rows_failed
  FROM ingest.runs ORDER BY started_at DESC LIMIT 5;
```

### Step 6. (선택) Phase 2 introspection 미실행 시 권장
첨부에 `db_schema_introspect_v2.sql` 있고 5개 새 CSV 가 없으면:
→ Phase 2 SQL 의 Section 9-15 실행 후 CSV 첨부해서 다음 세션에 전달.
(RLS, views, triggers, indexes, function bodies, module_data shapes 가 채워짐)

---

## 3. 다음 즉시 작업 (사용자가 명시하지 않으면 이걸 제안)

### 3.1 가장 가치 높은 작업 — Outreach 1순위 명단 export
**작업:** direct_fit 6개 firm + 추가 fit 높은 firm 의 DM 들 한 SELECT 로 추출.

**산출물 후보 컬럼:**
- partner name, title, seniority, is_decision_maker
- firm name, sector_focus, geographic_focus
- linkedin_url, email (있으면)
- 본인 사업과 직결되는 portfolio 회사 매핑 (Earthodic, Cruz Foam, Cloud Paper 등)
- 추천 outreach angle (1-2 문장)

이건 거의 즉시 가능한 SELECT 작업. 새 데이터 적재 없음.

### 3.2 At One Ventures portfolio 보강
**상태:** 4 partners 적재됐는데 portfolio 깊이 부족.
**필요:** Air Company, Nature Coatings, Beewise, Apis Cor 등 paper/material relevant 5-8개 추가.
**도구:** `ingest.upsert_portfolio_company` + `investor_portfolio_companies` link.

### 3.3 새 firm 추가 — 우선순위 후보
- **Walmart Strategic Capital** (포장재 buyer CVC)
- **PepsiCo Greenhouse** (포장재)
- **Coca-Cola Ventures**
- **Unilever Ventures**
- **Pritzker Group** (industrial family office)

각 firm 당 2-4 DM 적재 가능.

---

## 4. 첫 메시지 시 Claude 가 해야 할 일

새 세션의 첫 응답에서 다음 순서로 진행:

1. **첨부 파일 5개 확인 메시지** — 어느 게 있는지 명시
2. **PROJECT_CONTEXT.md 의 Section 1-3 요약** — 사용자에게 "맞는지" 한 번 확인
3. **이 KICKOFF 문서의 Section 2 환경 검증** 권유 — 사용자가 결과 공유
4. **다음 작업 선택지 제시** — Section 3.1/3.2/3.3 + 사용자 다른 우선순위

**금기사항:**
- DB 구조 추측 금지 — 항상 DB_SCHEMA_REFERENCE.md 참고
- 한국 firm 적재 금지
- 사용자 본인 정보 적재 금지
- 한국어 응답으로 + SQL 은 영문 그대로
- 익명 처리 정책 준수

---

## 5. 자주 발생하는 첫 메시지 패턴 + 대응

### "현재 DB 상태 확인하고 다음 작업 제안해줘"
→ Section 2 의 검증 쿼리 실행 권유 → 결과 받으면 Section 3 옵션 제시

### "X firm 추가해줘"
→ X 가 fit 기준 (PROJECT_CONTEXT Section 3) 충족하는지 확인
→ D1 diagnostic (`safe_insert_templates.sql`) 으로 이미 있는지 체크
→ web search 로 데이터 수집 (PROJECT_CONTEXT Section 6)
→ ingest 3-step 패턴으로 적재

### "Earthodic 같은 회사 더 찾아줘"
→ paper byproduct 활용 + sustainable material 키워드로 search
→ 후보 5-10개 propose → 사용자 선택 → 적재

### "outreach 명단 export 해줘"
→ Section 3.1 작업. SELECT 작성 후 결과 CSV 로 전달.

### "이전 세션에서 했던 X 어떻게 됐지?"
→ 이 KICKOFF Section 1 참고 + `ingest.runs` 쿼리로 확인

---

## 6. 세션 종료 시 (다음 세션 위한 handoff)

작업 끝낼 때:
1. 추가/변경된 데이터 카운트 표 정리
2. 발견한 새 인사이트 메모
3. 다음 세션 즉시 작업 후보 1-2개 명시
4. 이 KICKOFF 문서의 Section 1 (직전 세션 상태) 업데이트 권장

---

## 7. 안전 체크리스트 (매 작업 전 확인)

- [ ] PROJECT_CONTEXT.md 의 fit 기준 충족?
- [ ] 한국 관련 데이터 아닌가?
- [ ] DB_SCHEMA_REFERENCE.md 에서 해당 테이블 카드 확인?
- [ ] SCHEMA_GOTCHAS.md 의 helper 함수 표 (Section 0) 확인?
- [ ] safe_insert_templates.sql 에서 해당 패턴 복사?
- [ ] D1-D6 diagnostic 쿼리로 사전 검증?
- [ ] Idempotent 패턴 (ON CONFLICT / WHERE NOT EXISTS)?
- [ ] 사용자 익명 처리 유지?
- [ ] 한국어 응답 + 영문 SQL?

8개 모두 ✓ 면 안전하게 진행.
