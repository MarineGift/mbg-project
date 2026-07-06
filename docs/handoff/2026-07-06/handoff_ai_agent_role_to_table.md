# Handoff — enum→table 전환 + task_decomposer 시드 (2026-07-06)

## 배경
Phase 4 마이그레이션에서 `ai.agents.role` enum에 `task_decomposer`를 추가하고 같은 스크립트에서 그 값을 쓰려다 **55P04 (unsafe use of new enum value)**가 났고, 시드 프롬프트의 `{"subtasks":[...]}` JSON이 Supabase 에디터 파서를 건드려 **42P01 relation "3"**도 났다.

요청에 따라 **enum을 lookup 테이블로 완전 전환**한다. 이러면 새 role 추가가 enum ALTER가 아니라 그냥 INSERT라 55P04가 원천 제거되고, 앞으로 role 확장이 자유롭다.

## Probe로 확인한 실제 상태 (전환 안전성)
- enum 타입: `ai.agent_role`
- **사용처: `ai.agents.role` 단 한 곳** (다른 테이블 없음 → 전환 위험 최소)
- 실제 데이터: classifier 2, reply_drafter 14, strategy_advisor 2, summarizer 2 = **20행**
- enum 라벨 7개: classifier, reply_drafter, strategy_advisor, summarizer, **extractor, translator**, task_decomposer
  (코드 `AgentRole`엔 `content_extractor`로 잘못 들어가 있었고 `translator` 누락 — 실제와 불일치. 아래 D에서 정정)

## 전환 설계 (실 Postgres 16 검증)
1. `ai.agent_roles` lookup 테이블 생성 + role 7개 시드 (label/description/sort_order)
2. `ai.agents.role`을 `enum → text` 변환 (`using role::text`로 20행 값 그대로 보존)
3. FK `ai.agents.role → ai.agent_roles(key)` (NOT VALID → VALIDATE로 안전)
4. enum 타입 `ai.agent_role` DROP (사용처 없으니 안전, 이름 기반 가드로 재실행 안전)

**검증**: 20행 enum 상태 재현 → 전환 2회 실행 모두 에러 없음(idempotent). 최종 role=text, 20행 보존(분포 동일), lookup 7행, enum 0개. **핵심 테스트**: 새 role+에이전트를 한 스크립트에서 INSERT → 55P04 없이 성공(enum이었으면 실패). FK가 미등록 role 거부 확인.

## task_decomposer 시드 (파서-safe 별도 파일)
- 42P01을 유발한 `{...}` JSON 예시를 프롬프트에서 **완전 제거**. 프롬프트에 **중괄호·세미콜론·`into` 키워드 0개** 확인. JSON 구조는 말로 서술("object whose only key is subtasks, an array of objects..."), dollar-quote 대신 일반 작은따옴표+`''` 이스케이프 → 에디터 mis-split 불가.
- org당 1행, model=haiku, output_format=json, require_pii_masking=false. idempotent(NOT EXISTS).
- **검증**: 전환 후 시드 실행 → 2 org 2행, 재실행 0 insert, 프롬프트 1150자 정상.

## 코드 정합 (D)
`AgentRole` 타입을 실제 DB role에 맞춤: `content_extractor → extractor`, `translator` 추가. `content_extractor`는 타입 정의에만 있고 어디서도 값으로 안 쓰임(코드 grep 0) → 안전. task_decomposer는 Phase 4 커밋(`7471273`)에 이미 정상 반영됨.

## 파일 (4개)

| 파일 | 종류 | 목적지 |
|---|---|---|
| `migration_ai_agent_role_to_table.sql` | 마이그레이션(전환) | `sql\` |
| `seed_ai_agent_task_decomposer.sql` | 시드(파서-safe) | `sql\` |
| `patch_agent_role_type_align.ps1` | 패치(타입 정합, 선택) | `tools\patches\` |
| `handoff_ai_agent_role_to_table.md` | 이 문서 | `docs\handoff\2026-07-06\` |

## 적용 순서

### ① 무버
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### ② Supabase SQL Editor — 순서대로 2개 실행
**먼저** `migration_ai_agent_role_to_table.sql` 전체 실행. VERIFY:
- (a) role data_type = `text`
- (b) role별 카운트 = classifier 2 / reply_drafter 14 / strategy_advisor 2 / summarizer 2 (변화 없음)
- (c) `agents_role_fkey` 존재
- (d) `enum_still_exists` = 0

**그다음** `seed_ai_agent_task_decomposer.sql` 전체 실행. VERIFY: org별 task_decomposer 행(haiku/json/active).

이제 55P04도 42P01도 안 난다.

### ③ 타입 정합 패치 (선택)
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_agent_role_type_align.ps1
```

### ④ 빌드
```powershell
cd C:\dev\mbg-project
npm run build
```

## 동작 테스트
`/todo` → 태스크 열기 → "AI decompose" → 서브태스크 생성. (Phase 4 앱 코드는 `7471273`에 이미 배포됨. 이제 DB에 task_decomposer 에이전트가 있으므로 실제 동작.)

## 마무리
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql\migration_ai_agent_role_to_table.sql sql\seed_ai_agent_task_decomposer.sql tools\patches\patch_agent_role_type_align.ps1 src\types\ai.ts docs\handoff\2026-07-06\handoff_ai_agent_role_to_table.md
git commit -m "refactor(ai): convert agent role enum to lookup table; parser-safe task_decomposer seed; align AgentRole type"
git push origin marinebiogroup
```

## 참고 — 왜 이게 근본 해결인가
- 55P04: enum 새 값의 "커밋 후 사용" 제약이 사라짐. lookup 테이블은 INSERT 즉시 사용 가능.
- 42P01: 프롬프트에서 `{...}`/`;`/`into` 제거 → 에디터 파서 quirk 회피.
- 앞으로 새 에이전트 role(예: translator 실제 사용)은 `ai.agent_roles`에 INSERT 1줄 + 에이전트 행 1줄이면 끝.

## 미해결 (이월)
- Phase 3 리마인더 cron 등록 (엔드포인트·워커·DB 준비 완료).
- Calendar 뷰 드래그 리스케줄.
- `migration_campaign_rename_trigger.sql` (별건).
- (선택) reply_drafter 등 기존 role도 이제 lookup 기반이므로, 향후 role 관리 UI를 만들면 `ai.agent_roles`를 소스로 쓰면 됨.
