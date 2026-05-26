# 다음 세션 작업 체크리스트

이 문서는 다음 세션의 Claude (또는 직접 작업)가 순서대로 따라하면 되도록 정리한 체크리스트입니다.

---

## Phase A: 빌드 안정화 (예상 2~3시간)

### A-1. 환경 준비 ✅

```powershell
cd C:\dev\mbg-project
git status
git pull
git log --oneline -3

# .env.local 백업 확인 (비밀번호 관리자에 저장돼 있는지)
Get-Content .env.local | Select-Object -First 5
```

### A-2. DB 마이그레이션 적용

Supabase 대시보드 → SQL Editor에서 순서대로 실행:

- [ ] `supabase/migrations/025_lead_scores.sql` — lead_scores 테이블 + 초기 시드
- [ ] `supabase/migrations/026_saved_views.sql` — saved_views 테이블

각 실행 후 검증 (마지막 RAISE NOTICE 메시지 확인):
- 025: "Total active parties: X, Parties with lead_score: X" — 두 수가 같아야 함
- 026: "saved_views RLS policies: 4"

### A-3. Query stub을 실제 구현으로 교체

`src/lib/queries/lead-score.ts` 교체:

```typescript
import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export async function fetchLeadScoresMany(
  partyIds: string[],
): Promise<Record<string, number>> {
  if (!partyIds || partyIds.length === 0) return {};

  const supabase = await createSupabaseServerClient();
  // RPC 사용 (RLS 자동 적용 + 단일 호출)
  const { data, error } = await supabase
    .rpc('get_lead_scores_many', { p_party_ids: partyIds });

  if (error) {
    console.warn('[fetchLeadScoresMany]', error.message);
    return {};
  }

  const result: Record<string, number> = {};
  for (const row of (data ?? []) as any[]) {
    if (row?.party_id && typeof row.score === 'number') {
      result[row.party_id] = row.score;
    }
  }
  return result;
}
```

`src/lib/queries/saved-views.ts` 교체:

```typescript
import 'server-only';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import type { ModuleType } from '@/types/ai';

export interface SavedView {
  id: string;
  name: string;
  description?: string | null;
  entity_type: string;
  module: ModuleType | null;
  filters: Record<string, unknown>;
  sort: Array<{ field: string; dir: 'asc' | 'desc' }>;
  visible_columns: string[];
  is_default: boolean;
  is_shared: boolean;
  use_count: number;
  last_used_at?: string | null;
  created_at: string;
}

export async function fetchSavedViews(
  entityType: string,
  module: ModuleType,
): Promise<SavedView[]> {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('saved_views' as never)
    .select('*')
    .eq('entity_type' as never, entityType)
    .eq('module' as never, module)
    .order('use_count', { ascending: false })
    .order('name');

  if (error) {
    console.warn('[fetchSavedViews]', error.message);
    return [];
  }
  return ((data ?? []) as any[]) as SavedView[];
}
```

빌드 확인:
- [ ] `npm run build` 실행해서 TypeScript 에러 없음 확인
- [ ] `npm run dev` 후 brower에서 `/filler/parties` 열어서 정상 동작 확인

### A-4. SavedViewsDropdown 보강

`src/components/common/saved-views-dropdown.tsx` 개선 — 클릭 시 실제로 URL filter 적용:

(상세 코드는 02_calendar_integration_design.md의 우선순위가 더 높으므로 일단 Phase B 후 처리)

### A-5. 회귀 테스트

다음 페이지들 직접 열어서 정상 동작 확인:

- [ ] `/login` — 로그인 가능
- [ ] `/filler/parties` — 목록 + score 표시
- [ ] `/paper_mill/parties` — 동일
- [ ] `/investor/parties` — 동일  
- [ ] `/filler/parties/[id]` — party 상세
- [ ] `/inbox` — 받은 메일
- [ ] `/drafts` — 작성 중 메일
- [ ] `/engagements` — 거래 파이프라인
- [ ] `/tasks` — 할 일 목록
- [ ] `/settings/email-signature` — 설정
- [ ] `/settings/email-history` — 이메일 히스토리

### A-6. main에 merge

모든 페이지 OK 시:

```powershell
git add -A
git commit -m "feat: complete build restoration

- Add migrations 025_lead_scores, 026_saved_views
- Replace stub queries with real implementations
- Verified all pages render correctly"
git push origin fix/missing-modules-stubs

# main에 merge
git checkout marinebiogroup
git merge fix/missing-modules-stubs
git push origin marinebiogroup

# 태그
git tag v5.12-build-restored
git push origin v5.12-build-restored
```

---

## Phase B: 캘린더 통합 — Week 1 (인프라 + OAuth)

### B-1. 작업 브랜치 생성

```powershell
git checkout marinebiogroup
git pull
git checkout -b feature/calendar-integration
```

### B-2. 환경 변수 추가

1. Google Cloud Console에서 OAuth 2.0 Client ID 생성
   - https://console.cloud.google.com/apis/credentials
   - Authorized redirect URI: `http://localhost:3000/api/calendar/google/callback`
   - 추후 production: `https://<your-domain>/api/calendar/google/callback`

