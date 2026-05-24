# Stage 29-c Column Rename Table

handoff §A4 + §6 + 본 chat 의 V1 database.ts 검증 결과 통합.

---

## §1. 자동 변환 가능 (rename_codemod.ps1 처리)

### 1-1. V1 caller bug (DB 컬럼명 불일치)

| 패턴 (V1 caller) | 실재 DB 컬럼 | 위치 | 영향 |
|---|---|---|---|
| `org_id` | `organization_id` | app.* 다수 (email_whitelist, communications, parties 등) | runtime fail |
| `body_text` | `body_plain` | app.communications | runtime fail |
| `'country'` literal | `'country_code'` | app.parties | runtime fail |
| `.country` accessor | `.country_code` | app.parties (객체 속성) | runtime fail |
| `email_whitelist.value` | `email_whitelist.pattern` | app.email_whitelist | runtime fail |

→ 모두 단순 string replace. `rename_codemod.ps1` 가 처리.

⚠️ **`email_whitelist.value` 케이스**: codemod 가 자동 처리 안 함 (너무 일반적 단어 `value`). audit script A3 에 명시적 패턴 미포함. 별도 grep:
```powershell
Select-String -Path src -Recurse -Include *.ts,*.tsx -Pattern "email_whitelist.*value|value.*email_whitelist"
```
매치된 site case-by-case manual review.

### 1-2. urm.stages 의 정렬 컬럼

| 패턴 (V1 caller) | 실재 DB 컬럼 | 위치 |
|---|---|---|
| `stage_position` | `sort_order` | urm.stages |

→ 단순 rename. (단 `app.pipeline_stages` 의 컬럼명도 이미 `sort_order` 임 — V1 에서도 stage_position 은 caller bug)

---

## §2. 수동 처리 필요 (codemod 안 함)

### 2-1. party_type → party_type_id (FK)

**가장 영향 큰 변경**. 단순 rename 으로 해결 안 됨.

| V1 패턴 | V2 (urm) 변환 |
|---|---|
| `.eq('party_type', 'company')` | `.eq('party_type_id', <FK_UUID>)` + 별도 JOIN 또는 lookup table mapping |
| `.in('party_type', ['fund', 'individual'])` | (urm 에 fund/individual 없음, hard-delete 완료) → 코드 제거 또는 다른 조건 |
| `party_type === 'paper_mill'` | `party_type_id === <PAPER_MILL_ID>` 또는 `party_type_code === 'paper_mill'` (JOIN 후 alias) |
| `select('party_type')` | `select('party_type:party_types(code)')` (PostgREST JOIN), 또는 raw id 만 |
| INSERT/UPDATE 의 `party_type: 'company'` | `party_type_id: <ID>` |

상세 패턴: `party_type_join_pattern.ts`.

### 2-2. urm.parties.party_type enum (app) → urm.party_types code (urm)

