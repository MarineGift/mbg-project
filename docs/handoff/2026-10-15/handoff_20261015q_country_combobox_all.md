# Handoff 2026-10-15 (q) — 국가 콤보박스에 전체 국가 + 동티모르 추가

> 앞 문서: `handoff_20261015p_country_markets_page.md`

## 1. 변경
| 파일 | 위치 | 내용 |
|---|---|---|
| `fix_20261015q_countries_iso_fill.sql` | `sql/` | `app.countries` 에 없는 ISO 3166-1 국가 채움 (249개 목록, TL 포함). 기존 이름은 유지 |
| `parties-list-page.tsx` | `src/app/(app)/[partyType]/parties/page.tsx` | 국가 콤보박스 = **app.countries 전체** ∪ party 가 쓰는 코드 (이전: party 가 있는 국가만). p 의 시장현황 버튼 포함 |

- 국가 이름은 계속 DB(`app.countries`)에서 읽음 — 하드코딩 없음
- 행이 없는 국가를 고르면 목록은 0건, `<국가> 시장현황` 버튼으로 /markets/XX 이동
- tsc 0 errors

## 2. 적용
1. Supabase: fix_q 실행 → 결과 4행 (countries total / TL row / TL market row / party codes missing)
2. 파일 이동 · 커밋

```powershell
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = [ordered]@{
  'parties-list-page.tsx' = 'src\app\(app)\[partyType]\parties\page.tsx'
}
foreach ($n in $map.Keys) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($n); $ext = [System.IO.Path]::GetExtension($n)
  $rx = '^' + [regex]::Escape($base) + '( \(\d+\))?' + [regex]::Escape($ext) + '$'
  $all = Get-ChildItem -Path $dl -File | Where-Object { $_.Name -match $rx } | Sort-Object LastWriteTime -Descending
  if ($all) {
    Copy-Item -LiteralPath $all[0].FullName -Destination (Join-Path $repo $map[$n]) -Force
    $all | Remove-Item -Force
    Write-Output ('COPIED ' + $n)
  } else { Write-Output ('MISSING ' + $n + ' in Downloads') }
}
powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'tools\move-downloads.ps1')
cd $repo
git status -sb
git add sql/fix_20261015q_countries_iso_fill.sql "src/app/(app)/[partyType]/parties/page.tsx" docs/handoff
git commit -m "feat: country combobox lists every country in app.countries (+ ISO fill incl. Timor-Leste)"
git push origin marinebiogroup
```
