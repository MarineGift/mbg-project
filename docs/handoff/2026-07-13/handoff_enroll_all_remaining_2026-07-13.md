# Handoff — Send to ALL remaining investors (2026-07-13)

## 핵심 결론 먼저
업로드한 CSV(__67__)의 **70개 firm은 전부 email=null** = 발송 불가 명단입니다.
Breakthrough Energy, Amazon Climate Pledge, Bezos Earth Fund, DCVC 등 최상위 기후 펀드가 여기 묶여 있는데, **이메일이 없어서** 지금은 못 보냅니다. 보내려면 이메일 백필이 먼저입니다(대부분 info@ / contact@ 형태라 웹사이트에서 확보 가능).

## 파일
1. **`20260713170000_investor_send_audit.sql`** (READ-ONLY) → repo `sql/`
   - 지금 DB 기준 "보낼 수 있는 곳"을 정확히 조회. 4개 블록:
     - 0) 전체 요약 (총 투자자 / 이메일 있음 / 없음 / 이미 등록 / 미발송)
     - 1) **REACHABLE-BUT-NOT-YET-SENT** = 이메일 있고 아직 아무 시퀀스에도 없는 투자자 (= 이번에 보낼 대상)
     - 2) MISSING EMAIL = 이메일 없어 못 보내는 투자자 (백필 대상, website 포함)
     - 3) ALREADY ENROLLED = 이미 등록된 사람 + 어느 시퀀스인지
2. **`20260713180000_climate_sequence_enroll_all_remaining.sql`** → repo `sql/`
   - **섹터 무관**, 이메일 있는 미등록 투자자 **전원**을 climate 시퀀스에 등록 + 화요일 9시 PT 예약
   - 중복 가드: 이 시퀀스에 이미 있거나 다른 시퀀스에 active면 자동 제외
   - Part 0(미리보기) → 카운트 확인 → Part 1 실행

## 실행 순서 (권장)
1. `..._investor_send_audit.sql` 블록 0·1 실행 → **발송 가능 대상 수** 확인
2. `..._enroll_all_remaining.sql` Part 0 실행 → 같은 명단인지 확인
3. 이상 없으면 Part 1 실행 → 전원 등록
4. Part 2로 최종 로스터 확인

## ⚠️ 발송량 주의
전원 등록 시 **다음 화요일 9시에 대량 동시 발송**됩니다. 현재 이미 41명 예약 + 신규 N명. 발신 계정의 시간당 SMTP 한도를 확인하세요. 새 계정(워밍업 전)이면 한 번에 다 보내지 말고 나눠 보내는 게 안전합니다. 필요하면 next_send_at을 여러 화요일로 분산하는 SQL을 만들어 드립니다.

## 파일 이동 (Downloads → repo `sql/`)
```powershell
$names = @(
  '20260713170000_investor_send_audit',
  '20260713180000_climate_sequence_enroll_all_remaining'
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

## Finish (commit + push = 웹 자동 배포)
> push는 보관용. DB 반영은 Supabase SQL Editor 실행 필요.
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/20260713170000_investor_send_audit.sql sql/20260713180000_climate_sequence_enroll_all_remaining.sql
git commit -m "sql: investor send audit + enroll all remaining (email-having) investors, Tue 9am PT"
git push origin marinebiogroup
```

## 다음 후보 작업
- **이메일 백필**: CSV __67__의 70개 무이메일 firm 중 최상위 기후 펀드부터 info@/contact@ 확보 → `UPDATE app.parties SET email=...` 배치. 원하면 템플릿 제공.
- **겹치는 빈 시퀀스 archive**: "Investor Cold Outreach - FCC Climate Tech" (0 active) 정리.
