# HANDOFF — Inbox: 투자자 후속 메일(캘린더 초대 등) Mentors → Investors (2026-09-21 b)

## 문제
Mitchell Hauser의 `Invitation: Intro Meeting | MarineBio Group <> Strategic Ventures @ …` 가 Mentors로 표시됨. 웜인트로 제목이 아니고 Greentown 언급도 없어 1차 규칙(A–C)에 걸리지 않았고, 발신 주소가 멘토 contact라 mentor party에 연결됨.

## 추가 규칙 (`investor-intro.ts`, 미연결·mentor 연결·비자동 메일만)
- **D** 제목에 `MarineBio Group <> Firm` / `Firm <> MBG` 형태로 회사명이 있고, 그 이름의 investor party가 정확히 1개 → Investors + 해당 party로 재연결.
- **E** 같은 발신 주소의 이전 메일이 이미 Investors로 분류됨 → 이후 메일(초대, 후속)도 Investors, 그 투자사 party로 재연결.
- mailcarrier `investor_intro.reason`에 `subject_firm` / `prior_intro_sender` 기록.

## 기존 메일
`sql/backfill_20260921b_investor_followups.sql` — 1차 백필(A–C) 포함 상위집합. 이것만 Ctrl+A → Run. 멱등.

## 참고
- contact 자체(멘토 party 소속)는 옮기지 않음. 멘토이면서 투자자인 사람이 있을 수 있으므로 메일만 투자사로 연결.

## Inline mover
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = [ordered]@{
  'investor-intro.ts'      = 'src\lib\email\investor-intro.ts'
  'investor-intro.test.ts' = 'src\__tests__\email\investor-intro.test.ts'
  'mailcarrier.ts'         = 'src\lib\email\mailcarrier.ts'
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
