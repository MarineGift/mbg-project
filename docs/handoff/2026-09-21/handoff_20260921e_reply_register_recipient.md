\xef\xbb\xbf# Handoff 2026-09-21e — 회신 시 미등록 수신자 등록 확인창 (Whitelist + Investors contacts)

## 문제
Inbox 상세에서 Reply → Send 시 수신자(예: mret@svrglobal.com)가 `app.email_whitelist`에 없으면
`send-outbound.ts` 게이트가 `not_whitelisted`로 차단. 기존엔 `window.confirm`으로 whitelist만 추가.

## 변경
1. **NEW** `src/lib/actions/register-recipient.ts`
   - `previewRecipientRegistration()` : 어느 party에 붙을지 미리 계산(확인창 문구용, 읽기 전용)
   - `registerRecipientAsInvestor()` : party 결정 → contact 생성/연결 + whitelist(address) 추가
   - Party 결정 순서: ① 동일 email contact의 party ② 다이얼로그 party(hint) ③ 같은 도메인 contact를 가진 **investor** party
     ④ website에 도메인을 포함한 **investor** party ⑤ 없으면 investor party 신규 생성(이름=도메인, website=https://도메인)
   - 도메인 매칭은 investor 타입으로만 제한 (paper mill / filler supplier는 한 도메인에 여러 party가 정상)
   - 기존 contact는 다른 party로 이동하지 않음
2. `src/components/email/compose-email-dialog.tsx`
   - `window.confirm` 제거 → 다이얼로그 내부 오버레이 확인창 (**OK** = 등록 + 발송 / **Decline** = 발송 취소)
   - Reply all에서 미등록 주소가 여러 개면 하나씩 확인 (최대 10회 가드)
   - party 없는 회신(수동 경로)에서 등록 후 재발송 시 새 party/contact에 메일 연결
   - 수동 경로 blockedRecipient를 에러 메시지에서 추출 (기존: 항상 To[0])
3. `src/components/inbox/communication-detail-view.tsx`
   - `contactName={replyTarget.fromName}` 전달 → 새 contact의 full_name으로 사용

## 검증
- `npx tsc --noEmit` : 변경 파일 오류 0 (기존 12개 그대로)
- DB 변경 없음 (SQL 불필요)

## 수동 테스트
1. 미등록 발신자 메일 → Reply → Send → 확인창 표시
2. OK → toast "registered (...)" → 발송 → Investors 디렉토리에 party/contact 확인, Settings > Email whitelist에 주소 확인
3. Decline → "Send cancelled." / 발송 안 됨
4. 자동 생성된 investor party 이름(도메인)은 필요 시 수정

## Mover (inline, PowerShell 붙여넣기)
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ n='register-recipient';        e='.ts';  d='src\lib\actions' },
  @{ n='compose-email-dialog';      e='.tsx'; d='src\components\email' },
  @{ n='communication-detail-view'; e='.tsx'; d='src\components\inbox' }
)
foreach ($m in $map) {
  $hits = Get-ChildItem -LiteralPath $Dl -File | Where-Object { $_.Name -like ($m.n + '*' + $m.e) } | Sort-Object LastWriteTime -Descending
  if (-not $hits) { Write-Output ('MISS  ' + $m.n + $m.e); continue }
  $src = $hits[0]
  Unblock-File -LiteralPath $src.FullName -ErrorAction SilentlyContinue
  $destDir = Join-Path $Repo $m.d
  [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
  $dest = Join-Path $destDir ($m.n + $m.e)
  [System.IO.File]::Copy($src.FullName, $dest, $true)
  $hits | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
  Write-Output ('MOVED ' + $src.Name + ' -> ' + $dest)
}
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

## Push
```powershell
cd C:\dev\mbg-project
git status -sb
git add src/lib/actions/register-recipient.ts src/components/email/compose-email-dialog.tsx src/components/inbox/communication-detail-view.tsx docs/handoff
git commit -m "reply: confirm + register unknown recipient (whitelist + investor contact) then send"
git push origin marinebiogroup
```
