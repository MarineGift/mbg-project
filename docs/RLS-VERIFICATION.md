# RLS Verification Guide

본 문서는 STEP 1 SQL 적용 후 Row Level Security (RLS) 정책의 정확성을 검증하는 절차입니다.

## 왜 필요한가

URM Platform은 멀티테넌트 SaaS이며, 모든 데이터는 `organization_id`로 격리됩니다. 한 조직의 사용자가 다른 조직의 데이터를 볼 수 없어야 합니다. 이 격리는 두 층에서 강제됩니다:

1. **Database 레벨 (RLS 정책)** — Postgres가 SELECT/INSERT/UPDATE/DELETE 시점에 자동으로 행 단위 검증
2. **Application 레벨 (`organization_id` 명시)** — STEP 3 코드가 모든 쿼리에 `.eq('organization_id', ...)` 추가

DB 레벨이 깨지면 application 레벨의 버그 한 줄이 전체 데이터를 노출시킬 수 있습니다. 따라서 **DB 레벨 RLS는 1차 방어선**이며, 반드시 검증해야 합니다.

## 두 가지 검증 방법

### A. 정적 검증 (SQL meta-query)

`scripts/verify-rls.sql`을 Supabase SQL Editor에서 실행. 다음을 검사:

1. 각 테이블의 RLS 활성 상태 (`rowsecurity=true`)
2. 각 테이블의 정책 수와 명령(SELECT/INSERT/UPDATE/DELETE) 커버리지
3. 정책 식에 `organization_id` 또는 `user_organizations` 참조 존재 여부 (멀티테넌트 격리)
4. anon/authenticated 역할의 GRANT 권한
5. SECURITY DEFINER 함수 (RPC) 검사
6. 정책 누락된 테이블 탐지

**실행:**

```bash
psql "$SUPABASE_DB_URL" -f scripts/verify-rls.sql
```

또는 Supabase Dashboard → SQL Editor에 통째로 붙여넣고 Run.

### B. 동적 검증 (런타임)

`scripts/verify-rls-runtime.ts`는 **두 개의 실제 Supabase 클라이언트**를 만들어 (admin + anon) 행동을 검증.

`tsx`가 설치되지 않았다면:

```bash
npm install -D tsx
```

실행:

```bash
NEXT_PUBLIC_SUPABASE_URL="..." \
SUPABASE_SERVICE_ROLE_KEY="..." \
NEXT_PUBLIC_SUPABASE_ANON_KEY="..." \
npx tsx scripts/verify-rls-runtime.ts
```

검사 항목:

- anon 역할이 `ai.runs`, `ai.drafts`, `app.communications`를 SELECT할 수 없어야 함
- service_role은 모든 테이블 접근 가능
- anon 역할이 `ai.runs`에 INSERT 시도하면 차단

> **⚠️ 주의:** 이 스크립트는 production DB에 직접 호출합니다. **반드시 staging environment에서만 실행**하세요.

## 통과 기준

| 검사 | 기대 결과 |
|------|----------|
| `rls_enabled` 컬럼 | 모든 행에서 `true` |
| 정책 수 | 각 테이블에 최소 1개 (대부분은 `SELECT` + `INSERT/UPDATE` 분리) |
| 정책 식의 `organization_id` 참조 | `app.*`, `ai.*` 모든 테이블에서 `✓` |
| anon SELECT 차단 | 0건 또는 error |
| service_role SELECT | 정상 작동 |
| anon INSERT 차단 | error 발생 |

## 일반적인 문제와 해결

### 1. "RLS is disabled on this table"

테이블에 RLS가 켜져 있지 않음. STEP 1 SQL에 다음 누락:

```sql
ALTER TABLE app.communications ENABLE ROW LEVEL SECURITY;
```

### 2. anon이 데이터를 읽을 수 있음

GRANT가 너무 광범위하게 풀려 있거나, 정책에 `USING (true)`처럼 무조건 허용이 들어 있음. 다음을 확인:

```sql
-- anon은 SELECT만 명시적으로 허용된 컬럼/테이블만
REVOKE ALL ON TABLE app.communications FROM anon;
GRANT SELECT ON TABLE app.communications TO authenticated;

-- 정책은 user_organizations 조인으로 작성
CREATE POLICY communications_select ON app.communications FOR SELECT
  USING (
    organization_id IN (
      SELECT organization_id FROM app.user_organizations
      WHERE user_id = auth.uid() AND is_active = true
    )
  );
```

### 3. SECURITY DEFINER 함수 누락

`expire_stale_drafts()`, `match_knowledge_chunks()` 등은 호출자 권한과 무관하게 작동해야 함:

```sql
ALTER FUNCTION ai.expire_stale_drafts() SECURITY DEFINER;
ALTER FUNCTION ai.match_knowledge_chunks(uuid, text, vector(3072), integer) SECURITY DEFINER;
```

### 4. service_role이 정책에 막힘

service_role은 RLS를 우회해야 함. Supabase는 기본적으로 우회하지만, 정책에 `BYPASSRLS`나 `FORCE ROW LEVEL SECURITY`가 잘못 설정되었을 수 있음:

```sql
-- service_role은 RLS 우회 (Supabase default)
-- 만약 강제로 설정되어 있다면:
ALTER TABLE ai.runs NO FORCE ROW LEVEL SECURITY;
```

## 추가 권장 사항

1. **CI 통합:** staging 환경에서 deploy 직후 `verify-rls-runtime.ts`를 자동 실행
2. **e2e 테스트:** Playwright 등으로 두 사용자(orgs A, B)의 실제 행동 검증
3. **감사 로그:** `audit.*` 스키마의 RLS도 별도로 확인 (보통 admin only로 제한)
4. **신규 테이블 추가 시:** 테이블 생성 직후 RLS 활성화 + 정책 작성을 마이그레이션에서 강제

## STEP 1 SQL 점검 체크리스트

다음 항목이 STEP 1 SQL에 모두 포함되어 있는지 확인:

- [ ] 모든 `app.*`, `ai.*` 테이블에 `ENABLE ROW LEVEL SECURITY`
- [ ] 모든 사용자 접근 테이블에 SELECT 정책
- [ ] 사용자가 INSERT/UPDATE 가능한 테이블에 해당 정책
- [ ] 정책의 `USING` 또는 `WITH CHECK` 식에 `user_organizations` 또는 `organization_id` 검증
- [ ] `audit.*` 테이블은 service_role만 INSERT, 일반 사용자는 SELECT 차단
- [ ] `pg_cron` 함수들은 SECURITY DEFINER
- [ ] `match_knowledge_chunks` (RAG RPC)는 SECURITY DEFINER + organization_id 파라미터 검증
- [ ] `expire_stale_drafts` (cron RPC)는 SECURITY DEFINER

이 체크리스트를 만족시킨 후 위의 두 검증 스크립트를 모두 실행해서 모든 ✓가 나오면 RLS 검증 완료.
