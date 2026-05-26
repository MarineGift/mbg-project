# URM Platform — Phase 21a Handoff Document

**Last updated**: 2026-05-17  
**Branch**: marinebiogroup  
**Repo**: `C:\dev\mbg-project`

---

## 환경 정보

| 항목 | 값 |
|------|---|
| **OS** | Windows (PowerShell) |
| **Stack** | Next.js 14.2 + TypeScript + Supabase |
| **Supabase project** | `ogenmrgxwhpbfepeldqx` |
| **Organization ID** | `b25de8f2-1020-482f-9012-183f63883169` (MBG Project) |
| **Supabase server client** | `createSupabaseServerClient` from `@/lib/supabase/server` |
| **Default locale** | `'en'` (in `src/i18n/routing.ts`) |
| **i18n messages** | `src/i18n/messages/{en|ko|ja}.json` |

---

## Phase 20 (Tier 1 CRM) — 완료된 기능

### 20a — DB Foundation ✅
**Tables (app schema):**
- `email_templates` — 머지 필드 템플릿
- `meetings` — 통화/방문/Zoom 로그
- `saved_views` — 사용자별 필터 북마크

**Functions:**
- `app.calculate_lead_score(party_id)` — 0-100 점수
- `app.get_pipeline_forecast(org_id, months)` — 월별 가중 파이프라인

**Types**: `src/types/phase20.ts` 전체 타입 정의

### 20b — Meeting Log ✅
**Files:**
- `src/lib/actions/meetings.ts` — create/update/delete
- `src/lib/queries/meetings.ts` — fetchPartyMeetings/fetchEngagementMeetings
- `src/components/parties/meeting-form-dialog.tsx` — 5종 타입(call/visit/zoom/meet/other)
- `src/components/parties/party-meetings-list.tsx` — outcome 배지 + next steps 강조
- `src/app/(app)/[module]/parties/[id]/page.tsx` — 통합됨 (Notes 아래 표시)

### 20c — Email Templates ✅
**Files:**
- `src/lib/utils/merge-fields.ts` — `{{party.name}}` 등 렌더링
- `src/lib/actions/email-templates.ts`
- `src/lib/queries/email-templates.ts`
- `src/components/settings/email-template-form-dialog.tsx`
- `src/components/settings/email-templates-client.tsx`
- `src/components/compose/template-picker-dialog.tsx` — 재사용 가능 picker (compose에 아직 미통합)
- `src/app/(app)/settings/email-templates/page.tsx` — Settings 아래 자동 메뉴 표시

**머지 필드 지원:**
`party.name`, `party.countryCode`, `party.website`, `contact.fullName`, `contact.firstName`, `contact.lastName`, `contact.title`, `contact.email`, `my.name`, `my.email`

### 20d — Lead Score ✅
**핵심 차별화: 산업 데이터 기반 점수**

**Files:**
- `src/lib/queries/lead-score.ts` — `fetchLeadScore`, `fetchLeadScoresMany`
- `src/components/common/lead-score-badge.tsx` — Hot/Warm/Cool/Cold 배지

**SQL (Supabase 적용 완료):**
- `app.calculate_lead_score()` — TEXT 캐스팅 (enum 호환)
- `public.get_lead_scores_for_parties(UUID[])` — SECURITY DEFINER RPC

**점수 로직 (0-100):**
- Tier (max 30): tier_1=30, tier_2=20, tier_3=10, cold=0
- Industry signals for paper_mill (max 30):
  - mill count × 2 (max 15)
  - 0 confirmed suppliers = +15 (greenfield)
  - ≤2 suppliers = +8
- Engagement activity (max 25): open × 5 (max 15), won × 3 (max 10)
- Recent comms 30days (max 15)
- Paused = -20 penalty
- Closed/archived = 0

**Tier:**
- ≥70 = Hot 🔥 (rose)
- ≥40 = Warm (amber)
- >0 = Cool (sky)
- =0 = Cold (muted)

### 20e — Pipeline Forecast Widget ✅
**Files:**
- `src/lib/queries/forecast.ts`
- `src/components/dashboard/forecast-widget.tsx` — recharts Bar chart
- `src/app/(app)/page.tsx` — Dashboard 통합됨

**SQL:** `public.get_pipeline_forecast()` SECURITY DEFINER

**패키지 추가:** `npm install recharts`

