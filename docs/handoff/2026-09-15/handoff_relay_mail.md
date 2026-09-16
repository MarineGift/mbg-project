# Handoff — 멀티 도메인 SMTP 릴레이 (Railway / URM 서비스)

## 목적

Supabase Edge Functions는 아웃바운드 25/587 포트가 차단되어 MailCarrier로 직접 SMTP 발송이 불가능하다.
Railway에는 이 제약이 없으므로, 기존 URM 서비스에 릴레이 라우트를 추가해 외부 사이트가 HTTPS로 호출하도록 한다.

```
Supabase Edge Function --HTTPS--> urm.marinebiogroup.com/api/relay/mail --SMTP:587--> mail.<domain>
```

새 Railway 서비스나 새 커스텀 도메인은 필요 없다. 기존 서비스에 라우트만 추가한다.

## 배치 파일

| 다운로드 파일명 | 저장 경로 |
|---|---|
| `relay_mail_route.ts` | `src\app\api\relay\mail\route.ts` |

## 인라인 이동 스크립트 (복사해서 PowerShell에 붙여넣기)

```powershell
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'

$src = Get-ChildItem -Path $dl -Filter 'relay_mail_route*.ts' -File |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Host '[FAIL] relay_mail_route.ts not found in Downloads'; exit 1 }

Unblock-File -Path $src.FullName

$destDir = Join-Path $repo 'src\app\api\relay\mail'
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
$dest = Join-Path $destDir 'route.ts'

[System.IO.File]::Copy($src.FullName, $dest, $true)
Remove-Item -LiteralPath $src.FullName -Force

Write-Host "[OK] moved -> $dest"
```

## Railway 환경 변수

Railway 대시보드 > 기존 URM 서비스 > Variables 에 추가한다.

```
MAIL_RELAY_TOKEN=<openssl rand -hex 32 로 생성한 값>
MAIL_RELAY_PROFILES={"koreancoaching":{"host":"mail.koreancoaching.com","port":587,"useTls":false,"user":"hello@koreancoaching.com","pass":"********","fromName":"Korean Coaching"}}
```

도메인이 늘어나면 JSON에 키를 추가하기만 하면 된다. 코드 수정은 필요 없다.

MailCarrier에 Let's Encrypt 인증서를 등록한 뒤에는 해당 프로필의 `useTls`를 `true`로 바꾼다.
포트는 587 그대로 두면 되고, 트랜스포터가 STARTTLS로 협상한다.

## Supabase Edge Function 호출 예시

`supabase/functions/_shared/mailer.ts` 를 만들고 6개 함수가 이것만 import 하도록 정리한다.

```ts
export async function sendMail(opts: {
  to: string | string[];
  subject: string;
  html?: string;
  text?: string;
  replyTo?: string;
}) {
  const res = await fetch('https://urm.marinebiogroup.com/api/relay/mail', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-relay-token': Deno.env.get('MAIL_RELAY_TOKEN')!,
    },
    body: JSON.stringify({ profile: 'koreancoaching', ...opts }),
  });
  const data = await res.json();
  if (!data.ok) throw new Error(`relay failed: ${data.error}`);
  return data.messageId as string;
}
```

```bash
supabase secrets set MAIL_RELAY_TOKEN=<Railway와 동일한 값>
```

## 검증

배포 후 아래로 확인한다.

```powershell
$token = '<MAIL_RELAY_TOKEN>'
$body = @{
  profile = 'koreancoaching'
  to      = 'test@gmail.com'
  subject = 'relay test'
  text    = 'relay works'
} | ConvertTo-Json

Invoke-RestMethod -Uri 'https://urm.marinebiogroup.com/api/relay/mail' `
  -Method Post -ContentType 'application/json' `
  -Headers @{ 'x-relay-token' = $token } -Body $body
```

- `ok: true` + messageId 반환 -> 정상
- 401 -> 토큰 불일치
- 502 -> SMTP 연결 또는 인증 실패 (Railway 로그 확인)

## 주의

- 토큰이 없으면 누구나 이 엔드포인트로 메일을 보낼 수 있다. 오픈 릴레이가 되면 서버 IP가 RBL에 등록된다.
- MailCarrier 관리도구에서 릴레이 허용 IP에 Railway를 추가할 경우, 그 외 IP는 절대 허용하지 말 것.
- DKIM 미설정 상태에서는 Gmail/네이버 스팸함 위험이 있다. 탭스랩에 도메인별 DKIM 셀렉터 설정을 문의할 것.
- Let's Encrypt는 90일마다 갱신된다. PEM 재생성 + SMTP/POP3/IMAP 서비스 재시작을 자동화하지 않으면 3개월 뒤 메일이 끊긴다.

## Finish block

```powershell
cd C:\dev\mbg-project
git status -sb
git add src/app/api/relay/mail/route.ts
git commit -m "feat(relay): add multi-domain SMTP relay endpoint for external sites"
git push origin marinebiogroup
```

푸시하면 Railway가 자동 배포되어 웹에 즉시 반영된다.
