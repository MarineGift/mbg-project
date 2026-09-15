# HANDOFF — 중요 Party 메일 폴더 (mail folders)

날짜: 2026-09-15 · 대상: URM Platform (`MarineGift/mbg-project`, branch `marinebiogroup`)
요청: 메일함에 Greentown Labs 같은 중요 Party를 지정해서, 그 Party의 메일이 오면 해당 폴더에 모여 관리되게 한다.

---

## 1. 설계 — 메일을 옮기지 않는다

폴더는 **저장 위치가 아니라 저장된 뷰(saved view)** 입니다. 메일을 복사·이동하지 않습니다.

이유: 수신 메일은 이미 들어올 때 party가 붙습니다. `src/lib/email/header-parser.ts`의 `matchSenderToContactAndParty()`가 ① contacts.email 정확 일치 → ② parties.email 정확 일치 → ③ 발신 도메인 매칭(gmail/naver 등 공용 도메인은 제외) 순서로 `party_id`를 찾아 `app.communications.party_id`에 기록합니다. 그래서 폴더는

```
communications.party_id = <folder party>
   OR from_address ILIKE '%@<pinned domain>'
```

로 필터만 하면 되고, **폴더를 만드는 순간 과거 메일까지 전부 그 안에 들어와 있습니다.** 메일을 실제로 옮겼다면 party 탭·검색·스레드가 전부 이중 관리돼야 하고, 재동기화 때마다 어긋납니다.

`match_domains`는 contacts에 등록되지 않은 발신자(뉴스레터, `no-reply@`, 두 번째 회사 도메인)를 폴더에 끌어오기 위한 보조 장치입니다.

---

## 2. 변경 내역

### DB (신규 1)
`sql/migration_20260915_mail_folders.sql` — `app.mail_folders` 생성
- 컬럼: `id, organization_id, party_id, label, color, match_domains text[], sort_order, created_by, created_at, updated_at, deleted_at`
- `unique (organization_id, party_id) where deleted_at is null` — party당 살아있는 폴더 1개
- RLS 4종(select/insert/update/delete) `organization_id = app.current_organization_id()`, `authenticated` grant
- **Greentown Labs Houston 폴더 자동 시드** (해당 party가 없으면 조용히 건너뜀)
- VERIFY 3종 + 선택적 backfill(주석 처리): `party_id`가 비어 있는 greentownlabs.com 메일을 party에 붙이는 UPDATE. VERIFY 3 숫자를 보고 판단하세요.

`pglast.parse_sql()` 통과. **Supabase SQL Editor에서 Ctrl+A로 전체 선택 후 Run** (선택 영역만 실행되는 에디터 버릇 때문).

### 코드 (신규 4 / 수정 4)
신규
- `src/app/actions/mail-folders.ts` — list / listWithCounts / get / create / update / delete(soft) / reorder / party 검색. 도메인 입력은 `@x.com`, `https://x.com/`, `Foo@X.com` 다 받아서 `x.com`으로 정규화.
- `src/components/layout/mail-folder-nav.tsx` — 사이드바 Inbox 하위에 폴더 목록(미읽음/전체 카운트, 색 점).
- `src/components/inbox/mail-folder-manager.tsx` — 폴더 추가/이름/색/도메인/순서/삭제 UI.
- `src/app/(app)/inbox/folders/page.tsx` — `/inbox/folders` 관리 화면.

수정
- `src/types/inbox.ts` — `InboxFilters.partyDomains?: string[]` 추가(옵셔널이라 기존 사용처 영향 없음)
- `src/lib/queries/inbox.ts` — `partyId` + `partyDomains`가 같이 오면 `eq` 대신 `or(party_id.eq.X, from_address.ilike.*@d, ...)`
- `src/app/(app)/inbox/page.tsx` — `?folder=<uuid>` 해석(→ partyId + domains), 헤더에 폴더 이름/색, 탭 전환 시 `folder` 유지
- `src/components/layout/sidebar.tsx` — `<MailFolderNav />` 삽입 (**이 파일은 CRLF**입니다. 편집 시 줄바꿈 유지할 것)

---

## 3. 적용 순서

1. **SQL 먼저.** Supabase SQL Editor → `sql/migration_20260915_mail_folders.sql` 붙여넣기 → **Ctrl+A** → Run.
   - VERIFY 2에 Greentown 폴더 1줄이 나오면 정상.
   - VERIFY 3 숫자가 크면(= party_id 없는 greentownlabs.com 메일이 많으면) 맨 아래 backfill 블록의 주석을 풀고 따로 실행하세요. 폴더뿐 아니라 party의 Communications 탭까지 같이 채워집니다.
2. 파일 배치 → 커밋/푸시(아래 5절).
3. 배포 후 **Ctrl+Shift+R**.

SQL을 안 돌리고 코드만 배포하면 사이드바에 "Add mail folder"만 뜨고, 폴더 관련 액션이 `relation "app.mail_folders" does not exist` 에러를 냅니다.

---

## 4. 사용법

- 사이드바 Inbox 아래 **Folders** 섹션 → 폴더 클릭 → `/inbox?folder=<id>` (미읽음/전체 카운트 표시)
- **Manage folders** → party 검색해서 추가. 이름·색은 선택, 비우면 party 이름 사용
- Omya, Moorim, SMI 같은 곳도 같은 방식으로 추가
- 폴더 삭제는 뷰만 지웁니다 — 메일은 그대로

---

## 5. 마무리 (배포)

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/migration_20260915_mail_folders.sql `
        src/app/actions/mail-folders.ts `
        src/components/layout/mail-folder-nav.tsx `
        src/components/inbox/mail-folder-manager.tsx `
        "src/app/(app)/inbox/folders/page.tsx" `
        "src/app/(app)/inbox/page.tsx" `
        src/components/layout/sidebar.tsx `
        src/lib/queries/inbox.ts `
        src/types/inbox.ts `
        docs/handoff/2026-09-15
git commit -m "feat(inbox): party mail folders (saved views) with sidebar counts"
git push origin marinebiogroup
```

`git push` = 자동 배포. 레포는 public이므로 자격증명·실제 ID를 코드/주석에 넣지 말 것(이번 변경에는 없음).

---

## 6. 검증 상태 / 남은 것

- `npx tsc --noEmit`: 이번에 건드린 9개 파일 에러 0. (기존 에러는 `[partyType]/parties/page.tsx`, `api/relay/mail/route.ts`, `components/schedule/*` — `ignoreBuildErrors: true`라 배포는 통과)
- SQL: `pglast` 구문 검증 통과. 실제 DB 적용은 미실행.
- 미검증: 브라우저 동작.

남은 것
- 폴더별 카운트는 폴더 1개당 head 쿼리 2번입니다. 폴더가 20개를 넘어가면 단일 RPC로 묶는 게 낫습니다.
- 발신(outbound)도 같은 폴더에서 보고 싶으면 탭에서 Outbound로 전환하면 됩니다(folder 파라미터 유지됨). 다만 outbound는 `from_address`가 우리 주소라 `match_domains` 보조 매칭이 걸리지 않고 `party_id`로만 잡힙니다.
- 신규 party를 폴더로 만들었는데 비어 있다면, 그 party에 contact 이메일이 등록돼 있는지 먼저 보세요. 등록이 없으면 `match_domains`에 회사 도메인을 넣는 것이 가장 빠릅니다.
