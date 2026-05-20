# NEXT_SESSION_KICKOFF — 새 Claude 세션 시작 가이드 (v3)

> **버전:** 2026-05-19 v3 (URM Master Architecture 통합 + Phase 0 완료 상태)
> **목적:** 새 세션이 첫 메시지에서 즉시 생산성 발휘하도록.
> **이 문서의 위치:** starter kit 첨부 후 Claude 가 README → **이 문서** → URM_MASTER_ARCHITECTURE → 작업 phase 진행.

---

## 0. 첨부 파일 — Starter Kit (10개)

| 순서 | 파일 | 버전 | 역할 |
|------|------|------|------|
| 0 | **README_STARTER_KIT.md** | v2 | 마스터 인덱스 + 변경 이력 |
| 1 | **URM_MASTER_ARCHITECTURE.md** ⭐ | v1 | 10 원칙 + 6 building blocks + Phase plan (NEW — single source of truth) |
| 2 | **NEXT_SESSION_KICKOFF.md** (이 문서) | v3 | 시작 가이드 + 직전 상태 + 환경 검증 |
| 3 | **PROJECT_CONTEXT.md** | v2 | 사업 맥락 + fit 기준 + 컨벤션 |
| 4 | **DB_SCHEMA_REFERENCE.md** | v2.1 | DB 구조 (테이블, 컬럼, enum, FK, 함수, trigger) |
| 5 | **SCHEMA_GOTCHAS.md** | v3 | DB 함정 + helper 함수 활용 + Phase 2 통합 분석 |
| 6 | **safe_insert_templates.sql** | v3 | INSERT/UPSERT 표준 패턴 |
| 7 | **db_schema_introspect_v2.sql** | — | introspection 쿼리 (Phase 2 완료, 재실행 시 사용) |
| 8 | **migration_subtype_seniority_meta_2026Q2.sql** | — | 적용 완료 (참고용 보관) |
| 9 | **migration_person_firm_history_2026Q2.sql** | — | **미적용** — 다음 세션 Phase 2 실행 후보 ⭐ |
| 10 | **outreach_seed_top30_2026Q2.csv** | — | 진행 중 outreach 시드 (status 추적용) |

**읽기 순서:** 0 → **1 (URM Master Arch)** → 2 → 3 → 4 → 5 → (6/7/8/9 lookup)

---

## 1. 직전 세션 상태 (2026-05-19, 19:30 — 21:30)

### 1.1 완료된 일 (Phase 0)

- ✅ **Phase 2 introspection 7섹션** — RLS (272), views (5), triggers (128), indexes (451), function bodies (14)
- ✅ **SCHEMA_GOTCHAS v2 → v3** — §0.1 promote 패턴 + §10 Phase 2 통합
- ✅ **PROJECT_CONTEXT v1 → v2** — §10 partner 매핑 정정 + §11 module_data 실제 키
- ✅ **DB_SCHEMA_REFERENCE v1 → v2.1** — §1.4 + §1.5 + parties 카드 정정
- ✅ **safe_insert_templates v2 → v3** — Template 2b + 4 partner 매핑 정정
- ✅ **investor_subtype_meta + partner_seniority_meta 적용** — 16 rows (10 + 6), 트라이링구얼
- ✅ **편의 view 2개 적용** — `v_investor_subtype_options`, `v_partner_seniority_options`
- ✅ **Footprint Coalition `direct_fit` 태그** — 9/9 firm
- ✅ **Outreach Top 30 시드 CSV 생성** — `outreach_seed_top30_2026Q2.csv`
- ✅ **URM Master Architecture v1 작성** — 10 원칙 + 6 building blocks + 6 phase plan
- ✅ **person_firm_history SQL 작성** (Phase 2 — **미적용**, 다음 세션에서 실행 권장)

### 1.2 핵심 design 결정 (모든 문서에 반영됨)

1. 🔴 **partner 매핑** — VC 측 partner 는 `module='investor'` + `party_type='individual'` + `parent_party_id=firm.id`
2. 🔴 **두 module 컨텍스트** — `parties.module` (enum 9 값) vs `ingest.runs.module` (text)
3. 🟡 **10개 테이블 RLS 비활성** — multi-tenant 운영 전 ALTER 필요
4. 🟢 **사용자 10 원칙 합의** — Company-centric, multi-firm employee, dedup, status 등 (URM_MASTER_ARCHITECTURE §1)
5. 🟢 **6 Phase plan 합의** — Phase 1-6 우선순위 정립 (URM_MASTER_ARCHITECTURE §6)

### 1.3 DB 현재 카운트 (확인된 값)

```
app.parties                       1,764
app.investor_profile                111
app.investor_partner_profile        119
app.portfolio_companies             342
app.investor_portfolio_companies    445
ingest.runs                          15
app.lead_scores                   1,528
app.investor_subtype_meta            10  ← NEW (Phase 0)
app.partner_seniority_meta            6  ← NEW (Phase 0)
app.person_firm_history               0  ← NEW Phase 2 적용 시 119 채워질 예정
```

