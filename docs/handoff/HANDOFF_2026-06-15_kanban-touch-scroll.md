# URM CRM 핸드오프 - 2026-06-15: 칸반 컬럼 터치 스크롤 (touch-action)

대상: YunYoung / mbg-project. 브랜치 marinebiogroup.

## 증상
- 가로 페이저로 바꾼 뒤에도 폰에서 컬럼 안 세로 스크롤이 스와이프로 안 됨.
  유저는 "스크롤바가 작아서"라고 느꼈지만, 실제로는 카드 위 스와이프가 막혀 작은 스크롤바를 잡을 수밖에 없던 것.

## 진짜 원인
- 딜 카드 스타일에 `touchAction: 'none'`(드래그앤드롭용, kanban-client.tsx 525행).
  카드가 컬럼을 가득 채우는데 touch-action:none이라 카드 위 스와이프 시 브라우저가 스크롤/패닝을 못 함.
  -> 손가락 스와이프로는 스크롤 불가, 얇은 스크롤바를 잡아야만 했음.

## 수정 (1파일 1편집)
- `src/app/(app)/pipelines/[code]/kanban-client.tsx`
  - 카드 `touchAction: 'none'` -> `touchAction: 'manipulation'`.
    manipulation = 상하/좌우 패닝 + 핀치줌 허용. 이제 카드 위에서:
      세로 스와이프 -> 컬럼 스크롤, 가로 스와이프 -> stage 페이징.
  - 데스크톱은 마우스(PointerSensor)라 touch-action 영향 없음 -> 드래그앤드롭 그대로.
  - 모바일 터치 드래그앤드롭은 사실상 비활성(스크롤/페이징 우선). 필요하면 TouchSensor delay 방식으로
    long-press 드래그를 추가할 수 있으나, 지금은 스크롤 신뢰성 우선.

- 스크롤바는 직전(move-13)에서 14px로 키워둔 상태 유지(이제는 인디케이터 역할; 잡을 필요 없음).
- 패처: `patch-kanban-touch-scroll.ps1` (원자적 1앵커 count==1, 멱등, LF/UTF-8 no BOM).

## 검증
1. 패처 적용 -> npx tsc --noEmit 0 errors -> commit/push.
2. 폰 칸반: 카드 위를 위아래로 스와이프 -> 컬럼이 스크롤됨(이제 됨). 좌우 스와이프 -> stage 이동.
3. 데스크톱: 마우스로 카드 드래그앤드롭 정상.
