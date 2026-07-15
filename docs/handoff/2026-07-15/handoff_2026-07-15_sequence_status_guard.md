# Handoff — 2026-07-15 (2) 시퀀스 status 가드 [G3] + 7/20 타이밍 가설

`docs/handoff/2026-07-15/handoff_2026-07-15_session.md`의 **PART E-2**를 처리한 세션. 그 문서를 대체하지 않고 **덧붙인다.**

> ## 이번 산출물
> **[G3] 시퀀스 status 가드** — `get_due_enrollments`에 `JOIN app.email_sequences ... status = 'active'`.
> UI에서 시퀀스를 일시정지/아카이브해도 메일이 나가던 구멍을 초크포인트에서 닫는다.
> 파일 2개, `sql/docs`만. **앱 코드 변경 없음 → 7/20 발송 경로에 배포 리스크 0.**
>
> ## ⚠️ 그리고 발송을 멈추고 봐야 할 게 하나 나왔다
> **7/20에 40통이 안 나갈 가능성이 높다** (사고 아님 — 누락/지연). PART 2. **쿼리 한 방이면 판정된다.**

---

## PART 0 — 왜 E-2를 골랐나 (E-3은 왜 뺐나)

| 후보 | 판단 |
|---|---|
| **E-2 시퀀스 status 가드** | **채택.** DB 마이그레이션만, 반경 작음, 7/20 전에 넣을 수 있음 |
| E-3 quiet-hours 무방비 쓰기 | **보류.** 아래 재평가 참조 — 실동작 버그가 아니었다 |

### E-3 재평가 — **핸드오프의 "무방비 쓰기 = 위험" 프레이밍은 과장이다**

`sequence-processor.ts:114`의 `.update({ next_send_at: nextAt })`는 비교가 없지만, **이 줄에 도달하는 모든 행에서 이미 `GREATEST`와 동치다:**

- `get_due_enrollments`는 `next_send_at <= now()`인 행만 돌려준다 → **`next_send_at`은 항상 과거**
- `evaluateQuietHours`의 blocked 분기 4개를 전수 확인 → `nextAllowedAt`은 **항상 미래**
  - `within_quiet_hours` / `weekend_blocked` → `computeNextAllowed()`는 `now + 30분` 또는 `now + 1일 + 30분` 또는 `다음 월요일` (`quiet-hours.ts:186-214`)
  - `invalid_config` / `invalid_timezone` → `nextAllowedAt` 없음 → 프로세서가 `Date.now() + 30분`으로 폴백 (`:106`)
- 따라서 `GREATEST(past, future) = future = nextAt`. **덮어쓰기가 앞으로 당길 경로가 없다.**

실제 결함은 두 개뿐이고 둘 다 급하지 않다:
1. **`updated_at`을 안 찍는다** → 원장에 흔적이 없다 (관측성)
2. **불변식이 다른 파일에 산다** — `get_due_enrollments`의 `WHERE`가 깨지면 이 줄이 조용히 위험해진다 (견고성)

**`defer_enrollment` RPC를 넣어도 동작은 한 바이트도 안 바뀐다.** 7/20 5일 전에 발송 경로 TS를 건드릴 이유가 없다. → **E-3 우선순위 하향.** (그리고 PART 2의 드리프트도 이 RPC로는 못 고친다.)

---

## PART 1 — [G3] 시퀀스 status 가드

### 1-1. 문제 (2026-07-15 양쪽에서 재확인)

**발송 경로 어디에서도 `app.email_sequences.status`를 읽지 않는다.**

```sql
-- public.get_due_enrollments(): app.email_sequences 에 조인 자체가 없음
WHERE e.status = 'active'::app.enrollment_status   -- enrollment status, 시퀀스 아님
```
```ts
// src/lib/utils/sequence-processor.ts:82
.select("id, from_account_id, quiet_hours")   // status가 프로젝션에 없음
```

A-7에서 Seed를 멈출 때 드러난 그 구멍. **archive해도 메일은 계속 나간다. UI 일시정지는 아무 일도 안 한다.** 7/14~15에 세 번 본 것과 같은 부류 — 가드가 초크포인트에 없음.

### 1-2. 무엇을 막게 되는가 (컨벤션대로 4개 값 전수 열거)

