# Handoff — 2026-07-15 세션 종합 (가드 적용 → 구조적 해법 → 중복 발송 근본 원인 → 거절/바운스 정리)

`docs/handoff/2026-07-14/handoff_2026-07-14_evening.md`로 시작해 **하루에 4단계**를 밟은 세션. 앞선 두 핸드오프(`night`, `night2`)를 이 문서가 대체한다.

> ## 사업 피해 (이번 세션에 확인)
> 시퀀스가 같은 회사에 **19시간 간격 2통** → 투자자 클레임 + "관심 없음" 회신.
>
> ## 7/20 발송: **97통** — 리스크 전부 닫힘
> Climate 40 + Seed 57 (7/27 Climate 22). 가드·중복차단·거절차단·바운스차단 모두 적용·검증 완료.
> 헬스 뷰 실측: **ok 119 / do_not_send_party 8 / do_not_send_email 7**.

---

## PART A — 완료된 것 (전부 DB에서 직접 검증)

| 조치 | 파일 | DB | 검증 |
|---|---|---|---|
| 시퀀스 do-not-send 가드 | `migration_20260714235600` | ✅ | `has_dns_guard = true` |
| 발송 헬스 뷰 | `migration_20260714235500` | ✅ | — |
| World Fund 쿨다운 | `fix_20260714235700` | ✅ | `resend_not_before = 2026-08-04` |
| 뷰에 `blocks_direct` | `migration_20260715000100` | ✅ | 무회귀 129/5 동일 |
| `sendClass` 구조적 가드 | `patch_send_outbound_send_class.ps1` | ✅ 배포 `320457a` | tsc 신규 에러 0 |
| `advance_enrollment` 앵커 | `migration_20260715001000` | ✅ | `has_anchor_fix = true` |
| G1/G2 중복 가드 | `migration_20260715001100` | ✅ | `has_g1 = has_g2 = true` |
| 거절 3곳 차단 | `fix_20260715002000` | ✅ | 3건 `do_not_send_party` |
| 하드 바운스 기록 | `fix_20260715003000` | ⬜ **미적용** | PART D-1 |

### A-1. Seed 실측 = **66 / 67** (기존 "clean 67/67"은 무효)

차단 1건 = **First Bight Ventures** (`rejected_stage`, 7/14 15:27). 어제 preflight 이후에 들어온 거절이라 **가드가 없었으면 자기를 거절한 회사에 7/20 후속 콜드가 나갔다.**

### A-2. ⭐ party 단위 가드는 "넓은" 게 아니라 **필요조건** — 4번 증명됨

거절한 사람의 주소와 시퀀스가 쏘는 주소가 **다르다**. 콜드 아웃리치에선 이게 정상이다.

| 회사 | 차단 근거 주소 | 실제 발송 주소 | 주소 단위로 잡히나 |
|---|---|---|---|
| Energy Transition Ventures | craig@energytransitionvc.com | info@energytransitionvc.com | ❌ |
| Extantia Capital | jo@extantia.com | inbound@extantia.com | ❌ |
| First Bight Ventures | collin@firstbight.com | info@firstbight.com | ❌ |
| **Circulate Capital** | arosas@circulatecapital.com | hello@circulatecapital.com | ❌ |
| Azolla / World Fund | (일치) | (일치) | ✓ |

**리뷰 종결. party 단위 유지.**

### A-3. `sendClass` — 구조적 가드

```ts
export type SendClass = 'cold' | 'direct';   // SendOutboundInput.sendClass, default 'cold'
```

| sendClass | 뷰 적용 |
|---|---|
| `cold` | **모든** do-not-send 행이 차단 (party_id 또는 해석된 주소 매치) |
| `direct` | **`blocks_direct = true` 행만** 차단 (unsubscribe / suppress) |

- **기본값 `cold` = fail-closed.** 새 경로가 선언을 잊으면 막힌다. 이게 전부다
- 실행 순서: `[0] blocklist(전역)` → `[0a] do-not-send(콜드)` → `[1] whitelist`
- 42703 폴백 있음 → 배포 순서 사고 없음

