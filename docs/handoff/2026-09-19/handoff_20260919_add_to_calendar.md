# HANDOFF 2026-09-19 — Inbox/Communications: Add to Calendar (URM 단계)

## 1. 무엇을 만들었나

보낸/받은 메일 본문에서 **구글 밋 링크와 제안된 일정**을 뽑아 URM 캘린더에 등록하는 기능.

- 대상 화면 ①: 파티 상세 > Communications 탭 (메일 행의 View / Reply 옆, 읽기 모달 푸터)
- 대상 화면 ②: Inbox 스레드 상세 (펼친 메시지의 "Reply to this message" 아래)
- 버튼은 **본문에 미팅 링크나 파싱 가능한 날짜가 있을 때만** 노출된다. 없으면 행이 죽은 액션으로 지저분해지므로 숨긴다.
- 클릭하면 모달이 뜨고 파서 결과가 프리필된다. **전부 수정 가능**하다 — 파서는 단축키이지 최종 결정권자가 아니다.
- 저장하면 `/calendar`, `/today`에 즉시 나타난다.

이번 단계는 **URM 내부 캘린더까지**다. 구글 캘린더로의 push는 다음 단계(아래 6번).

## 2. 추가/수정 파일

### 신규 3
| 파일 | 역할 |
|---|---|
| `src/lib/meetings/parse-meeting-invite.ts` | 순수 파서 + 타임존 유틸. 서버/클라이언트 양쪽에서 import |
| `src/app/actions/add-email-to-calendar.ts` | 서버 액션. meetings 또는 calendar_events에 기록 |
| `src/components/meetings/add-to-calendar-modal.tsx` | 확인·수정 모달 + `emailHasMeetingSignal()` |

### 수정 2
| 파일 | 변경 |
|---|---|
| `src/components/parties/party-communications-timeline.tsx` | MessageRow 액션바 + EmailViewModal 푸터에 Add to Calendar, 모달 마운트 |
| `src/components/inbox/communication-detail-view.tsx` | ThreadMessageCard에 버튼(세로 버튼 컬럼으로 감쌈), 모달 마운트 |

**DB 마이그레이션 없음.** 원본 메일 id는 새 컬럼 대신 agenda/description 텍스트에 `Source email: <uuid>`로 남긴다.

## 3. 파서 동작 (parse-meeting-invite.ts)

### 뽑는 것
- 미팅 링크: Google Meet → Zoom → Teams → Webex 순. HTML 본문은 텍스트와 `href` 양쪽에서 찾는다.
- 전화 접속 줄: `+` 숫자 + `PIN|dial|phone` 이 함께 있는 줄만 (agenda에 프리필)
- 시각 후보 최대 6개, 점수순 정렬

### 핵심 원칙 — 시각은 반드시 날짜에 앵커
날짜 매치가 없는 "9:00"은 **무시**한다. 서명·전화번호·PIN이 그럴듯한 이벤트를 만들어내는 것을 막기 위함.

### 검증된 입력 형식 (테스트 9케이스 통과)
```
Tuesday, September 23, 2026 at 9:00 AM CDT
Tuesday Sep 23, 2026 . 9:00 - 9:30am (Central Time - Chicago)   <- 구글 초대문
2026-10-02 14:00 KST
Oct 7 from 10:00 to 11:00 AM ET                                 <- 연도 없음
10/15/2026 at 3pm PT
2026년 10월 5일 오후 2시 30분
<b>Thursday, September 25, 2026</b> at 11:00 AM CDT             <- HTML 본문
January 8 at 9:00 AM CST  (12월 발신 메일 -> 다음 해로 추론)
```

### 타임존 처리
- 메일에 적힌 표기를 IANA로 변환: `CDT/CST/CT` → America/Chicago, `ET/EST/EDT`, `PT`, `MT`, `KST`, `JST`, `BST`, `CET`, `UTC+9`, `Central Time - Chicago`, 그리고 `America/Chicago` 같은 IANA 직접 표기
- **CST는 미국 중부로 해석**한다 (중국 표준시 아님). 상대가 미국 투자자/제지사이므로.
- 표기가 없으면 프로필 타임존(없으면 `America/Chicago`) 적용
- 저장값은 **절대 시각(UTC ISO)**. 모달의 날짜 입력칸은 선택된 타임존에서 읽은 벽시계이므로, 브라우저 타임존과 무관하게 메일에 적힌 대로 09:00이 보인다.

### 주의: lookbehind 금지
이 파일에는 `(?<=`, `(?<!` 를 **절대 쓰지 말 것**. Safari 16.4 미만은 정규식 리터럴 파싱 단계에서 SyntaxError를 내고, 그러면 번들 전체가 죽는다. 현재 0개. 앞자리 문자를 캡처 그룹으로 받아 인덱스를 보정하는 방식으로 대체했다.

