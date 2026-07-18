# Handoff — 크라우드펀딩 플레이북 v2 + Marine Pack 자산 (2026-07-18)

## 요약

두 개 시드. **실행 순서 엄수.**

1. `seed_crowdfunding_playbook_v2.sql` — 재사용 표준 프로세스. 기존 템플릿(체크리스트 27/태스크 21)을 **42/41로 전면 교체**. 향후 모든 크라우드펀딩 캠페인에 그대로 적용되는 표준.
2. `seed_maskpack_us_retail_assets.sql` — Marine Pack 전용. `retailer` party_type + 미국 클린뷰티 리테일러 6곳 파티 + Indiegogo 딜에 제품 전용 태스크 4건.

## 설계 원칙 (v2)

- **스테이지 코드 7개 불변** (research/outreach/application/review/live_campaign/funded/closed) — 기존 딜 이력 보존
- **모든 태스크 템플릿은 체크리스트에 1:1 연결** — 2026-06-14 정책(`checklist_template_id is null`이면 인스턴스화 스킵) 준수
- Checklist = 상태(완료 조건), Task = 행동. 스테이지별 게이트:
  - research: 견적 3곳 기반 목표액 확정
  - outreach: 주간 go/no-go (리드 수 vs 목표), Day-1 확약 30 pct
  - application: 컴플라이언스 팩 (라벨/인증/안전자료)
  - live_campaign: 48시간 내 30 pct 모멘텀
  - funded: InDemand + B2B 리테일 + 회고
  - closed: **리드 리스트 보존** (다음 캠페인의 시드 자산)

## 지뢰 회피 기록

- `trg_apply_stage_playbook` 트리거는 **스테이지 변경 시에만** 발화 → 템플릿 교체 후 기존 딜에는 명시적 backfill 호출 필요 (시드 (4)번, plain SELECT로 처리, DO-block 없음)
- 템플릿 교체 시 어제 생성된 pb_* 인스턴스는 stale orphan soft-delete로 정리되고 새 템플릿으로 재생성됨. 커스텀 태스크(`extra_data.src=maskpack_seed_2026Q3`)는 `pb_task` 키가 없어 **영향 없음**
- 가드: 파이프라인 부재 시 `1/count(*)` division-by-zero로 즉시 중단
- 문자열 리터럴 세미콜론/단독 키워드 0건 (린트 검증)

## Marine Pack 자산 시드 내용

- 파티 6곳 (`us_clean_beauty_2026Q3`): Credo Beauty, The Detox Market, Grove Collaborative, Ulta Beauty(Conscious Beauty), Thrive Market, Sephora(Clean at Sephora)
  - funded 스테이지 "B2B retail outreach activated" 체크리스트의 타겟 리스트
  - research 단계에서는 영문 카피 벤치마크 채널로 활용
- 제품 태스크 4건: 특허 2건+NET 인증 영문 원페이저(high) / 클린뷰티 카피 벤치마크 / 미국인 모델 영상 신규 디자인 재편집(high) / 피부온도 하강 열화상 데모 촬영 — cosmetic 표현(cools, soothes)만, 의학적 클레임 금지

## 실행 순서

1. Supabase SQL Editor: `seed_crowdfunding_playbook_v2.sql` 실행 → VERIFY V1(42/41), V2(untied=0), V3
2. Supabase SQL Editor: `seed_maskpack_us_retail_assets.sql` 실행 → VERIFY V1(리테일러 6), V2(커스텀 태스크 12)
3. mover로 파일 배치 → finish block

## 파일 이동

### ① 유니버설 mover (권장)

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### ② 인라인 폴백 mover

```powershell
$dl = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$specs = @(
  @{ Filter='seed_crowdfunding_playbook_v2*.sql';   Dest='sql';                     Name='seed_crowdfunding_playbook_v2.sql' },
  @{ Filter='seed_maskpack_us_retail_assets*.sql';  Dest='sql';                     Name='seed_maskpack_us_retail_assets.sql' },
  @{ Filter='handoff_playbook_v2_maskpack*.md';     Dest='docs\handoff\2026-07-18'; Name='handoff_playbook_v2_maskpack.md' }
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
git status -sb
git add sql/seed_crowdfunding_playbook_v2.sql sql/seed_maskpack_us_retail_assets.sql docs/handoff/2026-07-18/handoff_playbook_v2_maskpack.md
git commit -m "seed: crowdfunding playbook v2 (42cl/41task reusable) + marine pack US retail parties and product tasks"
git push origin marinebiogroup
```

> **주의**: push는 Railway 자동 배포(urm.marinebiogroup.com 즉시 반영). 커밋 전 `git status -sb` 확인.

## 다음 단계

1. research 태스크 착수: 특허+NET 원페이저 → OEM 견적 → 클레임 맵 (3개가 목표액과 카피를 결정)
2. 클레임 맵 확정 후: 영문 상세페이지 카피 초안 (Credo/Ulta CB 벤치마크 반영) — 다음 세션 작업 후보
3. outreach 진입 전: DKIM/DMARC 정비 완료 필수 (기존 태스크)
