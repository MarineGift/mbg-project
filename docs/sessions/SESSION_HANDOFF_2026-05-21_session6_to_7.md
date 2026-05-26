# SESSION HANDOFF — Session 6 → Session 7

**Date:** 2026-05-21 (Session 6 종료)
**Project:** mbg-project — B2B CRM/sales intelligence (Next.js 14 + Supabase + Anthropic SDK)
**Owner:** YunYoung
**Business verticals:** paper filler (calcium carbonate) / chitin & chitosan / cosmetics

---

## §1. Session 6 요약 — Stage 23 완료

Session 5 의 stash (5 파일 잔재) 분석 → URM 관점 분류 → 단계적 적용.
**5 step + 2 sub-step** 으로 schema 정합 + frontend single source 회복.

### 완료된 Stage

| Stage | 작업 | 결과 | 비고 |
|:--:|---|:--:|---|
| **23** | URM cleanup (5 파일 + 2 정정) | ✅ | commit `58e5642` on `feature/stage23-urm-cleanup` |

---

## §2. Stage 23 세부 — 5 step + URM 정정

### Step 진행 표

| Step | 파일 | 변경 | tsc 변화 |
|:--:|---|---|:--:|
| **1** | `lead-score.ts` | `app.lead_scores` 직접 SELECT → `get_lead_scores_many` RPC | (broken→fixed) |
| **2** | `google/callback/route.ts` | orgId 3-tier fallback (stash 의도) | (Step 2.1 에서 URM 정정) |
| **3** | `microsoft/callback/route.ts` | 위와 동일 + dead `createHmac` import 제거 | (Step 3.1 에서 정정) |
| **4** | meetings.ts + calendar.ts + modal | `duration_minutes` → `duration_min` (3 파일 8 hit) | 138 → 141 (+3) |
| **5** | `party-detail.ts` | 미팅 query 도메인 추가 (7 신규 export, 방향 Y) | 141 → 143 (+2) |
| **5.1** | `party-detail.ts` | `noUncheckedIndexedAccess` fix (2 hit) | 143 → 141 (−2) |
| **2.1/3.1** | callback 2 파일 | fallback → single source URM 압축 | 141 유지 |

### Step 별 URM 평가

**Step 1 — lead-score.ts:**
- 현재 HEAD 는 `app.lead_scores` (존재 안 함) 직접 SELECT → 런타임 broken
- `public.get_lead_scores_many(uuid[])` RPC wrapper 호출로 변경 (DB 검증 ✅)
- URM: DB layer 추상화 + batch 효율 정합

**Step 2-3, 2.1, 3.1 — calendar callback:**
- Stash 의 의도: 3-tier fallback (`as any` ?? `app_metadata` ?? `user_metadata` ?? `app.users`)
- URM 위반 — single source of truth 부재 신호
- **2.1/3.1 정정**: `app.users.organization_id` 만 조회. 다른 source 모두 제거.
- 추가 정리: microsoft 의 dead `createHmac` import 제거 (HMAC state 검증 안 함)

**Step 4 — duration_minutes → duration_min:**
- DB `app.meetings.duration_min` (integer) 가 single source
- 3 파일 8 hit 모두 정정
- 부작용: `never[]` 추론 longstanding 이슈 표면화 (+3 tsc errors → Stage 24)

**Step 5 — party-detail.ts:**
- 미팅 도메인 추가 (Self-contained — fetchPartyDetail 옆에 배치)
- 7 신규 export: `MeetingStatus`, `MeetingAttendeeRef`, `PartyMeeting`, `PartyMeetingStats`,
  `fetchPartyMeetings`, `fetchUpcomingPartyMeetings`, `fetchPartyMeetingStats`, `mapMeeting`
- 방향 Y 채택: `meeting_mode` 컬럼 미사용 (DB 에 없음 — `channel` enum 으로 통일 예정)
- camelCase 매퍼 (`partyId`, `durationMin`) — frontend convention 정합

---

## §3. DB 검증 결과 (Session 6 측정)

Stage 23 작업 전 5 가지 DB 사실 확인:

