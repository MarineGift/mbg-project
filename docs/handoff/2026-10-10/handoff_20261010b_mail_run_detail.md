\xef\xbb\xbf# Handoff 2026-10-10b — Mail run detail (Recent runs 클릭 → 수신자 상세)

## 변경
1. NEW `src/lib/actions/mail-run-detail.ts` — `getMailRunDetail(runId)`: run 정보(템플릿·제목·From·옵션·생성/예약/시작/완료 시각) + `mail_run_recipients` 전체(1000행 페이지네이션) + 회사명·party type
2. NEW `src/components/mailing/mail-run-detail-dialog.tsx` — 상세 다이얼로그: 상태 필터(all/sent/failed/blocked/pending), 검색, 회사 링크(`/{type}/parties/{id}`), 보낸 메일 링크(`/inbox/{communication_id}`), CSV 내보내기, 진행 중 run 은 5초 자동 갱신. 실패/차단 행이 위로 정렬
3. `src/app/(app)/marketing/marketing-client.tsx` — Recent runs 행 클릭 → 다이얼로그
4. `src/app/(app)/mailing/bulk-mail-client.tsx` — Mailing 화면 run 목록도 클릭 → 같은 다이얼로그 (inline patch)
- DB 변경 없음. tsc 오류 12건 = 기존 그대로

## Mover (inline)
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ n='mail-run-detail-action'; e='.ts';  d='src\lib\actions';         t='mail-run-detail.ts' },
  @{ n='mail-run-detail-dialog'; e='.tsx'; d='src\components\mailing';  t='mail-run-detail-dialog.tsx' },
  @{ n='marketing-client';       e='.tsx'; d='src\app\(app)\marketing'; t='marketing-client.tsx' }
)
foreach ($m in $map) {
  $hits = Get-ChildItem -LiteralPath $Dl -File | Where-Object { $_.Name -like ($m.n + '*' + $m.e) } | Sort-Object LastWriteTime -Descending
  if (-not $hits) { Write-Output ('MISS  ' + $m.n + $m.e); continue }
  $src = $hits[0]
  Unblock-File -LiteralPath $src.FullName -ErrorAction SilentlyContinue
  $destDir = Join-Path $Repo $m.d
  [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
  $dest = Join-Path $destDir $m.t
  [System.IO.File]::Copy($src.FullName, $dest, $true)
  $hits | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
  Write-Output ('MOVED ' + $src.Name + ' -> ' + $dest)
}
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

## Mailing patch (inline)
```powershell
$f = 'C:\dev\mbg-project\src\app\(app)\mailing\bulk-mail-client.tsx'
$n = [string][char]10
$s = [System.IO.File]::ReadAllText($f).Replace([string][char]13 + $n, $n)
if ($s.Contains('MailRunDetailDialog')) { Write-Output 'SKIP  bulk-mail-client already patched' } else {
  $ok = $true
  $pairs = New-Object System.Collections.ArrayList
  [void]$pairs.Add(@(('import { fetchPartyTypeMaps } from ''@/lib/party-type-maps'';' + $n + ''), ('import { fetchPartyTypeMaps } from ''@/lib/party-type-maps'';' + $n + 'import { MailRunDetailDialog } from ''@/components/mailing/mail-run-detail-dialog'';' + $n + '')))
  [void]$pairs.Add(@(('  const [runs, setRuns] = useState<MailRunStatus[]>([]);' + $n + ''), ('  const [runs, setRuns] = useState<MailRunStatus[]>([]);' + $n + '  const [detailRunId, setDetailRunId] = useState<string | null>(null);' + $n + '')))
  [void]$pairs.Add(@(('                <div key={r.id} className="space-y-1.5">'), ('                <div key={r.id} className="space-y-1.5 cursor-pointer rounded-md p-1 hover:bg-muted/50" onClick={() => setDetailRunId(r.id)} title="Show recipients">')))
  [void]$pairs.Add(@(('      </Dialog>' + $n + '    </div>' + $n + '  );' + $n + '}' + $n + ''), ('      </Dialog>' + $n + '      <MailRunDetailDialog runId={detailRunId} onOpenChange={(o) => { if (!o) setDetailRunId(null); }} />' + $n + '    </div>' + $n + '  );' + $n + '}' + $n + '')))
  foreach ($p in $pairs) { if (-not $s.Contains($p[0])) { $ok = $false; Write-Output ('ERROR anchor not found: ' + $p[0].Substring(0, [Math]::Min(50, $p[0].Length))) } }
  if ($ok) {
    $last = $pairs[3]
    $i = $s.LastIndexOf($last[0])
    $s = $s.Substring(0, $i) + $last[1] + $s.Substring($i + $last[0].Length)
    for ($k = 0; $k -lt 3; $k++) { $s = $s.Replace($pairs[$k][0], $pairs[$k][1]) }
    [System.IO.File]::WriteAllText($f, $s, (New-Object System.Text.UTF8Encoding($false)))
    Write-Output 'PATCHED bulk-mail-client.tsx'
  }
}

```

## Push
```powershell
cd C:\dev\mbg-project
git status -sb
git add src/lib/actions/mail-run-detail.ts src/components/mailing/mail-run-detail-dialog.tsx "src/app/(app)/marketing/marketing-client.tsx" "src/app/(app)/mailing/bulk-mail-client.tsx" docs/handoff
git commit -m "mailing: run detail dialog (recipients, status filter, CSV)"
git push origin marinebiogroup
```