`app.email_sequence_status = draft | active | paused | archived` — `src/types/database.ts:6999`(생성된 타입)에서 확인.

| 값 | G3 적용 후 | 오늘 실제 영향 |
|---|---|---|
| `active` | 그대로 발송 | **Climate은 `'active'`로 명시 생성됨** (`20260713140000_...create.sql:101`) → 7/20 40통 무영향 |
| `paused` | **차단** | 이 파일의 목적. UI 일시정지가 이제 실제로 동작 |
| `archived` | **차단** | 실질 무변화 — archived는 Seed뿐이고 enrollment가 이미 cancelled |
| `draft` | **차단** | 만들다 만 시퀀스가 유출 못 함 |

> **⚠️ `src/types/phase21b.ts:4`가 틀렸다**
> ```ts
> export type SequenceStatus = 'active' | 'paused' | 'archived';   // 'draft' 누락
> ```
> DB enum은 4개. **TS 유니온이 틀린 것이지 DB가 아니다.** 런타임 영향은 없어서(UI는 active/paused/archived만 씀) 이번 커밋(sql/docs 전용)에서는 손대지 않았다. → 백로그.

### 1-3. 알고 써야 하는 시맨틱

- **enrollment cancel을 대체하지 않는다.** G3에 막힌 enrollment는 `active` + `next_send_at` 과거인 채로 남는다. status를 `active`로 되돌리면 **다음 워커 실행에 밀린 물량이 한꺼번에 나간다.** G1은 party당 48h를 잡지 영구 정지가 아니다 — 서로 다른 party는 전부 동시에 나간다. A-7의 Seed 되돌리기 주의사항과 동일. **영구 정지는 enrollment cancel(양겹)이 정본.**
- **소급 없음, 쓰기 없음.** 반환 집합만 거른다.
- **enum 캐스트는 의도적.** 라벨 오타면 CREATE 시점에 터진다. `status::text = 'active'`였다면 조용히 아무것도 매치 못 해 **전 발송을 막는다.**

### 1-4. 파일

| 파일 | 내용 |
|---|---|
| `migration_20260715010000_guard_sequence_status_get_due_enrollments.sql` | 함수. `001100` 대비 **순수 추가 6줄**(JOIN + 주석), 나머지 바이트 동일 — diff로 확인 |
| `migration_20260715010100_v_enrollment_send_health_sequence_status.sql` | 뷰. `send_status`에 `sequence_inactive` 추가 + 트레일링 컬럼 `sequence_status` |

**뷰를 같이 고치는 이유**: `migration_20260714235500` 헤더의 자체 규칙 — *"If get_due_enrollments changes, change this view in the same commit."* 안 고치면 뷰가 paused 시퀀스의 enrollment를 `ok`로 보고한다. **`ok`를 과다 보고하는 프리플라이트는 이 뷰가 없애려고 만들어진 바로 그 실패다.**

- `CREATE OR REPLACE VIEW`는 트레일링 추가만 가능 → `sequence_status`는 `send_status` **뒤**에. `send_status`의 이름/위치/타입은 불변, 값만 확장
- **소비자 확인**: `src/`에서 `v_enrollment_send_health` grep → **0건.** SQL Editor 전용 뷰라 새 값이 tsc를 못 깬다. `get_due_enrollments`는 반환 시그니처가 그대로라 `src/types/database.ts` 재생성 불필요
- G1(48h)은 여전히 뷰에 없다 — 워커 실행 시각의 함수지 enrollment의 정적 속성이 아니다

### 1-5. 프리뷰 — **적용 전 필수. 판정 규칙까지 읽고 실행할 것**

**P0. enum 실측** (TS를 믿지 말 것)
```sql
SELECT enumlabel AS status_value, enumsortorder
FROM pg_enum
WHERE enumtypid = 'app.email_sequence_status'::regtype
ORDER BY enumsortorder;
```
→ 기대: `draft, active, paused, archived`. 다르면 **멈추고** 1-2 표를 다시 쓸 것.

