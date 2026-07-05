# Handoff — 태그 정규화 최종 검증 통과 + 큐레이션 (2026-07-04)

## 최종 검증 (C1, 2026-07-05)
전 항목 통과 — **태그 정규화 작업 종결**:
deep_tech_seed 소멸(deep_tech 36 병합) / catalytic 6 / femtech 2 / grant 4 / ocean 7 / korea 13 / cvc 11.
JSONB 백필로 기존 투자사 전체 레거시 태그 회수 (fintech 55, consumer 54, climate_tech 51 등).

## 큐레이션 (선택이지만 권장)
`sql/fix_interest_tags_curation.sql`:
- 승격 14종: fintech·consumer·enterprise·ai·software·life_science·web3_crypto·defense_space·accelerator·angel_network·commerce·mobility·media·cybersecurity (ko/en 라벨 + sort_order)
- 별칭 ~45개 추가: saas/b2b_saas/enterprise_software→software, biotech/bio/life_sciences→life_science, sustainable_materials/materials_science→advanced_materials, biomanufacturing/synthetic_biology→biomaterials, plastics→specialty_chemicals, crypto/web3/blockchain→web3_crypto 등
- 병합 재실행 + 잔여 900 롱테일 리포트

## 실행
1. 다운로드 → `powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1`
2. Supabase에서 실행 → (4) 잔여 롱테일 확인 (저사용 태그만 남으면 정상)

## 개별 mover (예비용)

```powershell
$dl = Join-Path $env:USERPROFILE 'Downloads'
$src = Get-ChildItem -Path $dl -Filter 'fix_interest_tags_curation*.sql' |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Output 'ERROR: file not found in Downloads'; return }
Unblock-File -Path $src.FullName
$destDir = 'C:\dev\mbg-project\sql'
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
$dest = Join-Path $destDir 'fix_interest_tags_curation.sql'
[System.IO.File]::Copy($src.FullName, $dest, $true)
Remove-Item -Path $src.FullName -Force
Write-Output ('MOVED: ' + $dest)
```

## Finish block

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_interest_tags_curation.sql docs/
git commit -m "feat(db): interest tag curation - promote 14 canonicals, ~45 aliases, merge synonym sprawl"
git push origin marinebiogroup
```

## 다음 태스크 후보
1. `parties.ts` 폼 저장 → 정규화 테이블 동기화 패치 (현재 폼은 레거시 jsonb에만 씀)
2. Batch 9 연락처 인리치먼트 T2 (~59곳, 우선순위 wave2/3 high 13곳)
3. 배포된 TAGS 정렬/드롭다운 UI 실사용 확인 (urm.marinebiogroup.com)
