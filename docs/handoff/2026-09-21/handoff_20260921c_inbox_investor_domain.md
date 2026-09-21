# HANDOFF — Inbox: 발신 도메인으로 투자사 분류 (규칙 F) (2026-09-21 c)

## 문제
George Irven <girven@apventures.com> "APV <> Marinebio intro" (Teams 초대)가 미분류. 제목 약칭 APV ≠ party 이름 AP Ventures, Greentown 언급 없음, contact 미등록.

## 변경
- `investor-intro.ts` 규칙 **F**: 발신 도메인이 investor party의 website(또는 email) 도메인과 일치하는 party가 **정확히 1개** → Investors + 그 party로 재연결. 서브도메인 허용(mail.x.com → x.com), 웹메일(gmail 등) 제외, 미연결·mentor 메일만.
- A–C로 태그됐지만 회사명을 못 찾은 메일(예: josh@helioscv.com)도 도메인으로 재연결 시도.
- 테스트 7개 통과.

## 백필
`sql/backfill_20260921c_investor_sender_domain.sql` (단일 문장, RETURNING).
0행이면 AP Ventures party의 website가 비어 있는 것 → website에 apventures.com 입력 후 재실행.

## 이번 세션 DB 상태
- Run1 태그 27건, Run2 초대메일 → Strategic Ventures, Run3 mixmax 뉴스레터 태그 제거 + 5건 회사 재연결 (Strategic Ventures, Foley & Lardner LLP, MIH Capital ×2, Safer Made).

## Inline mover
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = [ordered]@{
  'investor-intro.ts'      = 'src\lib\email\investor-intro.ts'
  'investor-intro.test.ts' = 'src\__tests__\email\investor-intro.test.ts'
}
foreach ($name in $map.Keys) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
  $ext  = [System.IO.Path]::GetExtension($name)
  $hits = @(Get-ChildItem -LiteralPath $Dl -File | Where-Object { $_.Name -eq $name -or $_.Name -match ('^' + [regex]::Escape($base) + ' \(\d+\)' + [regex]::Escape($ext) + '$') } | Sort-Object LastWriteTime -Descending)
  if ($hits.Count -eq 0) { Write-Output ('MISS  ' + $name); continue }
  $dest = Join-Path $Repo $map[$name]
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($dest)) | Out-Null
  Unblock-File -LiteralPath $hits[0].FullName -ErrorAction SilentlyContinue
  [System.IO.File]::Copy($hits[0].FullName, $dest, $true)
  $hits | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
  Write-Output ('MOVED ' + $hits[0].Name + ' -> ' + $map[$name])
}
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