호출부 5곳: `sequence-processor:170`·`bulk-mail:230` = **cold** / `email-compose:157`·`communications:213`·`drafts:646` = **direct**.

> **왜 무조건 가드로 박으면 안 됐나**: `v_email_do_not_send`는 **콜드 억제 리스트**지 전역 억제가 아니다(전역은 `email_blocklist`). 무조건 박았으면 `drafts.ts:646 sendApprovedDraft`(답장한 사람에게 AI 답장)가 `reply_positive`에 막혔다. `is_follow_up`은 판별자가 아니다 — `reply_positive OR next_action='follow_up'` = UI 힌트.

### A-4. 중복 발송 근본 원인 — **벌크 리스케줄의 무조건 덮어쓰기**

> **정정 이력**: 이 문서의 최초판(커밋 `d64ea33`)은 원인을 `advance_enrollment` 앵커라고 적었다. **틀렸다.** 진짜 원인은 아래다. 앵커 수정(`migration_20260715001000`)은 그 자체로 옳은 견고성 개선이고 적용 상태를 유지하지만 **이번 사고의 원인이 아니다.**

`sql/20260713150000_climate_sequence_tuesday_9am_pt.sql` **Part 2**:

```sql
-- Part 2: Move all pending sends to the next Tuesday 09:00 PT.
UPDATE app.email_sequence_enrollments e
   SET next_send_at = v_next_send,
       updated_at   = now()
 WHERE e.sequence_id = v_seq_id
   AND e.status = 'active'
   AND e.next_send_at IS NOT NULL;
```

**`GREATEST`가 없다. 무조건 덮어쓴다.** 이미 step 2로 넘어가 7/20을 기다리던 enrollment까지 **6일 앞으로 끌어당겼다.**

타임라인 (모든 관측치와 일치):

| 시각 | 사건 |
|---|---|
| 7/13 21:06:34 (월 14:06 PT) | 시퀀스·스텝·68건 등록 생성. 한 트랜잭션 — `enrolled_at`이 마이크로초까지 동일. 전부 즉시 due |
| 7/13 21:07:12~21:08:08 | 워커 실행 — **이 시점엔 `quiet_hours`가 아직 없음.** step 1을 28건 발송 → advance → `next_send_at = enrolled+7 = **7/20**` |
| 7/13 21:08 이후 | **마이그레이션 적용.** Part 1이 `quiet_hours` 설정. **Part 2가 전 active enrollment의 `next_send_at`을 `7/14 09:00 PT = 16:00 UTC`로 덮어씀** — 7/20을 기다리던 28건 포함 |
| 7/14 16:00:19 (화 09:00 PT) | 27건 step 2 발송 ← **step 1로부터 19시간. 여기서 투자자를 잃었다** |
| 7/14 16:01:19~16:02:41 | 나머지 40건 step 1 발송 |

이후 값도 전부 맞는다: step 2 그룹 → `enrolled+14 = 7/27` ✓, step 1 그룹 → `enrolled+7 = 7/20` ✓.

**잔여 1건 미해명**: Planet A Ventures는 7/13 21:07:44에 step 1을 받았는데(28건 중 하나) 7/14에 step 2를 안 받았다. 68 = 27(step2) + 41(step1)로 딱 맞지 않는다. 사고 결론은 안 바뀌지만 기록해 둔다.

### A-4b. 참고 — `advance_enrollment` 앵커 수정 (사고 원인 아님, 견고성 개선)

```sql
-- 이전
next_send_at = v_enrolled_at + (v_next_day_offset || ' days')::INTERVAL
```

`day_offset`이 "메일 간 간격"이 아니라 **등록 시점에 고정된 절대 캘린더**. step N이 늦으면 step N+1이 그 지연을 안 기다린다.

```sql
-- 수정 후
gap          = next_offset - cur_offset          -- floor 1일
next_send_at = GREATEST(enrolled_at + next_offset, now() + gap)
```

정시면 두 항이 같아 **동작 무변화**. 늦은 스텝만 이동.

