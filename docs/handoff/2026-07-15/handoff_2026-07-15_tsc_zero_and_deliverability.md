# handoff_2026-07-15_tsc_zero_and_deliverability.md

이전: handoff_2026-07-15_unions_and_landmine.md → 이 문서
상태: **tsc 기준선 15건/5파일 → 0건 (검증 완료)**. 미결 4의 전제가 오진으로 판명. 미결 3 실측 완료.
발송까지: 7/21(화) 09:00 PT — **6일**.

---

## 이번 세션 요약

미결 3(딜리버러빌리티) / 4(타임존) / 7(tsc)를 전부 착수. 결론부터:

| 미결 | 결과 |
|---|---|
| 3. IP/SPF/DKIM/DMARC | **실측 완료.** 공개 블랙리스트 12곳 전부 clean. 진짜 구멍은 **DKIM 부재** + `p=none`. ERS는 별건. |
| 4. 타임존 (country 42703) | **오진.** 컬럼은 `country` 가 아니라 **`country_code`** — 처음부터 있었다. 백필 마이그레이션 불필요. |
| 7. tsc 15건/5파일 | **0건으로 종결.** 클린 체크아웃에서 before/after 양쪽 검증. |

---

## PART A — tsc 기준선 15건/5파일 → 0건 [종결]

`origin/marinebiogroup` 클린 체크아웃에서 재현 → 수정 → 재검증:

```
before : 15 errors, 5 files   (tsc_baseline.txt 와 완전 일치)
after  :  0 errors, exit 0
```

| 파일 | 건수 | 원인 |
|---|---|---|
| `applications-list-client.tsx` | 2 | TS18048 |
| `lib/actions/parties.ts` | 2 | TS2339 |
| `lib/tasks/decompose-actions.ts` | 1 | TS2345 |
| `scripts/fill-application.ts` | 9 | TS2322 + TS18048 |
| `scripts/inspect-form.ts` | 1 | TS2322 |

### 캐스트로 덮지 않은 유일한 건 — parties.ts

나머지 4파일은 전부 `noUncheckedIndexedAccess` 잡음이라 좁히기만 하면 끝난다.
**parties.ts의 TS2339 2건은 잡음이 아니라 실제 버그를 가리키고 있었다.**

- `partySchema` / `updateSchema` 에는 `sectorFocus` 필드가 **없다**. `sectorFocus`는
  `investorProfileSchema`(parties.ts:466)에만 존재한다.
- 그래서 `createParty`(238) / `updateParty`(366)의
  `rpc('sync_party_sector_focus', { p_codes: parsed.data.sectorFocus })` 는
  **`p_codes: undefined`** 를 보내고 있었다 → JSON 직렬화에서 키가 통째로 사라짐 →
  PostgREST가 시그니처 매칭 실패 → **PGRST202**.
- 즉 이 호출은 **한 번도 성공한 적이 없다.** `updateParty` 쪽은 `secErr`를
  `console.error`로만 흘려서 조용히 실패해 왔다.

수정: 두 호출을 지우고 `updateInvestorProfile` 안으로 이전. 커버리지 손실 없음 —
`party-form.tsx:376/391` 이 create/update **양쪽 경로 모두**에서 직후에
`persistProfile()` → `updateInvestorProfile()` 을 호출하고, 그 페이로드에
`sectorFocus: parseTagsInput(values.sectorFocus)` (369) 가 실려 있다.

**부수 효과: `app.investor_sector_focus` 정규화 동기화가 이제 처음으로 실제 동작한다.**
Q. 지금까지 sector_focus는 `app.investor_profile.sector_focus`(배열 컬럼, 524)에만
쌓이고 정규화 테이블은 비어 있었을 가능성이 높다. 다음 세션에서 확인할 것.

### 패치 적용 중 잡은 함정

`revalidatePath(\`/${parsed.data.partyType}/parties/${parsed.data.partyId}\`)` 로 끝나는
꼬리 블록이 parties.ts에 **2번**(446 `updateInvestorPriority`, 564 `updateInvestorProfile`)
나온다. PowerShell `.Replace()` 는 전건 치환이므로 짧은 앵커를 쓰면 sector sync가
`updateInvestorPriority` 에도 주입된다. 앵커를 `[parties.updateInvestorProfile] insert error:`
까지 늘려 유일화했고, **패치 스크립트 자체에 앵커 유일성 검사(`hits -ne 1` → FAIL)를 넣었다.**
앞으로 모든 in-place 패치에 이 가드를 기본 탑재할 것.

