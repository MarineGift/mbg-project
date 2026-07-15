# Handoff (증보) — 시퀀스 중복 발송 근본 원인 + 2중 차단 (2026-07-14 야간, D-2 후속)

`handoff_2026-07-14_night.md`의 D-2를 파다가 **실제 사업 피해가 확인된 버그**를 찾은 후속 기록.

> ## 사업 피해
> 시퀀스가 같은 회사에 **19시간 간격으로 2통**을 보냈고, 투자자에게서 클레임 + "관심 없음" 회신을 받음.

---

## PART A — D-2는 종결 (전제 오류)

evening 핸드오프 D-4 *"template_id=null이라 dedup 우회 → 2주 새 2번 접촉의 원인"* → **오진.**

| source | sends | parties | 기간 |
|---|---|---|---|
| sequence | **529** | 138 | 6/17 → 7/14 |
| untagged (수동/컴포즈/AI답장) | 47 | 12 | 6/09 → 7/13 |
| **bulk** | **29** | **1** | 6/15 → 6/29 |
| reminder | 9 | 0 (party_id null) | 6/22 → 6/30 |

- **bulk은 party 1개(테스트)에만 나갔다.** `already_sent`의 template_id 키가 뚫린다는 건 — 뚫릴 발송 자체가 없었음
- 90일 outbound 614건 중 template_id 있는 건 14건. `send-outbound.ts`의 template_id 기록이 최근 추가분이라 그럼
- **D-2 종결.** bulk 실사용 시작 전 재개할 것: ① `sent_at` → `occurred_at` (`status='sending'` 행은 `sent_at` NULL이라 recency 가드에서 탈락), ② UI `recentDays || undefined`가 0과 미설정을 구별 못 함 → resolver 기본값 구현 불가, ③ dedup 키를 template_id → `external_data->>'source'` / send_class로

기각된 가설들(전부 코드 추론 → 데이터가 반박):
- "cross-sequence 이중 등록" → 활성 시퀀스 중복 0건
- "`Investor Cold Outreach - FCC Climate Tech`의 day_offset 0,0이 원인" → 그 시퀀스는 **sends 0 / enrollments 0, 휴면 초안**
- "원본 `15 min...`과 `(copy)`가 같은 명단에 동시 발송" → **명단이 겹치지 않음.** 원본=climate/deeptech, copy=life science. 섹터별 의도적 분리

---

## PART B — 진짜 원인: `advance_enrollment`의 앵커

`pg_get_functiondef` 확인:

```sql
next_send_at = v_enrolled_at + (v_next_day_offset || ' days')::INTERVAL
```

**`enrolled_at` 기준. 직전 발송 시각이 아니다.** `day_offset`이 "메일 간 간격"이 아니라 **등록 시점에 고정된 절대 캘린더**로 동작한다. step N이 늦게 나가면 step N+1은 이미 due → 다음 워커 실행에서 즉시 발송.

실측 (`Climate Investor Cold Outreach -- FCC`):

```
step 1   68건   7/13 21:07 ──────────► 7/14 16:02
step 2   27건              7/14 16:00 ─► 7/14 16:01   ◄ step 1이 아직 나가는 중
```

**27개 party가 19시간 안에 2통.** 해당 등록은 7/7경 생성 → step 1이 7/13에야 발송(6일 지연) → step 2는 `enrolled_at + 7 = 7/14`가 due라 바로 따라붙음.

`Investor Cold Outreach - FCC Seed`는 step 0이 제때 나가서 무사: 6/30 → 7/6 → 7/13, 주간 간격 정상.

---

## PART C — 조치: 2겹

### C-1. 원인 제거 — `migration_20260715001000_fix_advance_enrollment_anchor.sql`

```sql
gap          = next_offset - cur_offset          -- 최소 1일
next_send_at = GREATEST(enrolled_at + next_offset, now() + gap)
```

- **정시 발송이면 두 항이 같아서 동작 무변화.** 늦은 스텝만 이동 — 지연분만큼 나머지 시퀀스를 뒤로 밀고, 뭉치지 않는다
- `GREATEST`는 **NULL을 무시**한다. 다음 스텝이 없을 때 `GREATEST(NULL, now()+gap)`이 실제 시각을 뱉어 존재하지 않는 스텝을 예약하게 됨 → **명시적 `IS NULL` 분기로 기존 NULL 시맨틱 보존**
- 최소 1일 floor는 gap 0인 스텝용 안전망. 해당 시퀀스(`FCC Climate Tech` step 0·1 둘 다 offset 0)는 휴면이지만 **floor에 의존하지 말고 day_offset을 따로 고칠 것**
- plpgsql이라 본문에 세미콜론 불가피 → **단독 실행 필수**

