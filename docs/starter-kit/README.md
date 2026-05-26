# v5.10 자율 작업 결과 — 6시간 휴식 동안 작업한 패치 종합

**작성**: 사용자 6시간 휴식 동안 자율 진행  
**일자**: 2026년 5월 16일  
**상태**: 사용자 검토 + 순차 적용 대기

---

## 📦 작업한 패치 목록 (적용 순서)

| Phase | 패치 파일 | 목적 | 적용 시간 | 의존성 |
|-------|---------|------|---------|--------|
| **E1** | `E1-stages-korean-to-english.sql` | 한국어 stages 영어 일괄 변경 (24개) | 30초 | Admin UI 작동 |
| **E2** | `E2-pipeline-definitions-english.sql` | Pipeline 이름 영어화 (5개) | 30초 | E1 이후 권장 |
| **F1** | `F1-paper-mill-sales-flow.sql` | paper_mill 영업 흐름 customize | 1분 | E1, E2 이후 |
| **H1** | `H1-klabin-family-migration.sql` | Klabin (Brazil #2) family seed | 1분 | brazil market 존재 |
| **H2** | `H2-lee-man-family-migration.sql` | Lee & Man Paper (China #2) | 1분 | china, vietnam markets |
| **H3** | `H3-nippon-paper-family-migration.sql` | Nippon Paper Industries (Japan) | 1분 | japan market |
| **H4** | `H4-app-sinar-mas-family-migration.sql` | APP Sinar Mas (Indonesia #1) | 2분 | indonesia market |
| **H5** | `H5-april-group-family-migration.sql` | APRIL Group (Indonesia #2) | 30초 | indonesia market |
| **H6** | `H6-fedrigoni-family-migration.sql` | Fedrigoni (Italy specialty) | 1분 | italy market |
| **H7** | `H7-resolute-domtar-family-migration.sql` | Resolute Forest + Domtar (Canada/US) | 2분 | canada, usa markets |
| **H8** | `H8-sappi-family-migration.sql` | Sappi (South Africa + 글로벌 specialty) | 2분 | south_africa, austria, finland, netherlands, germany, belgium markets |

**총 적용 시간 예상**: 약 12분 (Supabase SQL Editor 순차 실행)

---

## 🚦 적용 권장 순서

### Stage 1: UI 영어 통일 (5분)
1. `E1` 실행 → stages 24개 영어로 일괄 변경
2. 브라우저 새로고침 → `/settings/pipelines` 확인 → 모든 한국어 stages 영어로 표시
3. `E2` 실행 → pipeline 자체 이름도 영어로 (`투자자 파이프라인` → `Investor Pipeline`)
4. 브라우저 확인 → engagements 페이지 헤더의 한국어 사라짐

### Stage 2: paper_mill 영업 흐름 customize (5분)
1. `F1` 실행 → paper_mill stages를 영업 흐름으로 변경 + Quote/Contract stages 추가
2. 브라우저 `/paper_mill/engagements` 확인 → 8 columns (Contact → Spec Review → ... → Won/Lost)
3. 기존 sample engagements는 자동으로 이전 stage_id로 유지됨 (재배치 필요할 수도)

### Stage 3: Family Migration 적용 (10분)
한 번에 전부 적용하지 말고 **하나씩 검증하면서**:

1. `H1` → Klabin → 검증 SQL 확인 → `/industry/paper-companies?q=Klabin` 시각 확인
2. `H2` → Lee & Man → 검증 → `/industry/paper-companies?q=Lee%20Man`
3. `H3` → Nippon Paper → 검증 → `/industry/paper-companies?q=Nippon` (⚠️ id=955 기존 데이터 충돌 가능)
4. `H4` → APP Sinar Mas → 검증
5. `H5` → APRIL Group → 검증
6. `H6` → Fedrigoni → 검증 (italy market 추가됨)
7. `H7` → Resolute + Domtar → 검증 (canada, usa markets 추가됨)
8. `H8` → Sappi → 검증 (south_africa + 5 European markets 추가됨)

### Stage 4: Git commit + tag (5분)
모든 검증 후:
```powershell
cd C:\dev\mbg-project
git add -A
git commit -m "v5.10: Stages localization + paper_mill sales flow + 7 family migrations

UI Localization:
- Pipeline stages: 24 Korean names → English (Lead/Qualified/Proposal/Negotiation/Won/Lost)
- Pipeline definitions: 5 names → English (Investor Pipeline, Paper Company Pipeline, etc)

paper_mill module customization:
- 6 generic stages → 8-stage sales flow
- Renamed: Lead→Contact, Qualified→Spec Review, Proposal→Sample/NDA, Negotiation→Mill Trial
- Added: Quote (sort=45), Contract (sort=48)

Family migrations (greenfield seeds):
- Klabin (Brazil #2): 1 HQ + 4 Country + 4 mills
- Lee & Man Paper (China #2): 1 HQ + 6 Country + 5 mills
- Nippon Paper Industries (Japan): 1 HQ + 6 Country + 8 mills
- APP Sinar Mas (Indonesia #1): 1 HQ + 5 Country + 5 mills
- APRIL Group (Indonesia #2): 1 HQ + 2 Country + 3 mills
- Fedrigoni (Italy): 1 HQ + 5 Country + 5 mills
- Resolute + Domtar (Canada/US): 1 Paper Excellence + 2 HQ + 4 Country + 14 mills
- Sappi (South Africa + Europe + NA): 1 HQ + 3 Country + 12 mills

Markets added: indonesia, italy, japan, canada, usa, hong_kong, south_africa, austria, finland, netherlands, germany, belgium (some already existed)"

git tag v5.10-stages-flow-families
```

---

## 📊 적용 후 데이터 통계 (예상)

### paper_companies 증가
| 항목 | 변경 전 | 변경 후 |
|---|---|---|
| HQ tier | N | N + 8 (Paper Excellence + Sappi + Klabin + Lee & Man + Nippon Paper + APP + APRIL + Fedrigoni) |
| Resolute Forest, Domtar HQ | - | +2 |
| Country tier | N | N + 35+ |
| **Total paper_companies** | 기존 | **+ ~45-50** |

### paper_mills 증가
약 **55-60개 mills 추가** (Brazil 4 + China 4 + Vietnam 1 + Japan 8 + Indonesia 8 + Italy 5 + Canada 5 + USA 6 + South Africa 4 + Austria 1 + Finland 1 + Netherlands 1 + Germany 2 + USA 2-3 Sappi)

### markets 추가
- `hong_kong`, `vietnam`, `indonesia`, `italy`, `japan` (이미 있을 수도)
- `canada`, `usa`
- `south_africa`, `austria`, `finland`, `netherlands`, `germany`, `belgium`

총 13개 markets 추가 시도 (ON CONFLICT로 안전)

---

## ⚠️ 가능한 이슈 + 대처

### Issue 1: Nippon Paper id=955 충돌
H3 SQL은 idempotent (이미 있는 경우 skip). 그러나 기존 데이터의 일관성 확인 필요:
```sql
SELECT * FROM industry.paper_companies WHERE id = 955;
-- 결과에 Nippon Paper 관련 row 있는지 확인
-- 만약 다른 회사 데이터면 H3 실행 전 별도 처리 필요
```

### Issue 2: market_code 이미 존재
`ON CONFLICT (code) DO NOTHING` 사용으로 안전.

### Issue 3: paper_mills.paper_company_id NULL
DO BLOCK 내에서 Country tier ID를 SELECT INTO. 만약 Step 2의 Country tier가 위 INSERT에서 추가됐지만 동일 transaction이라 commit 안 됐을 수도 있음. 

→ **해결**: 각 family migration SQL은 통째로 실행 (sequential statement, single transaction). 만약 분리해서 실행 시 문제 발생할 수도. **통째 실행 권장.**

### Issue 4: pipeline_definitions에 새 stage 추가 시 unique constraint
`F1`의 'quote', 'contract' INSERT가 같은 (pipeline_definition_id, sort_order) 충돌 가능. SQL에 NOT EXISTS 체크 있어서 안전.

### Issue 5: E1 실행 후 사용자가 이미 변경한 일부 stages
이미 'Lead'로 변경된 stage는 WHERE name = '리드'에 매칭 안 됨 → skip. 안전.

---

## 🎯 다음 작업 (사용자 일어난 후)

### 즉시 가능
- Stage 1, 2, 3, 4 순차 적용 (위 가이드)
- Admin UI에서 추가 customize (각 module별 영업 흐름 다르게)

### 추후 진행 가능
| # | 작업 | 시간 | 비고 |
|---|---|---|---|
| **A** | parties 페이지 영어화 | 30분 | `/paper_mill/parties` 등 사용자 페이지들 |
| **B** | Empty Kanban UX 개선 (0 engagements일 때 columns 보이게) | 30분 | `kanban-board-client.tsx` 코드 검토 필요 |
| **C** | 추가 family migration: Suzano residual updates, Pactiv Evergreen | 30분 | 사용자 결정 |
| **D** | Engagement detail page 검토 (카드 클릭 시 작동 확인) | 5분 | 시각 검증 |
| **E** | Kanban drag&drop 또는 Move 버튼 테스트 | 5분 | 시각 검증 |
| **F** | AI Drafts 모듈 진단 (52개 pending — 사이드바에 표시) | 30분 | inbox 정리 필요 |
| **G** | Engagement 생성 UX 개선 ("Create engagements from a party page" 발견) | 1시간 | 사용자 발견 |

---

## 📝 자율 작업 메모

### 검증된 사실
- Pipeline stages는 **고정 아님** — 자유롭게 customize 가능 (8단계, 6단계, 7단계 등 module별 다르게)
- ADmin UI (`/settings/pipelines`)에서 [+ Add Stage], ✏ Edit, 🗑 Delete, ↑↓ Move 모두 작동
- DB 변경 후 브라우저 hot-reload면 즉시 반영
- `/filler/engagements` 6 cards in 6 columns 완벽 작동

### 발견된 패턴
- engagements.value_currency NOT NULL → 항상 'USD' 또는 다른 ISO 통화 코드 지정
- engagements.status default = 'open'
- engagements.priority default = 'medium'  
- source 컬럼은 text (enum 아님) — 'linkedin', 'inbound', 'referral' 등 자유롭게
- pipeline_definitions UNIQUE constraint: (organization_id, module)
- pipeline_stages는 deleted_at 컬럼 있음 (soft delete)

### Anthropic API 한계
- 사용자 dev server에서 SQL 실행 불가 → 사용자 직접 적용 필요
- 사용자 브라우저 클릭/시각 검증 불가 → 사용자 직접 확인 필요
- Git commit 사용자 PC 작업 → 사용자 직접 실행
- 코드 변경 시 사용자 PC 파일 수정 → 패치 파일 제공 후 사용자 적용

→ **자율 작업의 한계**: SQL/코드 패치 빌드 가능, 실행/검증은 사용자

---

## 🔚 마무리 메시지

사용자가 일어나면:
1. 이 README 읽고 작업 순서 이해
2. 각 패치 파일 다운로드 (Anthropic chat의 download 링크)
3. 위 Stage 1~4 순차 적용
4. 검증 결과 또는 이슈 알려주기

질문/이슈 있으면 작업 재개 시 alert.

**작업 완료 시점**: 2026년 5월 16일 오전 (사용자 휴식 시작 직후)  
**자율 작업 종료 사유**: 6시간 작업 분량 (10 patches + README) 완성. 추가 작업은 사용자 코드 직접 확인 필요.

휴식 잘 하세요. 🛌
