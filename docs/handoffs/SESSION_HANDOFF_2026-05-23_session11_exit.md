# SESSION 11 EXIT — Stage 28-a 종결 + URM V2 redesign decision

**Date:** 2026-05-23
**Branch:** `feature/stage23-urm-cleanup` @ `697c565` (pushed)
**Exit posture:** Stage 28-a only. Stage 28-b cancelled. **URM V2 redesign queued.**

---

## §A. 본 세션에서 결정/완료된 것

### A1. Stage 28-a — landed
- factory schema generic flip `'public'` → `'app'`
- `SbClient` / `SbBrowserClient` / `SbAdminClient` type alias export
- typed-rpc client param widen (SchemaName any)
- email-compose.ts 의 3 stale `createServerActionClient` sites → `SbClient`
- commit `697c565`, pushed origin

### A2. tsc 측정값 (확정)
- Stage 28-a 이전: **121 errors**
- Stage 28-a 이후: **183 errors** (+62, drift exposed 의 결과)
- +62 의 정체:
  - email-compose.ts 20 → 49 (+29)
  - queries/email-signatures.ts 3 → 20 (+17)
  - 나머지 소폭 (sequences, tracking, whitelist, communications)

### A3. Gotcha #45 (NEW) — 핸드오프 §5 에 추가
> `@supabase/ssr` 0.5.x vs `supabase-js` 2.x generic-position mismatch.
> ssr 의 createServerClient 가 3 generic 반환 (`SupabaseClient<Database, SchemaName, Schema>`) 인데,
> supabase-js 2.x 의 SupabaseClient class 는 5-generic 으로 확장됨.
> 2번째 slot 이 `SchemaNameOrClientOptions`, 3번째가 `SchemaName`. ssr 이 3번째 slot 에
> Schema 객체를 넘기면서 class 내부 Schema 계산이 `never` 로 collapse → caller 의
> `.from(...)` 가 row=never 가 됨.
> **Workaround**: `SbClient = SupabaseClient<Database, 'app'>` 단일 generic 으로 직접 선언,
> factory return 은 `as unknown as SbClient` cast. Single cast site (Gotcha #28 의 RPC 패턴과 동치).
> V2 redesign 후에도 동일 패턴 유효.

### A4. URM V1 의 미해결 drift (V2 가 흡수할 예정)

**Column rename (확정, SQL 로 verify 됨):**
| caller 가 쓰는 컬럼 | 실제 컬럼 | 위치 |
|---|---|---|
| `email_whitelist.org_id` | `organization_id` (uuid, NOT NULL) | app |
| `email_whitelist.value` | `pattern` (text, NOT NULL) | app |
| `communications.org_id` | `organization_id` | app |
| `communications.body_text` | `body_plain` (text, nullable) | app |
| `parties.country` | `country_code` (text, nullable) | app |

**Dead tables (확정, SQL 로 verify 됨 — 어떤 schema 에도 부재):**
- `email_signatures` (caller: email-compose.ts × 5, queries/email-signatures.ts 전체)
- `org_members` (caller: email-compose.ts × 3)
- `party_contacts` (caller: email-compose.ts × 1)

### A5. Product 결정 (V2 에 반영)

| feature | 결정 | V2 처리 |
|---|---|---|
| **email signatures** | **보류** | V2 schema 에 포함 X. 관련 caller 모두 cutover 시 stub 또는 삭제 |
| **org_members 권한 모델** | **`team_members` 흡수** | V2 에서 별도 table X. caller 의 권한 체크 → `team_members` redirect, 의미 보존 검증 필요 |
| **party_contacts junction** | **`contacts.is_primary` 흡수** | V2 에서 별도 junction X. `contacts.party_id` + `contacts.is_primary` 패턴으로 caller rewrite |

---

## §B. URM V2 redesign — 다음 세션 spec

**전제**: 외부 AI 가 설계한 V2 schema 모델을 사용자가 새 세션에 가져옴.
**목표**: V1 의 backbone 학습은 보존, drift 누적은 cutover 로 단번에 해소.

### B1. V2 가 받자마자 검증할 항목 (사용자 + AI 같이 review)

1. **`__InternalSupabase` block + `PostgrestVersion`** — supabase-js 의 헬퍼 타입이 의존. 없으면 typed-rpc 깨짐.
2. **Schema 명확화**:
   - `app` — 운영 transactional (parties, contacts, deals, engagements, ...)
   - `urm` — entity master / satellite (V1 에서 부분적으로 시도, V2 에서 통합)
   - `ai` — AI 산물 (drafts, classifications, embeddings)
   - `audit` — append-only 로그
3. **모든 운영 테이블에 `organization_id uuid NOT NULL`**. V1 의 `org_id` 혼재 재발생 방지.
4. **명명 표준 한 페이지**: `_at` (timestamp), `_id` (FK), `is_*` (bool), `*_code` (ISO/enum-like), `_normalized` (search optimized field).
5. **PostgREST exposed schemas 설정** — Dashboard 또는 `supabase/config.toml` 에서 `urm` schema 도 exposed 에 추가해야 `--linked` mode 의 gen types 가 가져옴. V1 에서 이게 막혀 regen 실패 (이번 세션).

### B2. 마이그레이션 전략 — 평행 구축 후 cutover

- **새 schema 는 `urm_v2` 또는 `app_v2`** 로 일단 평행 구축. V1 과 공존.
- **데이터 이전 SQL = idempotent + reversible**. `INSERT ... ON CONFLICT DO UPDATE` + 역방향 query 동봉.
- **Cutover 시점에 caller code 도 같이 swap** — schema 만 바꾸고 caller 가 옛 schema 보는 상태가 Stage 28-a 와 동일 함정 재발생.
- Cutover 후 V1 schema 는 일정 기간 (1-2 주) 유지 후 drop.

### B3. V1 lesson — V2 로 carry forward

- **Stage 28-a 의 `SbClient` factory pattern** (Gotcha #45 workaround) 그대로 적용. `'app'` 자리에 V2 의 default schema 이름.
- **Stage 27 의 typed RPC wrapper** (`src/lib/rpc/typed-rpc.ts`) 그대로 carry. V2 RPC 들도 같은 패턴으로 묶음.
- **URM V1 의 RLS hook (013 migration)** — V2 에서도 `organization_id` 기반 동일 패턴. 변경 시 모든 RLS policy 재작성 비용 큼, 가능하면 보존.

### B4. 다음 세션 시작 시 사용자가 가져올 것

1. **외부 AI 의 V2 schema 설계** (DDL 또는 ERD)
2. **본 핸드오프** (이 파일)
3. **V1 database.ts** (data migration SQL source schema reference)
4. **V1 row count 측정**:
   ```sql
   SELECT 'parties' AS t, COUNT(*) FROM app.parties
   UNION ALL SELECT 'contacts', COUNT(*) FROM app.contacts
   UNION ALL SELECT 'communications', COUNT(*) FROM app.communications
   UNION ALL SELECT 'email_whitelist', COUNT(*) FROM app.email_whitelist
   UNION ALL SELECT 'organizations', COUNT(*) FROM app.organizations
   UNION ALL SELECT 'team_members', COUNT(*) FROM app.team_members
   -- 추가: 다른 URM 관련 테이블
   ;
   ```
   결과로 migration cost 추정. < 1K rows → in-script. 100K+ → batch + monitoring 전략.

### B5. 다음 세션의 Stage 명명 — Stage 29 시리즈로 새로 시작

- **Stage 29-a**: V2 schema 평행 구축 (DDL 적용, RLS, 기본 RPC)
- **Stage 29-b**: 데이터 이전 SQL
- **Stage 29-c**: caller code cutover (schema 'app_v2' generic + import path)
- **Stage 29-d**: V1 schema drop + final cleanup

Stage 28-b/c/d 같은 sub-stage 누적 패턴 폐기. Stage 단위는 atomic 한 deliverable 한 개.

---

## §C. 본 세션의 미해결 잔재 (다음 세션이 무시해도 됨)

- urm satellite types regen 실패 (`--linked` mode 에서 빈 introspection) — V2 redesign 시 fresh 하게 가져오므로 V1 보강 불필요
- email-sequences.ts 의 JSDoc 코멘트 mojibake — 본 세션에서 revert (Stage 28-a 와 무관). V2 cutover 시 코멘트 재작성 자연스럽게 해결

---

## §D. 새 세션 첫 메시지 추천 형식

```
Stage 29 시작. URM V2 redesign + 데이터 이전.

첨부: V2 schema 설계 (외부 AI 산출)
첨부: 본 핸드오프 (Session 11 exit)
첨부: V1 row count SQL 결과

질문: V2 spec 받았는데 §B1 의 5 검증 항목 같이 review 부터 시작할까?
```

이 형식이면 새 세션이 컨텍스트 build-up 없이 바로 진입 가능.
