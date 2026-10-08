# Handoff 2026-10-07c — Partners: MBG Tier/분류 칩

## 변경
`src/app/(app)/[partyType]/parties/page.tsx`
- 헤더에 칩 2줄 추가 (`MBG ` 로 시작하는 interest_tags 가 있는 디렉토리에서만 표시):
  - **MBG priority**: Tier 1 / Tier 2 / Tier 3 + 건수
  - **MBG category**: CO2 Loop, IPO-Legal-Finance, Investor Prospect, Paper Value Chain ... + 건수
  - 클릭 → `?tag=<태그>` 필터, 활성 칩 다시 클릭 → 해제
- TAGS 칸: Greentown Labs 칩 + 행별 MBG 칩(Tier 먼저, 분류 다음). 클릭 시 해당 태그로 필터
- 색상: Tier 1 주황, Tier 2 하늘, Tier 3 회갈색, 분류 남색, Low Relevance 회색
- 버그 수정: tag / greentown / relevant 필터 시 상단 "N parties" 건수가 필터 결과로 표시
- DB 변경 없음. tsc 오류 12건 = 기존 그대로

## Mover (inline)
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$hits = Get-ChildItem -LiteralPath $Dl -File | Where-Object { $_.Name -like 'parties-page*.tsx' } | Sort-Object LastWriteTime -Descending
if (-not $hits) { Write-Output 'MISS parties-page.tsx' } else {
  $src = $hits[0]; Unblock-File -LiteralPath $src.FullName -ErrorAction SilentlyContinue
  $dest = Join-Path $Repo 'src\app\(app)\[partyType]\parties\page.tsx'
  [System.IO.File]::Copy($src.FullName, $dest, $true)
  $hits | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
  Write-Output ('MOVED ' + $src.Name + ' -> ' + $dest)
}
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

## Push
```powershell
cd C:\dev\mbg-project
git status -sb
git add "src/app/(app)/[partyType]/parties/page.tsx" docs/handoff
git commit -m "partners: MBG tier/category chips + tag filter count fix"
git push origin marinebiogroup
```