### C-2. 발송 시점 하드 가드 — `migration_20260715001100_guard_min_gap_get_due_enrollments.sql`

`migration_20260714235600` 위에 2개 추가. 나머지는 바이트 동일.

- **[G1] min-gap**: 해당 party가 최근 **2일** 내 `external_data->>'source'='sequence'` outbound를 받았으면 제외. DB의 실제 cadence는 전부 3일 이상(High Priority 0/3/7, Intel Inside 0/5, Seed·Climate 0/7/14/21)이라 **48h floor는 의도된 발송을 건드릴 수 없다.** 7/20 Seed는 직전이 7/13 → 7일 간격, 안전
- **[G2] `DISTINCT ON (e.party_id)`**: 같은 배치에서 같은 party의 enrollment 2건이 동시에 due면 G1이 못 잡는다(둘 다 아직 안 보냈으니 서로를 못 봄). 먼저 due한 것만 반환. 탈락분은 버려지지 않고 다음 실행에서 G1이 2일 잡아둔다. **오늘 기준 no-op** (활성 시퀀스 중복 0건)

**왜 2겹인가**: 001000은 *알려진* 원인을 없앤다. 001100은 원인이 무엇이든 결과를 불가능하게 만든다. 7/14 하루에 같은 부류의 버그를 두 번 찾았고, 두 번 다 **가드가 초크포인트가 아닌 곳에 살아서** 생긴 일이었다. `get_due_enrollments()`가 초크포인트다.

---

## PART D — 실행 순서

### 1. `migration_20260715001000_fix_advance_enrollment_anchor.sql` — 단독 실행

검증 (별도 실행) — 잘리지 않았는지:

```sql
SELECT pg_get_functiondef(p.oid) LIKE '%GREATEST%' AS has_anchor_fix
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.prokind = 'f' AND p.proname = 'advance_enrollment';
```

`true`여야 함.

### 2. `migration_20260715001100_guard_min_gap_get_due_enrollments.sql` — 단독 실행

검증 (별도 실행):

```sql
SELECT pg_get_functiondef(p.oid) LIKE '%DISTINCT ON%'       AS has_g2,
       pg_get_functiondef(p.oid) LIKE '%INTERVAL ''2 days''%' AS has_g1
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.prokind = 'f' AND p.proname = 'get_due_enrollments';
```

둘 다 `true`.

### 3. 무회귀 — 헬스 뷰 (별도 실행)

```sql
SELECT send_status, count(*)
FROM app.v_enrollment_send_health
WHERE enrollment_status = 'active'
GROUP BY send_status;
```

**129 ok / 5 do_not_send_party 유지.** (헬스 뷰는 G1/G2를 반영하지 않는다 — 뷰는 do-not-send만 본다. 이 쿼리는 순수 무회귀 확인용)

### 4. 발송 캘린더 확인 — 뭉친 데 없는지 (별도 실행)

```sql
SELECT sequence_name, next_send_at::date AS due_date, count(*) AS enrollments
FROM app.v_enrollment_send_health
WHERE enrollment_status = 'active'
GROUP BY 1, 2
ORDER BY 2, 1;
```

**같은 party 그룹이 이틀 이내에 연달아 잡혀 있으면 보고할 것.** 이미 세팅된 `next_send_at`은 옛 앵커로 계산된 값이라 001000이 소급 적용되지 않는다 — 다음 발송부터 새 앵커가 적용된다.

---

## PART E — 미결

1. **[7/20 전] `FCC Climate Tech`의 day_offset 0,0 수정** — 휴면이지만 등록되면 사고. floor에 의존 금지
2. **시퀀스 이름 중복 정리** — `15 min on a filler tech...` 동명 2개, `(copy)` 동명 2개, `삭제 - ` 접두사 잔재 1개. 이름이 같으면 헬스 뷰·쿼리·핸드오프에서 구분 불가. `step_order` 기준도 혼재(0-based: Seed/Climate Tech/High Priority, 1-based: Climate FCC/Intel Inside)
3. **`15 min...` step 0 = 59 sends / 30 parties** — 같은 스텝이 party당 약 2회. 미해명. 동명 시퀀스 2개가 합산된 것인지 재등록인지 확인 필요
4. **클레임 투자자 후속** — 어느 회사인지 특정하고 `email_send_outcomes`에 `outcome='rejected_other'` 기록 → 뷰가 영구 차단. 사과 메일은 `sendClass='direct'`라 가드에 안 막힘
5. **`reminder` 9건 party_id null** — 오늘 넣은 party 단위 가드가 이 경로를 못 잡음(주소 매치만). 외부 발송이면 D 항목
6. 이월: D-3(unsubscribe → blocklist 동기화), Lowercarbon 정정, tsc 선행 15건, World Fund 8/4 재개 감시