### 1.4 parties.module 분포

```
paper_mill: 1,073   filler:   419   investor: 243   partner: 15   customer: 14
```

---

## 2. 새 세션 첫 작업 — 환경 검증 (3분, 권장)

### Step 1. DB 카운트 변경 여부 (직전 세션 이후 변동)
```sql
SELECT 'parties' t, COUNT(*) FROM app.parties
UNION ALL SELECT 'investor_profile',             COUNT(*) FROM app.investor_profile
UNION ALL SELECT 'investor_partner_profile',     COUNT(*) FROM app.investor_partner_profile
UNION ALL SELECT 'portfolio_companies',          COUNT(*) FROM app.portfolio_companies
UNION ALL SELECT 'investor_portfolio_companies', COUNT(*) FROM app.investor_portfolio_companies
UNION ALL SELECT 'lead_scores',                  COUNT(*) FROM app.lead_scores
UNION ALL SELECT 'investor_subtype_meta',        COUNT(*) FROM app.investor_subtype_meta
UNION ALL SELECT 'partner_seniority_meta',       COUNT(*) FROM app.partner_seniority_meta
UNION ALL SELECT 'person_firm_history',          
  CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables 
                     WHERE table_schema='app' AND table_name='person_firm_history')
       THEN (SELECT COUNT(*)::int FROM app.person_firm_history) 
       ELSE -1 END  -- -1 = 테이블 미적용
ORDER BY 1;
```

**기대:** 직전 값과 동일 (`investor_subtype_meta=10`, `partner_seniority_meta=6`, `person_firm_history=0` 또는 -1).

### Step 2. 최근 ingest run 확인
```sql
SELECT label, started_at, rows_promoted, rows_failed
  FROM ingest.runs ORDER BY started_at DESC LIMIT 5;
```

### Step 3. Meta 테이블 sanity check (Phase 0 검증)
```sql
SELECT code, display_name_ko, firm_count, has_data 
  FROM app.v_investor_subtype_options;
-- 기대: 10 rows, vc=84 firm_count
```

### Step 4. (선택) Schema migration 적용 여부
```sql
SELECT 'enums', COUNT(*) FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace
 WHERE t.typtype='e' AND n.nspname IN ('app','public')
UNION ALL
SELECT 'tables app', COUNT(*) FROM information_schema.tables 
 WHERE table_schema='app' AND table_type='BASE TABLE';
```
**기대:** enums = 31, tables app = 70-72 (Phase 2 person_firm_history 적용 시 +1).

---

## 3. 다음 즉시 작업 — Phase plan 진행

URM_MASTER_ARCHITECTURE §6 의 Phase 진행 상태:

| Phase | 산출물 | 시간 | 상태 | 우선순위 |
|-------|--------|------|:----:|:----:|
| 0 | introspection, 매핑 정정, meta 테이블 | — | ✅ DONE | — |
| **2** | `person_firm_history` 적용 (SQL 작성 완료) | 5분 | 🟡 미적용 | **🔴 최우선** |
| **1** | paper_mill / filler profile 테이블 | 90-120분 | 🔴 TODO | 🔴 다음 |
| 4 | activity_status + phone + dedup | 60-90분 | 🔴 TODO | 🟡 |
| 3 | engagement_participants (firm-centric) | 60분 | 🔴 TODO | 🟡 |
| 5 | 새 module (govt_grant, sales) | 30-45분 each | 🔴 TODO | 🟢 향후 |
| 6 | Unified reporting views | 60-90분 | 🔴 TODO | 🟢 향후 |

### 3.1 권장 시작 — Phase 2 실행 (5분)

`migration_person_firm_history_2026Q2.sql` 을 Supabase 에서 실행 → 검증 결과 공유:

```sql
-- 검증 1: 카운트 (119 expected)
SELECT 'pfh' t, COUNT(*) FROM app.person_firm_history WHERE deleted_at IS NULL
UNION ALL
SELECT 'ipp', COUNT(*) FROM app.investor_partner_profile;

-- 검증 2: 동기화 (parent_party_id 자동 set)
SELECT COUNT(*) AS synced
  FROM app.parties p
  JOIN app.person_firm_history h 
    ON h.person_party_id = p.id 
   AND h.left_at IS NULL 
   AND h.is_primary = true
 WHERE p.parent_party_id = h.firm_party_id;
-- 기대: 119
```

### 3.2 다음 — Phase 1 (paper_mill / filler profile)

가장 큰 변환 작업. 1,492 행 마이그레이션. 새 세션 시작 시 다음 단계:

