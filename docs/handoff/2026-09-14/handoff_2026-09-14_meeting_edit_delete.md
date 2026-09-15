# HANDOFF — 캘린더 일정 수정/삭제 불가 수정 (meetings edit/delete)

날짜: 2026-09-14 · 대상: URM Platform (`Marinegift/MBG-Project`, branch `marinebiogroup`, Next.js + Supabase `app` schema)
증상: urm.marinebiogroup.com/calendar 에서 **입력된 일정을 수정·삭제할 수 없음**

---

## 1. 원인 (코드 확인 완료, 3가지)

| # | 원인 | 위치 |
|---|------|------|
| 1 | **미팅에는 수정/삭제 UI가 없었음.** `EditEventModal`은 `app.calendar_events`(`type==='event'`) 전용. 팝업의 연필/휴지통은 `isEvent` 조건에서만 렌더. 미팅 칩은 'View details'만 있고 `/meetings/[id]` 는 읽기 전용 서버 컴포넌트 | `src/app/(app)/calendar/page.tsx` `ItemDetailPopup`, `src/app/(app)/meetings/[id]/page.tsx` |
| 2 | **이벤트는 수정/삭제해도 화면이 안 바뀜.** `/calendar`는 클라이언트 컴포넌트이고 `items`를 서버 액션으로 받아 `useState`에 담는데, 수정 후 `router.refresh()`만 호출 → RSC 페이로드만 갱신되고 클라이언트 state는 그대로 → 칩이 그대로 남아 "수정이 안 된 것처럼" 보임 | `calendar/page.tsx`, `edit-event-modal.tsx` |
| 3 | **미팅을 지워도 다시 나타남.** `app.meetings.deleted_at`(소프트 삭제)을 `fetchMeetings` / `/meetings/[id]` 만 필터링. 캘린더 피드·Today·party-detail 3곳은 필터 없음 | `queries/calendar.ts`, `queries/today.ts`, `queries/party-detail.ts` |

---

## 2. 변경 내역

### 신규 3개
- `src/app/actions/meetings.ts`
  `getMeetingForEditAction` / `updateMeetingAction` / `deleteMeetingAction`.
  - 삭제는 **소프트 삭제**(`deleted_at`) + 연결된 `calendar_event_id` 미러 행 정리.
  - 결과 객체(`{ok:true|false}`) 반환 → 프로덕션 빌드에서도 Postgres 에러 메시지가 모달에 그대로 노출.
  - `updateMeetingAction`은 `scheduled_at` 변경 시 `occurred_at`도 같이 갱신(NOT NULL, 대부분의 목록 정렬 기준).
  - **`fetchMeetingDetail`을 쓰지 않은 이유**: `DETAIL_SELECT`의 `parties ( id, name )`, `pipeline_stages:stage_id` 가 실제 스키마와 불일치(`app.parties.party_name`, deal 스테이지는 `app.stages`) → PostgREST 42703/relationship 에러. 조인 없는 플랫 컬럼 조회로 회피.
- `src/components/meetings/meeting-edit-modal.tsx`
  제목 / 시작시각 / 소요시간 / 상태 / 유형 / 채널 / 장소 / 미팅 URL / 아젠다 / 노트 + 삭제.
  Radix Select는 빈 문자열 value 불가 → `__none__` 센티널 사용.
- `src/components/meetings/meeting-detail-actions.tsx`
  `/meetings/[id]` 헤더용 Edit/Delete 아일랜드(서버 컴포넌트 안의 클라이언트 조각). 삭제 후 `/calendar`로 이동.

### 수정 6개
- `src/app/(app)/calendar/page.tsx`
  - 미팅 칩 팝업에 연필/휴지통 추가(`isMeeting` 분기)
  - 현재 조회 범위를 `range` state로 보관 → `reload()` 추가, **생성·수정·삭제 후 피드 재조회**
  - 팝업에 에러 메시지 표시줄 추가
- `src/components/calendar/edit-event-modal.tsx` — `onChanged?: () => void` 추가(저장/삭제 후 호출)
- `src/lib/queries/calendar.ts` — meetings 피드에 `.is('deleted_at', null)`
- `src/lib/queries/today.ts` — 동일
- `src/lib/queries/party-detail.ts` — `fetchPartyMeetings`, `fetchUpcomingPartyMeetings`, `fetchPartyMeetingStats` 3곳에 동일
- `src/app/(app)/meetings/[id]/page.tsx` — 헤더에 `<MeetingDetailActions meetingId={m.id} />`

**DB 마이그레이션 없음.** `app.meetings.deleted_at` 은 이미 존재.

---

## 3. 파일 배치 (Downloads → repo)

다운로드 파일명은 충돌을 피하려고 평평하게 바꿨습니다. 아래 인라인 블록을 **PowerShell에 그대로 붙여넣기** 하면 정식 경로로 복사됩니다. (`(1)`, `(2)` 접미사 자동 처리, 최신 파일 선택, Unblock-File)

