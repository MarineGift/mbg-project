\xef\xbb\xbf# handoff_20260927e_delete_mail_before_2024

## 목적
`app.communications` 에서 **2024-01-01 00:00 UTC 이전 이메일(channel = email)** 을 전부 **하드 삭제** (활성 + 소프트삭제 행 모두).

## 파일
| 파일 | 위치 | 성격 |
|---|---|---|
| `diag_20260927_mail_before_2024.sql` | `sql\` | 읽기 전용 미리보기 (1개 statement) |
| `repair_20260927_delete_mail_before_2024.sql` | `sql\` | 실제 삭제 (한 트랜잭션) |

## 스키마 근거 (리포에서 확인)
- 날짜 기준: `occurred_at` (NOT NULL), 채널: `channel = 'email'`
- 자식 참조: `email_sequence_sends.communication_id`, `consultations.source_communication_id`, `engagement_email_details.source_communication_id` (FK, 모두 nullable → NULL 처리), `email_tracking.communication_id` (FK 없음 → NULL 처리)
- 첨부: `app.attachments` 는 다형(`entity_type='communication'`, `entity_id`) → 행 삭제
- 앱의 기존 삭제 액션은 soft-delete(`deleted_at`) — 이번 작업은 요청대로 hard delete

## 실행 순서
1. `diag_...sql` → Ctrl+A → Run. 섹션 6(fk)에 위 4개 외 FK가 있으면 실행 전 확인
2. `repair_...sql` → Ctrl+A → Run. 결과: `email before 2024 (expect 0)` = 0
3. FK가 막으면 전체 롤백되어 아무것도 바뀌지 않음 (안전)

## 주의
- Storage 버킷의 첨부 **파일 자체**는 SQL로 삭제 불가 (Storage API 전용) → 고아 파일로 남음
- IMAP 서버 메일은 건드리지 않음. MailCarrier는 `last_uid` 이후만 가져오므로 재수집 없음
- Supabase Pro 일일 백업 있음. 코드 변경 없음 → Railway 재배포 불필요 (push는 기록용)

## 이동 (inline fallback)
```powershell
$Repo='C:\dev\mbg-project'; $Dl=Join-Path $env:USERPROFILE 'Downloads'
$map=@{'diag_20260927_mail_before_2024.sql'='sql';'repair_20260927_delete_mail_before_2024.sql'='sql';'handoff_20260927e_delete_mail_before_2024.md'=('docs\handoff\'+(Get-Date -Format 'yyyy-MM-dd'))}
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
git add sql/diag_20260927_mail_before_2024.sql sql/repair_20260927_delete_mail_before_2024.sql docs/handoff
git commit -m "sql: delete email before 2024 (diag + repair)"
git push origin marinebiogroup
```
