# 캘린더 통합 모듈 설계

목표: Google Calendar + Microsoft Outlook Calendar 통합 뷰 +  
mbg-project parties/engagements와 미팅 자동 매핑

---

## 1. 비즈니스 요구사항 (이전 대화 기반)

- 구글 일정과 마이크로소프트 일정을 불러와 일정표에 표시
- 고객사와 미팅 등을 종합적으로 관리
- mbg-project와 통합 (별도 앱 아님)
- 기존 `app.engagements`와 자연스럽게 연결

---

## 2. 아키텍처

### 2.1 데이터 흐름

```
사용자 ──OAuth 인증──> Google Calendar API
                    ──OAuth 인증──> Microsoft Graph API
                                              │
                                              ▼
                                    ┌─────────────────┐
                                    │ Sync Worker      │
                                    │ (worker thread)  │
                                    └────────┬────────┘
                                              │ Read events
                                              ▼
                              ┌──────────────────────────────┐
                              │ app.calendar_events (cache)  │
                              │ - source: google/ms/internal │
                              │ - external_id, etag          │
                              └──────────┬───────────────────┘
                                          │
                ┌─────────────────────────┼─────────────────────────┐
                ▼                          ▼                          ▼
        ┌──────────────┐         ┌──────────────┐          ┌──────────────┐
        │ Calendar UI  │         │ Auto-match   │          │ Manual link  │
        │ FullCalendar │         │ to party     │          │ to engagement│
        └──────────────┘         └──────┬───────┘          └──────┬───────┘
                                          │                          │
                                          ▼                          ▼
                                ┌────────────────────┐    ┌──────────────────┐
                                │ app.meetings        │◄───┤ Meeting create   │
                                │ (party-linked)      │    │ wizard           │
                                └────────────────────┘    └──────────────────┘
```

### 2.2 동기화 전략

**Pull (외부 → 내부)**: 5분 주기 polling 또는 webhook (Google watch / MS subscription)
- 첫 sync: 과거 30일 + 미래 90일 이벤트 풀로드
- Incremental sync: `syncToken` (Google) / `deltaLink` (MS) 활용

**Push (내부 → 외부)**: mbg-project에서 만든 미팅을 외부 캘린더로 전송
- 사용자가 "Google에도 추가" 체크 시 즉시 push
- 충돌 처리: 외부 시스템이 source of truth (etag 비교)

---

## 3. DB 스키마

전체 SQL은 `030_calendar_integration.sql` 파일 참고. 요약:

### 3.1 `app.calendar_connections`
사용자별 OAuth 연결 정보

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `id` | uuid | PK |
| `user_id` | uuid | FK → app.users |
| `organization_id` | uuid | FK → app.organizations |
| `provider` | enum | 'google' / 'microsoft' |
| `account_email` | text | 연결된 계정 이메일 |
| `access_token` | text | **암호화 저장** (pgcrypto) |
| `refresh_token` | text | **암호화 저장** |
| `expires_at` | timestamptz | 토큰 만료 |
| `scopes` | text[] | OAuth scope |
| `sync_token` | text | Google syncToken |
| `delta_link` | text | MS Graph deltaLink |
| `last_sync_at` | timestamptz | 마지막 동기화 |
| `last_sync_status` | enum | 'success' / 'failed' / 'partial' |
| `last_error` | text | 디버깅용 |
| `is_active` | boolean | 일시 정지 |

### 3.2 `app.calendar_events`
외부/내부 캘린더 이벤트 통합 캐시

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `id` | uuid | PK (내부 ID) |
| `organization_id` | uuid | 격리용 |
| `connection_id` | uuid | NULL = internal-only 이벤트 |
| `source` | enum | 'google' / 'microsoft' / 'internal' |
| `external_id` | text | Google eventId / MS event.id |
| `external_etag` | text | 충돌 감지용 |
| `title` | text | |
| `description` | text | |
| `location` | text | 물리적 위치 또는 화상 회의 URL |
| `start_at` | timestamptz | |
| `end_at` | timestamptz | |
| `timezone` | text | IANA tz |
| `is_all_day` | boolean | |
| `attendees` | jsonb | `[{email, name, response}]` |
| `organizer_email` | text | |
| `meeting_url` | text | Google Meet / Teams / Zoom 링크 |
| `recurrence_rule` | text | RRULE (반복 이벤트) |
| `recurring_event_id` | text | 부모 반복 이벤트 |
| `party_id` | uuid | FK → parties (auto/manual) |
| `engagement_id` | uuid | FK → engagements |
| `meeting_id` | uuid | FK → app.meetings (생성 시) |
| `status` | enum | 'confirmed' / 'tentative' / 'cancelled' |
| `last_modified_at` | timestamptz | 외부 시스템 기준 |