**기능:**
- 6개월 weighted pipeline (value × probability/100)
- 월별 Bar chart + tooltip (weighted/total/count)
- Headline: total weighted + open deal count

### 20f — Saved Views ✅
**Files:**
- `src/lib/actions/saved-views.ts` — create/delete/togglePin
- `src/lib/queries/saved-views.ts` — fetchSavedViews
- `src/components/common/saved-views-dropdown.tsx` — Views dropdown + Save dialog

**SQL:** SECURITY DEFINER RPCs (`list_my_saved_views`, `create_saved_view`, `delete_saved_view`, `toggle_pin_saved_view`)
모두 `auth.uid()`로 사용자 격리

**기능:**
- 현재 URL 필터 캡처 → 이름 + Pin 옵션 저장
- 적용 시 동일 URL로 복원
- Pin 시 상단 고정
- entity별 격리 (party/engagement/task/draft)

### 추가 — Pagination ✅
**Files:**
- `src/components/common/pagination-bar.tsx` — Inbox 스타일 (재사용 가능)
- `src/app/(app)/[module]/parties/page.tsx` — 통합됨

**기능:**
- 페이지당 25/50/100/200 선택
- First/Prev/Next/Last 버튼
- "Page X of Y" 표시
- URL: `?page=2&perPage=100&sort=score`

---

## Phase 21a — 이메일 추적 ✅ (2026-05-17 완료)

### 아키텍처
TABS Mailer는 SMTP 릴레이 서버로 HTML 바디를 그대로 전달.
`communications.ts`에서 발송 직전에 픽셀을 삽입하고 TABS Mailer로 전달.

```
Compose 발송
  → createEmailTracking() : HTML에 1×1 픽셀 + 클릭 추적 링크 삽입
  → TabsMailerClient.sendOne(bodyHtml: injectedHtml)
  → 수신자 열람 시 /api/track/open/[token] 호출
  → app.email_tracking.open_count++ + first_opened_at 기록
```

### SQL 적용 이력
1. `phase21a_email_tracking.sql` — 테이블 3개 + RPC 4개 + RLS
   - `app.email_tracking` (org_id → app.organizations FK, draft_id plain UUID)
   - `app.email_tracking_links`
   - `app.email_tracking_events`
   - `public.record_email_open()` SECURITY DEFINER
   - `public.record_email_click()` SECURITY DEFINER
   - `public.create_email_tracking()` SECURITY DEFINER
   - `public.get_tracking_for_drafts()` SECURITY DEFINER
2. `phase21a_add_communication_id.sql` — communication_id 컬럼 추가
   - `ALTER TABLE app.email_tracking ADD COLUMN communication_id UUID`
   - `public.create_email_tracking()` RPC 교체 (p_communication_id 파라미터 추가)
   - `public.get_tracking_for_communications()` SECURITY DEFINER RPC 추가

**RLS 정책:** `auth.role() = 'authenticated'` (organization_members 테이블 없어서 단순화)

### 수정된 파일
| 파일 | 변경 내용 |
|------|----------|
| `src/lib/actions/communications.ts` | `createEmailTracking()` 호출 추가, `bodyHtml` 전달, `plainToHtml()` 내장 |
| `src/lib/actions/email-tracking.ts` | `communicationId` 파라미터 지원 |
| `src/lib/queries/email-tracking.ts` | `fetchTrackingMapForCommunications()` 추가 |

### 신규 파일
| 파일 | 역할 |
|------|------|
| `src/types/phase21.ts` | EmailTracking, TrackingPayload 등 타입 |
| `src/lib/utils/email-tracking.ts` | `extractLinks()`, `injectTracking()`, `plainToHtml()` |
| `src/app/api/track/open/[token]/route.ts` | 1×1 픽셀 GIF 응답 + open 기록 |
| `src/app/api/track/click/[token]/route.ts` | 클릭 기록 + 원본 URL 302 리다이렉트 |
| `src/components/inbox/tracking-badge.tsx` | Sent / 👁 opens / 🖱 clicks 배지 |
| `src/components/inbox/tracking-timeline.tsx` | 이벤트 타임라인 |
| `src/components/parties/party-tracking-panel.tsx` | 파티 상세 페이지 섹션 |

