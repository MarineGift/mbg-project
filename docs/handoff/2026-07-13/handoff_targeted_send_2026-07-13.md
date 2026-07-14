# Handoff — Targeted Investor Send (2026-07-13)

## 타겟 정의 (확정)
- **섹터** (4): `deep_tech`, `advanced_materials`, `industrial`, `climate`
- **스테이지**: Series A 이상
- **제외 섹터**: `healthcare`, `life_science`, `consumer` → 다른 덱으로 발송 예정
- **Form-only/portal-only**: 이메일 발송에서 제외, 별도 수동 제출 목록으로 관리
- **중복 제외**: 이미 어떤 시퀀스든 active/completed면 제외 (재발송 방지)
- **예약**: 다음 화요일 09:00 미 서부시간

## 파일 (실행 순서)
1. **`20260713190000_climate_sequence_enroll_targeted.sql`** → `sql/`
   - Part 0(스키마 확인) → Part 1(미리보기) → Part 2(등록) → Part 3(검증)
   - **⚠️ Part 0을 반드시 먼저 실행.** 스테이지 코드 실제값을 확인해야 함.
     (가정한 코드: `series_a, series_b, series_c, growth, late_stage`.
      Part 0-a 결과가 다르면 Part 1·2의 `series_a_plus` CTE의 IN 리스트를 실제 코드로 수정 후 실행.)
2. **`20260713200000_form_only_investor_worklist.sql`** (읽기전용) → `sql/`
   - Form/portal-only 투자자를 같은 타겟 조건으로 뽑은 **수동 제출 체크리스트** (submit_url 포함)
   - 이메일이 아니라 웹폼/포털로 직접 지원해야 하는 곳. CSV로 export해서 작업 목록으로 사용.
   - 두 번째 쿼리는 스테이지 무관 카운트(스테이지 데이터가 희소할 때 참고).

## ⚠️ 실행 전 필수 확인 (스테이지 코드)
스테이지 코드 실제값을 repo에서 확정하지 못했습니다. Part 0-a를 먼저 돌려서:
- "Series A"에 해당하는 실제 code 확인 (예: `series_a` vs `a` vs `seriesA`)
- 결과에 맞게 4개 파일 위치의 IN 리스트 통일
스테이지 focus 데이터가 비어있거나 희소하면, Series A 필터가 너무 빡빡할 수 있음 → 그 경우 스테이지 필터를 빼고 섹터+중복제외만으로 보내는 것도 방법(Part 1 미리보기 카운트로 판단).

## Form-only 제외가 맞는지 확인
현재 form-only 판별 = `parties.preferred_contact_method IN ('web_form','portal','form')`.
repo seed(seed_form_only_investors.sql)에서 확인된 실제값은 `web_form`, `portal`. 정상.

## 파일 이동 (Downloads → repo `sql/`)
```powershell
$names = @(
  '20260713190000_climate_sequence_enroll_targeted',
  '20260713200000_form_only_investor_worklist'
)
$dl = Join-Path $env:USERPROFILE 'Downloads'
$destDir = 'C:\dev\mbg-project\sql'
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
foreach ($base in $names) {
  $src = Get-ChildItem -Path $dl -Filter "$base*.sql" -File |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Warning "No $base*.sql in $dl"; continue }
  Unblock-File -Path $src.FullName
  $dest = Join-Path $destDir "$base.sql"
  [System.IO.File]::Copy($src.FullName, $dest, $true)
  if ($src.FullName -ne $dest) { Remove-Item -LiteralPath $src.FullName -Force }
  Write-Host "Moved -> $dest"
}
```

## Finish (commit + push)
> push는 보관용. DB 반영은 Supabase SQL Editor 실행 필요.
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/20260713190000_climate_sequence_enroll_targeted.sql sql/20260713200000_form_only_investor_worklist.sql
git commit -m "sql: targeted investor enroll (4 sectors, Series A+, dedup) + form-only worklist"
git push origin marinebiogroup
```

## 다른 덱 대상 (참고, 이번 발송 아님)
healthcare / life_science / consumer 섹터 투자자는 별도 덱으로 발송 예정.
필요 시 그 세그먼트용 시퀀스도 동일 패턴으로 만들 수 있음.
```
```