---

## PART B — 미결 4: `country` 42703은 오진이었다 [전제 붕괴]

이전 핸드오프: *"app.parties에 country 없음(42703) → 백필 선행. 백로그"*

**컬럼명이 틀렸을 뿐이다. `app.parties.country_code` (ISO-2)는 처음부터 있다.**
리포에서 3중 확인:

- `src/types/database.ts` → `parties.Row.country_code: string | null` (`city`, `region`도 함께)
- `sql/20260627120000_global_am_investors_batch3.sql` 외 약 10개 시드가
  `insert into app.parties (..., country_code, region, city, ...)` 로 이미 값을 넣고 있음
- UI도 이미 붙어 있음 — `party-form.tsx:92/339` (`countryCode`),
  `party-header.tsx:96` 렌더, `country-peers-panel.tsx:32` 가 `.eq('country_code', ...)` 필터

따라서 **백필 마이그레이션은 필요 없다.** 남은 미지수는 오직 **커버리지**다.
7/21에 맞을 40명 중 몇 명이 `country_code`를 갖고 있는가 — 그걸 재는 게
`20260715220000_scan_country_code_coverage.sql` (READ-ONLY, Q1~Q5).

- Q3가 09:00 PT = 16:00 UTC 기준 **수신자별 현지 도착 시각**을 뽑는다.
  유럽 18:00(퇴근 후) / 도쿄·서울 01:00(한밤중)이 몇 명인지 숫자로 나온다.
- Q4가 `country_code IS NULL` 인 대상만 이름으로 뽑는다. **짧으면 UI에서 손으로 넣고 끝.**
  (party-form에 필드가 이미 있다.) 마이그레이션 쓸 이유가 없다.
- Q5는 길 경우의 싸구려 80% 백필 — ccTLD → country. **PREVIEW SELECT일 뿐 쓰지 않는다.**
  주의: `.uk` 의 ISO-2는 `GB`다. `upper(tld)` 맹목 캐스트 금지.

---

## PART C — 미결 3: 딜리버러빌리티 실측 (2026-07-15 조회)

DNS를 직접 조회했다. 추정 아님.

### 나온 것

```
SPF    marinebiogroup.com        TXT   "v=spf1 ip4:49.254.118.167 ~all"
DMARC  _dmarc.marinebiogroup.com TXT   "v=DMARC1; p=none; rua=mailto:postmaster@marinebiogroup.com; fo=1"
MX     marinebiogroup.com        MX    10 mail.marinebiogroup.com
A      mail.marinebiogroup.com   A     49.254.118.167
PTR    49.254.118.167            PTR   mail.marinebio.kr.
A      mail.marinebio.kr         A     49.254.118.167
TXT    marinebio.kr              TXT   "v=spf1 ip4:49.254.118.167 ~all"
DMARC  _dmarc.marinebio.kr             NXDOMAIN
```

### 블랙리스트: 12곳 전부 clean

Spamhaus ZEN(SBL/CSS/XBL/PBL), SpamCop, Barracuda, SORBS, PSBL, Mailspike,
UCEPROTECT L1, AnonMails, Backscatterer, s5h, DroneBL, CBL — **전부 미등재.**

**이게 좋은 소식이자 중요한 소식이다.** 죽은 주소를 두 번씩 두들긴 대가가
아직 평판에 광범위하게 박히지 않았다. `fix_20260715003000` 이 그 고리를 끊은 게
제때였다. 다만 공용 리졸버에서 조회한 결과이므로 사내망에서 한 번 더 확인 권장(아래 블록).

### 판정

