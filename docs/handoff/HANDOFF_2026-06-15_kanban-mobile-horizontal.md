# URM CRM 핸드오프 - 2026-06-15: 모바일 칸반 가로 페이저 (세로 스크롤 충돌 해결)

대상: YunYoung / mbg-project. 브랜치 marinebiogroup.

## 증상
- 폰에서 칸반 컬럼 안 스크롤이 안 됨. "스크롤바가 작아서"라고 느꼈지만, 폰엔 잡아끄는 스크롤바가 없음.

## 진짜 원인
- 모바일 보드가 세로 스택(grid-cols-1)인데 각 컬럼도 세로 스크롤(overflow-y-auto) -> 같은 세로 축
  스크롤이 둘이라 손가락 스와이프가 어느 쪽을 스크롤할지 충돌. 컬럼이 안 움직이는 것처럼 보임.

## 수정 (2파일 5편집)
- `src/app/(app)/pipelines/[code]/kanban-client.tsx`
  - 보드 래퍼: `flex-1 overflow-y-auto bg-muted/30` -> `flex-1 overflow-hidden bg-muted/30 lg:overflow-y-auto`
    (모바일에선 래퍼 세로 스크롤 제거 -> 컬럼이 h-full로 영역을 채움).
  - 보드: `grid grid-cols-1 ...` -> 모바일 `flex h-full snap-x snap-mandatory gap-3 overflow-x-auto p-4`,
    sm+ `sm:grid sm:h-auto sm:snap-none sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-5` (원래 그리드 유지).
  - 컬럼: `h-[24rem] lg:h-[26rem] w-full` -> 모바일 `h-full w-[84vw] snap-start`, `sm:h-[26rem] sm:w-full`.
  => 폰: 좌우 스와이프로 stage 이동(가로), 컬럼 안은 상하 스와이프로 스크롤(세로). 축이 달라 충돌 없음.
     84vw라 다음 컬럼이 살짝 보여 가로 스크롤 힌트. snap으로 한 컬럼씩 페이징.
- `src/app/globals.css`
  - `.scrollbar-visible` ::-webkit-scrollbar 10px -> 14px, thumb 0.5 -> 0.6 (더 크고 진하게).

- 패처: `patch-kanban-mobile-horizontal.ps1` (원자적 5앵커 count==1, 멱등, LF/UTF-8 no BOM).
- 현재 원격 최신 코드(move-12 적용 상태) 기준 앵커 확인 완료.

## 검증
1. 패처 적용 -> npx tsc --noEmit 0 errors -> commit/push.
2. 폰에서 칸반:
   - 좌우로 넘기면 Prospect -> Qualified ... stage 이동.
   - 한 컬럼 안에서 위아래로 스와이프하면 딜 목록 스크롤(이제 잘 됨), 우측 스크롤바도 굵게 표시.
   - 데스크톱/태블릿(sm+/lg+) 그리드는 그대로.

## 참고(여전히 보류)
- 컴포저 '+ Checklist'/'+ Task' 버튼 제거 + 딜 페이지 모바일 자연 스크롤(R4)은
  `patch-deal-activity-and-scroll.ps1`에 있고 미적용. 체크리스트 stage 필터는 move-12로 적용됨.
