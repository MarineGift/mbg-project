# Handoff — Climate Sequence: Tuesday 9am PT + Expand (2026-07-13)

## 배경
- "Climate Investor Cold Outreach -- FCC" 시퀀스는 이미 생성됨 (28 active, 13 sent).
- UI "Update Sequence"의 FK 에러(`email_sequence_sends_step_id_fkey`)는 **스텝을 삭제→재삽입**하려 해서 발생. 이미 발송기록이 스텝을 참조 중이라 삭제가 막힌 것. **아래 SQL은 스텝을 지우지 않고 제자리 UPDATE**만 하므로 이 에러가 나지 않음.

## 파일 (실행 순서대로)
1. **`20260713150000_climate_sequence_tuesday_9am_pt.sql`** → repo `sql/`
   - 스텝 offset을 주간(0/7/14/21)으로 in-place UPDATE
   - `quiet_hours` = 화요일 09:00 America/Los_Angeles 창 + 주말 차단
   - **아직 발송 안 된** 모든 enrollment의 `next_send_at`을 다음 화요일 09:00 PT(UTC 환산, DST 자동 처리)로 이동
2. **`20260713160000_climate_sequence_enroll_more.sql`** → repo `sql/`
   - 다른 투자자 세그먼트를 같은 시퀀스에 추가 등록 + 화요일 9시 PT 예약
   - **중복발송 방지**: 이미 이 시퀀스에 있거나, **다른 시퀀스에 active인** 투자자는 자동 제외
   - Part 0(미리보기) 먼저 실행 → 대상 확인 후 Part 1 실행

## ⚠️ 실행 전 필독
- 두 파일 모두 **Part 0 / Part 1(INSPECT)** 를 먼저 실행해 눈으로 확인한 뒤 UPDATE/INSERT 부분을 실행할 것. 발송이 이미 나간 시퀀스라 신중히.
- **enroll_more.sql은 타겟 세그먼트를 골라야 함** (파일 안 주석):
  - Option A(기본): `energy` + `industrial` 섹터
  - Option B: `advanced_materials` + `deep_tech`
  - Option C: 섹터 필터 제거 = 이메일 있는 전체 투자자
  - Part 0와 Part 1의 필터를 **동일하게** 맞출 것.
- 실행 위치: Supabase SQL Editor (DB 즉시 반영). git push는 파일 보관용이며 SQL을 실행하지 않음.

## 이메일 없는 투자자 (별건)
업로드된 CSV(69개 firm)는 전부 email=null → 등록 대상에서 자동 제외됨. 이들에게 보내려면 먼저 email 백필 필요. 원하면 백필 템플릿 만들어줄 수 있음.

## 파일 이동 (Downloads → repo `sql/`) — 그대로 붙여넣기
```powershell
$names = @(
  '20260713150000_climate_sequence_tuesday_9am_pt',
  '20260713160000_climate_sequence_enroll_more'
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
> push는 파일 보관/배포용. DB 반영은 Supabase SQL Editor 실행이 필요.
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/20260713150000_climate_sequence_tuesday_9am_pt.sql sql/20260713160000_climate_sequence_enroll_more.sql
git commit -m "sql: reschedule climate sequence to Tue 9am PT (weekly) + guarded enroll expansion"
git push origin marinebiogroup
```

## 겹치는 시퀀스 정리 필요 (확인 요망)
현재 시퀀스 목록에 기후 관련이 2개 보임:
- "Climate Investor Cold Outreach -- FCC" (신규, 사용 중)
- "Investor Cold Outreach - FCC Climate Tech" (0 active / 0 sent)
후자를 안 쓸 거면 archive 권장(같은 투자자 중복등록 방지). enroll_more.sql의 "다른 시퀀스 active 제외" 가드가 있어 자동 충돌은 막지만, 목록 정리는 별개.
