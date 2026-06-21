# HANDOFF - 2026-06-21c : (app) CRM 레이아웃 폭 통일 + 폰트 확대

> 직전 핸드오프 `HANDOFF_2026-06-21b_dupfix_open_reports.md` (HEAD `a0ceb57`) 에 이어지는 작업.
> 한 일: 1920x1080에서 페이지마다 들쭉날쭉하던 본문 폭을 단일 토큰 `max-w-app`(1600px)으로 통일하고, 기본 폰트를 약 6% 키움.

---

## 0. 문제 / 원인

- 1920 화면에서 일부 페이지(리스트/테이블)는 full-width인데, 폼·상세 페이지는 가운데 좁은 컨테이너에 갇혀 우측 여백이 컸음.
- 근본 원인: `AppShell`의 `<main>`은 max-width가 없는데, **페이지별 컴포넌트가 제각각의 캡**(`max-w-2xl`~`max-w-7xl`, `container`)을 직접 걸고 있었음. 사이드바 `w-60`(240px) 기준 1920에서 콘텐츠 영역은 약 1680px인데 Mailing은 1024px, 대시보드 container는 1400px에서 잘림.

## 1. 해결 방침

- **단일 폭 토큰 `max-w-app = 1600px`** 신설(`tailwind.config.ts theme.extend.maxWidth`). 작업/데이터 페이지는 전부 이 폭으로 통일 → 1920에서 좌우 여백 최소화, 초광폭에서도 과도하게 늘어나지 않음.
- `container` 2xl 브레이크포인트도 1400 -> 1600으로 맞춰 대시보드와 일관화.
- **읽기/짧은 폼 페이지는 의도적으로 좁게 유지**(가독성): 이메일 compose/inbox 상세, task 상세, settings의 permissions/audit/assignments/calendar. (1600px로 늘리면 한 줄이 너무 길어져 오히려 보기 나쁨.)
- **기본 폰트 약 6% 확대**: `globals.css`에 `html { font-size: 106.25% }`(=17px base). 되돌리려면 그 html 규칙만 삭제.

리스트/테이블 페이지(Investors 등)는 원래 full-width라 그대로 둠(테이블은 넓을수록 좋음).

## 2. 변경 파일

설정 2:
- `tailwind.config.ts` — `maxWidth.app='1600px'` 추가, `container.screens.2xl` 1400->1600
- `src/app/globals.css` — `html { font-size: 106.25% }` 추가

(app) 페이지 15 (캡 -> `max-w-app`):
- `app/(app)/page.tsx` (container -> max-w-app)
- `app/(app)/mailing/bulk-mail-client.tsx`, `app/(app)/mailing/mailing-tabs-client.tsx`(2곳)
- `app/(app)/[partyType]/parties/[id]/page.tsx` + `loading.tsx`
- `app/(app)/[partyType]/parties/[id]/edit/page.tsx`, `app/(app)/[partyType]/parties/new/page.tsx`
- `app/(app)/reports/page.tsx`
- `app/(app)/drafts/[id]/page.tsx` + `loading.tsx`
- `app/(app)/settings/email-history/page.tsx`(2곳), `email-templates/page.tsx`, `email-sequences/page.tsx`(2곳), `email-whitelist/page.tsx`, `email-mailboxes/page.tsx`

> marketing/web/shop/admin 페이지는 공개 사이트라 **건드리지 않음**.

## 3. 적용 (in-place 패치)

다운로드 폴더에 `apply_responsive_2026-06-21.ps1` + 이 `.md` 를 받고:
```
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\apply_responsive_2026-06-21.ps1"
```
- 스크립트가 config/globals/15페이지를 in-place 패치하고, 이 핸드오프를 `docs/research/`로 이동.
- 멱등: 구 토큰(`max-w-5xl` 등)은 1회 치환 후 사라지므로 재실행해도 no-op. `[ok]/[skip]/[warn]`로 파일별 보고.
- `[warn] anchor not found`가 뜨면 그 파일이 그 사이 변경된 것 — 해당 파일만 수동 확인.

## 4. Finish block

```
cd C:\dev\mbg-project
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\apply_responsive_2026-06-21.ps1"
git status -sb
git add tailwind.config.ts src/app/globals.css "src/app/(app)" docs/research/HANDOFF_2026-06-21c_responsive_layout.md
git status -sb
git commit -m "style(app): unify CRM page width to max-w-app (1600px) + modest type scale-up"
git push origin marinebiogroup
```
> push = web(`mbg-project`) 자동 배포. CSS/className 변경이라 빌드 후 바로 반영.

## 5. 튜닝 포인트

- 폭이 너무 넓다/좁다 → `tailwind.config.ts`의 `maxWidth.app` 값(1600px) 한 곳만 조정하면 전체 반영.
- 폼(parties new/edit)이 너무 늘어져 보이면 그 두 파일만 `max-w-app` -> `max-w-4xl`로 되돌리면 됨.
- 폰트 확대 취소 → `globals.css`의 `html { font-size: 106.25% }` 규칙 삭제.
- 읽기 페이지(inbox/compose 등)도 넓히고 싶으면 알려주면 추가 반영.