### noUncheckedIndexedAccess
repo tsconfig에 켜져 있어 `m[1]`이 `string | undefined`다. 파일 안의 `cap(m, i)` 헬퍼로 처리했다. 새 정규식 코드를 추가할 때 같은 패턴을 쓸 것.

## 4. 저장 경로 (add-email-to-calendar.ts)

`app.meetings.party_id`가 NOT NULL이라 두 갈래다.

| 조건 | 기록 위치 | 결과 |
|---|---|---|
| 파티 연결됨 | `app.meetings` (createMeeting, 참석자 포함) | 'meeting' 소스 칩 |
| 파티 없음 | `app.calendar_events` (source `internal`) | 'event' 칩 |

둘 다 `getCalendarFeed()`가 읽으므로 캘린더에는 동일하게 뜬다. 파티가 없으면 모달에 그 사실을 안내한다.

- 중복 방지: 같은 party + 시작시각 ±1분에 살아있는 meeting이 있으면 경고 후 "Add it anyway"로만 강제 등록
- 참석자는 from/to/cc에서 수집, 모달에서 체크박스로 선택, 소문자 정규화 + 중복 제거 (`meeting_attendees`에 unique 제약이 없다)
- throw 대신 result 객체 반환 — 프로덕션 빌드에서 Next.js가 throw를 삼켜 모달에 에러가 안 보이는 것을 피하기 위함

## 5. 검증 상태

- 파서: 독립 컴파일 + 9케이스 런타임 테스트 통과 (repo와 동일한 strict + noUncheckedIndexedAccess 설정)
- 컴포넌트 3개: 구문 파싱 통과. **전체 `npx tsc --noEmit` 미실행** — 이 세션에서 `npm ci`가 끝나지 않았다. 기존에도 ~12개 선행 에러가 있고 `next.config.mjs`가 `ignoreBuildErrors: true`라 Railway 빌드는 막히지 않지만, 로컬에서 한 번 돌려볼 것.
- import 심볼(Textarea/Checkbox/Select/Button asChild/createMeeting/createCalendarEvent/SUPPORTED_TIMEZONES)은 실제 export 존재 확인 완료.

### 배포 후 손으로 확인할 것
1. 스크린샷의 Inquisitive Capital 스레드 → 보낸 메일 행에 Add to Calendar가 보이는가
2. 모달 프리필 시각이 메일에 쓴 시각과 같은가 (타임존 라벨 안내문 확인)
3. 저장 → `/calendar`와 `/today`에 칩이 뜨는가, `/meetings/<id>`가 열리는가
4. 같은 메일로 한 번 더 → 중복 경고가 뜨는가
5. 미팅 정보 없는 일반 메일에는 버튼이 **안** 보이는가

## 6. 다음 단계 — 구글 캘린더 반영

`src/lib/calendar/google-client.ts`에는 `updateGoogleEvent` / `deleteGoogleEvent`만 있고 **생성 함수가 없다**. 필요한 작업:

1. `google-client.ts`에 `createGoogleEvent(token, payload)` (POST `/calendars/primary/events`) 추가
2. `write-back.ts`에 `pushEventCreate()` 추가 — 기존 함수들처럼 never-throw, `{ ok, error? }` 반환
3. `add-email-to-calendar.ts` 성공 직후 best-effort 호출, 돌아온 외부 id를 `calendar_events.external_id` + `connection_id`에 저장 (meetings 경로면 mirror row를 만들어 `meetings.calendar_event_id`로 연결)
4. 이미 구글에서 만들어진 초대(메일이 구글 캘린더 초대문인 경우)를 다시 push하면 중복이 된다 — 본문에 `meet.google.com`이 있고 발신자가 우리일 때의 처리 규칙을 정해야 함
5. 활성 connection이 없으면 조용히 URM에만 저장

## 7. 적용 방법

파일 5개를 Downloads에 받은 뒤 인라인 PowerShell 블록으로 이동 → git push (채팅 응답의 블록 사용).

수정 대상 2개 파일은 **전체 교체**다. 기준 HEAD 해시(sha256 앞 16자리):
- `party-communications-timeline.tsx` = `7ae9f88c52091b7a`
- `communication-detail-view.tsx` = `646adacb7634756d`

다른 머신에서 이 두 파일을 먼저 고쳤다면 해시가 달라지고 그 변경이 덮어써진다. 이동 스크립트가 해시를 검사해 경고한다. 경고가 뜨면 덮어쓰지 말고 diff부터 볼 것.