**P1. active enrollment를 시퀀스 status별로**
```sql
SELECT s.status::text AS sequence_status,
       s.name         AS sequence_name,
       count(*)       AS active_enrollments,
       min(e.next_send_at) AS earliest_next_send,
       max(e.next_send_at) AS latest_next_send
FROM app.email_sequence_enrollments e
JOIN app.email_sequences s ON s.id = e.sequence_id
WHERE e.status = 'active'::app.enrollment_status
GROUP BY 1, 2
ORDER BY 1, 2;
```
→ 기대: `active / Climate Investor Cold Outreach -- FCC / 62`. Climate이 active가 아니면 **적용 금지** — 7/20 40통이 죽는다.

**P2. G3가 정확히 무엇을 침묵시키는가 — 이름으로 확인**
```sql
SELECT s.name AS sequence_name,
       s.status::text AS sequence_status,
       p.party_name,
       e.next_step_order,
       e.next_send_at
FROM app.email_sequence_enrollments e
JOIN app.email_sequences s ON s.id = e.sequence_id
JOIN app.parties p         ON p.id = e.party_id
WHERE e.status  = 'active'::app.enrollment_status
  AND s.status <> 'active'::app.email_sequence_status
ORDER BY s.name, e.next_send_at NULLS LAST;
```

| 결과 | 판정 |
|---|---|
| **0행** | 오늘 순수 no-op. **적용.** 앞으로의 일시정지/아카이브만 실효화된다 |
| 행 있음 | **한 줄씩 이름으로 볼 것.** 아직 보낼 생각이던 게 있으면 **적용 금지** — 시퀀스 status를 먼저 정리 |

### 1-6. 적용

Supabase SQL Editor에 **파일 하나씩, 통째로** 붙여넣고 실행 (010000 → 010100 순서).
010000은 본문에 `;`이 없어 단일 statement로 나간다 — 쪼개지 말 것.

### 1-7. 검증

```sql
SELECT pg_get_functiondef('public.get_due_enrollments()'::regprocedure)
       ILIKE '%email_sequence_status%' AS has_g3;
```
→ `has_g3 = true`

```sql
SELECT send_status, count(*)
FROM app.v_enrollment_send_health
WHERE enrollment_status = 'active'
GROUP BY 1
ORDER BY 2 DESC;
```
**교차 검증 불변식 2개** (둘 다 맞아야 함):
- `sequence_inactive` 행수 **== P2 행수**
- 전체 합 **== P1의 `active_enrollments` 합**

무회귀면 `ok` / `do_not_send_*` 분포가 적용 전과 동일해야 한다.

---

## PART 2 — ⚠️ 발견: 7/20에 40통이 안 나갈 가능성 (가설)

> **이건 코드를 읽고 세운 가설이다.** 지난 세션에 같은 종류의 가설이 **6개 전부 데이터에 반박당했다.** 그러니 사실로 취급하지 말 것. **아래 쿼리 하나면 판정된다.**

### 2-1. 관측

`quiet_hours` (`20260713150000` Part 1) = `{tz: America/Los_Angeles, start: '10:00', end: '09:00', weekends_blocked: true}`
→ **허용 창 = 평일 09:00–10:00 PT.** 그 외 전부 blocked.

이 정책엔 **"화요일"이라는 개념이 없다.** 요일 개념은 `weekends_blocked`뿐이다.
**"Tuesday 9am"은 Part 2의 일회성 `UPDATE`가 `next_send_at`을 화요일 09:00으로 찍은 데서만 나왔다** — 스키마에도 정책에도 없다.

그런데 `advance_enrollment`는 발송할 때마다 앵커를 **`enrolled_at + day_offset`으로 되돌린다.**

- `enrolled_at` = 7/13 21:06:34 UTC = **월 14:06 PT**
- step 1 발송(7/14) 후 → `next_send_at = enrolled_at + 7일` = **7/20 21:06:34 UTC = 월 14:06 PT**
- 7/20은 **화요일이 아니라 월요일**이고, 14:06 PT는 **허용 창 밖**

### 2-2. 그러면 어떻게 되나

`sequence-processor.ts`가 blocked → `next_send_at`을 밀고 `skipped++`. `computeNextAllowed`는 오후엔 **`now + 1일 + 30분`**을 준다:

