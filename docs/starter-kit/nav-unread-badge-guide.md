# NavUnreadBadge 사이드바 적용 가이드

## Step 1 — 사이드바 파일 찾기
PowerShell에서:
```powershell
Get-ChildItem -Recurse -Path "C:\dev\mbg-project\src" -Filter "*.tsx" |
  Select-String -Pattern "Inbox|inbox" |
  Select-Object -ExpandProperty Filename -Unique
```
→ 결과에서 sidebar, nav, layout 관련 파일 확인

## Step 2 — 해당 파일 상단 import 추가
```tsx
import { NavUnreadBadge } from '@/components/nav/nav-unread-badge';
```

## Step 3 — Inbox 메뉴 항목 찾아서 수정

### 수정 전 (대략적 패턴)
```tsx
<Link href="/inbox">
  <MailIcon className="h-4 w-4" />
  <span>Inbox</span>
</Link>
```

### 수정 후
```tsx
<Link href="/inbox" className="flex items-center gap-2 w-full">
  <MailIcon className="h-4 w-4" />
  <span>Inbox</span>
  <NavUnreadBadge orgId={orgId} />   {/* ← 추가 */}
</Link>
```

## Step 4 — orgId 전달

사이드바가 Server Component라면:
```tsx
// layout.tsx 또는 sidebar server component 안에서
const supabase = createServerComponentClient({ cookies });
const { data: { user } } = await supabase.auth.getUser();
const { data: member } = await supabase
  .from('organization_members')
  .select('organization_id')
  .eq('user_id', user.id)
  .single();
const orgId = member?.organization_id ?? '';
```

사이드바가 Client Component라면:
→ orgId를 props로 parent layout에서 내려주거나
→ NavUnreadBadge를 별도 Suspense wrapper로 감싸서 layout에서 직접 렌더

## AI Drafts처럼 보이려면
현재 AI Drafts의 badge 숫자(52)가 어떻게 구현됐는지 확인:
```powershell
Get-ChildItem -Recurse "C:\dev\mbg-project\src" -Filter "*.tsx" |
  Select-String "AI Drafts|ai.draft|aiDraft" |
  Select-Object Path, LineNumber, Line
```
→ 동일한 패턴으로 Inbox badge 추가

## read_at 미치환 수동 읽음 처리 (선택)
inbox 목록에서도 읽음 처리하려면 list item 클릭 시:
```tsx
// inbox list component
async function handleClick(id: string) {
  await markCommunicationRead(id);  // from communications.ts
  router.push('/inbox/' + id);
}
```