| 검증 | 결과 | 의미 |
|---|:--:|---|
| `app.meetings.meeting_mode` 컬럼 | **없음 (any schema)** | code 와 DB 격차 |
| `app.meetings.duration_min` (vs `_minutes`) | `_min` 만 존재 | HEAD broken |
| `app.lead_scores` 테이블 | **없음** (Stage 13d 후 삭제) | HEAD broken |
| `public.get_lead_scores_many` RPC | **존재** | wrapper 활용 가능 |
| `app.users.organization_id` 컬럼 | **존재** | URM single source |
| `meeting_attendees` 테이블 | 존재 (옛 API 가정 valid) | Stage 24 의 modal migration 결정용 |

### `app.meetings` 실제 스키마 (참고)
```
id, organization_id, party_id, engagement_id,
meeting_type (text), title (text), notes, occurred_at,
duration_min (integer), attendees (jsonb),
outcome, next_steps, agenda, ai_summary,
action_items (jsonb), channel (USER-DEFINED enum),
scheduled_at, actual_started_at, actual_ended_at,
location, meeting_url, status (USER-DEFINED enum),
follow_up_task_ids (ARRAY), calendar_event_id,
created_by, updated_by, created_at, updated_at, deleted_at
```

### `channel` enum 값 (15)
`in_person`, `video_call`, `video_conference`, `phone_call`, `email`, `sms`,
`kakaotalk`, `wechat`, `whatsapp`, `linkedin`, `slack`, `webform`,
`postal`, `hybrid`, `other`

→ **Stage 24 의 방향 Y 근거**: meeting mode 와 communication channel 이 같은 enum 공유.

---

## §4. 누적 핵심 학습 — Gotchas (Session 1-6)

### Session 1-4 기존 (#1 ~ #18)
- handoff_session4_to_5.md §7 참조

### Session 5 (#19 ~ #22)
- LANGUAGE sql eager 재컴파일 / CHECK normal dep / ALTER TYPE transaction 제약 / partial index WHERE dep
- handoff_session5_to_6.md §4 참조

### Session 6 신규 (#23 ~ #26)

**#23. PowerShell 의 `stash@{N}` interpolation 문제**
- PowerShell 이 `{0}` 을 string format placeholder 로 해석 → "Too many revisions" 에러
- 대응: **single quote** 로 감싸기 (`'stash@{0}'`)
- double quote 도 `-f` 연산자 placeholder 로 해석 가능성

**#24. UTF-8 BOM 오염 (stash 작성자 IDE 기본값)**
- 옛 PowerShell `Out-File` 또는 일부 IDE 가 BOM 추가
- git diff 에서 첫 줄에 `\uFEFF` 만 다른 noise 변경으로 표시
- 대응: `[System.IO.File]::WriteAllText` + `New-Object System.Text.UTF8Encoding $false` (no BOM)
- 검증: `[System.IO.File]::ReadAllBytes(...)[0..2]` 가 `EF BB BF` 가 아니어야 함

**#25. `noUncheckedIndexedAccess` 의 indexed access 결과 type**
- tsconfig 옵션 활성 시 `arr[i]` 의 return type 이 `T | undefined`
- 대응: `arr[i] ?? null` 또는 `arr.at(i) ?? null`
- 단순 length check 로는 narrowing 안 됨 (control flow analysis 제한)

**#26. Supabase `database.types.ts` 의 `never[]` 추론 한계**
- `app` schema 의 table 들 + 복잡 RETURNS RPC 가 `never` 추론
- 발현 조건: query builder method (`.from('xxx' as never).select(...).eq(...)`) 의 type narrowing 실패
- 영향 범위: Session 6 종료 시 ~56 errors (email-sequences 26, email-compose 20 hotspot)
- workaround 옵션:
  - `as never` cast (Stage 23 의 party-detail.ts 에 일부 적용)
  - typed wrapper 함수
  - Stage 24 의 1번 작업 범위

### 진단 도구 — Step 4 학습
- DB schema 와 code 격차 식별: `Get-ChildItem | Select-String -Pattern '<column>'` 으로 사용처 grep
- 격차의 root cause: Supabase types 가 DB 와 정확히 일치 → code 만 옛 가정 유지
- 단일 substring replace 가 충분 (distinctive column name 일 경우)

---

## §5. 현재 상태 (Session 6 종료 시점)

### Git 상태
- branch: `feature/stage23-urm-cleanup` (HEAD = `58e5642`)
- base: `feature/stage20-21-22-urm-complete` (`4bb6b4c`)
- PR 대기:
  - `feature/stage20-21-22-urm-complete` → main/dev
  - `feature/stage23-urm-cleanup` → 위 PR 머지 후 또는 별도 (검토 분리 권장)
