# URM CRM 핸드오프 (추가) - 2026-06-14: sim:inbound 검증 스크립트 stale 컬럼 수정

대상: YunYoung / mbg-project. 브랜치 marinebiogroup.

> processor enum 수정(핸드오프 d, commit e2834e9)은 정상 배포됨. 이 항목은 그 검증 스크립트의 별개 버그.

## 사실
- `npm run sim:inbound` 실패: `column parties.name does not exist` (script line 60).
- 원인: 스키마가 parties.name -> party_name 으로 이전됐는데 `src/scripts/simulate-inbound.ts`가 옛 `name`을 참조.
- 이건 **dev/test 스크립트 버그**일 뿐, 프로덕션 파이프라인과 무관. processor 수정과는 별개.

## 수정
- simulate-inbound.ts 3곳: `select('id, name, ...)` / `.eq('name', TEST_PARTY_NAME)` / `console.log(... ${party.name} ...)`
  -> 모두 `party_name`.
- 패처: `patch-sim-inbound-party-name.ps1` (앵커 count==1 x3, 멱등, 무변경 abort, LF/UTF-8 no BOM, ASCII 앵커).

## 검증 (수정 후)
- `npm run sim:inbound` (`.env.local`에 실제 ANTHROPIC_API_KEY 필요, 'UPM-Kymmene' party seed 필요).
  -> [1] party 조회 OK -> [2] inbound INSERT -> [3] processInbound(Haiku+Opus) -> [5] ai.drafts pending_review 1건 검증.
- 확인 SQL: select status, count(*) from ai.drafts group by status;  -> pending_review 1.
- 만약 '[1] party not found' 나오면: 'UPM-Kymmene'가 seed에 없는 것. seed 적용하거나, 스크립트의 party 조회를
  '해당 org의 임의 party 1건'으로 완화하면 됨(다음 작업 후보).

## 주의
- 이 스크립트 변경은 배포 동작에 영향 없음(서버/워커 무관). 레포 정합성 위해 커밋만.
