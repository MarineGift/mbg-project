\xef\xbb\xbf# handoff_20260927f_delete_mail_before_2026

## 이전 실행 결과 (repair_20260927)
- 2024년 이전 메일 **377건 삭제 완료** (inbound, 2020-05-20 ~ 2023-12-28), 첨부 240행
- 남은 메일 6,076건 (가장 오래된 메일: 2024-01-04)
- 확인된 실제 FK: `ai.drafts.inbound_communication_id`, `ai.drafts.sent_communication_id` (NO ACTION). 이번 파일에서 함께 처리

## 이번 작업
`occurred_at < 2026-01-01 00:00 UTC` 인 이메일을 전부 하드 삭제합니다. 대상은 2024년과 2025년 메일입니다.

## 파일
| 파일 | 위치 |
|---|---|
| `diag_20260927b_mail_before_2026.sql` | `sql\` (읽기 전용, 연도별 건수) |
| `repair_20260927b_delete_mail_before_2026.sql` | `sql\` (삭제, 한 트랜잭션) |

## 실행
1. diag → Ctrl+A → Run → 섹션 1_year 의 2024 / 2025 건수 확인
2. repair → Ctrl+A → Run → `email before 2026 (expect 0)` = 0

## 주의
- ai.drafts 행은 남기고 메일 참조만 NULL 처리
- Storage 첨부 파일은 SQL로 삭제 불가 → 고아 파일로 남음
- IMAP 서버 미변경, 재수집 없음 (last_uid). 코드 변경 없음

## 이동 (inline fallback)
```powershell
$Repo='C:\dev\mbg-project'; $Dl=Join-Path $env:USERPROFILE 'Downloads'
$map=@{'diag_20260927b_mail_before_2026.sql'='sql';'repair_20260927b_delete_mail_before_2026.sql'='sql';'handoff_20260927f_delete_mail_before_2026.md'=('docs\handoff\'+(Get-Date -Format 'yyyy-MM-dd'))}
foreach($k in $map.Keys){
  $base=[IO.Path]::GetFileNameWithoutExtension($k); $ext=[IO.Path]::GetExtension($k)
  $f=Get-ChildItem -Path $Dl -File -Filter ($base+'*'+$ext) -EA SilentlyContinue | Sort-Object LastWriteTime -Desc
  if(-not $f){Write-Output ('MISSING '+$k); continue}
  $d=Join-Path $Repo $map[$k]; [IO.Directory]::CreateDirectory($d)|Out-Null
  Unblock-File $f[0].FullName -EA SilentlyContinue
  [IO.File]::Copy($f[0].FullName,(Join-Path $d $k),$true)
  $f | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
  Write-Output ('MOVED '+$k)
}
```

## Push
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/diag_20260927b_mail_before_2026.sql sql/repair_20260927b_delete_mail_before_2026.sql docs/handoff
git commit -m "sql: delete email before 2026 (diag + repair)"
git push origin marinebiogroup
```
