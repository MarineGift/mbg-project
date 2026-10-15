\xef\xbb\xbf# Handoff 2026-10-15 (j) — Market 탭에 분석 원문 링크 (ChatGPT 공유 링크)

> 앞 문서: `handoff_20261015i_market_tab.md`

## 1. 파일
| 파일 | 위치 | 내용 |
|---|---|---|
| `migration_20261015j_country_market_links.sql` | `sql/` | `country_markets.report_links` jsonb 컬럼 |
| `country-markets.ts` | `src/lib/actions/` | 서버 액션: 링크 추가·삭제 |
| `country-market-links.tsx` | `src/components/parties/` | 링크 목록 + 추가 폼 (클라이언트) |
| `country-market-tab.tsx` | `src/components/parties/` | Market 탭 상단에 링크 섹션 |
| `page.tsx` | `src/app/(app)/[partyType]/parties/[id]/` | 탭에 페이지 경로 전달 (저장 후 새로고침용) |

## 2. 사용법
1. ChatGPT 에서 해당 국가 분석 대화 열기 → **Share** → **Copy link** (`https://chatgpt.com/share/...`)
2. URM 제지사·충전제사 화면 → **Market** 탭 → **시장 분석 원문** → **링크 추가**
3. 제목(예: "ChatGPT — 인도 PCC·GCC 생산기업") + URL → 저장
- 국가 단위로 저장 → 같은 나라의 모든 제지사·충전제사 Market 탭에 같은 링크 표시
- 새 탭으로 열림, ✕ 로 삭제, 같은 URL 중복 저장 방지, https 만 허용

## 3. 참고
- ChatGPT 공유 링크는 공유 시점 대화 사본 — 이후 대화를 이어가면 다시 공유해야 최신 내용 반영
- 공유 링크는 링크를 가진 누구나 볼 수 있음 — 민감 정보 포함 대화는 공유 전 확인

## 4. 적용
1. Supabase: migration 실행 (Ctrl+A → Run)
2. 파일 다운로드 → PowerShell

```powershell
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = [ordered]@{
  'country-markets.ts'       = 'src\lib\actions\country-markets.ts'
  'country-market-links.tsx' = 'src\components\parties\country-market-links.tsx'
  'country-market-tab.tsx'   = 'src\components\parties\country-market-tab.tsx'
  'page.tsx'                 = 'src\app\(app)\[partyType]\parties\[id]\page.tsx'
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
git add sql/migration_20261015j_country_market_links.sql src/lib/actions/country-markets.ts src/components/parties/country-market-links.tsx src/components/parties/country-market-tab.tsx "src/app/(app)/[partyType]/parties/[id]/page.tsx" docs/handoff
git commit -m "feat: Market tab report links (ChatGPT shared analysis per country)"
git push origin marinebiogroup
```
