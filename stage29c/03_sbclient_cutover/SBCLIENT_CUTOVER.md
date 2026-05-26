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