**1. Chevron 554는 범용 블랙리스트가 아니다.** 12곳이 clean인데 ERS만 막는다 =
Trend Micro 고유 등재. 49.254.x 대역이 한국 ISP 브로드밴드 풀이라
ERS의 **DIL(Dynamic IP List)** 에 대역 단위로 들어가 있을 가능성이 가장 높다.
Trend Micro 자체 문서가 이 경우를 명시한다 — 동적 IP 목록은
**IP 소유자(= ISP)만 해제 요청 가능**하고, 대안은
*"ISP가 지정한 메일 릴레이를 통해 발신하도록 메일 클라이언트를 설정"*.
즉 **우리가 폼을 넣어도 개인 자격이면 반려된다.** 이게 미결 3이 여태 안 풀린 이유일 수 있다.

**2. 진짜 구멍은 DKIM이다.** 흔한 셀렉터 20개(`default`, `mail`, `dkim`, `s1`, `s2`,
`k1`, `selector1/2`, `google`, `zoho`, `sendgrid` 등)를 훑었는데 **하나도 안 잡혔다.**
셀렉터는 임의 문자열이라 이것만으로 단정할 수 없다 — **확정 방법은 보낸 메일 원문 헤더의
`DKIM-Signature:` 줄에서 `s=` 를 읽는 것.** 없으면 없는 거다.
DKIM이 없으면 SPF 정렬 하나에 전부 걸리고, 전달(forward) 한 번에 인증이 통째로 깨진다.
US VC에게 콜드 메일을 넣으면서 DKIM이 없는 건 ERS보다 더 큰 상시 감점이다.

**3. `p=none`** — 감시만 하고 집행 안 함. 게다가 `rua`가
`postmaster@marinebiogroup.com` 로 가는데, `fix_20260715003000` 이 기록했듯
**그 사서함은 NDR이 쌓이기만 하고 아무도 파싱하지 않는 곳이다.**
DMARC 집계 리포트도 같은 무덤에 들어가고 있을 것이다.

**4. PTR 도메인 불일치 (경미).** `49.254.118.167` → `mail.marinebio.kr` →
다시 `49.254.118.167` 로 되돌아오므로 **FCrDNS 자체는 정상이다.** 다만 발신 도메인은
`marinebiogroup.com` 인데 PTR 호스트명은 `marinebio.kr` 이라 도메인이 어긋난다.
치명타는 아니고, 일부 필터에서 소폭 감점. 1·2·3 다음 순위.

### 권장 순서 (효과/비용 순)

1. **DKIM 발행** — 메일서버에 키 생성 → `<selector>._domainkey.marinebiogroup.com` TXT 게시.
   `marinebio.kr` 도 같은 박스를 쓰므로 동일 처리. 가장 큰 효과, 가장 낮은 비용, ISP 불필요.
2. **DMARC `rua` 를 사람이 읽는 주소로 교체.** postmaster 무덤에서 빼낼 것.
   DKIM 안착 후 `p=none` → `p=quarantine`.
3. **ERS는 그 다음.** `https://servicecentral.trendmicro.com/en-US/ers/` 에서
   `49.254.118.167` 조회 → 어느 DB(QIL / DIL / RBL+)에 걸렸는지부터 확인.
   **DIL이면 우리가 폼을 넣어도 안 된다 — ISP로 가야 한다.**
4. **구조적 선택지 (진지하게 검토 요망).** Austin TX 법인이 US VC에게 콜드 메일을
   한국 브로드밴드 IP에서 직접 쏘고 있다. 1·2를 다 해도 이 사실은 남는다.
   Google Workspace / M365 / SES / Postmark 릴레이로 옮기면 IP 평판 문제가
   **영구히** 사라진다. 40통 규모면 비용은 무시할 수준이고 SPF 한 줄이면 된다.
   ERS 해제 요청을 반복하는 것보다 싸다.

> 7/21 발송 자체는 막을 이유 없다. 12곳 clean이고 Chevron 1건 외 ERS 거절 관측 없음.
> DKIM만이라도 화요일 전에 올리면 그 40통이 더 나은 조건에서 나간다. DNS 전파 감안해 오늘.

### 재확인용 (Windows, ASCII only)