- **`GREATEST`는 NULL을 무시한다** → 다음 스텝 없을 때 실제 시각을 뱉어 유령 스텝을 예약함. **명시적 `IS NULL` 분기로 기존 NULL 시맨틱 보존**
- **소급 적용 안 됨** — 이미 세팅된 `next_send_at`은 옛 앵커 값. 다음 발송부터 적용

### A-5. G1/G2 — 발송 시점 하드 가드

- **[G1]** 같은 party가 **2일** 내 `external_data->>'source'='sequence'` outbound를 받았으면 제외. DB의 실제 cadence는 전부 3일 이상(High Priority 0/3/7, Intel Inside 0/5, Seed·Climate 0/7/14/21) → **48h floor는 의도된 발송을 건드릴 수 없다**
- **[G2]** `DISTINCT ON (e.party_id)` — 같은 배치 내 동일 party 중복 방지. 탈락분은 다음 실행에서 G1이 2일 잡아둠. 현재 no-op

**왜 2겹**: A-4b는 *한* 경로를 고치고, A-5는 원인이 무엇이든 결과를 불가능하게 만든다. **A-4의 진짜 원인은 A-4b가 아니라 벌크 리스케줄이었고, 그걸 막은 건 G1이다.** 이번 세션의 판단 중 유일하게 처음부터 옳았던 것 — 원인을 모르는 채로도 초크포인트에서 결과를 막는다.

### A-6. 거절 투자자 차단 (party 단위)

수신 메일 100건 전수 판독. 신규 3건:

| 회사 | 발신 | 내용 | 취소된 발송 |
|---|---|---|---|
| NFX | qed@nfx.com | not the right fit for NFX at this time | 7/20 |
| Aristos Ventures | info@aristosventures.com | no longer make new investments (파트너 작고, 청산 중) | 7/20 |
| Circulate Capital | arosas@circulatecapital.com | with regret... not proceeding | 7/27 |

기존: Extantia(**두 번** 거절), ETV, First Bight, Azolla(form), World Fund(쿨다운). **총 8곳 차단.**

**거절이 아닌 것 — 절대 기록 금지**: Playground Global / Lux Capital / Breakout Ventures / Founder Collective (전부 `info+noreply@`·`contact@` 오토리스폰더), CTAN(지원 안내), Azolla(Interest Form 요청 = 관심), **Pangaea Ventures(사람. Andrew Haughian, 7/8 미팅)**.

---

## PART B — 종결된 것

### B-1. D-2 (`template_id` dedup 우회) — **전제 오류로 종결**

| source | sends | parties | 기간 |
|---|---|---|---|
| sequence | **529** | 138 | 6/17 → 7/14 |
| untagged (수동/컴포즈/AI답장) | 47 | 12 | 6/09 → 7/13 |
| **bulk** | **29** | **1** | 6/15 → 6/29 |
| reminder | 9 | 0 (party_id null) | 6/22 → 6/30 |

**bulk은 party 1개(테스트)에만 나갔다.** dedup이 뚫린다는 건 — 뚫릴 발송이 없었다. 90일 outbound 614건 중 template_id 있는 건 14건(최근 추가된 기록 로직 때문).

**bulk 실사용 시작 전 재개할 것**: ① `sent_at` → `occurred_at` (`status='sending'` 행은 `sent_at` NULL이라 recency 가드에서 탈락), ② UI `recentDays || undefined`가 **0과 미설정을 구별 못 함** → resolver 기본값 구현 불가, ③ dedup 키를 template_id → `external_data->>'source'` / send_class로.

### B-2. 기각된 가설 — 전부 **코드 추론 → 데이터가 반박**

