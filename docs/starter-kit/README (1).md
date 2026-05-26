# Ingest Layer 사용 가이드

> Claude 가 웹에서 수집한 데이터를 한 번에 적재할 수 있게 설계된 단순한 인터페이스.

## TL;DR (3-step workflow)

```sql
-- 1) 새 수집 세션 시작
SELECT ingest.start_run(
    'us_vc_2026Q2',                                      -- 라벨 (유일)
    'investor',                                           -- 모듈
    'b25de8f2-1020-482f-9012-183f63883169'::uuid,        -- organization
    'US tier-1 VC firms collected via web research',     -- 설명
    ARRAY['NVCA','PitchBook','Visible','Aspire']         -- 출처
);

-- 2) JSON 페이로드 적재 (단일 또는 bulk)
SELECT ingest.stage_row('us_vc_2026Q2', '{
    "name": "Andreessen Horowitz",
    "legal_name": "AH Capital Management LLC",
    "subtype": "vc",
    "website": "https://a16z.com",
    "hq": {"city": "Menlo Park", "state": "CA", "country": "US"},
    "founded_year": 2009,
    "aum_usd_billions": 90.0,
    "stage_focus": ["seed","early","growth","late"],
    "sector_focus": ["ai","defense","biotech","fintech","crypto","enterprise"],
    "geographic_focus": ["US"],
    "tags": ["tier1","american_dynamism"],
    "portfolio": ["Coinbase","Databricks","Roblox","Stripe","Anthropic"],
    "source_note": "Aspire 2026; AlphaSense 2026"
}'::jsonb);

-- 또는 한 번에 bulk:
SELECT ingest.stage_rows_bulk('us_vc_2026Q2', '[
    {"name":"...", ...},
    {"name":"...", ...}
]'::jsonb);

-- 3) parties + profile + portfolio 로 자동 분배
SELECT * FROM ingest.promote_investors('us_vc_2026Q2');
--   action    | n
--  -----------+---
--   promoted  | 47   ← 새로 만든 row
--   merged    | 6    ← 기존 row 에 enrich 만 추가
--   skipped   | 0
--   failed    | 0

-- 4) 결과 확인
SELECT * FROM ingest.run_summary WHERE label = 'us_vc_2026Q2';
SELECT * FROM ingest.failed_rows WHERE run_label = 'us_vc_2026Q2';
```

## 페이로드 스키마 (investor)

모든 필드 nullable. 최소 `name` 만 있으면 동작.

```jsonc
{
    "name":             "Required. Firm 의 일반 표시명.",
    "legal_name":       "Optional. SEC ADV 등록명 등.",
    "subtype":          "vc | growth_equity | accelerator (default: vc)",
    "website":          "Optional. dedup 의 1순위 키 (도메인만 비교).",
    "hq": {
        "city":         "string",
        "state":        "string (US state code or province)",
        "country":      "string (ISO-2, default 'US')"
    },
    "founded_year":     2009,
    "aum_usd_billions": 90.0,
    "stage_focus":      ["seed","early","growth","late"],
    "sector_focus":     ["ai","fintech","enterprise"],
    "geographic_focus": ["US","Europe"],
    "tags":             ["tier1","american_dynamism"],
    "portfolio":        ["Stripe","Roblox","Databricks"],
    "source_note":      "Aspire 2026 ranking; Visible.vc 2026"
}
```

**배열은 JSON array 도 되고 CSV string 도 됩니다** (`coerce_text_array` 가 알아서 처리).
즉 `"stage_focus": "seed,early,growth"` 도 OK.

## 매칭 / 중복 처리

`stage_row()` 가 자동으로 `dedup_key` 를 계산:

1. **1순위**: `ingest.normalize_domain(website)` → `'https://www.a16z.com/about' → 'a16z.com'`
2. **2순위**: `LOWER(name)`

`promote_investors()` 가 같은 organization + module 안에서 `dedup_key` 로 기존 row 검색:

- **있으면 → merged**: 기존 row 의 NULL 필드만 채움, `module_data` jsonb 에 새 정보 추가
- **없으면 → promoted**: 새 parties + profile + portfolio 생성

같은 run 을 다시 promote 해도 안전 (멱등성). 이미 promoted/merged 인 row 는 건드리지 않음.

## 모니터링

```sql
-- 모든 run 의 상태
SELECT * FROM ingest.run_summary;

-- 실패한 row 만
SELECT * FROM ingest.failed_rows WHERE run_label = '...';

-- 특정 run 의 모든 row 상태
SELECT seq, name, status, error_message
FROM ingest.rows ir
JOIN ingest.runs r ON r.id = ir.run_id
WHERE r.label = 'us_vc_2026Q2'
ORDER BY seq;
```

## 롤백

```sql
-- 미리 확인 (실제로 안 지움)
SELECT * FROM ingest.rollback_run('us_vc_2026Q2');
-- 에러: 'Rollback is destructive. Call with p_confirm => TRUE'

-- 실제 실행 (merged 는 안 건드림, promoted 만 삭제)
SELECT * FROM ingest.rollback_run('us_vc_2026Q2', p_confirm => TRUE);
```

⚠️ `merged` 상태의 row 는 기존 데이터에 정보만 추가했으므로 롤백 안 됨. 그건 수동으로 처리해야 함.

## 새 모듈 확장 방법

현재는 `investor` 만 promote 함수가 있음. 다음 모듈 추가 시 패턴:

```sql
CREATE FUNCTION ingest.promote_paper_mills(p_run_label TEXT) RETURNS TABLE (action TEXT, n INT)
...
-- parties + industry_paper_mill_id 링크 + 기타 모듈별 처리
```

이 파일의 STEP 5 (`promote_investors`) 를 템플릿으로 복사해서 모듈별 필드를 매핑하면 됨.

## 왜 이렇게 설계했는가 (lessons learned)

이전 시도(`010_investor_seed_us_vc_v4`)에서 겪은 페인 포인트:

| 문제 | Ingest 레이어의 해법 |
|---|---|
| `name_normalized` 트리거가 외부 데이터 형식과 안 맞음 | `website domain` 으로 dedup → 트리거 영향 0 |
| 3-테이블 분리 INSERT → JOIN 누락 위험 | promote 함수 하나가 모두 처리 |
| 한 row 실패하면 전체 롤백 | row-level try/catch → 나머지 진행 |
| 부분 실패가 조용함 | `ingest.failed_rows` 뷰로 즉시 확인 |
| 어디서 가져온 건지 추적 안 됨 | `runs.sources[]` + `notes` 보존 |
| `organization_id`, enum, RLS 매번 처리 | 함수 시그니처에 한 번만 |
| INSERT VALUES 53줄 손코딩 | JSON array 하나로 끝 |

## 차후 확장 후보

- [ ] `promote_paper_mills(label)` — paper 산업 데이터
- [ ] `promote_filler_suppliers(label)` — filler 공급사
- [ ] `promote_partners(label)` — 일반 파트너 (정부·협회·KOTRA 등)
- [ ] `ingest.compare_versions()` — 같은 firm 의 시점별 데이터 변화 추적
- [ ] `ingest.export_to_csv()` — 외부 검토용 CSV 추출
- [ ] webhook → Edge Function 에서 자동 promote 트리거