**enum 매핑** (handoff §6 #5 + §4 의 app.parties.party_type enum 5값):

| app enum 값 | urm.party_types.code | 처리 |
|---|---|---|
| `company` | (없음) | profile 테이블 (investor / paper_mill / filler_supplier / buyer / customer / partner) join 으로 결정 |
| `individual` | (없음) | urm.parties 에 0 row (모두 soft-deleted, Stage 29-d 시 drop) |
| `fund` | (없음) | urm.parties 에 0 row (ε hard-delete) |
| `organization` | (없음) | 동상 |
| `government` | `government_grant` | 직접 매핑 |

→ caller logic 이 `party_type === 'fund'` 같은 비교를 하면 → 거의 dead code. 검토 후 제거.

→ `party_type === 'company'` 가장 흔함. urm 측에선 **profile 테이블 존재로 판별**. 예:
```typescript
// V1
const isInvestor = party.party_type === 'company' && /* ... */;

// V2 (urm)
const isInvestor = party.party_type_id === PARTY_TYPE.INVESTOR;
// 또는
const isInvestor = !!(await sbUrm
  .from('investor_profile')
  .select('id')
  .eq('party_id', party.id)
  .maybeSingle()).data;
```

### 2-3. portfolio_company_id (V1) → V2 module_data 보존

handoff §8: `portfolio_company_id (app.ipc)` → drop → `module_data._app_portfolio_company_id` (V2 jsonb)

| V1 (caller) | V2 (urm.investor_portfolio_companies) |
|---|---|
| `.select('portfolio_company_id')` | `.select('module_data')` + `data.module_data._app_portfolio_company_id` |
| `.eq('portfolio_company_id', id)` | 신규 컬럼 `portfolio_company_party_id` 또는 `portfolio_company_name_normalized` 사용 |
| INSERT `{ portfolio_company_id: ... }` | 별도 신설 컬럼 또는 module_data 에 직접 |

→ caller code 의 의도에 따라 다름. case-by-case.

### 2-4. parent_party_id / party_level (3-tier hierarchy)

**Stage 29-b handoff §8: "3-tier hierarchy DROP. parent_party_id, party_level carry 안 함".**

urm.parties 에는 이 컬럼 없음. V1 caller 가 사용한다면:
- (a) 코드 제거 (가장 흔함)
- (b) app.parties carry 영역으로 격리 (Stage 29-d 시 drop)

audit script A8 결과로 site list 확보 후 검토.

---

## §3. 코드 안 건드리는 케이스

### 3-1. module_data._app_* 접근

V1 의 일부 컬럼이 urm 측에서 `module_data` jsonb 의 `_app_*` prefix 키로 보존됨. caller 가 직접 접근하면 그대로 동작.

예: `_app_is_decision_maker`, `_app_module`, `_app_source`, `_app_product_grade`, `_app_organization_id`, `_app_portfolio_company_id`

→ codemod 처리 안 함. (caller 의 의도된 정상 패턴)

### 3-2. 외부 API response 의 필드명

caller code 에 `body_text`, `org_id` 등이 있을 때 외부 API response 파싱 컨텍스트면 정상 — DB call 아님.

→ rename_codemod.ps1 은 false positive 발생 가능. -DryRun + 수동 검토 필수.

대표 false positive 패턴:
- LinkedIn API: `country` (ISO 코드)
- Gmail API: `body` 내부 sub-field
- Slack API: `text` (body_text 아님)

검토 시 line context 확인. import 또는 함수 호출 컨텍스트로 판별.

---

## §4. 적용 순서

1. **dry run 으로 매치 site list 확보**:
   ```powershell
   .\rename_codemod.ps1 -ProjectRoot . -DryRun | Tee-Object stage29c_rename_dryrun.log
   ```

2. **stage29c_rename_log.csv 검토**. false positive 식별.

3. **자동 적용 (확신되는 패턴부터)**:
   ```powershell
   .\rename_codemod.ps1 -ProjectRoot . -Apply
   ```

4. **빌드 + tsc 확인**:
   ```powershell
   npm run build
   npx tsc --noEmit
   ```

5. **수동 처리 항목 (§2) 별도 작업**:
   - audit script A4 결과의 party_type 호출 사이트 → `party_type_join_pattern.ts` 패턴 적용
   - audit script A7 결과의 portfolio_companies → V2 패턴
   - audit script A8 결과의 parent_party_id → 제거 또는 격리

6. **다시 빌드 + tsc**:
   ```powershell
   npm run build
   npx tsc --noEmit
   ```

7. **git diff 검토 + commit**:
   ```powershell
   git diff --stat
   git diff > stage29c_rename.patch
   ```

---

## §5. 통계 추정 (audit script A3 결과로 정확화)

| 카테고리 | 예상 매치 수 (typical project) | 자동 처리 |
|---|---:|---|
| org_id | 5–20 | ✅ |
| body_text | 1–5 | ✅ |
| 'country' literal | 1–3 | ✅ |
| .country accessor | 1–10 | ✅ |
| stage_position | 0–5 | ✅ |
| party_type (직접) | 10–50 | ❌ 수동 |
| portfolio_companies (V1) | 1–10 | ❌ 수동 |
| parent_party_id / party_level | 0–5 | ❌ 수동 |

총 자동 처리 추정: 10–40 매치. 수동 처리 추정: 10–60 매치.
