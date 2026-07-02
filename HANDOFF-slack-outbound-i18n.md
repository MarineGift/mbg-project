# HANDOFF - Slack 아웃바운드 알림 + partyTypes i18n 패치

날짜: 2026-07-01 (세션 후반)
선행 상태: Slack <-> URM **인바운드 완료** (/urm help·note·contact 모두 동작,
slack_team_id=T0BEQGKC7N0 self-heal 확인). 이번 작업 = 나머지 반쪽(아웃바운드) + i18n 버그.

--------------------------------------------------------------------
## A. 이번 패치 내용 (파일 6개, 모두 in-place)
--------------------------------------------------------------------
1. `src/types/email.ts` — `InboundMessageEvent`에 `fromName`, `subject` 필드 추가
2. `src/lib/email/mailcarrier.ts` — `persistInbound` 반환 이벤트에 두 필드 채움
3. `src/workers/mailcarrier-worker.ts` — 새 인바운드 메일 수신 시 `notifySlack()` 호출
   (fire-and-forget, AI 처리 블로킹 없음; `event.organizationId` 사용 = SaaS 표준 준수).
   알림 형식: `New inbound email / From: 이름 <주소> / Subject: ... / {APP_URL}/inbox/{id}`
4. `src/i18n/messages/en.json` / `ko.json` / `ja.json` — partyTypes 누락 키 5개 추가:
   `buyer`, `government_grant`, `consultant`, `crowdfunding_platform`, `self`
   (Railway Deploy Logs의 `MISSING_MESSAGE: partyTypes.self (en)` 에러 원인 제거.
   ko/ja 값은 \uXXXX 이스케이프 = 표준 JSON, 렌더 정상)

검증 완료(Claude 샌드박스): branch 최신 + 본 패치로 `next build` exit=0,
`/api/slack/commands` route 유지, worker transpile OK, tsc 신규 에러 없음.

--------------------------------------------------------------------
## B. 적용 방법 — 아래 블록을 PowerShell에 그대로 붙여넣기
--------------------------------------------------------------------
(멱등: 이미 적용된 파일은 SKIP 출력. ERROR 뜨면 anchor 불일치 = 중단하고 보고)

```powershell
$ErrorActionPreference = 'Stop'
$repo = 'C:\dev\mbg-project'
$LF = [string][char]10
function Apply-Patch($rel, $old, $new, $guard) {
  $p = Join-Path $repo $rel
  $t = [System.IO.File]::ReadAllText($p)
  $t = $t.Replace([string][char]13 + $LF, $LF)
  if ($t.Contains($guard)) { Write-Host ('SKIP (already patched): ' + $rel); return }
  if (-not $t.Contains($old)) { Write-Host ('ERROR anchor not found: ' + $rel); return }
  $t = $t.Replace($old, $new)
  [System.IO.File]::WriteAllText($p, $t)
  Write-Host ('PATCHED: ' + $rel)
}

# --- Patch 1: src/types/email.ts ---
$old = (@('  /** Excerpt of ParsedHeaders (for party matching). */','  fromAddress: string;','}') -join $LF)
$new = (@('  /** Excerpt of ParsedHeaders (for party matching). */','  fromAddress: string;','  /** Display name of the sender, when present. */','  fromName: string | null;','  /** Original subject line (unmasked). */','  subject: string;','}') -join $LF)
$guard = (@('Display name of the sender, when present.') -join $LF)
Apply-Patch 'src/types/email.ts' $old $new $guard

# --- Patch 2: src/lib/email/mailcarrier.ts ---
$old = (@('      piiCategories: categories,','      fromAddress: headers.from.address,','    };') -join $LF)
$new = (@('      piiCategories: categories,','      fromAddress: headers.from.address,','      fromName: headers.from.name ?? null,','      subject: headers.subject,','    };') -join $LF)
$guard = (@('      piiCategories: categories,','      fromAddress: headers.from.address,','      fromName:') -join $LF)
Apply-Patch 'src/lib/email/mailcarrier.ts' $old $new $guard

# --- Patch 3: src/workers/mailcarrier-worker.ts ---
$old = (@('import { processInbound } from ''../lib/email/processor'';') -join $LF)
$new = (@('import { processInbound } from ''../lib/email/processor'';','import { notifySlack } from ''../lib/slack/notify'';') -join $LF)
$guard = (@('lib/slack/notify') -join $LF)
Apply-Patch 'src/workers/mailcarrier-worker.ts' $old $new $guard

# --- Patch 4: src/workers/mailcarrier-worker.ts ---
$old = (@('            const result = await processInbound(supabase, ORG_ID, event.communicationId);') -join $LF)
$new = (@('            // Slack outbound notify - fire-and-forget, never blocks AI processing','            void notifySlack(','              event.organizationId,','              `New inbound email\nFrom: ${event.fromName ? `${event.fromName} <${event.fromAddress}>` : event.fromAddress}\nSubject: ${event.subject || ''(no subject)''}\n${env.NEXT_PUBLIC_APP_URL}/inbox/${event.communicationId}`,','            );','            const result = await processInbound(supabase, ORG_ID, event.communicationId);') -join $LF)
$guard = (@('void notifySlack(') -join $LF)
Apply-Patch 'src/workers/mailcarrier-worker.ts' $old $new $guard

# --- Patch 5: src/i18n/messages/en.json ---
$old = (@('    "crowdfunding": "Crowdfunding",') -join $LF)
$new = (@('    "crowdfunding": "Crowdfunding",','    "buyer": "Buyers",','    "government_grant": "Government Grants",','    "consultant": "Consultants",','    "crowdfunding_platform": "Crowdfunding",','    "self": "Our Company",') -join $LF)
$guard = (@('"crowdfunding_platform"') -join $LF)
Apply-Patch 'src/i18n/messages/en.json' $old $new $guard

# --- Patch 6: src/i18n/messages/ko.json ---
$old = (@('  "crowdfunding":') -join $LF)
$new = (@('  "buyer": "\uAD6C\uB9E4\uCC98",','  "government_grant": "\uC815\uBD80\uC9C0\uC6D0",','  "consultant": "\uCEE8\uC124\uD134\uD2B8",','  "crowdfunding_platform": "\uD06C\uB77C\uC6B0\uB4DC\uD380\uB529",','  "self": "\uC790\uC0AC",','  "crowdfunding":') -join $LF)
$guard = (@('"crowdfunding_platform"') -join $LF)
Apply-Patch 'src/i18n/messages/ko.json' $old $new $guard

# --- Patch 7: src/i18n/messages/ja.json ---
$old = (@('    "crowdfunding":') -join $LF)
$new = (@('    "buyer": "\u8CFC\u8CB7\u5148",','    "government_grant": "\u653F\u5E9C\u652F\u63F4",','    "consultant": "\u30B3\u30F3\u30B5\u30EB\u30BF\u30F3\u30C8",','    "crowdfunding_platform": "\u30AF\u30E9\u30A6\u30C9\u30D5\u30A1\u30F3\u30C7\u30A3\u30F3\u30B0",','    "self": "\u81EA\u793E",','    "crowdfunding":') -join $LF)
$guard = (@('"crowdfunding_platform"') -join $LF)
Apply-Patch 'src/i18n/messages/ja.json' $old $new $guard

Write-Host 'All patches done.'
```

