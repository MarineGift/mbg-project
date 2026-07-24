# Handoff — 클레임 맵 + 증빙 원페이저 (2026-07-18)

## 요약

research 스테이지 high 태스크 2건의 산출물.

1. `claims_map_marinepack_en.md` — EN 카피 단일 기준(master). GREEN/YELLOW/RED 3단 분류 + 기존 영문 상세페이지 스크리닝 재작성 매핑 + 히어로 카피 초안. 상세페이지·광고·심사답변·CS 전부 이 맵을 따름.
2. `proof_onepager_marinepack_en.md` — 특허 2건(10-1852779 단독보유, 10-1921612 충남대 공동) + NET 2023-0010(해수부, ~2028-07-09) + KGFC 2017 영문 원페이저. 캠페인 페이지 proof 섹션과 B2B 덱(Credo/Ulta) 공용.

## 주의 사항

- **NET 인증의 기술명은 "chitin-derived nanomesh 천연 고흡수성 폴리머 제조기술"** — 마스크팩 특허(해조 섬유/나노셀룰로오스)와 기술 계보가 다르므로 원페이저에서는 "마린 바이오소재 플랫폼 인증"으로 정확히 포지셔닝했다. 캠페인 페이지에서 NET을 "이 마스크팩 자체의 인증"처럼 쓰면 과장 리스크.
- 열화상 온도 하강 수치는 실측 기록 확정 전까지 placeholder. 뷰티 프로그램 방영분의 측정 조건(전후 온도, 경과 시간)을 확보하면 YELLOW 조건 충족 후 수치 기입.
- RED 리스트 최종 점검: 페이지 발행 전 treats/heals/inflammation/acne/antibacterial/regenerate/collagen/melanin/FDA 전문 검색 0건 확인.

## 파일 이동 (인라인 mover — 캠페인 문서 전용 경로)

```powershell
$dl = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$specs = @(
  @{ Filter='claims_map_marinepack_en*.md';    Dest='docs\campaign\maskpack';  Name='claims_map_marinepack_en.md' },
  @{ Filter='proof_onepager_marinepack_en*.md';Dest='docs\campaign\maskpack';  Name='proof_onepager_marinepack_en.md' },
  @{ Filter='handoff_claims_proof_assets*.md'; Dest='docs\handoff\2026-07-18'; Name='handoff_claims_proof_assets.md' }
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

> 유니버설 mover는 `claims_map_*` / `proof_onepager_*` 패턴을 라우팅하지 않으므로 이번엔 인라인 mover 사용. (handoff는 유니버설로도 이동됨 — 중복 실행해도 CLEAN 처리.)

## Finish block

```powershell
cd C:\dev\mbg-project
git status -sb
git add docs/campaign/maskpack/claims_map_marinepack_en.md docs/campaign/maskpack/proof_onepager_marinepack_en.md docs/handoff/2026-07-18/handoff_claims_proof_assets.md
git commit -m "docs: marine pack EN claims map (master) + patents/NET proof one-pager"
git push origin marinebiogroup
```

> push = Railway 자동 배포. 커밋 전 `git status -sb`.

## URM 태스크 처리

SQL Editor에서 두 태스크 완료 처리:

```sql
update app.tasks set status = 'completed', completed_at = now(), updated_at = now()
where deal_id = (select id from app.deals
                 where deal_name = 'Mask Pack - Indiegogo US Campaign'
                   and deleted_at is null)
  and title in ('Finalize FDA-safe claims copy (EN master)',
                'Patents and NET cert one-pager (EN)')
  and deleted_at is null;
```

## 다음 단계

1. 열화상 실측 기록 확보 (방영분 캡처 + 측정 조건) → YELLOW 수치 확정
2. OEM 견적 3곳 (7/25 기한) — 목표액 확정의 마지막 입력값
3. 클레임 맵 기반 영문 상세페이지 풀 카피 초안 — 다음 세션
