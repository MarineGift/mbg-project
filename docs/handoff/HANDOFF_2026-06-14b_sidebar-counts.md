# URM CRM 핸드오프 (정정/후속) - 2026-06-14 저녁

대상: YunYoung / mbg-project (Next.js 14.2 + Supabase `app` schema)
레포: MarineGift/mbg-project, 브랜치 `marinebiogroup` (push = urm.marinebiogroup.com 자동 배포)

> 이 파일은 같은 날 앞선 핸드오프(`HANDOFF_2026-06-14_dashboard-revalidate.md`)의 **정정/후속**이다.
> "AI Draft 보냈는데 카운트 안 변함"의 진짜 원인이 추가로 드러났다.

---

## 카운트 미갱신 - 두 개의 서로 다른 카운트 표시가 있었다

URM에는 "메일 발송 후 갱신돼야 하는 카운트"가 **두 군데**다. 이를 혼동하면 안 된다.

### (1) Dashboard 페이지 카드 - 서버 컴포넌트 (앞 세션에서 수정함, 유효)
- `src/app/(app)/page.tsx`의 Inbox/Outbound/To-Do/Parties/Deals 카드.
- 서버에서 Supabase로 집계 -> Next.js 캐시 대상.
- 앞 세션 수정(`drafts.ts` 5개 액션에 `revalidatePath('/', 'layout')` 추가, commit 19ae346)은
  **이 서버 카드**에 유효하다. 헛수고 아님. AI Draft approve/send/reject 후 대시보드 카드가 갱신된다.

### (2) 사이드바 뱃지 + Directory/Pipeline 카운트 - 클라이언트 컴포넌트 (이번에 수정)
- `src/components/layout/sidebar.tsx`는 **`'use client'`** 컴포넌트.
- 카운트(Inbox/InBound/OutBound/Sent/To-Do/Calendar/Campaigns, Directory 파티 수,
  Pipeline 딜 수)를 **`useEffect(..., [])` 안에서 `createSupabaseBrowserClient()`로 직접 fetch**한다.
- 의존성 배열이 `[]` 라서 **마운트 시 단 한 번만** 가져온다.
- App Router에서 `(app)` 레이아웃(=사이드바)은 페이지 간 soft navigation에서 **언마운트되지 않으므로**,
  한 번 읽은 숫자가 그 세션 내내 고정 -> **F5(하드 리로드)** 해야만 갱신.
- `revalidatePath`는 서버 캐시용이라 이 클라이언트 fetch에는 **전혀 영향 없음**. (그래서 앞 수정으로도 안 변했던 것.)
- 증거: 스크린샷 2장에서 Sent 3/Out Bound 3/3 (고정) vs Sent 4/Out Bound 4/4 (하드 리로드 후).

---

## 이번 수정

- 파일: `src/components/layout/sidebar.tsx`
- 두 useEffect(파이프라인 딜 수 effect, 뱃지 카운트 effect)의 의존성 배열을 `[]` -> `[pathname]`로 변경.
  - `pathname`은 이미 `const pathname = usePathname()`로 스코프에 있음. 추가 의존성이라 exhaustive-deps 린트 무해.
  - 효과: 컴포넌트 재마운트 없이도 **라우트가 바뀔 때마다** 카운트 재조회. 발송 후 아무 메뉴 이동(Inbox<->Dashboard 등)하면 즉시 갱신.
- 산출물 패처: `patch-sidebar-count-refresh.ps1` (앵커 count==1 가드 2개, 멱등 체크, 불일치 시 무변경 abort, LF/UTF-8 no BOM).

---

## 남은 한계 (선택 후속) - "이동 없이 제자리 갱신"

- `[pathname]`은 **네비게이션 시점**에 갱신한다. 같은 페이지에 머문 채 발송만 하고 이동을 안 하면 사이드바는 그대로다.
- 제자리 즉시 갱신을 원하면 둘 중 하나:
  1. **ui-store nonce**: `ui-store.ts`에 `badgeNonce`/`bumpBadges()` 추가 -> compose 다이얼로그/draft approve 성공 시 `bumpBadges()` 호출 -> 사이드바 카운트 effect 의존성에 `badgeNonce` 추가. (3파일 surgical)
  2. **Supabase Realtime**: 이미 `RealtimeProvider`가 `app.communications`에 붙어 있으니, 사이드바가 그 이벤트 구독해 카운트 재조회. (더 큰 작업)
- 또한 compose/수동 발송 경로(`communications.ts`)의 `revalidatePath('/', 'layout')`는 `if (parsed.data.partyId)` **조건부**라,
  partyId 없는 회신은 대시보드 서버 카드가 갱신 안 될 수 있음(무조건 호출로 바꾸면 해결). 사이드바와는 별개 이슈.

---

## 운영 메모 (유지)
- 레포 PUBLIC: 파일은 `https://raw.githubusercontent.com/MarineGift/mbg-project/marinebiogroup/<경로>`로 직접 읽기. `(app)` -> `%28app%29`.
- 패처/배포 컨벤션: ASCII PowerShell, 앵커 count==1, 멱등, 무변경 abort, LF/UTF-8 no BOM. 커밋 전 `npx tsc --noEmit` 0 errors -> `git status -sb` -> commit -> `git push origin marinebiogroup`(웹 배포).