UNIQUE `(connection_id, external_id)` — 중복 방지

### 3.3 `app.meetings`
mbg-project 내부 미팅 (party-centric)

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `id` | uuid | PK |
| `organization_id` | uuid | |
| `party_id` | uuid | FK → parties (필수) |
| `engagement_id` | uuid | FK → engagements (선택) |
| `title` | text | |
| `meeting_type` | enum | discovery/pitch/negotiation/... |
| `meeting_mode` | enum | in_person/video_call/phone_call |
| `scheduled_at` | timestamptz | |
| `duration_minutes` | int | |
| `location` | text | |
| `agenda` | text | |
| `notes` | text | 미팅 후 작성 |
| `ai_summary` | text | AI 요약 (Phase C) |
| `follow_up_task_ids` | uuid[] | 자동 생성된 task |
| `status` | enum | scheduled/completed/cancelled/no_show |
| `calendar_event_id` | uuid | FK → calendar_events |
| `created_by` | uuid | |

### 3.4 `app.meeting_attendees`
미팅 ↔ contact 다대다

| 컬럼 | 타입 | 설명 |
|---|---|---|
| `meeting_id` | uuid | |
| `contact_id` | uuid | FK → contacts (NULL 가능 = 외부 참석자) |
| `email` | text | contact 없는 경우 |
| `name` | text | |
| `role` | text | organizer / required / optional |
| `response` | text | accepted / declined / tentative / no_response |

---

## 4. OAuth 흐름

### 4.1 Google Calendar

1. `/api/calendar/google/connect` → Google OAuth consent screen
   - Scopes: `https://www.googleapis.com/auth/calendar.readonly` (Phase 1)
   - 추후: `calendar.events` (write 가능)
2. Callback `/api/calendar/google/callback`
   - authorization code → access_token + refresh_token
   - `app.calendar_connections`에 암호화 저장
   - 첫 sync 트리거

### 4.2 Microsoft Graph

1. `/api/calendar/microsoft/connect` → MS login
   - Scopes: `Calendars.Read` (Phase 1), `Calendars.ReadWrite` (Phase 2)
   - `offline_access` 필수 (refresh token 받기)
2. Callback `/api/calendar/microsoft/callback`
3. MSAL (`@azure/msal-node`)로 토큰 관리

### 4.3 토큰 암호화

`pgcrypto` 사용. Supabase에 `app.encryption_key` (env var)로 키 주입.

```sql
-- 저장
INSERT INTO app.calendar_connections (..., access_token, ...) VALUES (
  ...,
  pgp_sym_encrypt(:plain_token, current_setting('app.encryption_key')),
  ...
);

-- 조회
SELECT pgp_sym_decrypt(access_token::bytea, current_setting('app.encryption_key'))::text
FROM app.calendar_connections WHERE id = :id;
```

---

## 5. 코드 구조 (mbg-project 안에)

```
src/
├── app/
│   ├── (app)/
│   │   ├── calendar/                       ← 신규
│   │   │   ├── page.tsx                    ← FullCalendar 메인 뷰
│   │   │   └── connections/
│   │   │       └── page.tsx                ← OAuth 연결 관리
│   │   └── [module]/parties/[id]/
│   │       └── (기존, meetings 탭 추가)
│   └── api/
│       └── calendar/
│           ├── google/
│           │   ├── connect/route.ts
│           │   ├── callback/route.ts
│           │   └── sync/route.ts
│           ├── microsoft/
│           │   ├── connect/route.ts
│           │   ├── callback/route.ts
│           │   └── sync/route.ts
│           └── webhooks/
│               ├── google/route.ts         ← Google watch notification
│               └── microsoft/route.ts      ← MS subscription notification
├── components/
│   ├── calendar/                           ← 신규
│   │   ├── calendar-view.tsx               ← FullCalendar wrapper
│   │   ├── event-detail-drawer.tsx
│   │   ├── meeting-create-form.tsx
│   │   ├── connection-card.tsx
│   │   └── party-meeting-link-dialog.tsx
│   └── parties/
│       └── party-meetings-list.tsx         ← 기존 stub, 실제 구현으로 교체
├── lib/
│   ├── calendar/                           ← 신규
│   │   ├── google-client.ts                ← googleapis SDK wrapper
│   │   ├── microsoft-client.ts             ← @microsoft/microsoft-graph-client wrapper
│   │   ├── sync.ts                         ← 동기화 핵심 로직
│   │   ├── matcher.ts                      ← 이벤트 ↔ party 자동 매핑
│   │   └── tokens.ts                       ← OAuth 토큰 암복호화 helper
│   ├── queries/
│   │   ├── calendar-events.ts              ← SELECT 쿼리
│   │   ├── meetings.ts                     ← 기존 stub 교체
│   │   └── calendar-connections.ts
│   └── actions/
│       ├── calendar-sync.ts                ← 수동 sync trigger
│       ├── meeting-create.ts
│       └── meeting-update.ts
└── workers/
    └── calendar-sync-worker.ts             ← 주기 sync (cron 또는 Edge Function)
```