---

## PART F — 컨벤션 추가

- **`GREATEST`/`LEAST`는 NULL을 무시한다** — NULL이 "없음"을 뜻하는 자리에 쓰면 조용히 값을 만들어낸다. 명시적 `IS NULL` 분기로 감쌀 것
- **스케줄 오프셋의 앵커를 명시할 것** — `day_offset`이 "등록 이후 N일"인지 "직전 발송 이후 N일"인지가 스키마 어디에도 없었고, 이름만으로는 후자로 읽힌다. 실제는 전자였다
- **가드는 초크포인트에** — 오늘 세 번째 확인. `get_due_enrollments()`(시퀀스), `sendOutboundEmail()`(전 경로)가 초크포인트다

---

## 파일 이동

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{ glob = 'migration_20260715001000_fix_advance_enrollment_anchor*.sql';      dest = 'C:\dev\mbg-project\sql'; name = 'migration_20260715001000_fix_advance_enrollment_anchor.sql' },
  @{ glob = 'migration_20260715001100_guard_min_gap_get_due_enrollments*.sql';  dest = 'C:\dev\mbg-project\sql'; name = 'migration_20260715001100_guard_min_gap_get_due_enrollments.sql' },
  @{ glob = 'handoff_2026-07-14_night2_sequence_double_send*.md';               dest = 'C:\dev\mbg-project\docs\handoff\2026-07-14'; name = 'handoff_2026-07-14_night2_sequence_double_send.md' }
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
git commit -m "fix(sequence): anchor next_send_at on actual send + min-gap/one-per-party guards in get_due_enrollments"
git push origin marinebiogroup
```

푸시 = 웹 자동 배포. **이 커밋은 sql/docs만이라 앱 코드 영향 없음** — DB 반영은 SQL Editor 실행이 정본이다. 파일만 올라가고 함수는 안 바뀐다는 뜻이니, **PART D를 먼저 실행할 것.**

---

## 다음 세션 킥오프 (복붙)

```
mbg-project 이어가자. docs/handoff/2026-07-14/handoff_2026-07-14_night2_sequence_double_send.md 기준.

사업 피해: 시퀀스가 같은 회사에 19시간 간격 2통 -> 투자자 클레임 + "관심 없음" 회신.

근본 원인 (pg_get_functiondef로 확정):
- advance_enrollment: next_send_at = enrolled_at + day_offset. 직전 발송이 아니라 등록일 기준.
  step N이 늦으면 step N+1이 이미 due -> 즉시 발송. Climate step1(7/13 21:07~7/14 16:02)과
  step2(7/14 16:00~16:01)가 겹쳐 27개 party가 19시간 내 2통.
- Seed는 step0이 정시라 무사: 6/30 -> 7/6 -> 7/13 주간. 7/20 발송 안전.

조치 2겹 (DB 적용 여부 확인할 것):
1. migration_20260715001000_fix_advance_enrollment_anchor.sql
   next_send_at = GREATEST(enrolled_at + next_offset, now() + gap), gap floor 1일.
   GREATEST가 NULL 무시하므로 다음 스텝 없을 때는 명시적 IS NULL 분기로 NULL 유지.
2. migration_20260715001100_guard_min_gap_get_due_enrollments.sql
   G1: 같은 party가 2일 내 sequence outbound 받았으면 제외 (실제 cadence는 전부 3일+ 라 안전)
   G2: DISTINCT ON (party_id) - 같은 배치 내 동일 party 중복 방지. 현재 no-op

D-2(template_id dedup)는 종결 - 전제 오류. bulk은 party 1개(테스트)에만 나감.

기각된 가설 (전부 코드 추론 -> 데이터가 반박):
- cross-sequence 이중 등록 (활성 중복 0)
- FCC Climate Tech day_offset 0,0 (휴면. sends 0/enrollments 0)
- 원본 15min과 (copy) 명단 중복 (겹치지 않음. climate vs life science 섹터 분리)

미결: FCC Climate Tech day_offset 0,0 수정, 시퀀스 동명 정리, 15min step0 59sends/30parties 미해명,
클레임 투자자 outcome 기록, reminder party_id null
```
