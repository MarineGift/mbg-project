\xef\xbb\xbf# Handoff 2026-10-15 (i) — 제지사·충전제사 화면 Market 탭

> 앞 문서: `handoff_20261015h_syria_mills_fillers.md`

## 1. 파일
| 파일 | 위치 | 내용 |
|---|---|---|
| `migration_20261015i_country_markets_ko_fcc.sql` | `sql/` | `country_markets` 에 한국어 헤드라인·보고서 기준 FCC 예상 물량 컬럼 추가 + 35개국 값 |
| `country-market-tab.tsx` | `src/components/parties/` | Market 탭 (한국어 UI) |
| `party-detail-tabs.tsx` | `src/components/parties/` | Market 탭 추가 (Overview 다음) |
| `page.tsx` | `src/app/(app)/[partyType]/parties/[id]/` | Market 탭 연결, Overview 의 Country market 카드 제거 |

## 2. Market 탭 내용
1. **핵심 지표** (URM 데이터로 실시간 계산)
   - 제지사 수 · 우선순위 지정 수
   - 충전제 제조사 수
   - 확인된 제지 생산능력 합계 (Mill profile 에 생산능력이 입력된 밀)
   - FCC 예상 물량 — 밀 카드 Base 시나리오 합계 + 로열티 ($15/t)
   - FCC 예상 공급 물량 — 보고서 기준 범위 + 근거 (`fcc_potential_*`)
   - 국가 key numbers
2. 시장 요약 · 충전제 현황 · 제지사 현황 · 접근 전략 · 리스크 · 다음 단계
3. **제지사 표**: 우선순위, 회사(링크), 지역, 지종, 생산능력, FCC Base t/년, 로열티
4. **충전제 제조사 표**: 회사(링크), 지역, 유형, 광물, 시장 역할
- 다른 회사 링크는 `?tab=market` 로 열려 국가 간 비교가 쉬움
- 요약·섹션은 `summary_ko` / `sections_ko` 가 있으면 한국어, 없으면 영어 표시 (현재 헤드라인만 한국어)

## 3. 테이블 변경 (`app.country_markets`)
- 추가 컬럼: `headline_ko`, `summary_ko`, `sections_ko` jsonb, `fcc_potential_low_t`, `fcc_potential_high_t`, `fcc_potential_basis_ko`
- 제지사·충전제 수, 생산능력, 시나리오 물량은 저장하지 않음 — 매번 `app.parties` + 프로필에서 계산 (새 회사 추가 시 자동 반영)
- 마지막에 `notify pgrst, 'reload schema'` 포함

## 4. 적용 순서
1. Supabase: migration 실행 (Ctrl+A → Run) → 결과 확인
2. 4개 파일 다운로드 → 아래 PowerShell
3. 제지사 화면 → **Market** 탭 확인

```powershell
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @{
  'country-market-tab.tsx' = 'src\components\parties\country-market-tab.tsx'
  'party-detail-tabs.tsx'  = 'src\components\parties\party-detail-tabs.tsx'
  'page.tsx'               = 'src\app\(app)\[partyType]\parties\[id]\page.tsx'
}
foreach ($n in $map.Keys) {
  $rx = '^' + [regex]::Escape([System.IO.Path]::GetFileNameWithoutExtension($n)) + '( \(\d+\))?\.tsx$'
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
git add sql/migration_20261015i_country_markets_ko_fcc.sql src/components/parties/country-market-tab.tsx src/components/parties/party-detail-tabs.tsx "src/app/(app)/[partyType]/parties/[id]/page.tsx" docs/handoff
git commit -m "feat: Market tab on mill / filler pages (counts, capacity, FCC volumes, linked mills and fillers)"
git push origin marinebiogroup
```
