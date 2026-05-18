# URM Platform Handoff v5.5

**날짜**: 2026-05-15
**이전**: v5.4 (2026-05-14)
**다음**: v5.6 (UI Phase B 이어서 + Mondi family 정리 또는 #20/#23 Phase 3)

---

## v5.4 → v5.5 변경점

### 핵심 성과 — Sappi family 25 → 6 row 정리 완료 🎉

**옵션 B 패턴 확정 + 첫 multinational family 정리 실 사례.** 13 family 중 Sappi(21 → 25 실측)부터 시작, Phase 1 + Phase 2 전체 진행. 다음 family는 같은 패턴 반복 가능.

### 새 schema 결정 — #17 옵션 A 적용

`public.tier_role` ENUM (`HQ`, `Regional`, `Country`, `Plant`) 생성.
- `industry.paper_companies.tier_role` 컬럼 추가 (NULLABLE)
- `industry.filler_suppliers.tier_role` 컬럼 추가 (NULLABLE)
- 두 컬럼 모두 인덱스 보유
- `paper_mills`에는 추가 안 함 — paper_mills 자체가 Plant tier로 schema 차원 암시

### 새 schema 결정 — #18 옵션 B 적용 (옵션 B 본격 진입)

**`paper_mills`를 plant 단일 정본.** `paper_companies`에서 Plant tier row 제거. Sappi에 적용 완료:
- mill 6개 reattach (Alfeld/Gratkorn → Sappi Europe, 남아공 4 → Sappi Limited HQ 직속)
- paper_companies plant 6 row DELETE (267, 341, 431, 494, 551, 566)

### 새 schema 확장 — `app.parties.industry_paper_mill_id` 컬럼 신설

`app.parties`에 mill 단위 reference 컬럼 추가:
```sql
ALTER TABLE app.parties ADD COLUMN industry_paper_mill_id BIGINT;
ALTER TABLE app.parties ADD CONSTRAINT parties_industry_paper_mill_id_fkey
  FOREIGN KEY (industry_paper_mill_id) REFERENCES industry.paper_mills(id)
  ON DELETE SET NULL;
CREATE INDEX parties_industry_paper_mill_id_idx ON app.parties(industry_paper_mill_id);
```

Plant tier를 paper_mills로 단일 정본화하면서 app.parties에서도 mill 직접 reference 가능.

### Production security 확립

`industry.{paper_mills, paper_companies, filler_suppliers, markets}` 4 테이블 RLS enable + `industry_select_authenticated` SELECT policy 적용. authenticated user에게 read 권한 통과.

---

## Phase 1 + Phase 2 진행 결과 — Sappi family 25 → 6 row

### 최종 Sappi 6 row (paper_companies)

| tier_role | id | name | market_code | mill | notes |
|---|---|---|---|---|---|
| HQ | 204 | Sappi Limited | south_africa | 4 | — |
| Regional | 1 | Sappi Europe | europe_composite | 3 | High-priority filler consumer... |
| Regional | 54 | Sappi North America | usa | 3 | — |
| Country | 370 | Sappi Italy | italy | 0 | — |
| Country | 396 | Sappi Portugal | portugal | 0 | V11.4 annotation 보존 |
| Country | 1018 | Sappi Finland | finland | 1 | M-real history 보존 |

### paper_mills 매핑 (11 mill, Sappi family)

```
Sappi Limited (HQ) 산하 4:
  - 302 Springs Gauteng
  - 303 KwaZulu-Natal (Dissolving wood pulp)   = Saiccor
  - 304 Mpumalanga                              = Ngodwana
  - 305 KwaZulu-Natal (Paper)                   = Stanger

Sappi Europe (Regional) 산하 3:
  - 392 Alfeld
  - 461 Gratkorn (Graz Styria)
  - 497 Multi-region                            ⚠️ rollup, Phase 3 split 대상 (#23)

Sappi North America (Regional) 산하 3:
  - Cloquet Mill
  - Somerset Mill
  - Westbrook Mill

Sappi Finland (Country) 산하 1:
  - 386 Finland                                 ⚠️ mill_name dirty, Phase 3 정리 대상 (#20)
```

### 단계별 row 변화

```
시작:  25 row
Phase 1 (Plant 6 deprecate)        → 19 row  (267/341/431/494/551/566 DELETE)
Phase 2-B (Finland dup 정리)       → 17 row  (260/757 DELETE, 1018 정본 + M-real notes)
Phase 2-C (Italy/Lanaken/compound) → 15 row  (373/455 DELETE, mill 497 → Sappi Europe)
Phase 2-D (Portugal/Swiss/multi-mill) → 13 row  (797/334 DELETE, linkage 552/557/561 → K-C 488)
Phase 2-E (Compound 7 일괄)        → 6 row   (795/799/875/877/987/1057/1070 DELETE)
```

### app.parties 정리

Sappi 관련 row 정합:
- Plant 6 row의 link reattach (Phase 1, `industry_paper_company_id` → NULL, `industry_paper_mill_id` 채움)
- Sappi Finland dup 제거 (260 DELETE, 757 → name='Sappi Finland' + 1018 reattach)
- Italy/Lanaken/Portugal/Swiss/multi-mill 정리 시 같은 패턴 적용

### supplier_mill_linkages 정리

- linkage 730 (Omya↔Gratkorn): paper_mill_id=461 backfill + paper_company_id=1 reattach
- linkage 552/557/561 (V11.4 잘못된 매핑): paper_company_id 797 → 488 (K-C SA plants, mill 314의 real parent)로 정합 복구
- compound 7 linkage (754/643/647/739/650/736/563): weak evidence (E4/E5)라 일괄 DELETE

---

## 새 schema 발견 (v5.4 audit 누락 사항)

### `industry.supplier_mill_linkages` 컬럼 + FK

```
22 컬럼: id, market_code (NOT NULL), legacy_id, filler_supplier_id, paper_company_id,
        paper_mill_id, supplier_name_raw, paper_company_name_raw, mill_site_raw,
        country_region, relationship_type, filler_type, supply_structure,
        confirmation_status, confidence_grade, evidence_level,
        supplier_evidence_url, transaction_evidence_url, customer_mill_evidence_url,
        current_status, assessment_scope, notes, created_at

FK 4개:
  filler_supplier_id → industry.filler_suppliers(id)    NO ACTION
  market_code        → industry.markets(code)            NO ACTION
  paper_company_id   → industry.paper_companies(id)      NO ACTION ⚠️ v5.4 누락
  paper_mill_id      → industry.paper_mills(id)          NO ACTION
```

### `app.parties` 컬럼 (관련 부분)

```
industry_paper_company_id   bigint  YES   기존
industry_filler_supplier_id bigint  YES   기존
industry_paper_mill_id      bigint  YES   ★ v5.5에서 신설
parent_party_id             uuid    YES   party 간 hierarchy
party_level                 text    YES   ⚠️ tier 라벨 컬럼 ('country_entity' 값)
tier                        tier_level NO ⚠️ ENUM ('tier_3' 값 — customer tier 추정)
module                      module_type NO  ('paper_mill' 등 ENUM)
module_data                 jsonb   NO    모듈별 메타
```

### `paper_companies` 기준 incoming FK 3개

```
app.parties.industry_paper_company_id          → SET NULL
industry.paper_mills.paper_company_id          → CASCADE  ⚠️ 위험
industry.supplier_mill_linkages.paper_company_id → NO ACTION
```

**v5.5 lesson #7**: paper_companies / filler_suppliers 기준 incoming FK 점검도 schema audit 필수 단계. v5.3 27 테이블 reference map + v5.4 18+ audit 모두 이를 누락. 다음 family 정리 시 incoming FK 전수조사 먼저.

### `industry` 8개 테이블 (전부)

```
filler_plants               (v5.4 신설)
filler_suppliers
market_findings             ⚠️ v5.4 미식별 — Phase 3 점검 대상
markets
paper_companies
paper_mills
supplier_mill_linkages
verification_queue          ⚠️ v5.4 미식별 — Phase 3 점검 대상
```

---

## 운영 lesson 추가 (v5.4 lessons 확장)

7. **`paper_companies` 기준 incoming FK 점검 필수** — outgoing FK + UNIQUE constraint 점검만으로는 부족. DELETE 전 incoming FK 전수조사. v5.4에서 두 번 누락(supplier_mill_linkages.paper_company_id, app.parties.industry_paper_company_id).
8. **022 promotion script 버그 확인** — `app.parties.module='paper_mill'` + `party_level='country_entity'` 모순 다수 발견. Country tier paper_companies를 paper_mill module로 잘못 promotion. Sappi 외 다른 family도 같은 패턴 가능. Phase 3 audit 필수.
9. **V11.4 자동생성 stub 패턴 인지** — `notes='Auto-created from paper_mills'` 또는 `'Auto-created from supplier_mill_linkages'` 보이는 row는 V11.4 자동생성. 정보 가치 거의 없음, DELETE 안전. compound entity 8개 + Finland dup 3개 모두 이 패턴.
10. **paper_mills multi-region rollup 패턴** — `mill_name='Multi-region'` 또는 country/region 수준 이름 (`Finland`, `KwaZulu-Natal`, `Mpumalanga`) 다수 발견. plant 단위 정본 보장 부분 깨짐. Phase 3 광범위 정리 작업 필요.
11. **RLS off + GRANT SELECT 만으로도 read 작동** — 단 production security는 RLS enable 권장. v5.5에서 4 테이블 RLS enable 완료.
12. **Supabase SQL editor multi-statement 함정 재확인** — 마지막 query 결과만 노출. 결정 query (audit 등)는 반드시 단독 Run.

---

## 미해결 항목 (Phase 3+ 작업)

v5.4 미해결 + 새 발견:

**v5.4 그대로 유지:**
- **#8**: Supabase 타입 재생성 (`.schema('industry' as never)` + `app.parties` 새 컬럼 반영)
- **#9**: i18n 라벨 cosmetic
- **#12**: 3-tier 운영화 (parent_party_id backfill)

**v5.4 부분 진행:**
- **#15**: compound entity 정책 — Sappi 7 row DELETE로 처리. 다른 family에도 동일 패턴 적용 예정
- **#17**: ✅ 완료 (옵션 A — industry.tier_role ENUM)
- **#18**: ✅ Sappi에 적용 완료 (옵션 B — paper_mills 단일 plant 정본). 다른 12 family에 같은 패턴 반복 필요

**v5.5 신규:**
- **#19**: `app.parties.tier` (tier_level ENUM, 'tier_3' 값) 의미 파악. enterprise/customer tier vs HQ/Regional/Country/Plant. #17과 별개 의미일 가능성.
- **#20**: `paper_mills.mill_name` 정규화. Phase 1-2에서 발견된 dirtiness:
  ```
  - Country 수준 이름: 'Finland' (mill 386)
  - 광역주 이름: 'KwaZulu-Natal' x2 (mill 303 Saiccor, 305 Stanger — 식별 불가)
                 'Mpumalanga' (mill 304 Ngodwana), 'Springs Gauteng' (mill 302 Springs)
  - 도시+annotation: 'Gratkorn (Graz Styria)' (mill 461)
  ```
- **#21**: `paper_companies` → `app.parties` promotion 전수 audit. 022 script bug (module='paper_mill' + party_level='country_entity' 모순) 광범위 가능. Sappi 외 13 family에도 같은 bug 가능.
- **#22**: `app.parties.party_level` (text) ↔ `industry.tier_role` (ENUM) 정합성 정책. 일원화 vs 양쪽 유지 결정. 022 script의 module type 누락 + Country를 paper_mill로 promote한 bug 같이 점검.
- **#23**: `paper_mills` multi-region rollup split. 8개 이상 발견:
  ```
  314  Multi-region (south_africa)   → K-C SA plants (488)
  275  Multi-region (austria 추정)    → K-C Colombia plants ⚠️ V11.4 매핑 모순
  400  Multi-region (germany)         → Sonae Arauco Germany plants ⚠️ 의심
  484  Multi-region Italy + USA       → Sofidel (692)
  494  Multi-region Italy + Spain + France + Hungary → Lucart (688)
  495  Multi-region Italy             → RDM (621)
  497  Multi-region (italy)           → Sappi Europe (임시, v5.5 reattach) ⚠️ 진짜 split 필요
  498  Multi-region (italy)           → IP Italia ⚠️ 의심
  ```
  paper_mills 전체 audit으로 추가 발견 가능. #20과 묶어서 처리.
- **#24**: `industry.market_findings`, `industry.verification_queue` 테이블 정체 파악. v5.4 미식별, 데이터 분포 + 사용처 점검.

---

## v5.6+ Step 재정의

### Step A — Paper side 정리 (Sappi 완료, 12 family 남음)

A-1 ✅ Sappi 완료 (v5.5 본 작업)
A-2 다음 family (우선순위 미정):
  - **Mondi 43** — 가장 큰 family, Sappi와 유사 구조 예상 (multi-country, 4 tier 활용)
  - **Stora Enso 24** — finnish + swedish, country/regional tier 활용 예상
  - **UPM 26** — finnish, paper + biofuels
  - **Smurfit 26** — packaging focus
  - 또는 row 적은 family부터 (Metsä 8, Fedrigoni 9)

A-3 placeholder 183 정책 (v5.4 unchanged)
A-4 compound 정책 일반화 (Sappi 사례 적용)

### Step B — Filler side 정리 (시작 안 됨)

v5.4 그대로:
- Omya 31, Imerys 38, Artemyn 39, MTI 34 동일명 split
- Artemyn ↔ Imerys (former assets) 통합 정책
- MTI ↔ Specialty Minerals (모자회사) 정책

### Step C — paper_mills 측 정리 (#20 + #23)

- mill_name 정규화 (광역주/country 수준 이름 → 도시 단위)
- multi-region rollup split (8+ row)
- paper_mills 전체 audit으로 추가 dirty row 발견

### UI Phase A — Industry 화면 (Phase B 진행 중)

v5.5 끝나는 시점 상태:
- ✅ Phase 0: RLS/GRANT 완료
- ✅ Phase A 1단계: shadcn init + badge/table 추가, `TierRoleBadge.tsx` + `EvidenceBadge.tsx` 생성
- 🔄 Phase A 2단계: `industry/layout.tsx` + `IndustryTabs.tsx` 생성 시작 (코드 준비됨, paste 직전 채팅 한도 도달)
- ⏳ Phase A 3단계: `industry/paper-mills/page.tsx` (server) — 코드 준비됨, 본인 환경 반영 필요
- ⏳ Phase A 4단계: `industry/paper-mills/PaperMillsTable.tsx` (client) — 코드 준비됨

UI sample 코드 전체는 별도 file (`urm_industry_ui_phase1.md`)에 정리됨, v5.6에서 이어서 진행.

---

## Phase 7-c 진입 조건 + 현재 상태

- ✅ Schema 발견 완료 (v5.4 18+ audit + v5.5 추가 발견)
- ✅ industry.filler_plants 신설 완료
- ✅ 명명 컨벤션 결정 (3-info 모델 + 4 role)
- ✅ #17 옵션 A 적용 (tier_role ENUM)
- ✅ #18 옵션 B 진입 (paper_mills 단일 정본)
- ✅ Sappi family 첫 정리 완료 (6 row)
- ✅ app.parties.industry_paper_mill_id 컬럼 신설 + FK + 인덱스
- ✅ RLS 4 테이블 enable + SELECT policy 적용
- 🔄 UI Phase A 진행 중 (Phase B paper-mills 코드 paste 단계)
- ⏸ 12 multinational family 정리 (v5.6+)
- ⏸ filler side 정리 (Step B, v5.6+)
- ⏸ paper_mills 정리 (#20 + #23, Phase 3)
- ⏸ 022 promotion script audit (#21)
- ⏸ `app.parties.tier`/`party_level` vs `industry.tier_role` 정합 (#19 + #22)

---

## v5.5 끝나는 시점 정확한 상태 — UI 작업 이어받을 정보

### 본인 환경 (v5.5 진행 중 확인됨)

```
Stack:           Next.js 14.2, TypeScript strict, Supabase, shadcn/ui, Tailwind
프로젝트 경로:    C:/dev/mbg-project
Supabase server: src/lib/supabase/server.ts
함수 이름:        createSupabaseServerClient (createClient 아님)
                 Database/'public' generic + cookies handler 정상 구현
src/components/ui/:  avatar, button, card, checkbox, dialog, dropdown-menu,
                    input, label, radio-group, select, separator, skeleton,
                    textarea, tooltip (+ shadcn init 후 badge, table 추가됨)
```

### v5.5 완료된 UI 작업 (1단계)

```
src/components/industry/TierRoleBadge.tsx       ✅ 생성
src/components/industry/EvidenceBadge.tsx       ✅ 생성
src/components/ui/badge.tsx                     ✅ shadcn 추가
src/components/ui/table.tsx                     ✅ shadcn 추가
```

### 즉시 이어받을 작업 (v5.6 시작점)

```
Step 1: src/app/ 폴더 구조 확인 — industry layout 정확한 경로 결정
        (authenticated route group 있는지: src/app/(authenticated)/... 등)

Step 2: industry/layout.tsx + IndustryTabs.tsx paste
        - 코드는 핸드오프 첨부 file 섹션 3 그대로
        - cn import path: '@/lib/utils' (확인 필요)

Step 3: industry/paper-mills/page.tsx (server) paste
        - createClient → createSupabaseServerClient 변경
        - .schema('industry' as never) 캐스팅 유지
        - 본인 환경 반영 코드는 v5.5 마지막 답변 참조

Step 4: industry/paper-mills/PaperMillsTable.tsx (client) paste
        - file 섹션 5 그대로

Step 5: 브라우저 /industry/paper-mills 접속
        - Sappi 11 mill이 tier_role badge로 시각화되는지 확인
        - 552 row pagination 작동 확인
        - 데이터 안 보이면 디버깅:
          a) Supabase embed (paper_company:paper_company_id) → file 섹션 9 fallback
          b) RLS authentication 확인
          c) console error 점검
```

### 알려진 미해결 — UI 측

- `.schema('industry' as never)` 후 후속 메서드 타입 추론 깨질 가능성. `(supabase as any).schema('industry')` 임시 우회 가능 (#8 해결되면 자동 해결).
- Supabase `paper_company:paper_company_id (...)` embed 작동 여부 검증 필요. 안 되면 fallback (분리 fetch + 클라이언트 join).

---

## 다음 세션 시작 프롬프트 (template)

```
v5.5 핸드오프 첨부합니다. v5.5에서 Sappi family 정리 완료 (25→6 row) +
Industry UI Phase A 1단계까지 끝나고, Phase B (paper-mills 페이지) 코드 paste
직전에 채팅 한도 도달.

v5.6에서 이어서:
1. UI Phase B 마무리 (layout/tabs/page/table 4 파일 paste + 브라우저 확인)
2. 그 후 다음 작업 결정 (Mondi family 정리 / paper_mills #20+#23 / filler side Step B)

src/app/ 폴더 트리 캡처 보내드릴 테니 정확한 경로 결정부터 도와주세요.
```

---

## 오늘 세션 성과 요약 (v5.5)

1. ✅ #17 옵션 A 결정 + 실행 — `public.tier_role` ENUM + 2 컬럼 추가 + 2 인덱스
2. ✅ #18 옵션 B 결정 + Sappi 적용 — paper_mills 단일 plant 정본 패턴 확립
3. ✅ `app.parties.industry_paper_mill_id` 컬럼 신설 (ALTER + FK + 인덱스)
4. ✅ Sappi Phase 1 — Plant 6 row deprecate, mill reattach (유럽 2 → Sappi Europe, 남아공 4 → Sappi Limited)
5. ✅ Sappi Phase 2-B — Finland dup 3 row 정리 (1018 정본, M-real history 보존)
6. ✅ Sappi Phase 2-C — Italy/Lanaken/compound 1 정리 (370 Country, 373/455 deprecate, mill 497 → Sappi Europe 임시)
7. ✅ Sappi Phase 2-D — Portugal/Switzerland/multi-mill 정리 (396 cleanup, 334/797 deprecate, K-C linkage 정합 복구)
8. ✅ Sappi Phase 2-E — Compound 7 row 일괄 deprecate + linkage 7 DELETE
9. ✅ paper_companies 기준 incoming FK 3개 전수조사 (v5.5 lesson #7)
10. ✅ supplier_mill_linkages schema audit (22 컬럼 + 4 FK)
11. ✅ app.parties 컬럼 발견 — `tier`/`party_level`/`industry_paper_mill_id` 등 (v5.5 #19 + #22 등록)
12. ✅ paper_mills multi-region rollup 패턴 광범위 발견 — 8+ row (v5.5 #23 등록)
13. ✅ 022 promotion script bug 발견 — module='paper_mill' + party_level='country_entity' 모순 (v5.5 #21 등록)
14. ✅ V11.4 자동생성 stub 패턴 인지 — notes='Auto-created from...' 식별 (lesson #9)
15. ✅ RLS 4 테이블 enable + `industry_select_authenticated` SELECT policy
16. ✅ Industry UI Phase A 시작 — TierRoleBadge + EvidenceBadge 컴포넌트 생성, shadcn badge/table 추가
17. ✅ Sappi family 정리 결과 정합 검증 — 6 row (1 HQ + 2 Regional + 3 Country) + paper_mills 11 mill + app.parties dup 제거 + linkages 정합