- stash: empty
- .bak 7 파일 보존 (Stage 24 비교용, .gitignore 적용)

### tsc 상태
- baseline (Stage 22 직후): **138**
- 현재 (Stage 23 종료): **141 (delta +3)**
- 분포:
  - email-sequences.ts: 26 (never 추론, ~half)
  - email-compose.ts: 20 (never)
  - sequence-processor.ts: 12 (never)
  - party-communications-timeline.tsx: 7
  - 기타: ~76

### DB 상태
- Stage 23 은 frontend only — DB 변경 없음
- DB URM 100% 일치 모듈: investor, paper_mill, buyer, sales, email_sequence (Session 5 까지)
- module type enum 11 values (Session 4 와 동일)

---

## §6. Session 7 우선순위 (URM 기준 재정렬)

**핵심 원칙 (사용자 결정):**
> "현재 있는 데이터는 모두 삭제해도 되니 현재 있는 데이터보다는 URM 기준이 더 중요하다."

### 권장 순서

**1. meetings.ts 전면 재작성 + modal migration (가장 큰 URM 위반)**

- 현재: meetings.ts 가 schema 와 어긋난 옛 API (`createMeeting`, `MeetingRow`, `MeetingAttendeeRow`,
  `CreateMeetingInput`, `MeetingType`, `MeetingMode`) 보유 — Stage 23 에서 보존됨
- 사용처: `meeting-create-modal.tsx` 1 곳
- 작업:
  - meetings.ts: 옛 API 전부 제거. party-detail.ts 의 새 타입 import 재사용
  - meeting-create-modal.tsx: 새 API 사용 (`channel` enum, `duration_min`, party-detail 의 `PartyMeeting`)
  - DB 가정 정합: `attendees` jsonb 컬럼 직접 사용 (vs `meeting_attendees` 테이블 두 갈래)
- URM: meeting 도메인의 single source = party-detail.ts (또는 meetings.ts 로 통합 — 결정 필요)
- 데이터 폐기 가능: 기존 meeting 행 RLS 통해 cascade delete 후 fresh insert

**2. channel enum 통합 (방향 Y 완성)**

- 현재: code 에 `MeetingMode = 'in_person' | 'video_call' | 'phone' | 'in_person' | 'hybrid'` (`phone_call` 부분 미정합)
- DB: `channel` enum (15 values, in_person/video_call/phone_call/hybrid 모두 포함)
- 작업:
  - `MeetingMode` type 제거. 대신 `channel` enum 의 subset 활용
  - meeting-create-modal 의 `MEETING_MODES` 상수 → DB 의 enum 값 fetch (또는 hard-code subset)
  - calendar.ts 의 `meeting_mode` 컬럼 select → `channel` 컬럼
- URM: DB enum 이 single source

**3. never 추론 56 errors 일괄 정리**

- Hotspot:
  - email-sequences.ts (26) — Stage 21 의 RPC 호출들이 type 추론 실패
  - email-compose.ts (20)
  - sequence-processor.ts (12)
- workaround 옵션 (선택):
  - **옵션 A**: 각 RPC 호출 site 에 `as never` cast 추가 (mechanical, ~2시간)
  - **옵션 B**: typed wrapper 함수 도입 (`src/lib/rpc/typed-rpc.ts` 같은 파일에 모든 RPC 호출 일원화)
  - URM 기준으로는 옵션 B 가 정합 — RPC 호출의 single source of truth
- 데이터 영향 없음 (type 만 영향)

**4. log_change 함수 도입 (Stage 20 audit trigger 활성)**

- Session 5 의 Stage 20 에서 audit trigger 가 `log_change` 함수 부재로 skip 됨
- 공통 audit log 시스템 설계 + IPP / PC 의 audit trigger 활성

**5. Investor outreach UI**

- `v_investor_outreach_list` view 활용 (CSV 38 확인)
- partner_seniority enum 활용 (CSV 61)

### 우선순위 조정 가능성

위 1, 2 가 같은 도메인 (meeting) — 묶어서 Stage 24 로 진행 가능.
3 (never) 은 별개 Stage (Stage 25 또는 24의 sub-stage). 4-5 는 별도 stage.

---

## §7. 환경 확인 (Session 7 시작 시 1번 실행)

