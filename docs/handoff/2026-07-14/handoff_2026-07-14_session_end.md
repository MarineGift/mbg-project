# Handoff — 발송 D-Day 운영 + Outcome 시스템 구축 (2026-07-14 세션 종료)

다음 세션은 이 문서만 읽으면 이어받을 수 있음. **다음 세션 첫 작업은 맨 아래 "다음 세션 킥오프 메시지" 블록을 그대로 붙여넣으면 시작됨.**

---

## PART A — 오늘 완료된 것

### 1. Dedup (완료 ✓)
- Seed 시퀀스에서 중복 10건 cancelled (overlap 8 + test 2)
- Part 2 검증: 2+ active 중복 = 0건
- 파일: `sql/20260713250000_dedup_active_enrollments.sql` (v3, 커밋됨)

### 2. Climate 발송 (완료 ✓ — 7/14 발송됨)
- **68건 전원 화요일 7/14 08:00 PT (15:00 UTC)로 변경 후 발송 완료**
- Step 2는 **7/21 화요일** 예정 (day_offset 7). Seed 시퀀스 68건은 **7/20** 발송 예정
- 파일: `sql/20260713260000_climate_send_8am_tuesday.sql`

### 3. 폼 제출 플레이북 (완료 ✓)
- `docs/handoff/2026-07-13/handoff_form_submission_playbook_2026-07-13.md`
- 답변 뱅크(연락처 전부 기입됨: yunyoung.heo@marinebiogroup.com / 512-996-7083 / founder LinkedIn / founded 2026) + 투자자별 Why-us 문단 + 판단
- **NSF SBIR Project Pitch 4섹션 전문 초안 포함** (섹션 4.1.1, 각 3,500자 제한 충족). NSF 26-510, full proposal 마감 2026-11-04. **제출 전 자격 확인 필수: 지분 50%+ 미국 시민/영주권자 + PI 주 소속**
- 제출 확정: P1 10곳 (1955, Azolla, CEV, Emerald, Lowercarbon, Newlab, GGC, CTAN, mHUB, Toyota) + Anzu, Breakout, SOSV, P&G(조건부) + 비희석 3 (NSF, Third Derivative, VFC) + SWAN
- **First Bight는 취소됨** — 7/11 회신으로 stage 거절 이미 받음 (아래 스코어보드)
- SKIP: Activate/Cyclotron/CRI/Innovation Crossroads(개인 펠로우십), In-Q-Tel, PepsiCo, C2C

### 4. 발송 결과(Outcome) 시스템 (완료 ✓ — 오늘의 핵심 산출물)
- **`app.email_send_outcomes`** 테이블 생성됨: outcome 10종 CHECK (bounce_hard/soft, send_failure, rejected_sector/stage/other, unsubscribe_request, auto_reply, reply_positive/neutral) + next_action (suppress/resend_later/switch_deck/switch_contact/follow_up/none) + resend_not_before
- **`app.v_email_do_not_send`** 뷰: bounce_hard + unsubscribe + suppress + 쿨다운 중 주소
- **발송 가드 (모든 향후 enrollment SQL에 필수)**:
```sql
AND NOT EXISTS (
  SELECT 1 FROM app.v_email_do_not_send dns
  WHERE dns.email_lower = lower(candidate.email)
)
```
- Enrollment 동기화 규칙: bounce/suppress → status 'failed', rejected/unsubscribe → 'cancelled' (step 2+ 차단)
- 파일: `sql/migration_20260714090000_email_send_outcomes.sql`, `sql/20260714100000_record_send_outcomes_batch1.sql`, `sql/20260714110000_outcome_lookup_snippets.sql` (조회 Q1~Q5)

### 5. 오늘의 발송 결과 스코어보드 (7/14, DB 기록 완료)
| 상대 | outcome | next_action | 메모 |
|---|---|---|---|
| Planet A Ventures (startups@planet-a.com) | bounce_hard | **switch_contact** | 550 5.2.1 계정 비활성. 대체 주소 발굴 필요 |
| Eclipse Ventures (admin@eclipse.capital) | bounce_hard | **switch_contact** | IT 정책 차단(unauthorized external domain). 콜드메일 영구 불가 → 폼/warm intro |
| Extantia Capital (jo@extantia.com) | rejected_other | resend_later **2027-01-15** | 정중한 거절, 문 열림("following your progress"). 미국 검증+로열티 증빙으로 재접근 |
| Energy Transition Ventures (craig@) | rejected_sector | none | 섹터 불일치, 종료 |
| First Bight (collin@) | rejected_stage | none | "Series A too advanced". 콘셉트 긍정. 폼 제출 취소됨 |

---

## PART B — 확정 스키마 사실 (신규, 삽질 방지)

- **`app.parties` 이름 컬럼 = `party_name`** (`name` 아님!). org 컬럼 = `organization_id`
- **`app.email_sequences`에 org_id/organization_id 없음** → 시퀀스는 name으로 매칭
  - 'Climate Investor Cold Outreach -- FCC' (68 active, step1 발송됨)
  - 'Investor Cold Outreach - FCC Seed' (68 active @ 7/20, 10 cancelled)
- `app.email_send_outcomes`: log 테이블, created_by 없음, organization_id는 party에서 복사. 인덱스: lower(recipient_email), party_id, outcome
- 빈 시퀀스 다수 존재 (15 min... 2종, 삭제-..., Intel Inside, High Priority, FCC Climate Tech) — 나중에 archive 정리 대상

## PART C — 미결 사항 (우선순위)

