# Handoff 2026-10-15 (p) — Country Markets 화면 (국가별 보기, 동티모르 포함)

> 앞 문서: `handoff_20261015o_thailand_mills_fillers.md`

## 1. 문제
시장현황(`app.country_markets`)은 제지사·충전제사 상세의 Market 탭에서만 보였다. 국가 필터도 해당 타입 party 가 있는 국가만 나와서, 행이 없는 동티모르(TL, priority none)는 URM 어디서도 볼 수 없었다.

## 2. 변경
| 파일 | 위치 | 내용 |
|---|---|---|
| `markets-page.tsx` | `src/app/(app)/markets/page.tsx` | **/markets** — 국가 목록 (시장현황 행 + 제지사·충전제사가 있는 국가 합집합). 우선순위·요약(headline_ko)·제지사 수·충전제사 수(실시간, 1000행 페이징)·FCC 예상·AI 링크 여부·확인일. 우선순위 칩 필터, `시장현황 미등록` 필터 |
| `markets-code-page.tsx` | `src/app/(app)/markets/[code]/page.tsx` | **/markets/TL** 등 — Market 탭과 같은 화면(`CountryMarketTab`)을 국가 코드로 표시, 제지사·충전제사 목록 링크 |
| `sidebar.tsx` | `src/components/layout/sidebar.tsx` | Directory 아래 **Country Markets** 메뉴 |
| `parties-list-page.tsx` | `src/app/(app)/[partyType]/parties/page.tsx` | 제지사·충전제사 목록에 `<국가> 시장현황` 버튼 (필터 없으면 Country Markets 로) |

DB 변경 없음. 동티모르 행은 이미 있음 (TL, priority none). tsc 통과.

## 3. 적용
```powershell
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = [ordered]@{
  'markets-page.tsx'      = 'src\app\(app)\markets\page.tsx'
  'markets-code-page.tsx' = 'src\app\(app)\markets\[code]\page.tsx'
  'sidebar.tsx'           = 'src\components\layout\sidebar.tsx'
  'parties-list-page.tsx' = 'src\app\(app)\[partyType]\parties\page.tsx'
}
foreach ($n in $map.Keys) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($n); $ext = [System.IO.Path]::GetExtension($n)
  $rx = '^' + [regex]::Escape($base) + '( \(\d+\))?' + [regex]::Escape($ext) + '$'
  $all = Get-ChildItem -Path $dl -File | Where-Object { $_.Name -match $rx } | Sort-Object LastWriteTime -Descending
  if ($all) {
    $dest = Join-Path $repo $map[$n]
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($dest)) | Out-Null
    Copy-Item -LiteralPath $all[0].FullName -Destination $dest -Force
    $all | Remove-Item -Force
    Write-Output ('COPIED ' + $n)
  } else { Write-Output ('MISSING ' + $n + ' in Downloads') }
}
powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'tools\move-downloads.ps1')
cd $repo
git status -sb
git add "src/app/(app)/markets" "src/app/(app)/[partyType]/parties/page.tsx" src/components/layout/sidebar.tsx docs/handoff
git commit -m "feat: Country Markets page (all countries incl. no-mill countries like Timor-Leste)"
git push origin marinebiogroup
```
