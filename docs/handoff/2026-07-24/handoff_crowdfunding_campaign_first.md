# Handoff — 크라우드펀딩 Campaign-first Deal + Checklist 엔진 (2026-07-23)

## 요약

GitHub(marinebiogroup 브랜치)에서 기존 핸드오프 3건(maskpack seed / playbook v2 / kickstarter plan)과 라이브 코드를 직접 읽고 확인한 결과 및 산출물 2건.

### 확인된 현재 상태

1. **캠페인 필수(DB)** — `campaign_dataroom.sql`이 이미 `deals.campaign_id NOT NULL` + BEFORE INSERT fallback 트리거("General" `…ff`)를 적용해 둠. **DB는 campaign-first 완료 상태.** 단, New Deal 모달이 Standalone 기본이라 캠페인 미선택 시 조용히 General로 귀속 → UI/서버 강제 필요(이번 패치).
2. **Checklist/Task 자동 생성** — `trg_apply_stage_playbook`은 `AFTER INSERT OR UPDATE`. **Deal 생성 즉시 첫 스테이지(research) 분량이 인스턴스화**되고, 스테이지 이동마다 해당 스테이지 분량 추가 생성. 추가 작업 불필요, VERIFY만 실행.
3. **진행 모델 검토 결론** — Task 완료 → 해당 Checklist **자동 완료(파생 상태)는 채택**. 스테이지 내 checklist 간 순차 잠금("다음 checklist로 이동")은 **비채택**(checklist는 병렬 완료 조건). "다음"의 단위는 **Stage**: 전 checklist 완료 → `stage_ready=true` 신호 → **스테이지 이동은 수동 확정**(go/no-go·펀딩 결과 등 외부 판단 게이트 존재) → 이동 시 기존 트리거가 다음 스테이지 checklist/task 자동 생성.

## 산출물

| 파일 | 내용 |
|---|---|
| `sql\migration_checklist_autocomplete_readiness.sql` | (A) `trg_task_checklist_autocomplete`: 하위 task 전부 completed/cancelled → checklist 자동 완료(`extra_data.auto_complete` 태그). task 재오픈 시 **auto 태그가 있는 항목만** 원복(수동 체크 보호). 예외 무해화(태스크 저장 차단 금지). + 1회성 backfill. (B) `app.v_deal_stage_readiness` 뷰: deal별 현 스테이지 checklist_total/complete, open_tasks, `stage_ready` (security_invoker). |
| `tools\patches\patch_deal_campaign_required.ps1` | ① 모달: Standalone/Campaign 토글 제거, Campaign 셀렉트 상시 노출 + required 검증 ② `createDeal`: `campaign_id` 없으면 서버에서 거부. DB fallback 트리거는 시드 안전망으로 유지. 앵커 가드로 멱등. |

## 실행 순서

1. Supabase SQL Editor: `migration_checklist_autocomplete_readiness.sql` 전체 실행 → 하단 VERIFY V1(트리거), V2(크라우드펀딩 딜 readiness), V3(항목별 task 집계) 확인
2. PowerShell: 패치 실행

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_deal_campaign_required.ps1
```

3. `npx tsc --noEmit` — 베이스라인 15 에러 대비 증가 없어야 함
4. 로컬에서 New Deal 모달 확인: Campaign 셀렉트가 required로 표시, 미선택 시 에러
5. 커밋/푸시 (아래 finish block)

## 지뢰 회피 기록

- 트리거는 `deal_checklists.extra_data.auto_complete`로 자동/수동 완료를 구분 — **수동 체크는 절대 자동 원복하지 않음**
- task 판정: `status not in ('completed','cancelled')` + `deleted_at is null` (soft-delete된 task는 차단 요인 아님)
- 문자열 리터럴 내 세미콜론/단독 키워드 0건, DO-block 없음(함수 본문은 `$fn$` 인용)
- 모달 패치 후 `dealMode` state 완전 제거 → unused-var 에러 원천 차단
- `v_deal_stage_readiness`는 `security_invoker=true` — RLS는 기저 테이블 정책을 따름

## 파일 이동

### ① 유니버설 mover (권장)

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

(`migration_*.sql` → `sql\`, `patch_*.ps1` → `tools\patches\`, `handoff_*.md` → `docs\handoff\2026-07-23\` 자동 라우팅)

### ② 인라인 폴백 mover (파일별)

```powershell
$dl = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$specs = @(
  @{ Filter='migration_checklist_autocomplete_readiness*.sql'; Dest='sql';                     Name='migration_checklist_autocomplete_readiness.sql' },
  @{ Filter='patch_deal_campaign_required*.ps1';               Dest='tools\patches';           Name='patch_deal_campaign_required.ps1' },
  @{ Filter='handoff_crowdfunding_campaign_first*.md';         Dest='docs\handoff\2026-07-23'; Name='handoff_crowdfunding_campaign_first.md' }
)
foreach ($s in $specs) {
  $f = Get-ChildItem -Path $dl -Filter $s.Filter | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($null -eq $f) { Write-Host ('NOT FOUND: ' + $s.Filter); continue }
  Unblock-File -Path $f.FullName
  $dest = Join-Path $repo $s.Dest
  [System.IO.Directory]::CreateDirectory($dest) | Out-Null
  $target = Join-Path $dest $s.Name
  [System.IO.File]::Copy($f.FullName, $target, $true)
  Remove-Item -Path $f.FullName -Force
  Write-Host ('MOVED: ' + $target)
}
```

## Finish block

```powershell
cd C:\dev\mbg-project
powershell -ExecutionPolicy Bypass -File tools\patches\patch_deal_campaign_required.ps1
npx tsc --noEmit
git status -sb
git add sql/migration_checklist_autocomplete_readiness.sql tools/patches/patch_deal_campaign_required.ps1 docs/handoff/2026-07-23/handoff_crowdfunding_campaign_first.md "src/app/(app)/pipelines/[code]/new-deal-modal.tsx" "src/app/(app)/pipelines/[code]/actions.ts"
git commit -m "feat: campaign-required deal creation + checklist autocomplete trigger + stage readiness view"
git push origin marinebiogroup
```

> **주의**: `git push origin marinebiogroup`은 Railway 자동 배포를 트리거한다 (urm.marinebiogroup.com 즉시 반영). 커밋 전 `git status -sb`로 스테이징 확인 필수.

## 다음 단계 (후보)

1. **UI에 readiness 노출**: 딜 상세/칸반 카드에 `v_deal_stage_readiness` 기반 "N/M 완료 · 이동 준비됨" 배지 + 원클릭 스테이지 이동 버튼 (이동 자체는 수동 확정 유지)
2. **캠페인 상세 페이지에 "New Deal" 버튼**: `campaigns/[id]`에서 campaign_id 프리필로 모달 오픈 (campaign-first UX 완성)
3. Mask Pack 딜 2건으로 실전 검증: research task 완료 → checklist 자동 완료 → stage_ready 확인 → outreach 이동 → v2 outreach 템플릿 생성 확인