```powershell
# 1. branch + commit 확인
git --no-pager log --oneline -3
git branch --show-current  # → feature/stage23-urm-cleanup (또는 머지된 main/dev)

# 2. tsc baseline (Stage 24 의 출발점)
$baseline = (npx tsc --noEmit 2>&1 | Select-String -Pattern 'error TS' | Measure-Object).Count
Write-Host "tsc baseline: $baseline (Stage 23 종료 시 141)"

# 3. .bak 파일 보존 확인 (Stage 24 비교용)
Get-ChildItem -Path src -Recurse -Filter '*.bak' | Format-Table FullName, Length

# 4. stash 상태 (empty 여야 함)
git stash list
```

```sql
-- DB 검증 (Session 6 의 사실 재확인)
SELECT
  EXISTS (SELECT 1 FROM information_schema.tables
          WHERE table_schema='app' AND table_name='meetings') AS s_meetings,
  EXISTS (SELECT 1 FROM information_schema.tables
          WHERE table_schema='app' AND table_name='meeting_attendees') AS s_attendees_table,
  EXISTS (SELECT 1 FROM information_schema.columns
          WHERE table_schema='app' AND table_name='meetings' AND column_name='duration_min') AS s_duration_min,
  NOT EXISTS (SELECT 1 FROM information_schema.columns
              WHERE column_name='meeting_mode') AS s_no_meeting_mode_anywhere,
  NOT EXISTS (SELECT 1 FROM information_schema.tables
              WHERE table_schema='app' AND table_name='lead_scores') AS s_no_lead_scores_table,
  EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
          WHERE n.nspname='public' AND p.proname='get_lead_scores_many') AS s_rpc_exists;
```

모두 `true` 여야 함.

---

## §8. Frontend (mbg-project) 상태

### Stage 23 변경 파일 (7 파일, .bak 보존)

```
src/lib/queries/lead-score.ts          — RPC wrapper (10 lines 변경)
src/lib/queries/party-detail.ts        — 미팅 도메인 추가 (+211 lines)
src/lib/queries/meetings.ts            — duration_min schema 정합 (5 hit)
src/lib/queries/calendar.ts            — duration_min (2 hit)
src/components/meetings/meeting-create-modal.tsx — duration_min (1 hit)
src/app/api/calendar/google/callback/route.ts    — URM single source
src/app/api/calendar/microsoft/callback/route.ts — URM single source + dead import 제거
```

### .gitignore 적용 패턴
- `*.bak` — Stage 23 patch backups (untracked, Stage 24 비교용)

### 회귀 가능성
- 변경된 7 파일 모두 .bak 보존 → manual rollback 가능:
  ```powershell
  # 특정 파일 rollback
  Copy-Item src\<file>.bak src\<file> -Force
  ```
- git history: `git checkout 4bb6b4c -- <file>` 로도 가능 (Stage 22 시점)

---

## §9. 사용자 작업 스타일 (Session 6 추가 학습)

- **URM 기준 우선**: 데이터 폐기 가능, 현재 데이터보다 URM 정합이 더 중요
- 명확한 결정 (single_select 옵션 선택, 또는 짧은 자유 답)
- 단계적 검증 선호 (sanity check 마다 결과 붙여넣기)
- PowerShell + Supabase SQL Editor 직접 실행
- .bak 자동 보존 + manual rollback 가능한 patch 선호
- handoff 마지막에 다음 stage 우선순위 명시적 요청
- **Session 6 신규**: stash 분석 → URM 분류 → step 별 정정 → 단일 commit 의 워크플로우 효과적
- **Session 6 신규**: tsc count 를 KPI 로 사용하되, "broken state 복구" 가 +tsc 보다 우선

---

## §10. 첨부 파일 (`/mnt/user-data/outputs/` — Session 6 산출물)

### Session 6 적용 완료 (commit `58e5642`)
- 7 파일 변경 (위 §8)
- 7 .bak 파일 working tree 보존 (untracked)

### Session 7 시작 준비
- 본 handoff 문서 (`SESSION_HANDOFF_2026-05-21_session6_to_7.md`)
- 모든 결정 사항 + 환경 확인 + 우선순위 명시

### 폐기 권장 (분석용 임시 파일)
- `stash0_full.diff` (60KB, working tree 의 untracked) — Session 6 분석에 사용, 보존 불요

---

**Session 6 종료. Stage 23 완료. Frontend URM cleanup 완성.**
**Session 7 첫 작업: Stage 24 (meetings.ts 전면 재작성 + modal migration + channel enum 통합).**
