# 세션 핸드오프 — 2026-05-28

mbg-project (URM Platform) / repo `MarineGift/mbg-project` branch `marinebiogroup`
local `C:\dev\mbg-project` · org `b25de8f2-1020-482f-9012-183f63883169` · Supabase `ogenmrgxwhpbfepeldqx`

오늘 두 트랙을 진행: **(1) 캘린더 통합** (외부 차단으로 일시중단), **(2) 크라우드 펀딩** (DB 구조 완료).

---

## 0. 이번 세션 핵심 교훈

- 메모리가 ~13일(5/14 시점) 낡아 있었고, 그 사이 **V2 리디자인**(Session 10→11, `docs/urm_refactoring_spec.md`)이 있었음.
- 옛 모델(`parties.module` buyer/filler, `party_level`, 별도 `industry.*` 스키마, crowdfunding/product_launch party type)은 **제거됨**.
- 초반 진단 SQL이 전부 실패한 건 데이터 손실이 아니라 **스키마가 바뀐 것** → 기억이 아닌 **클론 레포/라이브 DB로 먼저 검증**하는 원칙 재확인.

---

## 1. 확정된 V2 스키마 사실 (이번 세션 검증)

- **`app.stages`가 정규 stage 테이블** (`stages.pipeline_id` → `pipelines` 직접 FK). `app.pipeline_stages`는 **레거시**(구 module 시대; `pipeline_definition_id` + `stage_type` enum) — **건드리지 않음**.
- **pipelines는 party_type/module 무관 독립 테이블** → 새 파이프라인 추가가 깔끔함.
- 구조 흐름: `pipelines → stages → deals → {deal_checklists, tasks, engagements, deal_stage_history, reward_tiers, deal_backers}`.
- **`deals.party_id`는 NOT NULL** (캠페인도 party 필요 → Option 2 채택, 아래).
- `party_type` enum (DB): investor, paper_mill, partner, customer, filler_supplier (※ TS에는 buyer/government_grant도 있으나 DB enum엔 위 5개).
- deals 참조 자식(정식 FK): `deal_checklists`, `tasks`, `deal_stage_history`, `reward_tiers`, `deal_backers`.
- **`engagements`는 `deal_id` 컬럼은 있으나 deals로의 FK 제약이 없음** (논리적 연결만). 그 외 `engagements.task_id`→tasks, `party_id`→parties, `stage_id_at_time`→stages.
- 자식 간 연결: `tasks.checklist_id`→deal_checklists, `tasks.assigned_to_contact_id`→contacts.
- 모든 app 테이블 RLS 패턴: `organization_id = app.current_organization_id()` (헬퍼 존재; `app.current_user_id()`도 있음).
- 마이그레이션 추적 테이블(`supabase_migrations.schema_migrations`)은 희소함 — 대부분 SQL Editor로 직접 적용했기 때문.

---

## 2. 트랙 A — 캘린더 통합 (⏸ 외부 차단으로 일시중단)

목표: 좌측 사이드바에 캘린더 표시 + Google/Microsoft 이벤트 pull(추후 push).
**기능의 ~90%가 레포에 이미 구현돼 있음**: OAuth connect/callback 라우트(google·microsoft), 클라이언트 라이브러리(`src/lib/calendar/*`), UI(`/calendar`, `/settings/calendar`), 쿼리(`src/lib/queries/calendar.ts`, V2 정렬됨), 마이그레이션 `030_calendar_integration.sql` + `031_calendar_token_functions.sql`.

### 완료
- **사이드바 배선**: `src/components/layout/sidebar.tsx`에 Calendar 링크(`/calendar`) + `nav.calendar` i18n 키(ko/en/ja) 추가. (working tree에 **미커밋** 상태)
- **DB 사전요건 검증**: pgcrypto는 `extensions` 스키마에 존재(※ public 아님). 030 테이블/enum 존재.
- **031 토큰 함수 수정 완료**: 원본이 시그니처 불일치 + `search_path`에 `extensions` 누락으로 깨져 있었음 → `031_calendar_token_functions_clean_reset.sql` 실행으로 5개 함수 클린 재생성(`SET search_path = app, public, extensions`), 라운드트립 테스트 통과.
  - ⚠️ **레포의 `supabase/migrations/031_...` 원본은 아직 옛 깨진 버전** → clean-reset 내용으로 교체 필요(재배포 무결성).
- **암호화 키**: `CALENDAR_TOKEN_ENCRYPTION_KEY` 재생성(.env.local, 32-byte base64, 미노출). **이 키는 변경 금지**(connect 후 변경 시 토큰 복호화 깨짐).

### 펜딩 — 외부 차단
- **OAuth 앱 등록이 막힘**: Google Cloud Console이 `www.gstatic.com` 로드 실패로 안 열림(광고차단 확장 또는 네트워크/방화벽/VPN 추정).
- **내일 시도**: 시크릿 창 / 다른 브라우저 / 폰 핫스팟 / VPN·확장 끄기 / `gstatic.com`·`googleapis.com` 허용.
- 콘솔 열리면: Google Calendar API 활성화 → OAuth 웹 클라이언트(콜백 `/api/calendar/google/callback`) → env 채우기 → `/settings/calendar`에서 Connect → Sync.
- 필요 env: `GOOGLE_CALENDAR_CLIENT_ID/_SECRET/_REDIRECT_URI`, `MICROSOFT_CALENDAR_CLIENT_ID/_SECRET/_REDIRECT_URI`, `NEXT_PUBLIC_APP_URL`(+ 이미 설정된 암호화 키). dev에선 `CRON_SECRET` 비워둠. **모든 redirect URI + APP_URL + 콘솔 등록을 한 포트로 통일**(3000 또는 3001).
- 가이드: `calendar-step2-oauth-setup.md`, `calendar-oauth-registration-guide.md`.