```powershell
$ip = '49.254.118.167'
Write-Host "--- SPF / DMARC / MX ---"
Resolve-DnsName marinebiogroup.com -Type TXT -ErrorAction SilentlyContinue |
  Where-Object { $_.Strings -match 'spf1' } | ForEach-Object { "SPF   : " + ($_.Strings -join '') }
Resolve-DnsName _dmarc.marinebiogroup.com -Type TXT -ErrorAction SilentlyContinue |
  ForEach-Object { "DMARC : " + ($_.Strings -join '') }
Resolve-DnsName marinebiogroup.com -Type MX -ErrorAction SilentlyContinue |
  ForEach-Object { "MX    : " + $_.NameExchange }
Write-Host "--- PTR ---"
Resolve-DnsName $ip -Type PTR -ErrorAction SilentlyContinue |
  ForEach-Object { "PTR   : " + $_.NameHost }
Write-Host "--- DKIM selector probe ---"
$hit = $false
foreach ($s in @('default','mail','dkim','s1','s2','k1','selector1','selector2','google','zoho','smtp','em')) {
  $n = "$s._domainkey.marinebiogroup.com"
  $r = Resolve-DnsName $n -Type TXT -ErrorAction SilentlyContinue
  if ($r) { Write-Host ("FOUND : {0}" -f $n); $hit = $true }
}
if (-not $hit) { Write-Host "DKIM  : none of the probed selectors resolved" }
Write-Host "--- DNSBL ---"
$rev = ($ip -split '\.')[3..0] -join '.'
foreach ($z in @('zen.spamhaus.org','bl.spamcop.net','b.barracudacentral.org','dnsbl.sorbs.net')) {
  $r = Resolve-DnsName "$rev.$z" -Type A -ErrorAction SilentlyContinue
  if ($r) { Write-Host ("LISTED: {0} -> {1}" -f $z, ($r.IPAddress -join ',')) }
  else    { Write-Host ("clean : {0}" -f $z) }
}
```

`smtp_host` 는 env가 아니라 DB(`app.inbound_mailboxes`)에 있다 —
`20260715221000_scan_mail_sender_config.sql` Q2가 뽑는다. **비밀번호는 안 뽑는다**
(`smtp_password_encrypted IS NOT NULL` 불리언만). 이 값이 릴레이 경유인지
직접 발송인지를 가르고, 그게 ERS 해제가 애초에 맞는 레버인지를 결정한다.

---

## 다음 발송 (변동 없음)

7/21(화) 09:00 PT = 16:00 UTC, Climate step 2, 40통. 워커 자동(60초 폴링).
이후 7/28 62통(step3 22 + 40), 8/4 62통.

## 미결 (갱신)

1. 7/21 09:00 PT 발송 관찰 (40통) → 헬스 뷰 실측
2. ~~FCC Climate Tech day_offset 0,0~~ **종결** (fd23f25)
3. **딜리버러빌리티** — 실측 완료(PART C). 잔여 액션: ① DKIM 발행 ② DMARC rua 교체 →
   `p=quarantine` ③ ERS 조회로 DB 종류 확인(DIL이면 ISP 경유) ④ 릴레이 이전 검토
4. **타임존** — 전제 오진 정정(`country_code` 존재). 백필 마이그레이션 불필요.
   잔여: coverage scan 실행 → NULL 소수면 UI 수기 입력
5. ~~phase21b.ts 유니온~~ **종결** (9b6288f, 9408269, 1063b43)
6. E-3 quiet-hours 무방비 쓰기 = 우선순위 하향 유지
7. ~~tsc 15건 5파일~~ **종결 (0건)**. 시퀀스 이름 중복은 아카이브로 실질 해소.
   잔존: World Fund 8/4 재개 감시 / Lowercarbon 이중 노출
8. **[신규] `app.investor_sector_focus` 실제로 비어 있는지 확인** — PART A 참조.
   sector focus 동기화가 PGRST202로 한 번도 안 돌았을 가능성. 비어 있으면 재동기화 필요

## 이월된 주의사항 (유효)

- **step_order 기수 혼재**: 0-기반/1-기반이 섞임. `step_order > 1` 금지, `LAG(...) IS NOT NULL` 기준.
- **enum typname**: `sequence_status` 아니라 **`email_sequence_status`**.
- `enrollment_status` 에 text 리터럴 COALESCE 시 22P02 — `e.status::text` 로 풀 것.
- **[신규] PowerShell `.Replace()` 는 전건 치환.** in-place 패치는 앵커 유일성 검사 필수.

---

## 파일 배치

