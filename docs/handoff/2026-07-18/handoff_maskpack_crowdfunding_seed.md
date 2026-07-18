# Handoff — 마스크팩 크라우드펀딩 캠페인 시드 (2026-07-18)

## 요약

기존 `crowdfunding` 파이프라인(research → outreach → application → review → live_campaign → funded/closed, 플레이북 템플릿 체크리스트 27 + 태스크 21 적용됨)에 마스크팩 캠페인을 얹는 시드.

**새 파이프라인을 만들지 않는다.** 2026-06-15 플레이북 시드가 이미 DB에 있고, `app.apply_stage_playbook(deal_id, stage_id)` 함수로 스테이지 진입 시 태스크가 인스턴스화된다.

## 시드 내용 (`sql\seed_maskpack_crowdfunding_campaign.sql`)

1. **party_type `cf_platform`** — max(id)+1 + NOT EXISTS 가드 (other_supplier 추가 때와 동일 패턴)
2. **파티 3건** — Indiegogo, Kickstarter, Wadiz (`entity_type = company`, `domain_normalized` 가드)
3. **캠페인** — `d0000000-0000-4000-8000-0000000000fc` "Mask Pack Crowdfunding 2026" (fd/fe/ff 다음 결정적 UUID, created_by = YunYoung uuid)
4. **딜 2건** — 둘 다 stage `research` 진입
   - Mask Pack - Indiegogo US Campaign (high, USD 40,000)
   - Mask Pack - Wadiz Korea Campaign (medium, KRW 30,000,000)
5. **플레이북 인스턴스화** — `select app.apply_stage_playbook(...)` 플레인 문장 (DO-block 없음)
6. **마스크팩 전용 커스텀 태스크 9건** (`extra_data.src = maskpack_seed_2026Q3`)
   - research: FDA 클레임 카피 확정 / OEM 견적 3곳 / 리드 목표 역산 / US 라벨 팩 / 안전성 자료 / 촬영용 샘플
   - outreach: DKIM·DMARC 정비(소비자 발송 전 필수) / URM 프리런치 너처 시퀀스
   - Wadiz 딜: 제출 패키지 점검(책임판매업 번호 반영 등)

## 지뢰 회피 기록

- **`deals.campaign_id`는 현재 NOT NULL** — 6/20 `pipeline_seed_deals` 마이그레이션의 INSERT 컬럼 목록에는 없다. 그대로 복사하면 23502. 이번 시드는 campaign_id 명시.
- 문자열 리터럴 내 `;` 없음, 단독 SQL 키워드(from/into/where/select/join) 없음 (SQL Editor 파서 대응)
- `ON CONFLICT` 미사용 — 전부 NOT EXISTS 가드 (answer_library 사례와 동일 원칙)
- BEGIN/COMMIT, DO-block 없음 — 문장 단위 자립형

## 실행 순서

1. Supabase SQL Editor에서 `seed_maskpack_crowdfunding_campaign.sql` 전체 실행
2. 파일 하단 VERIFY 3개 실행:
   - V1: 딜 2건, stage = research
   - V2: Indiegogo 딜 = playbook_tasks(research분) + custom 8 / Wadiz 딜 = playbook + custom 1
   - V3: cf_platform 파티 3건
3. 아래 mover로 파일을 리포에 배치 후 커밋

## 파일 이동

### ① 유니버설 mover (권장)

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

(`seed_*.sql` → `sql\`, `handoff_*.md` → `docs\handoff\2026-07-18\` 자동 라우팅)

### ② 인라인 폴백 mover (파일별)

```powershell
$dl = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

# seed SQL
$f = Get-ChildItem -Path $dl -Filter 'seed_maskpack_crowdfunding_campaign*.sql' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($null -eq $f) { Write-Host 'NOT FOUND: seed_maskpack_crowdfunding_campaign*.sql' } else {
  Unblock-File -Path $f.FullName
  $dest = Join-Path $repo 'sql'
  [System.IO.Directory]::CreateDirectory($dest) | Out-Null
  $target = Join-Path $dest 'seed_maskpack_crowdfunding_campaign.sql'
  [System.IO.File]::Copy($f.FullName, $target, $true)
  Remove-Item -Path $f.FullName -Force
  Write-Host ('MOVED: ' + $target)
}

# handoff md
$f = Get-ChildItem -Path $dl -Filter 'handoff_maskpack_crowdfunding_seed*.md' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($null -eq $f) { Write-Host 'NOT FOUND: handoff_maskpack_crowdfunding_seed*.md' } else {
  Unblock-File -Path $f.FullName
  $dest = Join-Path $repo 'docs\handoff\2026-07-18'
  [System.IO.Directory]::CreateDirectory($dest) | Out-Null
  $target = Join-Path $dest 'handoff_maskpack_crowdfunding_seed.md'
  [System.IO.File]::Copy($f.FullName, $target, $true)
  Remove-Item -Path $f.FullName -Force
  Write-Host ('MOVED: ' + $target)
}
```

## Finish block

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/seed_maskpack_crowdfunding_campaign.sql docs/handoff/2026-07-18/handoff_maskpack_crowdfunding_seed.md
git commit -m "seed: mask pack crowdfunding campaign (Indiegogo/Wadiz deals + playbook + custom tasks)"
git push origin marinebiogroup
```

> **주의**: `git push origin marinebiogroup`은 Railway 자동 배포를 트리거한다 (urm.marinebiogroup.com에 즉시 반영). 커밋 전 `git status -sb`로 스테이징 상태를 확인할 것.

## 다음 단계 (시드 적용 후)

1. URM 화면에서 Mask Pack 캠페인 필터로 딜 2건 확인
2. research 태스크 착수 순서: 클레임 카피 → OEM 견적 → 리드 역산 (이 3개가 펀딩 목표액을 결정)
3. 프리런치 랜딩페이지 + 리드 수집 폼은 별도 작업 (outreach 스테이지 진입 전 준비)