2. Azure Portal에서 App registration 생성
   - https://portal.azure.com → Azure AD → App registrations
   - Redirect URI (Web): `http://localhost:3000/api/calendar/microsoft/callback`
   - API permissions: Calendars.Read, offline_access (delegated)

3. `.env.local`에 추가:
```
GOOGLE_OAUTH_CLIENT_ID=...
GOOGLE_OAUTH_CLIENT_SECRET=...
GOOGLE_OAUTH_REDIRECT_URI=http://localhost:3000/api/calendar/google/callback

MS_OAUTH_CLIENT_ID=...
MS_OAUTH_CLIENT_SECRET=...
MS_OAUTH_TENANT_ID=common
MS_OAUTH_REDIRECT_URI=http://localhost:3000/api/calendar/microsoft/callback

# 32바이트 무작위 hex (PowerShell로 생성: [System.BitConverter]::ToString((1..32 | %{Get-Random -Min 0 -Max 256})).Replace('-',''))
CALENDAR_ENCRYPTION_KEY=<32-byte-hex>
```

4. Supabase에 encryption key 주입:
```sql
ALTER DATABASE postgres SET app.calendar_encryption_key TO 'your-key-here';
```

### B-3. DB 마이그레이션 적용

- [ ] `supabase/migrations/030_calendar_integration.sql` 실행

검증: "Tables created: 4 / 4, RLS policies: 10+"

### B-4. npm 패키지 설치

```powershell
npm install googleapis @microsoft/microsoft-graph-client @azure/msal-node isomorphic-fetch @fullcalendar/react @fullcalendar/daygrid @fullcalendar/timegrid @fullcalendar/list @fullcalendar/interaction rrule date-fns-tz
```

### B-5. OAuth 라우트 구현

생성할 파일들 (이 세션에서 만들어진 가이드 참조):
- [ ] `src/lib/calendar/tokens.ts` — 토큰 암복호화 helper
- [ ] `src/lib/calendar/google-client.ts` — Google SDK wrapper
- [ ] `src/lib/calendar/microsoft-client.ts` — MS Graph wrapper
- [ ] `src/app/api/calendar/google/connect/route.ts`
- [ ] `src/app/api/calendar/google/callback/route.ts`
- [ ] `src/app/api/calendar/microsoft/connect/route.ts`
- [ ] `src/app/api/calendar/microsoft/callback/route.ts`

각 파일의 구현 가이드는 새 세션에서 Claude에게 요청하세요.

### B-6. 연결 관리 UI

- [ ] `src/app/(app)/calendar/connections/page.tsx`
- [ ] `src/components/calendar/connection-card.tsx`

---

## Phase B: 캘린더 통합 — Week 2 (Sync + 표시)

### B-7. Sync 로직

- [ ] `src/lib/calendar/sync.ts` — 핵심 동기화
- [ ] `src/lib/calendar/matcher.ts` — party 자동 매칭
- [ ] `src/app/api/calendar/[provider]/sync/route.ts` — 수동 trigger

### B-8. FullCalendar UI

- [ ] `src/app/(app)/calendar/page.tsx`
- [ ] `src/components/calendar/calendar-view.tsx`
- [ ] `src/components/calendar/event-detail-drawer.tsx`

---

## Phase B: Week 3 (Party 통합)

### B-9. party-meetings-list 실제 구현

기존 stub `src/components/parties/party-meetings-list.tsx`를 실제로 만들어:
- meetings 테이블에서 데이터 가져오기
- 미팅 추가/편집 dialog
- 캘린더 이벤트와 link 표시

### B-10. meetings.ts 쿼리 교체

`src/lib/queries/meetings.ts` stub을 실제 쿼리로 교체.

---

## 작업 시 주의사항 (이전 세션 교훈)

1. **TypeScript generic이 들어간 파일은 Base64 인코딩 후 PowerShell `[System.Convert]::FromBase64String`로 작성**. `@'...'@` here-string 사용 금지.

2. **PowerShell 경로에 `[module]` 같은 대괄호 있으면 `-LiteralPath` 사용** 또는 `[System.IO.File]::Exists()`.

3. **빌드 깨질 가능성 있는 변경은 작업 브랜치에서**. main(`marinebiogroup`)에 직접 push 금지.

4. **DB 마이그레이션 적용 후 항상 검증 NOTICE 확인**. 실패 시 롤백 SQL 준비.

5. **OAuth 토큰은 절대 평문으로 DB에 저장하지 않기**. 항상 `app.encrypt_calendar_token()` 거치기.

---

## 막힐 때 도움 받기

이 핸드오프 문서들을 새 Claude 세션에 보여주고:

> "mbg-project의 캘린더 통합 작업 중이다. 03_next_session_checklist.md의 Phase B Week 1 B-5 단계가 막혔다. Google OAuth callback에서 토큰 받은 후 calendar_connections에 저장하는 route handler를 작성해줘."

처럼 구체적으로 어느 단계에서 무엇이 필요한지 명시하면 빠르게 도움받을 수 있습니다.
