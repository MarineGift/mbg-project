# HANDOFF — 발신 도메인 규칙 F 오분류 복구 + 가드 (2026-09-21 d)

## 사고
`backfill_20260921c` 실행 시 플랫폼 메일 ~130건이 investor party로 잘못 연결됨:
LinkedIn 알림 → Stuart Levinson(website가 LinkedIn 프로필), Microsoft/Azure → Microsoft Climate Innovation Fund(microsoft.com), Samsung 계정 → Samsung Ventures(samsung.com), Activate 뉴스레터 → Activate.
원인: `messages-noreply@` 처럼 noreply가 중간에 붙은 주소를 자동발송으로 못 걸렀고, 과거 메일은 List-Unsubscribe 헤더가 저장돼 있지 않았으며, 플랫폼/대기업 도메인 차단이 없었음.
정상 연결: George Irven → AP Ventures, Josh Grehan → Helios Climate Ventures, Neal Dikeman → Energy Transition Ventures (유지).

## 복구
`sql/repair_20260921_revert_sender_domain.sql` — 위 3개 도메인 외 전부 party_id/태그 원복 (원래 미연결 메일).

## 규칙 F 가드 (코드, 이미 배포된 F를 대체)
1. 플랫폼/대기업 호스트 차단: linkedin, microsoft, samsung, google, apple, amazon, facebook, x, crunchbase 등 (서브도메인 포함) — 발신 쪽과 party website 쪽 모두.
2. 역할 주소 차단: local part 어디든 noreply/info/notifications/invitations/security/account/jobs/messages/groups 등.
3. 대화성 요구: 답장(In-Reply-To)이거나 제목·새 본문에 MarineBio/MBG/FCC 언급 (주소·URL 제거 후).
테스트 9개 통과.

## 교훈
party.website가 LinkedIn 프로필이나 모회사 도메인인 investor가 있다 — 도메인 기반 매칭은 반드시 플랫폼 차단 + 사람 발신자 + 대화성 조건과 함께.

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