---

## 6. 자동 매칭 로직 (events → parties)

`lib/calendar/matcher.ts`:

1. **참석자 이메일 도메인 매칭**
   - 이벤트의 attendee 이메일 도메인 추출
   - `app.parties.domain_normalized`와 매칭

2. **회사명 키워드 매칭**
   - 이벤트 title/description에서 등록된 party 이름 검색
   - `fuzzy_match_score` 함수 활용 (이미 001 SQL에 정의됨)

3. **contact 이메일 직접 매칭**
   - attendee 이메일이 `app.contacts.email`과 일치하면 그 contact의 party로 자동 연결

4. **확신도(confidence) 점수**
   - 0.9 이상: 자동 link
   - 0.5~0.9: 사용자 확인 후 link
   - 0.5 미만: 수동 매핑 필요로 표시

---

## 7. 라이브러리 의존성

추가할 npm 패키지:

```json
{
  "dependencies": {
    "googleapis": "^144.0.0",
    "@microsoft/microsoft-graph-client": "^3.0.7",
    "@azure/msal-node": "^2.16.0",
    "isomorphic-fetch": "^3.0.0",
    "@fullcalendar/react": "^6.1.15",
    "@fullcalendar/daygrid": "^6.1.15",
    "@fullcalendar/timegrid": "^6.1.15",
    "@fullcalendar/list": "^6.1.15",
    "@fullcalendar/interaction": "^6.1.15",
    "rrule": "^2.8.1",
    "date-fns-tz": "^3.2.0"
  }
}
```

설치 명령:
```powershell
npm install googleapis @microsoft/microsoft-graph-client @azure/msal-node isomorphic-fetch @fullcalendar/react @fullcalendar/daygrid @fullcalendar/timegrid @fullcalendar/list @fullcalendar/interaction rrule date-fns-tz
```

---

## 8. 환경변수 (`.env.local`에 추가)

```ini
# Google Calendar OAuth
GOOGLE_OAUTH_CLIENT_ID=...
GOOGLE_OAUTH_CLIENT_SECRET=...
GOOGLE_OAUTH_REDIRECT_URI=http://localhost:3000/api/calendar/google/callback

# Microsoft Graph OAuth
MS_OAUTH_CLIENT_ID=...
MS_OAUTH_CLIENT_SECRET=...
MS_OAUTH_TENANT_ID=common
MS_OAUTH_REDIRECT_URI=http://localhost:3000/api/calendar/microsoft/callback

# 토큰 암호화 키 (32 bytes hex)
CALENDAR_ENCRYPTION_KEY=<32-byte hex string>
```

각 OAuth 앱은 Google Cloud Console / Azure Portal에서 별도 생성 필요.

---

## 9. 보안 체크리스트

- [ ] access/refresh token은 pgcrypto로 암호화 저장
- [ ] `CALENDAR_ENCRYPTION_KEY`는 Supabase Vault 또는 환경변수 (절대 git 노출 X)
- [ ] RLS: 사용자는 자기 `connection`만 SELECT/UPDATE/DELETE
- [ ] OAuth state 파라미터 검증 (CSRF 방지)
- [ ] Token refresh 실패 시 자동 비활성화 + 사용자에게 재인증 요청
- [ ] Webhook endpoint는 서명 검증
- [ ] Rate limit (Google: 600/min/user, MS: 10,000/10min)

---

## 10. MVP 범위 (3주 안에 끝낼 분량)

**Week 1**: 인프라
- DB 마이그레이션 (calendar_connections, calendar_events, meetings, meeting_attendees)
- OAuth flow (Google + MS)
- 토큰 저장 및 refresh

**Week 2**: 동기화 + 표시
- Google/MS API에서 이벤트 pull
- `app.calendar_events`에 캐시
- FullCalendar UI로 표시
- party-events 자동 매칭 (도메인 기반)

**Week 3**: party 통합
- party detail page의 meetings 탭 실제 구현
- 수동 매핑 dialog
- 미팅 생성 폼 (engagement 연결)
- 회귀 테스트

**Phase 2 (Week 4~5)**:
- Push (내부 → 외부)
- Webhook 실시간 동기화
- 미팅 후 follow-up task 자동 생성

**Phase 3 (Week 6~7)**:
- AI 미팅 요약 (Anthropic SDK + ai.agents 활용)
- 미팅 추천 / 일정 충돌 감지
- Multi-user shared calendar
