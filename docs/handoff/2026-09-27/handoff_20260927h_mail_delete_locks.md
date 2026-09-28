\xef\xbb\xbf# handoff_20260927h_mail_delete_locks

## 증상
배치 삭제(`repair_20260927c`, 1000건)도 `Failed to fetch (api.supabase.com)`.
리포 확인 결과 `app.communications` 트리거는 모두 AFTER INSERT → 삭제와 무관.
추정 원인: 처음 타임아웃된 삭제 쿼리가 서버에서 계속 실행 중이며 행 잠금을 잡고 있어 이후 실행이 모두 대기.

## 파일
| 파일 | 역할 |
|---|---|
| `diag_20260927d_mail_delete_locks.sql` | 읽기 전용: 실행 중 세션, 블로킹, 인덱스 존재 여부, 트리거 |
| `fix_20260927d_cancel_stuck_mail_delete.sql` | 30초 넘게 실행 중인 communications/attachments/ai.drafts 쿼리 종료 (전체 롤백) |

## 실행
1. diag → `1_session` 에 오래 실행 중인 delete 가 보이는지, `2_index` 에 인덱스 7개가 있는지 확인
2. 오래된 delete 가 있으면 cancel 실행
3. 인덱스가 없으면 `fix_20260927c_mail_delete_indexes.sql` 먼저 실행
4. `repair_20260927c_delete_mail_before_2026_batch.sql` 다시 실행 (0 될 때까지 반복)

## 이동 (inline fallback)
```powershell
$Repo='C:\dev\mbg-project'; $Dl=Join-Path $env:USERPROFILE 'Downloads'
$map=@{'diag_20260927d_mail_delete_locks.sql'='sql';'fix_20260927d_cancel_stuck_mail_delete.sql'='sql';'handoff_20260927h_mail_delete_locks.md'=('docs\handoff\'+(Get-Date -Format 'yyyy-MM-dd'))}
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
git add sql/diag_20260927d_mail_delete_locks.sql sql/fix_20260927d_cancel_stuck_mail_delete.sql docs/handoff
git commit -m "sql: diag + cancel stuck mail delete sessions"
git push origin marinebiogroup
```
