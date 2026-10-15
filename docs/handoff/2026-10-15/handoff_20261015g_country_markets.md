\xef\xbb\xbf# Handoff 2026-10-15 (g) — 국가별 시장현황 테이블 + 제지사·충전제 화면 연결

> 앞 문서: `handoff_20261015f_philippines_mills_fillers.md`

## 1. 파일
| 파일 | 위치 | 내용 |
|---|---|---|
| `migration_20261015g_country_markets.sql` | `sql/` | 새 테이블 `app.country_markets` + RLS + 34개국 시장현황 시드 (upsert) |
| `country-market-panel.tsx` | `src/components/parties/` | 서버 컴포넌트 — 국가 시장현황 + 해당국 제지사·충전제사 목록 조회 |
| `country-market-panel-client.tsx` | `src/components/parties/` | 접이식 카드 — 버튼을 누르면 시장현황 표시 |
| `page.tsx` (패치) | `src/app/(app)/[partyType]/parties/[id]/` | Mill / Plant profile 카드 아래에 Country market 카드 삽입 |

## 2. 테이블 `app.country_markets`
- 국가당 1행: `organization_id + country_code` 유니크 (ISO 2자리, 대문자)
- 컬럼: `country_name`, `priority` (high / medium / low / on_hold / none), `headline`, `summary`, `sections` jsonb, `checked_at`, `deleted_at`
- `sections`: `fillers`, `mills`, `strategy`, `risks`, `next_steps[]`, `key_numbers[{label,value}]`, `files[]` (근거 SQL·handoff 파일명)
- **연결 방식**: `app.parties.country_code` — 같은 코드의 paper_mill / filler_supplier 를 화면에서 조회 (FK 없음, 국가코드 공유)
- RLS: 다른 조직 테이블과 동일 (`organization_id = app.current_organization_id()`), `set_updated_at` 트리거
- 시드 34개국: US, JP, IN, CN, ID, MY, VN, KR, TW, SA, AE, MM, BD, PK, AF, IR, LB, IL, JO, IQ, KW, YE, OM, LK, BT, NP, NZ, PG, TL, BN, KH, LA, AU, PH — 재실행 시 내용 갱신

## 3. 화면
- 제지사·충전제사 Overview 탭, Mill/Plant profile 카드 아래: **Country market: {국가}** 카드 (기본 접힘)
- 헤더: 우선순위 배지, headline, "N mills · M fillers in URM"
- 버튼 클릭 시: Summary · Key numbers · Filler makers · Paper mills · Approach · Risks · Next steps · URM 내 해당국 제지사/충전제사 목록 (outreach priority 순, 링크, 현재 회사 강조) · 근거 파일
- 해당 국가 행이 없으면 카드 표시 안 함

## 4. 참고
- 기존 `CountryPeersPanel` 은 `parties.name` / `parties.party_type` 컬럼을 조회 — 실제 컬럼은 `party_name` / `party_type_id` 라 빈 결과일 가능성 높음. 새 카드가 같은 역할을 하므로 추후 정리 대상
- 시장현황 수정은 SQL 로 `app.country_markets` upsert (편집 화면은 아직 없음)

## 5. 적용 순서
1. Supabase: `migration_20261015g_country_markets.sql` Ctrl+A → Run → 결과 CSV 확인
2. PowerShell (아래) — 컴포넌트 2개 복사, page.tsx 패치, SQL·handoff 이동
3. commit + push → Railway 자동 배포

## 6. PowerShell
```powershell
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$utf8 = New-Object System.Text.UTF8Encoding($false)
# 1) components -> src\components\parties
foreach ($n in @('country-market-panel.tsx', 'country-market-panel-client.tsx')) {
  $rx = '^' + [regex]::Escape([System.IO.Path]::GetFileNameWithoutExtension($n)) + '( \(\d+\))?\.tsx$'
  $all = Get-ChildItem -Path $dl -File | Where-Object { $_.Name -match $rx } | Sort-Object LastWriteTime -Descending
  if ($all) {
    Copy-Item -LiteralPath $all[0].FullName -Destination (Join-Path $repo ('src\components\parties\' + $n)) -Force
    $all | Remove-Item -Force
    Write-Output ('COPIED ' + $n)
  } else { Write-Output ('MISSING ' + $n + ' in Downloads') }
}
# 2) patch party detail page (idempotent)
$p = Join-Path $repo 'src\app\(app)\[partyType]\parties\[id]\page.tsx'
$s = [System.IO.File]::ReadAllText($p)
if ($s.Contains('CountryMarketPanel')) { Write-Output 'page.tsx already patched' }
else {
  $nl = "`n"; if ($s.Contains("`r`n")) { $nl = "`r`n" }
  $imp = "import { PlantProfileCard } from '@/components/parties/plant-profile-card';"
  $anchor = '                <PartyApplicationPanel'
  if (-not $s.Contains($imp) -or -not $s.Contains($anchor)) { Write-Output 'ANCHOR NOT FOUND - page.tsx not changed' }
  else {
    $s = $s.Replace($imp, $imp + $nl + "import { CountryMarketPanel } from '@/components/parties/country-market-panel';")
    $block = @(
      '                {partyCountry &&',
      "                  (full.party.partyType === 'paper_mill' ||",
      "                    full.party.partyType === 'filler_supplier') && (",
      '                  <CountryMarketPanel partyId={full.party.id} country={partyCountry} />',
      '                )}'
    ) -join $nl
    $i = $s.IndexOf($anchor)
    $s = $s.Substring(0, $i) + $block + $nl + $s.Substring($i)
    [System.IO.File]::WriteAllText($p, $s, $utf8)
    Write-Output 'PATCHED page.tsx'
  }
}
# 3) sql + handoff
powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'tools\move-downloads.ps1')
cd $repo
git status -sb
git add sql/migration_20261015g_country_markets.sql src/components/parties/country-market-panel.tsx src/components/parties/country-market-panel-client.tsx "src/app/(app)/[partyType]/parties/[id]/page.tsx" docs/handoff
git commit -m "feat: country market overviews (app.country_markets) + Country market card on mill / filler pages"
git push origin marinebiogroup
```