| 가설 | 출처 | 반박 |
|---|---|---|
| "시퀀스가 뷰를 가드로 쓴다" | 오후 핸드오프 | `has_dns_guard = false` |
| "World Fund는 email null이라 무해" | 저녁 세션 | `recipient_email` 살아있음 |
| "template_id dedup 우회가 2번 접촉 원인" | 저녁 핸드오프 | bulk은 party 1개에만 |
| "cross-sequence 이중 등록이 원인" | 이번 세션 | 활성 중복 0건 |
| "`FCC Climate Tech` day_offset 0,0이 원인" | 이번 세션 | 휴면. sends 0 / enrollments 0 |
| "원본 `15 min`과 `(copy)`가 명단 중복" | 이번 세션 | **겹치지 않음.** climate/deeptech vs life science 섹터 분리 |
| "`advance_enrollment` 앵커가 근본 원인" | 이번 세션 | 벌크 리스케줄 Part 2였음. `enrolled_at` 양쪽 동일 |
| "`day_offset`을 나중에 편집했다" | 이번 세션 | 스텝 `created_at = updated_at`, 수정 이력 없음 |
| "`quiet_hours` {10:00, 09:00}가 뒤집혔다" | 이번 세션 | **의도된 화요일 9시 창.** 규칙은 6/29 핸드오프 L70에 이미 문서화돼 있었음 |

**성과가 난 건 전부 먼저 측정한 쪽이었다.**

---

## PART C — 미해명 (원인 살아있음, 결과는 G1이 막는 중)

### C-1. ✅ Climate 27건 step 2 조기 발송 — **해결됨. PART A-4 참조.**

`sql/20260713150000_climate_sequence_tuesday_9am_pt.sql` Part 2의 무조건 `UPDATE ... SET next_send_at = v_next_send`가 원인. 잔여 미해명은 Planet A 1건뿐.

### C-2. `15 min...` step 0 = **59 sends / 30 parties** — party당 약 2회

동명 시퀀스 2개가 합산된 것인지 재등록인지 불명. cadence 쿼리에서 `15 min on a filler tech...`의 스텝이 **두 벌씩** 나왔다 → 동명 시퀀스 2개 존재 가능성.

---

## PART D — 실행 대기

### D-1. 하드 바운스 기록 — `fix_20260715003000_record_hard_bounces.sql` (**✅ 적용됨**)

> 결과: 죽은 주소 **11개** 기록 (13건 중 Chevron / `test@test.com` 제외). 헬스 뷰 `ok 126 → 119`, `do_not_send_email 0 → 7` — **활성 enrollment 7건이 죽은 주소를 향하고 있었다.** Seed 7/20 배치가 64 → 57로 감소.

**적용 전 프리뷰 필수** (단독 실행). NDR 본문을 350자 발췌로만 봤다:

```sql
SELECT lower(substring(coalesce(c.body_plain, c.body_summary, '') from '<([^<>]+@[^<>]+)>')) AS failed_recipient,
       CASE
         WHEN coalesce(c.body_plain, c.body_summary, '') LIKE '%Trend Micro%'         THEN 'our_ip_blocked'
         WHEN coalesce(c.body_plain, c.body_summary, '') LIKE '%RCPT: 550%'           THEN 'hard_bounce'
         WHEN coalesce(c.body_plain, c.body_summary, '') LIKE '%DNS lookup failure%'  THEN 'domain_dead'
         WHEN coalesce(c.body_plain, c.body_summary, '') LIKE '%Connect failure%'     THEN 'unreachable'
         ELSE 'other'
       END AS kind,
       count(*) AS ndrs,
       max(c.occurred_at)::date AS last_ndr
FROM app.communications c
WHERE c.channel::text = 'email'
  AND c.direction::text = 'inbound'
  AND c.from_address = 'postmaster@marinebiogroup.com'
  AND c.deleted_at IS NULL
  AND c.occurred_at >= now() - interval '120 days'
GROUP BY 1, 2
ORDER BY 2, 1;
```

`failed_recipient`가 NULL이면 정규식 불일치 → INSERT는 0건(무해)이지만 그 전에 알아야 한다.

**문제**: MailCarrier가 NDR을 우리에게 배달 → `from_address = postmaster@marinebiogroup.com`, `party_id = MarineBio Group`(**우리 자신**). 대상 party와 연결이 끊겨 `bounce_hard`가 **0건**이고 시퀀스가 죽은 주소를 계속 때린다. 6/24와 6/30에 **같은 주소로 두 번씩** 반송됐다.

