# Handoff 2026-10-11 — Greentown Labs 두 도메인(.com / .org) 통합

> 이전 문서: `docs/handoff/2026-10-10/handoff_20261010f_after_e.md`

## 1. 문제
- Greentown Labs 스태프가 `greentownlabs.com` 과 `greentownlabs.org` 두 도메인을 함께 씀. Chloe 는 예전엔 .com, 지금은 .org 로 메일을 보냄.
- URM 은 .com 만 알고 있었음:
  - 인바운드 게이트(`lib/email/whitelist.ts`): 연락처가 .com 으로만 등록 + 파티 웹사이트도 greentownlabs.com → `@greentownlabs.org` 발신자가 "모르는 사람"으로 판정되어 **저장 자체가 건너뛰어질 수 있음** (2026-09-15 BASF 건과 같은 패턴)
  - Greentown Labs Houston 메일 폴더 `match_domains` = `greentownlabs.com` 하나
  - 발신자 매칭(`lib/email/header-parser.ts`)은 `contacts.email` 정확일치만 → chloe@…org 는 연락처 매칭 실패. 도메인 폴백이 같은 도메인의 **다른 직원 연락처**를 붙일 수도 있었음

## 2. 해결 — 한 사람 = 한 연락처, 주소 여러 개
| 위치 | 내용 |
|---|---|
| `header-parser.ts` | 새 `findContactByAnyAddress()` — `contacts.email` + `contacts.email_secondary` + `app.contact_emails` 어느 것이든 일치하면 같은 연락처. 폴더가 여러 도메인을 핀하면 형제 도메인으로 간주 → 같은 로컬파트(chloe@)만 매칭 (동료에게 붙지 않음) |
| `whitelist.ts` | 게이트가 `email_secondary`, `contact_emails`, 메일 폴더 핀(주소/도메인)도 "아는 상대"로 인정 |
| SQL | whitelist 두 도메인, 폴더에 .org 추가, 스태프마다 contact_emails(본 주소 primary + 쌍둥이 alias), `email_secondary` 채움, 기존 고아 메일 연결 |

- Partner 상세의 스태프 패널은 이미 `contact_emails` 를 모두 표시함 → Chloe 아래에 `.com · primary` 와 `.org · alias` 두 줄이 보임
- 연락처 병합/삭제 없음. 쌍둥이 주소를 다른 연락처가 이미 쓰고 있으면 건너뜀 (VERIFY 3 staff 에서 확인)
- Will(`will@greentownlabs.*`) 메일은 투자자 인트로 분류 규칙 유지 — 백필에서 제외

## 3. 실행 순서

### 3-1. 파일 이동
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
fallback (인라인):
```powershell
$dl = Join-Path $env:USERPROFILE 'Downloads'; $repo = 'C:\dev\mbg-project'
$map = @(
  @('fix_20261011_greentown_dual_domain*.sql',   'sql\fix_20261011_greentown_dual_domain.sql'),
  @('patch_20261011_greentown_dual_domain*.ps1', 'tools\patches\patch_20261011_greentown_dual_domain.ps1'),
  @('handoff_20261011_greentown_dual_domain*.md','docs\handoff\2026-10-11\handoff_20261011_greentown_dual_domain.md')
)
foreach ($m in $map) {
  $f = Get-ChildItem -LiteralPath $dl -Filter $m[0] -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $f) { Write-Output ('MISSING ' + $m[0]); continue }
  Unblock-File -LiteralPath $f.FullName
  $dest = Join-Path $repo $m[1]
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($dest)) | Out-Null
  [System.IO.File]::Copy($f.FullName, $dest, $true)
  Remove-Item -LiteralPath $f.FullName
  Write-Output ('MOVED ' + $m[1])
}
```

### 3-2. 코드 패치
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_20261011_greentown_dual_domain.ps1
```
기대 출력: `PATCHED src\lib\email\header-parser.ts`, `PATCHED src\lib\email\whitelist.ts`, `DONE`
(`ERROR changed since review` 가 나오면 다른 PC 커밋이 먼저 들어온 것 — `git pull --rebase` 후 다시 실행)

### 3-3. Supabase SQL
`sql/fix_20261011_greentown_dual_domain.sql` — **Ctrl+A 후 Run**. 마지막 VERIFY 한 장:
- `1 whitelist` greentownlabs.com / .org 둘 다 active=true
- `2 folder` Greentown 폴더에 `greentownlabs.com greentownlabs.org`
- `3 staff` 스태프마다 `all` 칸에 두 주소 (`*` = primary)
- `4 mail greentownlabs.org` linked 숫자
- `5 chloe` 이미 저장된 Chloe 메일과 연결된 파티/연락처

### 3-4. GitHub push (= Railway 자동 배포, web + worker)
```powershell
cd C:\dev\mbg-project
git status -sb
git add src/lib/email/header-parser.ts src/lib/email/whitelist.ts sql/fix_20261011_greentown_dual_domain.sql tools/patches/patch_20261011_greentown_dual_domain.ps1 docs/handoff
git commit -m "mail: one contact, many addresses - Greentown .com/.org sibling domains"
git push origin marinebiogroup
```
non-fast-forward 거절 시: `git fetch` → `git pull --rebase` → `git push origin marinebiogroup`

### 3-5. (필요할 때만) 놓친 .org 메일 다시 받기
3-3 의 `5 chloe` 에 최근 .org 메일이 없다면 게이트에서 건너뛴 것. 워커는 `last_processed_uid` 이후만 읽으므로 커서를 되돌린다. 저장된 메일은 message_id 중복 검사로 건너뛰므로 중복이 생기지 않음. **배포(3-4) 끝난 뒤** 실행.
```powershell
cd C:\dev\mbg-project
node --env-file=.env.local tools/imap-find.mjs yunyoung.heo@marinebiogroup.com chloe 30
```
가장 오래된 놓친 메일의 uid 를 보고 (예: 1830 → 1829):
```sql
update app.mailcarrier_state
   set last_processed_uid = 1829,
       updated_at = now()
 where username = 'yunyoung.heo@marinebiogroup.com'
   and last_processed_uid > 1829
returning username, kind, last_processed_uid;
```
워커 다음 주기 후 3-3 VERIFY 를 다시 돌려 `5 chloe` 확인.

## 4. 규칙 (새로 정함)
- **한 사람 = 한 연락처.** 두 번째 주소는 새 연락처가 아니라 `app.contact_emails`(label alias) + `contacts.email_secondary` 로 붙인다.
- 한 조직이 도메인을 여러 개 쓰면 그 파티 메일 폴더 `match_domains` 에 **모든 도메인**을 넣는다. 이것이 게이트 통과 + 형제 도메인 연락처 매칭의 근거가 된다.
- 다른 회사가 같은 상황이면: 폴더에 도메인 추가 + 해당 연락처에 contact_emails alias 추가 (이 SQL 의 2·3b 단계를 회사명/도메인만 바꿔 재사용).
