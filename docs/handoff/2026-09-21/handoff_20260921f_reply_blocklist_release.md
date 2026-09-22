\xef\xbb\xbf# Handoff 2026-09-21f — 회신 시 do-not-send(blocklist) 차단 처리 + 자동 수신거부 오탐 수정

## 증상
Reply → Send 시 toast: `Recipient is on the do-not-send list: mret@svrglobal.com`
→ whitelist 문제가 아니라 `app.email_blocklist`(address, reason=unsubscribe, notes=auto:...) 차단.
원인: 인바운드 수신거부 자동감지(`bounce-parser.ts detectUnsubscribe`)가 메일 **본문 전체**(인용된 이전 스레드, 회사 footer 포함)를
검사해서 "opt out / remove me / stop sending" 같은 문구를 사람의 수신거부 요청으로 오인.

## 변경
1. `src/lib/email/bounce-parser.ts` — `freshReplyText()` 추가: 인용 이력(`>`, `On ... wrote:`, `From:`, Original Message),
   서명 구분자(`-- `), 맺음말(Best, Regards, Thanks, 감사합니다...) 이전의 새 본문만 검사, 최대 1200자
2. `src/lib/actions/email-blocklist.ts` — `findBlocklistMatches()`, `releaseBlocklistAddress()` 추가
   (address 행만 `is_active=false` + notes에 "released from reply" 기록, 삭제 안 함. domain/regex 규칙은 Settings에서만 변경)
3. `src/lib/actions/communications.ts`, `src/lib/actions/email-compose.ts` — `blocklisted` errorCode를 다이얼로그까지 전달
   (기존에는 `send_failed`로 뭉개짐)
4. `src/components/email/compose-email-dialog.tsx` — blocklist 차단 시 확인창:
   차단 사유 표시 → **OK** = do-not-send 해제 + whitelist + Investors contact 등록 + 발송 / **Decline** = 취소

## 검증
- tsc: 변경 파일 오류 0 (기존 12개 그대로)
- detector 테스트: footer/인용문 속 "opt out", "please remove me" → 미감지 / 새 본문 첫 줄 "Please remove me" → 감지

## 오탐 점검 (선택)
`sql/probe_20260921_blocklist_auto_unsub.sql` — 자동 등록된 unsubscribe 행 목록 (읽기 전용). Ctrl+A 후 Run.

## Push
```powershell
cd C:\dev\mbg-project
git status -sb
git add src/components/email/compose-email-dialog.tsx src/lib/actions/communications.ts src/lib/actions/email-blocklist.ts src/lib/actions/email-compose.ts src/lib/email/bounce-parser.ts sql/probe_20260921_blocklist_auto_unsub.sql docs/handoff
git commit -m "reply: release auto do-not-send + register then send; unsubscribe detector scans fresh text only"
git push origin marinebiogroup
```