**죽은 주소 11개**:
```
ventures@baincapital.com          550 User Unknown
contact@kdtvc.com                 550 inactive      (andrew@kdtvc.com 도 존재하지 않음)
emailinquiries@archventure.com    550 Access denied
info@sanderling.com               550 undeliverable
info@sofinnovapartners.com        550 Access denied
info@springrockventures.com       550 Access denied
info@avalon-ventures.com          550 Access denied
startups@planet-a.com             550 inactive
info@daylightpartners.com         DNS 실패
info@dallasventurepartners.com    연결 실패
test@test.com                     DNS 실패   <- 테스트 데이터가 실서비스에
```

**⚠️ 설계: 바운스는 주소 단위. `party_id = NULL`로 넣는다.**

| | 차단 범위 | 이유 |
|---|---|---|
| 거절 (`fix_20260715002000`) | **party 단위** | 회사가 "안 한다"고 했음 |
| 바운스 (`fix_20260715003000`) | **주소 단위만** | 주소가 죽었을 뿐, 회사는 아무 말도 안 함 |

뷰는 `(email_lower, party_id)`로 그룹핑하고 가드는 둘을 **따로** 매치하므로 `party_id NULL` → 주소 하나만 차단. `emailinquiries@archventure.com`이 막혔다고 **ARCH를 통째로 죽이면 안 된다.**

**⚠️ Chevron 제외**: `554 ... blocked using Trend Micro Email Reputation Services for this 49.254.118.167` — **우리 IP가 블랙리스트**지 Chevron 주소 문제가 아니다. `bounce_hard`로 찍으면 **우리 인프라 문제로 리드를 죽인다.** World Fund 오토리스폰더와 같은 함정.

검증:

```sql
SELECT count(*) AS bounce_rows
FROM app.v_email_do_not_send
WHERE party_id IS NULL AND outcomes LIKE '%bounce_hard%';
```

```sql
SELECT send_status, count(*)
FROM app.v_enrollment_send_health
WHERE enrollment_status = 'active'
GROUP BY send_status;
```

### D-2. 발신 IP 평판 — **인프라 작업**

`49.254.118.167`이 Trend Micro ERS에 등재. D-1이 악순환의 앞쪽(죽은 주소 반복 발송)을 끊지만, **등재 해제는 별도**: https://www.ers.trendmicro.com/reputations 에서 delisting 요청. SPF/DKIM/DMARC 점검도 같이.

---

## PART E — 미결 (우선순위)

1. **[D-1] 하드 바운스 적용** — 프리뷰 → INSERT → 검증
2. **[C-1] Climate 27건 원인** — `email_sequence_steps.updated_at` 한 줄
3. **[7/20 전] `FCC Climate Tech` day_offset 0,0 수정** — 휴면이지만 등록되면 사고. floor에 의존 금지
4. **배포 후 스모크** — 컴포즈에서 Azolla(폼 제출) 앞 수동 발송이 **나가야** 정상(direct). 워커 실행 후 헬스 뷰 유지 확인
5. **IP delisting + SPF/DKIM/DMARC** (D-2)
6. **`unsubscribe_request` → `email_blocklist` 동기화** — `blocks_direct`는 임시 방어막. 전역 억제의 정본은 blocklist여야 함
7. **시퀀스 이름 중복 정리** — `15 min on a filler tech...` 동명 2개, `(copy)` 동명 2개, `삭제 - ` 잔재 1개. `step_order` 기준 혼재(0-based: Seed/Climate Tech/High Priority, 1-based: Climate FCC/Intel Inside)
8. **`reminder` 9건 `party_id` null** — party 단위 가드가 이 경로를 못 잡음(주소 매치만)
9. **World Fund 8/4 재개 감시** — `next_send_at = 7/27`이 과거라 8/4에 즉시 step 3 발송
10. **Lowercarbon 이중 노출 대응** (이월) — $5M 구버전 + 민감 IP 둘 다 submitted:
    > Quick update since our submission: we've since finalized the round at **$3M on a $27M pre-money** (previously $5M/$30M), with use of funds evenly split $1M each across applied R&D, IP, and operations.
    >
    > (2문장째는 상황 판단 — 민감 IP 제출을 먼저 상기시키는 게 역효과일 수 있음. 상대가 IP를 물으면 그때 데이터룸으로)