| 파일 | 목적지 |
|---|---|
| `handoff_2026-07-15_tsc_zero_and_deliverability.md` | `docs\handoff\2026-07-15\` |
| `patch_20260715_tsc_baseline_to_zero.ps1` | `tools\patches\` |
| `20260715220000_scan_country_code_coverage.sql` | `sql\` |
| `20260715221000_scan_mail_sender_config.sql` | `sql\` |

유니버설 무버 한 줄 (4개 전부 라우팅됨):
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 fallback (무버가 없거나 실패할 때):
```powershell
$moves = @(
  @{ Pattern = 'handoff_2026-07-15_tsc_zero_and_deliverability*.md';  Dir = 'C:\dev\mbg-project\docs\handoff\2026-07-15'; Name = 'handoff_2026-07-15_tsc_zero_and_deliverability.md' },
  @{ Pattern = 'patch_20260715_tsc_baseline_to_zero*.ps1';            Dir = 'C:\dev\mbg-project\tools\patches';            Name = 'patch_20260715_tsc_baseline_to_zero.ps1' },
  @{ Pattern = '20260715220000_scan_country_code_coverage*.sql';      Dir = 'C:\dev\mbg-project\sql';                      Name = '20260715220000_scan_country_code_coverage.sql' },
  @{ Pattern = '20260715221000_scan_mail_sender_config*.sql';         Dir = 'C:\dev\mbg-project\sql';                      Name = '20260715221000_scan_mail_sender_config.sql' }
)
foreach ($m in $moves) {
  $src = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter $m.Pattern -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host ("NOT FOUND: {0}" -f $m.Pattern); continue }
  Unblock-File $src.FullName
  [System.IO.Directory]::CreateDirectory($m.Dir) | Out-Null
  $dest = Join-Path $m.Dir $m.Name
  [System.IO.File]::Copy($src.FullName, $dest, $true)
  Remove-Item $src.FullName
  Write-Host ("MOVED: {0}" -f $dest)
}
```

## 실행

```powershell
# 1) tsc 기준선을 0으로. 멱등 - 두 번 돌려도 안전. 끝에서 tsc 자동 검증.
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_20260715_tsc_baseline_to_zero.ps1
```

```
# 2) Supabase SQL Editor 에서 (둘 다 READ-ONLY, 쓰기 없음):
#      sql\20260715221000_scan_mail_sender_config.sql   <- Q2 smtp_host 가 핵심
#      sql\20260715220000_scan_country_code_coverage.sql <- Q3/Q4 가 핵심
```

```powershell
# 3) DKIM 여부 확정: 최근 보낸 메일 1통의 원문 헤더에서 DKIM-Signature 의 s= 를 읽을 것.
#    (DNS 셀렉터 추측으로는 "없다"를 증명할 수 없다.)
```

## 마무리

```powershell
cd C:\dev\mbg-project
git status -sb
git add tools\patches\patch_20260715_tsc_baseline_to_zero.ps1
git add sql\20260715220000_scan_country_code_coverage.sql
git add sql\20260715221000_scan_mail_sender_config.sql
git add src\app\"(app)"\applications\applications-list-client.tsx
git add src\lib\actions\parties.ts
git add src\lib\tasks\decompose-actions.ts
git add src\scripts\fill-application.ts
git add src\scripts\inspect-form.ts
git add docs\handoff\2026-07-15\handoff_2026-07-15_tsc_zero_and_deliverability.md
git commit -m "fix: clear tsc baseline 15->0 + re-home sector focus sync (PGRST202 dead call); docs: deliverability audit"
git push origin marinebiogroup
```

**push = Railway 자동 배포 = 웹 반영.** 이번엔 문서만이 아니다 —
`parties.ts` 의 실동작이 바뀐다(sector focus 동기화가 create/updateParty 에서
`updateInvestorProfile` 로 이동, 그리고 **처음으로 실제 동작**한다).
투자자 저장 경로에 영향이 있으니 배포 후 투자자 1건을 저장해 보고
`app.investor_sector_focus` 에 행이 생기는지 확인할 것 — 미결 8과 같은 확인이다.

배포 전에 `git status -sb` 로 `src/` 5개 파일이 의도대로 잡혔는지 볼 것.