---

## 3. 트랙 B — 크라우드 펀딩 (✅ DB 구조 완료)

설계 결정: 캠페인 = **새 독립 파이프라인**의 `deals` 1행. backer = **B안**(party/contact 연계 + 약정 junction). reward tiers 포함.

### 완료 (검증됨)
`crowdfunding_setup.sql` 실행 — 검증 8행 + 2테이블 확인:
- `app.pipelines` : `crowdfunding` 파이프라인(sort_order=2).
- `app.stages` : 8단계 — planning(5%) → preparing(15%) → pre_launch(30%) → live(50%) → funded(90%) → fulfillment(95%) → closed(100%, won+terminal) → cancelled(0%, lost+terminal). stage `name`은 기존 컨벤션대로 영문.
- `app.reward_tiers` : 캠페인 리워드 등급(deal FK CASCADE, min_amount, limit_qty/claimed_qty, estimated_delivery, sort_order) + RLS + index + authenticated GRANT.
- `app.deal_backers` : 후원 junction(deal_id + party_id/contact_id/reward_tier_id NULL 허용, pledge_amount, status CHECK pledged/collected/refunded/failed/cancelled, is_anonymous, display_name, pledged_at/collected_at) + RLS + index + GRANT.

### Option 2 — party_id 처리 (오늘 채택)
`deals.party_id`가 NOT NULL이므로, **공유 host party** 하나를 만들어 모든 캠페인 deal이 참조. backer는 `deal_backers`에 별도.
- `crowdfunding_host_party.sql` 실행 → `'Crowdfunding Campaigns (Host)'` party 생성(type/entity id는 코드로 조회, idempotent).
- (host의 party_type은 'partner'로 기본 — host엔 진짜 counterparty type이 없어 임의; 조정 가능.)

### 다음 세션 — 첫 캠페인 생성 템플릿 (준비 완료, 바로 실행 가능)
```sql
DO $$
DECLARE
  v_org      uuid := 'b25de8f2-1020-482f-9012-183f63883169';
  v_pipeline uuid;
  v_stage    uuid;
  v_host     uuid;
  v_deal     uuid;
BEGIN
  SELECT id INTO v_pipeline FROM app.pipelines WHERE code='crowdfunding' AND organization_id=v_org;
  SELECT id INTO v_stage    FROM app.stages    WHERE pipeline_id=v_pipeline AND code='planning';
  SELECT id INTO v_host     FROM app.parties   WHERE party_name='Crowdfunding Campaigns (Host)'
                                                 AND organization_id=v_org AND deleted_at IS NULL;

  INSERT INTO app.deals
    (deal_name, pipeline_id, current_stage_id, party_id, status, value_amount, value_currency,
     organization_id, created_at, updated_at)
  VALUES
    ('[SAMPLE] My first campaign', v_pipeline, v_stage, v_host, 'open', 50000, 'USD',
     v_org, now(), now())
  RETURNING id INTO v_deal;

  INSERT INTO app.reward_tiers (organization_id, deal_id, name, min_amount, currency, sort_order)
  VALUES (v_org, v_deal, 'Early bird', 25, 'USD', 1),
         (v_org, v_deal, 'Standard',   50, 'USD', 2),
         (v_org, v_deal, 'Premium',   150, 'USD', 3);

  RAISE NOTICE 'campaign deal: %', v_deal;
END $$;
```
※ `deals.status` 허용값 미확인 — `'open'`이 안 맞으면 기존 deals의 status 값을 확인해 맞출 것.

---

## 4. 다음 세션 우선순위

1. **캘린더**: Google 콘솔 `gstatic` 차단 해제 → OAuth 등록(가이드) → connect/sync → pull 검증.
2. **크라우드 펀딩**:
   - host party 생성 확인(`crowdfunding_host_party.sql`).
   - 위 템플릿으로 첫 캠페인 deal + reward_tiers 생성(필요 시 status 값 조정).
   - 그 후 **UI 연결** — crowdfunding 파이프라인이 칸반/사이드바에 뜨는지 확인, 안 뜨면 파이프라인 표시 로직을 **클론 레포에서 먼저 진단** 후 배선.
3. **위생**:
   - 레포 `031` 마이그레이션을 clean-reset 내용으로 교체.
   - tsc 오류(Claude 패치 아님): `src/lib/queries/communication-detail-v2.ts:183` 캐스트를 `as NonNullable<CommunicationDetail['party']>['partyType']`로 수정(`next build`만 막음, dev는 정상).

---

## 5. 이번 세션 산출 파일 (Downloads)

- `crowdfunding_setup.sql` (적용·검증 완료)
- `crowdfunding_host_party.sql` (Option 2 host party)
- `031_calendar_token_functions_clean_reset.sql` (DB 적용 완료; 레포 교체 필요)
- `calendar-step2-oauth-setup.md`, `calendar-oauth-registration-guide.md` (참고)
- `SESSION_HANDOFF_2026-05-28.md` (이 문서)
