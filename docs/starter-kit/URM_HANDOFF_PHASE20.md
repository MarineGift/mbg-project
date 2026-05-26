# URM Platform — Phase 20 Handoff Document

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

## Phase 20 (Tier 1 CRM) — 완료된 5개 기능

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

---

## 다음 단계 추천 (Phase 21+)

### Tier 2 — B2B 영업 핵심 (각 2-4주)
| # | 기능 | 설명 |
|---|------|------|
| 21a | **이메일 추적** | open/click 픽셀 + 리다이렉트, 인박스에 표시 |
| 21b | **이메일 시퀀스** | 자동 follow-up cadence (Day 0/3/7) |
| 21c | **AI Deal Summary** | Anthropic SDK로 "지난 30일 활동 요약" |
| 21d | **커스텀 필드** | 모듈별 추가 필드 (JSONB) |
| 21e | **활동 리포트** | 단계별 체류시간, 전환율 by stage |

### Tier 3 — URM 차별화 (장기)
| # | 기능 | 차별성 |
|---|------|------|
| 22 | **Filler-Mill Match Score** | 우리 supplier × mill 필요 = 매치 확률 |
| 23 | **샘플 트래킹** | 제지업 특화 워크플로 |
| 24 | **지역 지도 뷰** | mill location 시각화 |
| 25 | **제품 카탈로그** | 표준 grade, 기술 스펙 |

### Compose 통합 (단발 작업)
- `template-picker-dialog.tsx`를 compose-form.tsx에 통합
- "Insert Template" 버튼 추가

---

## 작업 스타일 메모

- **언어**: Korean으로 대화, English UI text
- **PowerShell**: 대괄호 경로는 `-LiteralPath` 사용
- **패치 방식**: 다운로드 가능한 zip 파일 단위로 전달
- **SQL**: self-contained (no placeholders), Supabase SQL Editor에서 그대로 실행 가능
- **자동 진행**: 한 단계 완료 → 스크린샷 확인 → 다음 단계 자동 진행

---

## 새 세션 시작 시

이 문서를 첫 메시지로 붙여넣고, 원하는 Phase 21 기능 선택만 하면 즉시 진행 가능합니다.

**제 추천 시작점:**
- Quick win: **Phase 21a (이메일 추적)** — 메일 인프라 이미 있어서 빠름
- URM 차별화 극대화: **Phase 22 (Filler-Mill Match Score)** — 진짜 무기