11. **tsc 선행 에러 15건 / 5파일** (이월) — `applications-list-client.tsx`(badge ×2), `parties.ts`(sectorFocus ×2), `decompose-actions.ts`(SbClient), `fill-application.ts`(×9), `inspect-form.ts`(×1). 배포는 통과 중 → Railway 로그로 `ignoreBuildErrors` 확인
12. Material Impact 파트너 직송 (백로그), 익명화 2건 nda_only 미보관, 기후펀드 백필 70개

---

## PART F — 컨벤션 (이번 세션 추가분)

기존 evening PART E 전부 유효. 추가:

- **가드는 초크포인트에.** 하루에 같은 부류 버그를 세 번 봤고 전부 가드가 호출부에 살아서였다. 초크포인트는 `get_due_enrollments()`(시퀀스), `sendOutboundEmail()`(전 경로)
- **가드를 넣기 전에 "무엇을 막게 되는지" 먼저 열거할 것.** 억제 리스트는 *어떤 종류의 발송을* 막는지가 semantics의 절반이다
- **뷰/함수의 semantics를 이름으로 추측하지 말 것** — `is_follow_up`을 "직접 발송 허용"으로 오독할 뻔했다
- **`GREATEST`/`LEAST`는 NULL을 무시한다** — NULL이 "없음"인 자리에 쓰면 조용히 값을 만든다. 명시적 `IS NULL` 분기로 감쌀 것
- **스케줄 오프셋의 앵커를 명시할 것** — `day_offset`이 "등록 이후"인지 "직전 발송 이후"인지가 스키마 어디에도 없었고 이름은 후자로 읽힌다. 실제는 전자였다
- **`CREATE OR REPLACE VIEW`는 트레일링 컬럼 추가만 가능** — 중간 삽입/타입 변경 불가. 소비자가 부분집합만 select하면 안전
- **PostgREST 42703은 뷰 버전 스큐 신호** — 새 컬럼 의존 코드는 42703 폴백 경로를 가질 것
- **`next_send_at`은 앞으로만 밀 수 있다.** 이 컬럼을 쓰는 모든 코드는 `GREATEST(next_send_at, new_value)`여야 한다. 무조건 덮어쓰는 곳이 둘 있었다 — `20260713150000` Part 2(**사고 원인**)와 `sequence-processor.ts`의 quiet-hours 분기(`.update({next_send_at: nextAt})`, 비교 없음, `updated_at`도 안 찍어 원장에 흔적이 없음). 후자는 **미수정**
- **벌크 리스케줄은 재앙 반경이 크다.** 한 문장이 68건의 일정을 6일 당겼다. `WHERE`에 "아직 안 나간 것만" 조건이 있어야 했다
- **핸드오프에 틀린 근본 원인을 남기지 말 것 — 공백보다 나쁘다.** 다음 세션이 믿는다. 확정 못 했으면 미해명으로 적을 것
- **`.ps1`은 ASCII-only. 한국어 페이로드를 PowerShell 문자열에 넣지 말 것.** 넣으면 PS 5.x가 CP949로 파싱해 히어스트링 따옴표가 깨진다(2026-07-15에 실제 발생). 한국어 문서는 **패치하지 말고 UTF-8 BOM .md로 통째 교체**할 것
- **차단 범위를 사유에 맞출 것** — 사람의 거절 = party 단위, 주소 바운스 = 주소 단위(`party_id NULL`). 기계 실패(오토리스폰더, 우리 IP 차단)로 리드를 은퇴시키지 말 것
- **mover가 `docs/handoff/<today>`로 라우팅** — UTC 날짜라 한국 시간 밤에는 다음 날로 간다. 핸드오프 내부 경로 참조와 어긋날 수 있음
- **Downloads를 비울 것** — 옛 파일이 남아 있으면 mover가 커밋된 리포 파일을 덮어쓴다. 이번에 `M` 3건 발생(내용은 동일, CRLF 경고뿐이었음). `git diff`로 확인 후 `git checkout --`

