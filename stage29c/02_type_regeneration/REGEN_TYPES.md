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
