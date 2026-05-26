# D5-3d 가이드 — Supabase schema 헬퍼 사용법

## 도입

`src/lib/supabase/schema-helpers.ts` 가 추가됨. 4개 함수 export:

```typescript
import { sbApp, sbUrm, sbAi, sbIndustry } from '@/lib/supabase/schema-helpers';
```

각 함수는 Supabase client 인스턴스를 받아서 schema-scoped client 반환. 기존 client setup (createClient, server/client 분리, RLS 설정) 은 **건드리지 않음**.

---

## 코드 변환 패턴

### 패턴 A: 기존 `.schema('xxx').from(...)` 호출 (audit Section 2 의 10건)

**Before**:
```typescript
const { data } = await supabase
  .schema('app')
  .from('communications')
  .select('*')
  .eq('party_id', partyId);
```

**After**:
```typescript
import { sbApp } from '@/lib/supabase/schema-helpers';

const { data } = await sbApp(supabase)
  .from('communications')
  .select('*')
  .eq('party_id', partyId);
```

→ 의미 동일. 단, 명시적 헬퍼라 헷갈림 없음.

### 패턴 B: schema 미지정 `.from(...)` (audit Section 3 의 506건)

이게 D5-3e 의 핵심 작업. 현재 코드 대부분이 이 형태. 호출 테이블에 따라 헬퍼 선택:

**Before**:
```typescript
const { data } = await supabase
  .from('parties')      // ← 어느 schema? 모름. default = public
  .select('*');
```

**After — CRM 도메인**:
```typescript
import { sbUrm } from '@/lib/supabase/schema-helpers';

const { data } = await sbUrm(supabase)
  .from('parties')      // ← urm.parties (명시)
  .select('id, name, party_type_id, country_code');
```

**After — Mail infra**:
```typescript
import { sbApp } from '@/lib/supabase/schema-helpers';

const { data } = await sbApp(supabase)
  .from('communications')
  .select('*');
```

---

## D5-3e cutover 매핑표 (audit Section 3 의 .from() 분포 기준)

### sbUrm 으로 변환 (CRM 도메인 — 약 220건)

| Table arg | Count | 비고 |
|---|---:|---|
| `parties` | 176 | `urm.parties` |
| `tasks` | 18 | `urm.tasks` |
| `pipeline_stages` | 14 | ⚠ **`urm.stages` 로 이름 변경**도 같이 |
| `contacts` | 13 | `urm.contacts` |
| `deals` | 13 | `urm.deals` |
| `party_supply_links` | 6 | `urm.party_supply_links` |
| `pipelines` | 1 | `urm.pipelines` |
| `stages` | 1 | `urm.stages` |
| `engagement_stage_history` | 1 | `urm.deal_stage_history` (이름 변경) |

### sbApp 으로 명시 (Mail infra — 약 165건, *PERMANENT*)

| Table arg | Count | 비고 |
|---|---:|---|
| `communications` | 41 | 핵심 mail infra |
| `drafts` | 17 | ⚠ schema 확인 필요 (ai.drafts 가능성) |
| `email_signatures` | 12 | |
| `mail_merge_jobs` | 9 | |
| `meetings` | 9 | Layer 분리상 mail infra (또는 urm.engagements?) |
| `email_templates` | 8 | |
| `users` | 9 | `app.users` |
| `pipeline_definitions` | 4 | ⚠ 검토 — pipelines? |
| `consultations` | 4 | |
| `calendar_events` | 4 | |
| `meeting_attendees` | 4 | |
| `calendar_connections` | 3 | |
| `email_tracking` | 3 | |
| `strategy_actions` | 2 | |
| `mailcarrier_state` | 2 | |
| `email_whitelist` | 2 | |
| `organizations` | 2 | |
| `auto_send_rules` | 2 | (ai 일 수도) |
| `response_strategies` | 1 | |
| `email_sequence_sends` | 1 | |
| `brand_voice` | 1 | **sbAi** (ai.brand_voice) |
| `attachments` | 1 | |
| `agents` | 1 | **sbAi** (ai.agents) |
| `saved_views` | 1 | |
| `email_tracking_events` | 1 | |

### sbIndustry 로 변환 (Industry 도메인 — 약 102건)

| Table arg | Count | 비고 |
|---|---:|---|
| `paper_companies` | 33 | |
| `paper_mills` | 31 | |
| `supplier_mill_linkages` | 18 | |
| `filler_suppliers` | 17 | |
| `markets` | 3 | |

### 무시 또는 검증 필요 (~10건)

| Table arg | Count | 분류 |
|---|---:|---|
| `R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7` | 3 | base64 GIF 데이터, false positive (regex 가 잡은 string literal) |
| `email-attachments` | 5 | 검토 필요 (storage bucket 이름일 수도) |
| `msg1`, `msg2`, `fake pdf bytes`, `raw rfc822` | 4 | 테스트 데이터 / mock |
| `runs` | 5 | **sbAi** (ai.runs) |

---

## cutover 우선순위 (D5-3e ~ D5-3f 분할)

| 순서 | 작업 | 영향 | 위험 |
|---|---|---|---|
| 1 | Section 2 의 10건 `schema('app')` → `sbApp()` | 의미 동일, 단순 변환 | 매우 낮음 |
| 2 | `paper_*` / `filler_*` / `supplier_*` / `markets` → `sbIndustry()` | 정확도 향상 (default public 호출이 영향 받았을 가능성) | 낮음 |
| 3 | Mail infra 호출 → `sbApp()` 명시 | 정확도 향상 | 낮음 |
| 4 | `agents` / `brand_voice` / `runs` → `sbAi()` | 정확도 향상 | 낮음 |
| 5 | `parties` 176 호출 → `sbUrm()` + party_type → party_type_id JOIN | 핵심 cutover | 높음 (테스트 필수) |
| 6 | `contacts` / `deals` / `tasks` / `stages` / `pipelines` → `sbUrm()` | CRM 코어 | 중간 |
| 7 | `pipeline_stages` → `stages` rename + `sbUrm()` | 코드 + schema 양쪽 | 중간 |
| 8 | Inbox UI: linkEmailToDeal server action (D5-3g) | 새 기능 | 신규 작성 |

---

## 검증 흐름

각 cutover 단계마다:

```powershell
# 1. tsc 에러 0 유지
npx tsc --noEmit 2>&1 | Select-String 'error TS' | Measure-Object

# 2. 한 모듈 cutover 후 dev 실행 + 영향받는 페이지 수동 확인
npm run dev

# 3. git diff 확인 후 단위별 commit
git add <files>
git commit -m "D5-3e/X: cutover <module> to sbUrm"
```

---

## 주의 사항

1. **`schema()` 가 method chaining 중간에 못 옴**: 반드시 `sbXxx(supabase)` 가 chain 의 시작.
   ```typescript
   // ❌ supabase.from('x').schema('urm') -- syntax error
   // ✅ sbUrm(supabase).from('x')
   ```

2. **`as never` cast 제거 검토**: 기존 코드의 `.from('x' as never)` 는 type 우회 목적. helper 도입 후 타입이 정확하면 cast 제거.

3. **server vs client component**: supabase client 가 server 인지 client 인지 헬퍼는 관심 없음. 사용자가 넘긴 인스턴스 그대로 schema 만 스코프.

4. **drafts 의 schema**: D5-1 audit 결과 `ai.drafts.body_plain` 확인됨 → `sbAi(supabase).from('drafts')`. app.drafts 가 따로 있는지는 D5-3e 시작 시 재확인.