```powershell
$repo = 'C:\dev\mbg-project'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ src='actions_meetings.ts';          dst='src\app\actions\meetings.ts' },
  @{ src='meeting-edit-modal.tsx';       dst='src\components\meetings\meeting-edit-modal.tsx' },
  @{ src='meeting-detail-actions.tsx';   dst='src\components\meetings\meeting-detail-actions.tsx' },
  @{ src='calendar_page.tsx';            dst='src\app\(app)\calendar\page.tsx' },
  @{ src='meetings_id_page.tsx';         dst='src\app\(app)\meetings\[id]\page.tsx' },
  @{ src='edit-event-modal.tsx';         dst='src\components\calendar\edit-event-modal.tsx' },
  @{ src='queries_calendar.ts';          dst='src\lib\queries\calendar.ts' },
  @{ src='queries_today.ts';             dst='src\lib\queries\today.ts' },
  @{ src='queries_party-detail.ts';      dst='src\lib\queries\party-detail.ts' }
)
foreach ($m in $map) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($m.src)
  $ext  = [System.IO.Path]::GetExtension($m.src)
  $hit  = Get-ChildItem -LiteralPath $dl -File |
          Where-Object { $_.Name -like ($base + '*' + $ext) } |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $hit) { Write-Host ("MISS  " + $m.src); continue }
  try { Unblock-File -LiteralPath $hit.FullName } catch {}
  $dest    = Join-Path $repo $m.dst
  $destDir = [System.IO.Path]::GetDirectoryName($dest)
  [void][System.IO.Directory]::CreateDirectory($destDir)
  [System.IO.File]::Copy($hit.FullName, $dest, $true)
  Write-Host ("OK    " + $hit.Name + "  ->  " + $m.dst)
}
```

경로에 `(app)` 와 `[id]` 가 들어가므로 와일드카드 해석 문제를 피하려고 전부 .NET 메서드(`[System.IO.File]::Copy`, `Directory::CreateDirectory`)를 씁니다. `tools\move-downloads.ps1` 은 `sql_`/`handoff_`/`patch_` 접두사 라우팅용이라 이번 src 파일에는 쓰지 않습니다. 이 handoff 문서 자체는 mover가 `docs\handoff\2026-09-14\` 로 보냅니다.

---

## 4. 검증 상태

- `npx tsc --noEmit`: **변경한 9개 파일 에러 0**.
  (기존 에러는 `[partyType]/parties/page.tsx`, `api/relay/mail/route.ts`, `components/schedule/*` — 9/10 일과표 handoff 것 포함. `next.config.mjs`에 `typescript.ignoreBuildErrors: true` 라 배포는 통과)
- esbuild 구문 검사: 9개 파일 전부 통과.
- `npm run build`: 컨테이너에서 `fonts.googleapis.com` 접근 불가로 `layout.tsx`의 next/font 에서만 실패. 코드와 무관 — 로컬/Railway에서는 정상.
- **미검증**: 실제 브라우저 동작. 아래 스모크 테스트 권장.

### 스모크 테스트
1. `/calendar` → 미팅 칩(📅, 예: "Office Hours: Incubator Partnership Team") 클릭 → 팝업에 연필/휴지통이 보이는지
2. 연필 → 제목·시각 변경 → Save → **모달 닫히자마자 칩이 새 제목/위치로 바뀌는지**(새로고침 없이)
3. 휴지통 → 확인 → 칩이 즉시 사라지는지 → F5 후에도 안 돌아오는지 → `/today`, 해당 party 상세에서도 사라졌는지
4. `/meetings/<id>` 헤더 우측 Edit/Delete 동작 확인, 삭제 후 `/calendar`로 이동하는지
5. 구글 이벤트(🟢) 수정/삭제 시에도 화면이 즉시 갱신되는지 (원인 #2 회귀 확인)

---

## 5. 마무리 (배포)

```powershell
cd C:\dev\mbg-project
git status -sb
git add src/app/actions/meetings.ts `
        src/components/meetings/meeting-edit-modal.tsx `
        src/components/meetings/meeting-detail-actions.tsx `
        "src/app/(app)/calendar/page.tsx" `
        "src/app/(app)/meetings/[id]/page.tsx" `
        src/components/calendar/edit-event-modal.tsx `
        src/lib/queries/calendar.ts `
        src/lib/queries/today.ts `
        src/lib/queries/party-detail.ts `
        docs/handoff/2026-09-14/handoff_2026-09-14_meeting_edit_delete.md
git commit -m "fix(calendar): edit/delete for meetings + refresh client feed after mutations"
git push origin marinebiogroup
```

`git push` = 자동 배포입니다. 푸시하는 순간 urm.marinebiogroup.com 에 반영되고, **레포는 public** 이므로 커밋 내용도 그대로 공개됩니다(자격증명·실제 ID를 코드/주석에 넣지 말 것 — 이번 변경에는 없음).

---

## 6. 남은 작업 (선택)

- **To-Do / 딜 태스크 / 커뮤니케이션 칩**은 여전히 캘린더에서 수정·삭제 불가(각자 페이지에서만 가능). 같은 패턴(`actions/<domain>.ts` + 모달 + 팝업 분기)으로 확장 가능.
- 미팅 **참석자 편집**은 이번 범위 밖(`app.meeting_attendees`). `addAttendee` / `removeAttendee` 는 `queries/meetings.ts`에 이미 있으므로 모달에 섹션만 추가하면 됨. 스크린샷의 "ATTENDEES (0)"는 Greentown 초대 메일에서 미팅을 만들 때 참석자를 안 넣어서 비어 있는 상태.
- `queries/meetings.ts`의 `fetchMeetingDetail` **DETAIL_SELECT가 실제 스키마와 불일치**(위 2항 참조) — 호출하는 곳이 생기면 터짐. 별도로 정리 필요.
- 삭제된 미팅 복구 UI 없음(`deleted_at`을 null로 되돌리는 SQL로만 가능).