1. **[내일부터 매일] 메일함 → outcome 기록.** 새 바운스/거절/회신을 `email_send_outcomes`에 INSERT (batch1 파일의 Part 2 패턴 재사용). Brightfuture 회신(7/14 06:07, 3KB) 아직 미분류 — 본문 확인 필요
2. **[7/20 전] Seed 시퀀스 발송 전 점검**: null_email 체크 + do-not-send 가드로 교차 확인 (Seed 68건 중 문제 주소 사전 차단)
3. **폼 제출 실행**: 플레이북 순서 P1 10곳 → Anzu/Breakout/SOSV → NSF (자격 확인 후)
4. Planet A / Eclipse 대체 컨택 발굴 (Q5 목록)
5. 이메일 없는 최상위 기후펀드 백필 (Breakthrough Energy, Bezos Earth Fund 등 70개 — 지난 핸드오프에서 이월)
6. 과거 $5M 표기 주의: 7/10 라운드 재구성 전 개별 발송분에 "$5M Series A" 존재 (First Bight 스레드에서 확인). 구발송 상대와 대화 재개 시 "$3M at $27M pre로 조정" 한 줄 대응
7. 빈 시퀀스 archive 정리 (급하지 않음)

## PART D — 컨벤션 요약 (변동 없음)

- 소통: 한국어(논의) + 영어(코드/SQL/덱). 콘솔 ASCII-only, 한국어 .md는 UTF-8 BOM
- 파일 라우팅: `tools\move-downloads.ps1` (프리픽스 규칙). 핸드오프마다 mover + finish 블록
- git: 두 머신 사용 중이므로 **작업 시작 전 `git pull` 필수** (오늘 non-fast-forward 충돌 발생했었음 → `git pull --rebase`로 해결)
- Supabase SQL Editor: 문자열 내 세미콜론/`into` 금지, self-contained 문장, enum은 `::app.enrollment_status` 캐스트
- repo PUBLIC: raw.githubusercontent.com/MarineGift/mbg-project/marinebiogroup/<path>

---

## 다음 세션 킥오프 메시지 (그대로 복붙)

```
mbg-project 작업 이어가자. docs/handoff/2026-07-14/handoff_2026-07-14_session_end.md 기준.

오늘 목표: URM에 발송 결과 대시보드 페이지 `/mailing/outcomes` 추가 + MailCarrier NDR 자동 기록 워커 확장.

배경:
- DB에 app.email_send_outcomes 테이블과 app.v_email_do_not_send 뷰가 이미 있음 (migration_20260714090000_email_send_outcomes.sql 참조, repo sql/에 커밋됨)
- outcome 10종: bounce_hard/soft, send_failure, rejected_sector/stage/other, unsubscribe_request, auto_reply, reply_positive/neutral
- next_action 6종: suppress, resend_later(+resend_not_before), switch_deck, switch_contact, follow_up, none

작업 1 — /mailing/outcomes 페이지:
- 먼저 repo에서 기존 mailing 관련 페이지 구조를 읽고 (raw.githubusercontent, route-group (app)는 %28app%29로 인코딩) 그 컨벤션(서버 컴포넌트, Supabase 클라이언트 패턴, shadcn/ui, next-intl)을 그대로 따를 것
- 화면 구성 3블록:
  ① 요약 카드: outcome별 카운트 (snippets Q3)
  ② 액션 보드: next_action IN (switch_contact, switch_deck, follow_up) 목록 (Q5)
  ③ 재접근 대기: resend_later 목록, resend_not_before 오름차순 + D-day 표시 (Q4)
- 테이블에 party_name 링크(기존 party 상세 라우트로), outcome 배지 색상: bounce=red, rejected=orange, reply_positive=green, auto=gray
- 신규 outcome 수동 입력 폼(간단 버전)도 페이지에 포함: recipient_email, outcome, reason, next_action, resend_not_before
- RLS/권한은 기존 mailing 페이지와 동일 패턴

작업 2 — MailCarrier NDR 파서 (워커 확장):
- 기존 MailCarrier IMAP 워커 코드를 repo에서 찾아 읽을 것
- NDR 판별: From에 postmaster/mailer-daemon 또는 제목에 Undeliverable/전송 실패/Delivery Status Notification
- 파싱: 원 수신자 주소(본문의 Final-Recipient 또는 550 라인), SMTP 코드로 hard(5xx)/soft(4xx) 구분
- app.email_send_outcomes에 INSERT (source='mailcarrier', bounce_hard는 next_action='suppress' 기본)
- 중복 방지: 동일 recipient_email + evidence_ref 존재 시 skip
- INSERT 후 해당 주소의 active enrollment를 'failed'로 (기존 Part 3 로직과 동일)

완료 기준: 페이지가 오늘 기록된 5건(Planet A, Eclipse, Extantia, ETV, First Bight)을 표시하고, 배포(push) 후 urm.marinebiogroup.com/mailing/outcomes 에서 확인 가능.
```

---

## 파일 이동 + Finish

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

개별 fallback:
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads\handoff_2026-07-14_session_end*.md" |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File $src.FullName
  $dest = 'C:\dev\mbg-project\docs\handoff\2026-07-14'
  [System.IO.Directory]::CreateDirectory($dest) | Out-Null
  [System.IO.File]::Copy($src.FullName, (Join-Path $dest 'handoff_2026-07-14_session_end.md'), $true)
  Remove-Item $src.FullName
  Write-Host "MOVED -> docs\handoff\2026-07-14\handoff_2026-07-14_session_end.md"
} else { Write-Host "NOT FOUND in Downloads" }
```

```powershell
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup   # 두 머신 사용 - pull 먼저!
git status -sb
git add sql/ docs/handoff/
git commit -m "docs: 2026-07-14 session-end handoff (outcome system, send day results)"
git push origin marinebiogroup   # push = urm.marinebiogroup.com 자동 배포
```
