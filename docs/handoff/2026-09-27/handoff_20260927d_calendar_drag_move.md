# HANDOFF — 2026-09-27 d: 캘린더 드래그로 일정 날짜 이동

## 기능
/calendar Month·Week 보기에서 일정 칩을 다른 날짜 칸으로 끌어다 놓으면 날짜가 자동 수정된다.
시간 일정은 같은 시각(로컬, DST 안전)으로 옮기고 길이는 유지. 종일/날짜 항목은 날짜만 변경.

| 칩 | 저장 위치 | 외부 반영 |
|---|---|---|
| Calendar events (Google/Microsoft/URM) | app.calendar_events start_at/end_at | Google/Microsoft Calendar write-back (updateCalendarEvent) |
| Meetings | app.meetings scheduled_at(+occurred_at) | 연결된 calendar_events 미러가 있으면 같이 이동 + write-back |
| Deal tasks | app.tasks due_at | - |
| To-Do | app.todo_items due_date | - |
| Deal: next step | app.deals next_step_date | Pipeline 반영 |
| Deal: close | app.deals expected_close_date | Pipeline 반영 |

이동 불가: Communications(이력), 반복 일정의 개별 회차(시리즈 전체가 움직이므로 Edit 로 수정).
이동 후 우측 하단 토스트(성공/실패), 화면은 월 유지한 채 조용히 다시 불러옴.

## 파일
- NEW `src/app/actions/calendar-move.ts` — moveCalendarItemAction
- `src/components/calendar/calendar-view.tsx` — HTML5 drag & drop (MonthGrid, WeekGrid 종일/시간 칸), 드롭 대상 하이라이트
- `src/components/calendar/calendar-event-chip.tsx` — draggable props
- `src/app/(app)/calendar/page.tsx` — handleItemMove (낙관적 이동 + 토스트 + silent reload)
- tsc: 신규 오류 0 (기존 12건 그대로)

## 참고
- Google 쪽 반영은 calendar_connections 토큰이 유효해야 함. 실패 시 로컬은 이동되고 서버 로그에 `[calendar write-back][update]`.
- "+N more" 모달 안의 칩은 드래그 대상 아님 (월 칸에 보이는 칩만).

## Push
cd C:\dev\mbg-project
git status -sb
git add src/app/actions/calendar-move.ts src/components/calendar/calendar-view.tsx src/components/calendar/calendar-event-chip.tsx "src/app/(app)/calendar/page.tsx" docs/handoff
git commit -m "calendar: drag & drop reschedule (Google write-back, meetings, tasks, todo, deal dates)"
git push origin marinebiogroup
