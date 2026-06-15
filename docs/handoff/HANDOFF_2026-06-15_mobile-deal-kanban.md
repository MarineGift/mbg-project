# URM CRM 핸드오프 - 2026-06-15: 모바일 UI 2건 (딜 정보 패널 / Kanban 카드)

대상: YunYoung / mbg-project. 브랜치 marinebiogroup.

## (A) 딜 상세 - Activity 위로 정보 패널이 겹침
- 원인: `src/app/(app)/pipelines/[code]/deals/[id]/page.tsx`의 2단 본문이
  `flex` 행 + `<aside className="w-80 shrink-0 ...">`. 모바일(~380px)에서 w-80(320px)이
  메인(flex-1)을 짓눌러 Activity 타임라인을 가림.
- 수정: aside를 새 클라이언트 컴포넌트 `DealInfoAside`로 교체.
  - 데스크톱(lg+): 기존과 동일한 우측 사이드 컬럼(`hidden lg:block`).
  - 모바일(<lg): aside 숨김 -> 메인이 전체 폭 사용(겹침 해소). 우하단 떠있는 info 아이콘 버튼 ->
    탭하면 우측 슬라이드오버로 About/Company/Notes 표시, 바깥/X로 닫음.
  - children(PropertyCard/CompaniesCard/NotesCard)은 서버에서 렌더되어 그대로 전달(데이터 로직 없음).
  - 신규 파일: `src/app/(app)/pipelines/[code]/deals/[id]/deal-info-aside.tsx`.

## (B) Kanban - Lead 카드가 화면을 꽉 채워 스크롤바를 못 누름
- 원인: `src/app/(app)/pipelines/[code]/kanban-client.tsx` 컬럼이 `h-[26rem]` 고정 +
  내부 `scrollbar-thin overflow-y-auto`. 모바일에서 그 얇은 내부 스크롤바가 안 보이고 누르기 어려움.
  보드는 `grid grid-cols-1 ... lg:grid-cols-4`라 모바일에서 컬럼이 세로로 쌓임.
- 수정:
  - 컬럼 높이 `h-[26rem]` -> `h-auto lg:h-[26rem]`. 모바일은 컬럼이 콘텐츠 높이로 자라 내부 스크롤
    함정이 사라지고, 보드(바깥 overflow-y-auto)에서 페이지 스크롤로 전체(모든 stage)를 자연스럽게 봄.
  - 카드 패딩 `p-3` -> `p-2.5` (살짝 컴팩트).

## 파일/적용
- 패처: `patch-mobile-deal-and-kanban.ps1` (2파일 4앵커, 원자적 count==1, 멱등, LF/UTF-8 no BOM).
- 신규 컴포넌트: `deal-info-aside.tsx` (mover가 route-group 경로로 복사).
- mover: `move-and-apply-10.ps1` (Unblock-File -> 컴포넌트 복사 -> 핸드오프 이동 -> 패처 실행 -> finish).
- tsconfig strict만(noUnusedLocals 없음).

## 검증
1. mover 실행 -> npx tsc --noEmit 0 errors -> commit/push.
2. 모바일(또는 브라우저 좁은 폭)에서:
   - 딜 상세: Activity가 안 가려짐, 우하단 info 아이콘 -> 슬라이드오버로 정보 확인.
   - Kanban: Lead/Qualified 등 전체가 페이지 스크롤로 보이고 카드가 약간 작아짐.

## 참고
- 우하단 떠있는 버튼이 브라우저 확장 오버레이(분홍 아이콘) 근처일 수 있음(앱 외부 요소, 기능엔 무관).
- 더 강하게 원하면: Kanban을 모바일에서 가로 스와이프(컬럼 옆으로 narrow 고정폭) 방식으로 재설계 가능.
