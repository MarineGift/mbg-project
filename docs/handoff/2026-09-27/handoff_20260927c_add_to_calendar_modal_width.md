# HANDOFF — 2026-09-27 c: Add to Calendar 모달 가로 넘침 수정

## 증상
Inbox 상세 → Add to Calendar 모달에서 내용이 오른쪽으로 잘리고 가로 스크롤바가 생김 (긴 Zoom URL).

## 원인
shadcn DialogContent 는 `grid` 인데 열 정의가 없어 암묵 열 폭이 max-content → 긴 Zoom 링크 길이만큼 열이 넓어짐. 링크의 `truncate` 는 flex 안에서 min-w-0 이 없어 동작 안 함.

## 수정 (`src/components/meetings/add-to-calendar-modal.tsx`, in-place patch)
- DialogContent: `w-[calc(100vw-2rem)] grid-cols-[minmax(0,1fr)] overflow-x-hidden`
- Meeting link: anchor `min-w-0 flex-1`, URL 텍스트 `<span className="truncate">`
- 2열 grid 자식 `min-w-0`, SelectTrigger `min-w-0 [&>span]:truncate` (Timezone 긴 라벨)

## Push
cd C:\dev\mbg-project
git status -sb
git add src/components/meetings/add-to-calendar-modal.tsx docs/handoff
git commit -m "calendar modal: stop horizontal overflow (grid minmax, truncate link)"
git push origin marinebiogroup