| 시각 (PT) | 판정 | 다음 |
|---|---|---|
| 월 7/20 14:06 | blocked | 화 7/21 14:36 |
| 화 7/21 14:36 | blocked | 수 7/22 15:06 |
| … 하루 +30분씩 드리프트 … | | |
| 토 7/25 16:36 | **weekend** 분기 | 월 7/27 **09:00 UTC = 02:00 PT** |
| 월 7/27 02:00 PT | blocked (02:00 < 09:00) | +30분씩 (오전엔 `+1일`이 없음) |
| 월 7/27 **09:00 PT** | **허용** | **발송** |

→ **7/20에 0통. 40통은 7/27 오전 9시경에 나간다.** 손실이 아니라 **일주일 지연**이고, 7/27 Climate step 3 배치(22통)와 같은 날에 겹친다. (party가 서로 달라 G1은 안 잡는다.)

### 2-3. 판정 쿼리 — **이거 하나면 끝난다**

```sql
SELECT s.name           AS sequence_name,
       e.next_step_order,
       count(*)         AS n,
       to_char(min(e.next_send_at AT TIME ZONE 'America/Los_Angeles'),
               'YYYY-MM-DD Dy HH24:MI') AS earliest_pt,
       to_char(max(e.next_send_at AT TIME ZONE 'America/Los_Angeles'),
               'YYYY-MM-DD Dy HH24:MI') AS latest_pt
FROM app.email_sequence_enrollments e
JOIN app.email_sequences s ON s.id = e.sequence_id
WHERE e.status = 'active'::app.enrollment_status
  AND e.next_send_at IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;
```

| `earliest_pt` | 판정 |
|---|---|
| `2026-07-21 Tue 09:00` | **가설 폐기.** 무언가 재정렬했다. 7/20(월)이 아니라 7/21(화)에 나간다는 뜻이므로 핸드오프의 "7/20" 표기도 정정 대상 |
| `2026-07-20 Mon 14:06` | **가설 확인.** 드리프트 실재 → 2-4 |
| 그 외 | 사실대로 적을 것 |

### 2-4. 확인되면 (아직 고치지 말 것 — 먼저 측정)

`next_send_at`을 다음 화요일 09:00 PT로 다시 스냅하는 게 최소 조치지만, **`20260713150000` Part 2가 사고를 낸 그 문장이다.** 재발 방지 필수:
- `GREATEST(next_send_at, v_next_send)` — **앞으로만.** Part 2엔 이게 없어서 68건을 6일 당겼다
- `WHERE`에 **"아직 안 나간 것만"** 조건
- **한 번 스냅해도 다음 advance에서 또 풀린다.** 근본 해법은 `advance_enrollment`가 요일/시각 창을 아는 것이거나, `day_offset`을 7이 아닌 값으로 두는 게 아니라 **정책을 스케줄러에 두는 것**. 이번 세션 범위 밖 — E로 올린다

---

## PART 3 — 컨벤션 추가분

- **"X시 발송"이 스키마 어디에 사는지 확인할 것.** Climate의 "화요일 9시"는 정책이 아니라 **일회성 UPDATE의 잔상**이었다. `quiet_hours`는 시각·주말만 알지 요일을 모른다. 한 번 발송하면 `advance_enrollment`가 앵커를 `enrolled_at`으로 되돌려 정렬이 풀린다
- **생성된 타입(`src/types/database.ts`)이 손으로 쓴 타입(`src/types/phase21b.ts`)을 이긴다.** enum 값은 항상 전자에서 확인. 후자는 `draft`가 빠져 있었다
- **가드에 enum 캐스트를 쓸 것.** `::text` 비교는 오타 시 조용히 전부 차단(fail-closed지만 무성). enum 캐스트는 CREATE에서 터진다
- **뷰와 함수는 같은 커밋에.** `v_enrollment_send_health`가 자기 헤더에 그렇게 써 뒀다. 이번에 지켰다
- **`pglast`로 붙여넣기 전에 파싱할 것** — `pip install pglast` → `pglast.parse_sql(text)`. 함수 본문의 `;` 개수도 같이 센다. SQL Editor에서 절반 실행되는 사고를 막는다

---

