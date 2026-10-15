\xef\xbb\xbf# Handoff 2026-10-15 (k) — 국가별 AI 분석 링크 3개 필드 (ChatGPT · Claude · Gemini)

> 앞 문서: `handoff_20261015j_market_links.md`

## 1. 변경
- `app.country_markets` 에 고정 필드 3개: **`chatgpt_url`**, **`claude_url`**, **`gemini_url`** (https 만 허용 — check 제약)
- 국가당 1행이라 같은 나라의 모든 제지사·충전제사 Market 탭에 동일 링크 표시
- 기존 `report_links` 에 저장된 링크는 도메인으로 해당 필드에 복사 (chatgpt.com / claude.ai / gemini.google.com) — `report_links` 컬럼은 남겨두되 화면에서 사용 안 함

## 2. 파일
| 파일 | 위치 |
|---|---|
| `migration_20261015k_country_market_ai_links.sql` | `sql/` |
| `country-markets.ts` (서버 액션 `setCountryMarketAiLink`) | `src/lib/actions/` |
| `country-market-links.tsx` (3행 고정 UI) | `src/components/parties/` |
| `country-market-tab.tsx` | `src/components/parties/` |

## 3. 화면 (Market 탭 → AI 시장 분석 원문)
| 행 | 동작 |
|---|---|
| ChatGPT / Claude / Gemini | 링크 있으면 새 탭으로 열기 · **변경** · ✕ 삭제 / 없으면 "미입력" + **입력** |

## 4. 적용
1. Supabase: migration 실행 (Ctrl+A → Run) — 결과에 국가별 has_chatgpt / has_claude / has_gemini
2. 파일 다운로드 → PowerShell

```powershell
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = [ordered]@{
  'country-markets.ts'       = 'src\lib\actions\country-markets.ts'
  'country-market-links.tsx' = 'src\components\parties\country-market-links.tsx'
  'country-market-tab.tsx'   = 'src\components\parties\country-market-tab.tsx'
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
git add sql/migration_20261015k_country_market_ai_links.sql src/lib/actions/country-markets.ts src/components/parties/country-market-links.tsx src/components/parties/country-market-tab.tsx docs/handoff
git commit -m "feat: country market AI links as fields (chatgpt_url, claude_url, gemini_url)"
git push origin marinebiogroup
```