1. `parties.module='paper_mill'` 1,073 행의 `module_data` 키 분포 재확인
2. `app.paper_mill_profile` + `app.paper_mill_contact_profile` DDL 설계
3. 마이그레이션 SQL — module_data jsonb → 컬럼으로 승격
4. helper `ingest.promote_paper_mills` 작성 (investor 패턴 카피)
5. `app.filler_supplier_profile` 동일 패턴
6. starter kit 의 모든 문서 갱신 (DB_SCHEMA_REFERENCE 에 카드 추가 등)

---

## 4. 첫 메시지 시 Claude 가 해야 할 일

새 세션 첫 응답에서:

1. **첨부 파일 확인** — 10개 모두 있는지
2. **URM_MASTER_ARCHITECTURE §1-4 요약** — vision 한 번 재확인 + 사용자 동의 받기
3. **이 KICKOFF §2 환경 검증** 권유 — DB 카운트 + meta 테이블
4. **Phase 진행 상태 확인** — §3 표 보여주고 사용자 선택 받기
   - Phase 2 즉시 실행 (5분)
   - Phase 1 본격 진행 (90-120분)
   - 또는 사용자 다른 우선순위

**금기사항:**
- DB 구조 추측 금지 — DB_SCHEMA_REFERENCE 참고
- 한국 firm 적재 금지
- 사용자 본인 정보 적재 금지
- 한국어 응답 + SQL 영문
- 익명 처리 정책 준수
- 🔴 VC partner 적재 시 `module='partner'` 사용 X — `module='investor'` + `party_type='individual'`
- 🔴 새 module 추가 시 URM_MASTER_ARCHITECTURE §3 의 6 building blocks 패턴 따름

---

## 5. 자주 발생하는 첫 메시지 패턴 + 대응

### "이전 세션 어디까지 했지?"
→ 이 KICKOFF §1 + URM_MASTER_ARCHITECTURE §6 Phase 표 보여주고 사용자에게 다음 단계 선택권

### "Phase 2 진행하자"
→ `migration_person_firm_history_2026Q2.sql` 사용자에게 안내 → 실행 후 결과 공유 → starter kit 업데이트 (DB_SCHEMA_REFERENCE 에 person_firm_history 카드 + KICKOFF v3 → v4)

### "Phase 1 진행하자" (paper_mill / filler profile)
→ 큰 작업이므로 단계별:
  1. module_data 키 분포 재확인 SQL
  2. profile 테이블 DDL draft 보여주고 사용자 동의
  3. 마이그레이션 SQL 작성 (트랜잭션)
  4. helper 함수 작성
  5. starter kit 업데이트

### "X firm 추가해줘"
→ X 가 fit 기준 (PROJECT_CONTEXT §3) 충족 확인 → D1 diagnostic → web search → ingest 3-step

### "outreach 명단 업데이트해줘"
→ 사용자가 가져온 CSV (status 채워진 것) 분석 → 응답률 / 다음 batch 제안

### "새 module (예: govt_grant) 추가해줘"
→ URM_MASTER_ARCHITECTURE §4 Cookbook 따라 3-step 진행

---

## 6. 세션 종료 시 (다음 세션 위한 handoff)

작업 끝낼 때:
1. 추가/변경된 데이터 카운트 갱신 (§1.3)
2. 발견한 새 인사이트 메모
3. 다음 세션 즉시 작업 후보 명시
4. 이 KICKOFF §1 (직전 세션 상태) 업데이트
5. URM_MASTER_ARCHITECTURE §6 Phase 표 업데이트 (완료된 Phase 표시)
6. 변경된 starter kit 파일 새 버전 export

---

## 7. 안전 체크리스트 (매 작업 전 확인)

- [ ] URM_MASTER_ARCHITECTURE 의 6 building blocks 패턴 따름?
- [ ] PROJECT_CONTEXT 의 fit 기준 충족?
- [ ] 한국 관련 데이터 아닌가?
- [ ] DB_SCHEMA_REFERENCE 에서 해당 테이블 카드 확인?
- [ ] SCHEMA_GOTCHAS 의 helper 함수 + Phase 2 통합 확인?
- [ ] safe_insert_templates 에서 해당 패턴 복사?
- [ ] D1-D6 diagnostic 쿼리로 사전 검증?
- [ ] Idempotent 패턴 (ON CONFLICT / WHERE NOT EXISTS)?
- [ ] 🔴 VC partner 적재 시 `module='investor'` + `party_type='individual'` + `parent_party_id`?
- [ ] 🔴 `'investor_partner'::app.module_type` enum cast 안 함?
- [ ] 새 module 추가 시 URM_MASTER_ARCHITECTURE §4 cookbook 따름?
- [ ] 트랜잭션 (BEGIN ... COMMIT) 사용?
- [ ] 사용자 익명 처리 유지?
- [ ] 한국어 응답 + 영문 SQL?

14개 모두 ✓ 면 안전하게 진행.