---

## 파일 이동

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{ glob = 'fix_20260715003000_record_hard_bounces*.sql'; dest = 'C:\dev\mbg-project\sql'; name = 'fix_20260715003000_record_hard_bounces.sql' },
  @{ glob = 'handoff_2026-07-15_session*.md';              dest = 'C:\dev\mbg-project\docs\handoff\2026-07-15'; name = 'handoff_2026-07-15_session.md' }
)
foreach ($m in $map) {
  $src = Get-ChildItem (Join-Path $dl $m.glob) -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($src) {
    Unblock-File $src.FullName
    [System.IO.Directory]::CreateDirectory($m.dest) | Out-Null
    [System.IO.File]::Copy($src.FullName, (Join-Path $m.dest $m.name), $true)
    Remove-Item $src.FullName
    Write-Output ("MOVED: " + $m.name)
  } else { Write-Output ("NOT FOUND: " + $m.glob) }
}
```

## Finish

```powershell
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup
git status -sb
git add sql/ docs/
git commit -m "sql: record hard bounces at address level from NDR bodies; docs: 2026-07-15 session handoff"
git push origin marinebiogroup
```

푸시 = 웹 자동 배포. **이 커밋은 sql/docs만이라 앱 코드 영향 없음** — DB 반영은 SQL Editor 실행이 정본이다.

---

## 다음 세션 킥오프 (복붙)

```
mbg-project 이어가자. docs/handoff/2026-07-15/handoff_2026-07-15_session.md 기준.

상태: 7/20 발송 97통 (Climate 40 + Seed 57), 7/27 Climate 22. 헬스 ok 119 / party 8 / email 7.
- get_due_enrollments 가드 적용 (has_dns_guard=true)
- sendOutboundEmail에 sendClass 'cold'|'direct' 구조적 가드, default cold (커밋 320457a 배포됨)
- advance_enrollment 앵커 수정 + G1(2일 min-gap)/G2(DISTINCT ON party_id) 적용
- 거절 8곳 party 단위 차단 (NFX/Aristos/Circulate 신규) + 죽은 주소 11개 email 단위 차단

중복 발송 근본 원인 = sql/20260713150000_climate_sequence_tuesday_9am_pt.sql Part 2.
  UPDATE ... SET next_send_at = v_next_send WHERE status='active' -- GREATEST 없음
  step 2로 넘어가 7/20을 기다리던 28건을 7/14로 당김 -> 19시간 만에 2통 -> 투자자 클레임.
  advance_enrollment 앵커는 원인이 아니었음(문서 최초판의 오류, 정정됨).
  quiet_hours {10:00,09:00}은 의도된 화요일 9시 창이지 오타가 아님.

최우선:
1. 7/20 발송 관찰 (97통). 워커가 자동 실행. 발송 후 헬스 뷰로 실측 확인
2. sequence-processor.ts quiet-hours 분기의 무방비 쓰기 (미수정).
   defer_enrollment RPC로 GREATEST 적용 필요. G1이 막고 있어 급하지 않음
3. FCC Climate Tech day_offset 0,0 수정 (휴면이지만 지뢰)
4. IP 49.254.118.167 Trend Micro delisting + SPF/DKIM/DMARC
5. 타임존: Climate의 09:00 PT가 유럽엔 18:00, 도쿄엔 01:00. app.parties에 country 컬럼
   없음(42703) -> 백필 선행. 사용자 지시로 백로그

핵심 교훈: 코드 읽고 원인 추론한 가설은 이번 세션에 6개 전부 데이터에 반박당했다.
성과는 전부 먼저 측정한 쪽에서 나왔다. 가드는 초크포인트에.
```