## 파일 이동

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{ glob = 'migration_20260715010000_guard_sequence_status_get_due_enrollments*.sql'; dest = 'C:\dev\mbg-project\sql'; name = 'migration_20260715010000_guard_sequence_status_get_due_enrollments.sql' },
  @{ glob = 'migration_20260715010100_v_enrollment_send_health_sequence_status*.sql';  dest = 'C:\dev\mbg-project\sql'; name = 'migration_20260715010100_v_enrollment_send_health_sequence_status.sql' },
  @{ glob = 'handoff_2026-07-15_sequence_status_guard*.md';                            dest = 'C:\dev\mbg-project\docs\handoff\2026-07-15'; name = 'handoff_2026-07-15_sequence_status_guard.md' }
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

> Downloads를 먼저 비울 것. 옛 파일이 남아 있으면 mover가 커밋된 리포 파일을 덮어쓴다(지난 세션 `M` 3건).

## Finish

```powershell
cd C:\dev\mbg-project
git pull --rebase origin marinebiogroup
git status -sb
git add sql/ docs/
git commit -m "sql: [G3] guard get_due_enrollments on sequence status; view: surface sequence_inactive; docs: 2026-07-15 handoff (2)"
git push origin marinebiogroup
```

푸시 = 웹 자동 배포. **이 커밋은 sql/docs만이라 앱 코드 영향 없음** — DB 반영은 SQL Editor 실행이 정본이다. `git diff`로 의도치 않은 `M`이 없는지 먼저 확인.

---

## 다음 세션 킥오프 (복붙)

```
mbg-project 이어가자. docs/handoff/2026-07-15/handoff_2026-07-15_sequence_status_guard.md 기준.
(그 전 상태는 같은 폴더 handoff_2026-07-15_session.md)

이번에 한 것: [G3] 시퀀스 status 가드.
- get_due_enrollments에 JOIN app.email_sequences ... status = 'active' 추가 (migration_20260715010000)
- v_enrollment_send_health에 sequence_inactive + 트레일링 컬럼 sequence_status (migration_20260715010100)
- 이제 UI 일시정지/아카이브가 실제로 발송을 멈춘다. 단 영구 정지는 여전히 enrollment cancel이 정본
  (status만 되돌리면 밀린 물량이 한꺼번에 나감)
- 적용 여부: P0/P1/P2 프리뷰 결과에 따름. 검증은 has_g3=true + sequence_inactive 행수 == P2 행수

⚠️ 최우선: 7/20에 Climate 40통이 안 나갈 가능성 (핸드오프 PART 2, 가설)
  quiet_hours 허용 창 = 평일 09:00-10:00 PT. "화요일 9시"는 정책이 아니라 20260713150000 Part 2의
  일회성 UPDATE 잔상이고, advance_enrollment가 앵커를 enrolled_at(월 14:06 PT)으로 되돌려 정렬이 풀렸다.
  -> next_send_at = 7/20 21:06 UTC = 월 14:06 PT = 허용 창 밖 -> 하루 +30분씩 드리프트 -> 7/27 09:00 PT 발송 추정
  판정 쿼리(핸드오프 2-3): next_send_at AT TIME ZONE 'America/Los_Angeles'가
    Tue 09:00 -> 가설 폐기 / Mon 14:06 -> 확인
  코드에서 추론한 가설이다. 먼저 측정할 것.

E-3(quiet-hours 무방비 쓰기)는 우선순위 하향. 재평가 결과 실동작 버그가 아님 -
  get_due_enrollments가 next_send_at<=now()인 행만 주고 nextAllowedAt은 항상 미래라 이미 GREATEST와 동치.
  실제 결함은 updated_at 미기록(관측성)과 불변식이 다른 파일에 산다는 것(견고성)뿐.
  defer_enrollment RPC를 넣어도 동작 무변화이고, PART 2의 드리프트도 못 고친다.

백로그 추가: src/types/phase21b.ts:4 SequenceStatus 유니온에 'draft' 누락 (DB enum은 4개).
  런타임 영향 없음. 생성된 타입 src/types/database.ts:6999가 정본.

나머지 미결은 이전 핸드오프 PART E 그대로 (FCC Climate Tech day_offset 0,0 / IP delisting /
타임존 백필 / 시퀀스 이름 중복 / World Fund 8/4 재개 감시 / Lowercarbon 이중 노출 / tsc 15건).
```
