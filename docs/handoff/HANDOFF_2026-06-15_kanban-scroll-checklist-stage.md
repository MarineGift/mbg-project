# URM CRM 핸드오프 - 2026-06-15: 칸반 스크롤/패딩 + 컴포저 체크리스트 stage 필터

대상: YunYoung / mbg-project. 브랜치 marinebiogroup.

## 현재 상태(재확인)
- 적용됨(이전): DealInfoAside(딜 정보 슬라이드오버), 칸반 h-auto+p-2.5.
- 미적용: 컴포저 체크리스트 stage 필터, 컴포저 +Checklist/+Task 버튼 제거(이번엔 요청에 없어 보류).

## 요청 2건
1) 칸반이 화면을 꽉 채워 스크롤이 제대로 안 됨 -> 칸반 약간 줄이고, 딜 카드 패딩 늘리고, 스크롤바 보이게.
2) Activity 컴포저의 체크리스트가 현재 stage에 맞게 안 나옴 -> 현재 stage 것만.

## 수정 (3파일 5편집)
- `src/app/(app)/pipelines/[code]/kanban-client.tsx`
  - 컬럼 높이 `h-auto lg:h-[26rem]` -> `h-[24rem] lg:h-[26rem]`:
    모바일에서 컬럼이 모든 딜을 펼쳐 화면을 꽉 채우던 것을 24rem 고정 박스로 바운드(스크롤 가능).
  - 컬럼 스크롤 영역 `scrollbar-thin` -> `scrollbar-visible` (항상 보이는 10px/50% 스크롤바).
  - 딜 카드 패딩 `p-2.5` -> `p-3`.
- `src/app/globals.css`
  - `.scrollbar-visible` 유틸 추가(@layer utilities, scrollbar-thin 아래). webkit 스크롤바를
    스타일링하면 모바일에서 overlay가 아니라 항상 표시됨(10px, thumb muted-foreground/0.5, track muted/0.4).
- `src/app/(app)/pipelines/[code]/deals/[id]/page.tsx`
  - Activity 컴포저용 deal_checklists 쿼리에 `if (currentStageId) .eq('stage_id', currentStageId)` 추가
    -> 드롭다운에 현재 stage 체크리스트만(중복/타 stage 항목 제거).

- 패처: `patch-kanban-scroll-and-checklist-stage.ps1` (원자적 5앵커 count==1, 멱등, LF/UTF-8 no BOM).
- 현재 코드(원격 최신) 기준으로 앵커 확인 완료.

## 검증
1. 패처 적용 -> npx tsc --noEmit 0 errors -> commit/push.
2. 폰에서:
   - 칸반: 각 stage 컬럼이 24rem 박스로 줄고, 오른쪽에 또렷한 스크롤바, 카드 패딩 여유.
   - 딜 상세 Activity: 체크리스트 드롭다운이 현재 stage 것만.

## 참고(보류 항목)
- 컴포저 '+ Checklist'/'+ Task' 버튼 제거(R2/R3)와 딜 페이지 모바일 자연 스크롤(R4)은
  이전 `patch-deal-activity-and-scroll.ps1`에 들어있고 아직 미적용. 원하시면 그 패치도 적용/조정 가능.