### 검증 완료 (2026-05-17)
- 테스트 발송: "Test URM Mail" → `ceo@marinebiogroup.com`
- `app.email_tracking` 행 생성 확인 ✅
- `communication_id` 연결 확인 ✅
- 픽셀 호출 후 `open_count = 1`, `first_opened_at` 기록 확인 ✅

### 미완료 (다음 세션에서 가능)
- 인박스 목록에 `<TrackingBadge>` 표시 (쿼리는 완성됨, UI 통합만 남음)
- 파티 상세 페이지에 `<PartyTrackingPanel>` 추가
- Compose에 `template-picker-dialog.tsx` 통합

---

## Parties Page — 현재 통합 상태

`src/app/(app)/[module]/parties/page.tsx`에 통합된 기능:
1. **Lead Score 컬럼** + 색상 배지
2. **Sort by score** 토글 버튼 (점수 내림차순)
3. **Saved Views 드롭다운** (Pin/Apply/Delete)
4. **Pagination bar** (Inbox 스타일)

---

## SQL 적용 이력 (Supabase Dashboard)

순서대로 실행했음:
1. `phase20_foundation_v2.sql` — 3개 테이블 + 2개 함수
2. `expose_lead_score_rpc.sql` — public.calculate_lead_score 래퍼
3. `fix_lead_score_v2.sql` — enum TEXT 캐스팅
4. `public.get_lead_scores_for_parties` 생성 (SECURITY DEFINER)
5. `expose_forecast_rpc.sql` — public.get_pipeline_forecast 래퍼
6. `saved_views_rpc.sql` — 4개 SECURITY DEFINER RPCs
7. `phase21a_email_tracking.sql` — 이메일 추적 테이블 3개 + RPC 4개 + RLS
8. `phase21a_add_communication_id.sql` — communication_id 컬럼 + RPC 2개 교체/추가

---

## 다음 단계 추천 (Phase 21b+)

### Tier 2 — B2B 영업 핵심
| # | 기능 | 설명 | 우선순위 |
|---|------|------|---------|
| 21a | **이메일 추적** | ~~open/click 픽셀 + 리다이렉트~~ | ✅ 완료 |
| 21b | **이메일 시퀀스** | 자동 follow-up cadence (Day 0/3/7) | 높음 |
| 21c | **AI Deal Summary** | Anthropic SDK로 "지난 30일 활동 요약" | 높음 |
| 21d | **커스텀 필드** | 모듈별 추가 필드 (JSONB) | 중간 |
| 21e | **활동 리포트** | 단계별 체류시간, 전환율 by stage | 중간 |

### Tier 3 — URM 차별화 (장기)
| # | 기능 | 차별성 |
|---|------|------|
| 22 | **Filler-Mill Match Score** | 우리 supplier × mill 필요 = 매치 확률 |
| 23 | **샘플 트래킹** | 제지업 특화 워크플로 |
| 24 | **지역 지도 뷰** | mill location 시각화 |
| 25 | **제품 카탈로그** | 표준 grade, 기술 스펙 |

### 단발 작업 (언제든 가능)
- 인박스 발송 목록에 `<TrackingBadge>` 표시
- 파티 상세 페이지에 `<PartyTrackingPanel>` 추가
- Compose에 `template-picker-dialog.tsx` 통합 ("Insert Template" 버튼)

---

## 작업 스타일 메모

- **언어**: Korean으로 대화, English UI text
- **PowerShell**: 대괄호 경로는 `-LiteralPath` 사용
- **패치 방식**: ZIP 다운로드 + PowerShell Copy-Item 코드 블록으로 전달
- **SQL**: self-contained (no placeholders), Supabase SQL Editor에서 그대로 실행 가능
- **자동 진행**: 한 단계 완료 → 스크린샷 확인 → 다음 단계 자동 진행
- **middleware.ts 없음**: `/api/track/*` 인증 없이 자동 공개 접근 가능

---

## 새 세션 시작 시

이 문서를 첫 메시지로 붙여넣고, 원하는 Phase 기능 선택만 하면 즉시 진행 가능합니다.

**추천 시작점:**
- 빠른 완성: **인박스 TrackingBadge 통합** — 코드 완성됨, UI 연결만 남음
- 다음 큰 기능: **Phase 21b (이메일 시퀀스)** — Day 0/3/7 자동 follow-up
- URM 차별화 극대화: **Phase 22 (Filler-Mill Match Score)** — 진짜 무기
