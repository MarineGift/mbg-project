# HANDOFF - 2026-06-21d : party 상세 헤더/본문 좌우 정렬

> 직전 `HANDOFF_2026-06-21c_responsive_layout.md` (HEAD `e28d8be`) 후속. 폭 통일 후 남은 단일 이슈 수정.

## 문제
- party 상세(`[partyType]/parties/[id]`)에서 헤더(`PartyHeader`: 뒤로가기 + 제목 "ABC Paper Limited")는 본문 스크롤 영역 **밖**의 별도 컴포넌트라 전체폭 좌측에 붙는데, 본문만 `max-w-app mx-auto`로 가운데 정렬돼 좌측 라인이 어긋났음.
- Campaigns/Mailing/Reports/Investors 등 다른 페이지는 헤더·본문이 같은 컨테이너라 이미 정렬 정상. 이 페이지만 헤더가 분리돼 있어 문제.

## 해결
- 헤더 두 줄과 본문을 **모두 동일한 `max-w-app mx-auto px-6` 컨테이너**로 통일 (Reports/Mailing이 쓰는 패턴과 동일). 좌·우 라인 정확히 일치.
- `<header>` 의 full-bleed 하단 보더는 유지(바깥 요소에 있음).

## 변경 파일
- `src/components/parties/party-header.tsx` — 헤더 2개 행 div: `px-6 ...` -> `max-w-app mx-auto px-6 ...`
- `src/app/(app)/[partyType]/parties/[id]/page.tsx` — 본문: 바깥 `p-6` 제거하고 중앙 블록 내부에 `px-6 py-6` (헤더와 동일 구조로 맞춤)

## 적용
다운로드에 `apply_party_align_2026-06-21.ps1` + 이 md 받고:
```
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\apply_party_align_2026-06-21.ps1"
```
멱등(구 클래스 문자열은 1회 치환 후 사라짐).

## Finish block
```
cd C:\dev\mbg-project
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\apply_party_align_2026-06-21.ps1"
git status -sb
git add "src/app/(app)/[partyType]/parties/[id]/page.tsx" src/components/parties/party-header.tsx docs/research/HANDOFF_2026-06-21d_party_header_align.md
git status -sb
git commit -m "style(party): align detail header with body inside max-w-app container"
git push origin marinebiogroup
```
> push = web 자동 배포. 배포 후에도 안 바뀌면 브라우저 강력 새로고침(Ctrl+F5)로 CSS 캐시 비우기.

## 참고
- 헤더 우측 버튼(Mindmap/Edit)이 카드 우측 라인에 맞춰 살짝 안쪽으로 들어옴(의도된 정렬).
- 다른 상세성 페이지(inbox/compose 등)는 읽기용이라 좁게 유지 중. 원하면 별도 요청.