--------------------------------------------------------------------
## C. 이 handoff 파일 mover (Downloads -> repo 루트)
--------------------------------------------------------------------
```powershell
$ErrorActionPreference = 'Stop'
$src = Get-ChildItem (Join-Path $env:USERPROFILE 'Downloads') -Filter 'HANDOFF-slack-outbound-i18n*.md' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Host 'ERROR: file not found in Downloads'; return }
Unblock-File -LiteralPath $src.FullName
$dstDir = 'C:\dev\mbg-project'
[System.IO.Directory]::CreateDirectory($dstDir) | Out-Null
$dst = Join-Path $dstDir 'HANDOFF-slack-outbound-i18n.md'
[System.IO.File]::Copy($src.FullName, $dst, $true)
Remove-Item -LiteralPath $src.FullName
Write-Host ('MOVED: ' + $dst)
```

--------------------------------------------------------------------
## D. Railway 변수 확인 (push 전에!)
--------------------------------------------------------------------
- **lucky-patience(Worker)** 서비스 Variables에 `NEXT_PUBLIC_APP_URL=https://urm.marinebiogroup.com`
  이 있는지 확인, 없으면 추가. (알림 속 inbox 링크가 이 값을 씀. 없으면 기본값
  http://localhost:3000 링크가 나감. env는 optional이라 빌드는 안 깨짐.)
- 변수 추가 시 staged change Deploy 필요.

--------------------------------------------------------------------
## E. Finish block (push = Railway 자동배포 = 웹 게시)
--------------------------------------------------------------------
```powershell
cd C:\dev\mbg-project
git status -sb
git add src/types/email.ts src/lib/email/mailcarrier.ts src/workers/mailcarrier-worker.ts src/i18n/messages/en.json src/i18n/messages/ko.json src/i18n/messages/ja.json HANDOFF-slack-outbound-i18n.md
git commit -m "feat(slack): notify channel on new inbound email; fix missing partyTypes i18n keys"
git pull --rebase origin marinebiogroup
git push origin marinebiogroup
```
- push 하면 web(mbg-project)·worker(lucky-patience) 둘 다 재배포됨.
- `git status -sb`에서 위 6+1개 파일만 변경돼 있는지 먼저 확인.

--------------------------------------------------------------------
## F. 배포 후 테스트
--------------------------------------------------------------------
1. 두 서비스 Deployments 모두 Success 확인.
2. **아웃바운드**: 화이트리스트에 있는 주소(또는 기존 스레드 회신)로
   폴링 중인 메일박스(예: ceo@marinebiogroup.com)에 테스트 메일 발송
   -> 1분 내 #all-marinebiogroup 에 "New inbound email ..." 알림 + inbox 링크.
3. **i18n**: URM inbox 상세 페이지 열기 -> Railway Deploy Logs에
   `MISSING_MESSAGE: partyTypes.*` 가 더 이상 안 찍히면 OK.

--------------------------------------------------------------------
## G. 남은 백로그
--------------------------------------------------------------------
- DB 타입 재생성 -> slack route/notify의 `as any` 제거
- Deal/Meeting 생성 시 알림 (원하면 server action에 notifySlack 한 줄씩)
- Capital Factory: 덱 폼 제출 / Caroline 인트로 메일 / 7-14 Cup of Capital 등록
- SaaS 표준 유지: 엔티티 테이블 organization_id + created_by(auth.uid()) + org RLS,
  join/history/lookup/log/1:1detail 제외. 신규 테이블은 생성 시부터 준수.

## 기록: 오늘 세션에서 해결한 배포 장애
- Railway Variables에 빈 이름 변수 -> 모든 빌드가 `secret ID missing for ""` 로 5연속 실패,
  옛 빌드(eaec5a1f)가 계속 Active였음. 변수 정리 후 정상화. 코드 문제 아니었음.
