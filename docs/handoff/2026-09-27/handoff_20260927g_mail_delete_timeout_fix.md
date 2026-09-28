\xef\xbb\xbf# handoff_20260927g_mail_delete_timeout_fix

## 증상
`repair_20260927b_delete_mail_before_2026.sql` 실행 시 `Error: Failed to fetch (api.supabase.com)` — 대시보드 요청 타임아웃.
원인 추정: 메일 행 삭제마다 참조 FK 컬럼(ai.drafts 등)을 검사하는데 인덱스가 없어 매번 전체 스캔.

## 파일
| 파일 | 위치 | 역할 |
|---|---|---|
| `fix_20260927c_mail_delete_indexes.sql` | `sql\` | FK 컬럼 인덱스 추가 + 현재 상태 확인 |
| `repair_20260927c_delete_mail_before_2026_batch.sql` | `sql\` | 1회 최대 1000건 삭제, 0 될 때까지 반복 |

## 실행
1. fix 실행 → `email before 2026 still present` 확인 (0이면 이전 삭제가 이미 커밋된 것, 종료)
2. 0이 아니면 batch 파일 반복 실행 → `remaining (run again if > 0)` = 0 까지
3. fix 파일이 멈추면 이전 삭제가 아직 실행 중 → 몇 분 뒤 재실행

## 이동 (inline fallback)
```powershell
$Repo='C:\dev\mbg-project'; $Dl=Join-Path $env:USERPROFILE 'Downloads'
$map=@{'fix_20260927c_mail_delete_indexes.sql'='sql';'repair_20260927c_delete_mail_before_2026_batch.sql'='sql';'handoff_20260927g_mail_delete_timeout_fix.md'=('docs\handoff\'+(Get-Date -Format 'yyyy-MM-dd'))}
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
git add sql/fix_20260927c_mail_delete_indexes.sql sql/repair_20260927c_delete_mail_before_2026_batch.sql docs/handoff
git commit -m "sql: FK indexes + batched delete for email before 2026"
git push origin marinebiogroup
```
