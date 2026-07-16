# Handoff — Omya KR 중복 수정 + MLC 홈페이지 수집 (2026-07-16, 2차)

## 0. 먼저: 제가 틀렸습니다

지난 세션에서 **"KR filler supplier 0건"**이라고 단정했는데, **사실이 아닙니다.**

- `Omya (Korea)` (id `fac3df6e-875a-4cc3-97d4-fbb0ca10dd7f`)가 **이미 존재**합니다. `20260620220000_filler_parties_website_families_batch14.sql`에 있습니다.
- `Specialty Minerals (Korea)` (id `4986266c-...`)도 이미 존재합니다.

**왜 놓쳤나**: 리포에서 `,'KR'` 리터럴 패턴으로만 grep했습니다. 그런데 filler 기본 로스터(약 99~126행)는 애초에 리포 마이그레이션에 없고 DB에 직접 들어간 데이터라, 그 grep으로는 보일 수가 없었습니다. batch14의 UUID 주석 목록을 먼저 봤어야 했습니다.

**결과**: `Omya Korea Inc.`가 **중복 행**으로 들어갔습니다. NOT EXISTS 가드는 party_name 완전일치라 `Omya (Korea)`와 충돌하지 않았습니다.

**Supabase에서 아직 seed를 실행하지 않았다면** 중복은 없고, 아래 수정 파일은 전부 no-op으로 안전하게 지나갑니다.

**다행인 부분**: 나머지 3개(**태경산업 / 태경비케이 / 지엠씨**)는 로스터에 없는 진짜 신규입니다. 그대로 유효합니다. 그리고 조사 과정에서 batch14에 남아 있던 미해결 플래그 **"Omya Korea 5-plant claim verification needed"**를 확인해 해소했습니다.

---

## 1. `fix_omya_korea_dupe_2026-07-16.sql` → `sql\`

1. **기존 `Omya (Korea)` 행에 조사 결과를 이관**: `country_code='KR'`, 서울/마포, intro_ko/intro_en.
2. **profile notes에 검증 결과 기록**: 5개 공장(군산·안동·함백·온산·제천, 건식3+슬러리2, 120만 t+, 광산 5곳, 1990년~) **확인 완료**.
   - ⚠️ **불일치 1건**: 기존 노트의 "Yeongwol 200k+ t/y GCC"가 현재 omya.com 공장 목록에 없습니다. 영월이 광산이거나 개명/폐쇄된 사이트일 수 있어 한 번 더 확인 필요 — 노트에 남겨뒀습니다.
3. **중복 `Omya Korea Inc.` 행 + profile 삭제**. contacts/deals/communications/deal_parties가 붙어 있으면 삭제가 차단되도록 가드를 걸었습니다.

검증 쿼리 실행 시 **KR filler = 정확히 4행**이어야 합니다: GMC / Omya (Korea) / Taekyung BK / Taekyung Industry.

---

## 2. `enrich_mlc_us_filler_2026-07-16.sql` → `sql\`

Mississippi Lime은 **이미 DB에 있습니다** (id `cbde4480-031d-4836-b7bb-a9b5a335b7cb`). 추가가 아니라 **보강**입니다.

### 🚨 발견 1 — 도메인이 바뀌었습니다

DB에는 `www.mississippilime.com`. 실제 사이트는 **`www.mlc.com`** — 현재 **MLC**로 d/b/a 사용 중입니다. → 업데이트했습니다.

### 🚨 발견 2 — MLC는 PCC에서 철수한 것으로 보입니다

DB의 기존 평가는 **"⭐ 미국 자국 PCC 시장의 두 번째 사업자 (MTI 다음)"** 입니다. 그런데 현재 mlc.com의 **샘플 요청 폼**과 **컴플라이언스 문서 요청 폼** 두 곳 모두에 이렇게 적혀 있습니다:

> ***PCC products are no longer sold by MLC.**

- `markets/paper` 페이지에는 아직 "Ste. Genevieve 머천트 PCC + 제지사 온사이트 satellite PCC"가 남아 있지만, 그 페이지가 폼보다 **오래됐습니다** (contact 페이지 최종수정 2026-03-27).
- 현재 GCC 라인업(CalCarb R1/R2/mineral filler/coal mine rock dust/athletic field marker/ag stone/AC3/poultry grit/FGD/feed grade)에 **제지용 필러 등급이 없습니다.**
- 과거 제지 제품 Magnum Fill 70% 슬러리, Magnum Gloss PCC는 단종된 것으로 보입니다.

**FCC 로열티 관점에서 중요합니다.** 사실이라면 MLC는 라이선싱 타깃 순위에서 내려가야 합니다.

→ 그래서 `market_role`을 **덮어쓰지 않았습니다.** profile notes에 **CONFLICT FLAG**로 append만 하고 판단은 남겨뒀습니다. Dan Menniti나 Bill Wleklinski에게 확인 후 결정하세요.

### 회사 정보

1907년 설립, 미국 최대 석회 기업(비상장, 지주사 **HBM Holdings**, 매출 약 3.76억 달러, 직원 약 750명, 미국 lime 시장 약 10.4%). 본사 St. Louis, MO. **Ste. Genevieve(MO)**에 아메리카 최대 석회 설비. 그 외 Calera(AL), Verona(KY), Vicksburg(MS), Weirton(WV), Chester(SC), Mobile(AL), Prairie du Rocher(IL), Bridgeville(PA) 등 12곳 이상. 영국 **Singleton Birch** 보유. **2026년 1월 Burnett 인수**.

### 담당자 13명 (mlc.com/contact-us 공개)

**FCC 우선 타깃 (decision_maker = true)**

| 이름 | 직함 | 이메일 | 전화 |
|---|---|---|---|
| **Dan Menniti** | Global Business and Sales Manager – **Specialty Products** | dtmenniti@mlc.com | (412) 979-8030 |
| **Bill Wleklinski** | Sales & BD Manager – **Specialty Products** | wjwleklinski@mlc.com | (614) 967-6221 |
| Ted Frey | Director Sales & Customer Support | tpfrey@mlc.com | (502) 432-3296 |
| Eustace Conway | Director – Southern Sales & Logistics | econway@mlc.com | (601) 994-4418 |

**Senior RSM**: Will O'Neal (West, woneal@mlc.com), Paul Pine (East, pmpine@mlc.com)

**RSM**: Jennifer Huff (jjhuff@mlc.com / TX·CO·OK 등), Dan Okenfuss (djokenfuss@mlc.com), David Cox (dwcox@mlc.com), David Evans (drevans@mlc.com), **Andy Bergman** (awbergman@mlc.com / OH·PA·NY·ME 등 **북동부 제지 벨트 + 캐나다**), Kyle Mehl (kwmehl@mlc.com), Al Smith (aasmith@mlc.com)

> 실질 진입점은 **Specialty Products 2명**입니다. RSM들은 석회/석회석 물량 영업 territory라 FCC와 결이 다릅니다 — 커버리지용으로만 넣고 `is_decision_maker=false`로 뒀습니다. 단 **Andy Bergman**은 북동부 제지 벨트를 커버해서 예외적으로 쓸모가 있을 수 있습니다.

본사 +1 314-543-6300 / 800-437-5463 · 구매팀 purchasing@mlc.com (16147 U.S. Highway 61, Ste. Genevieve, MO 63670) · LinkedIn 등록.

---

## 3. 파일 이동

### 방법 A — 유니버설 무버 (권장)

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### 방법 B — 인라인 무버 (폴백)

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'fix_omya_korea_dupe_2026-07-16*.sql';   Dest = (Join-Path $repo 'sql'); Name = 'fix_omya_korea_dupe_2026-07-16.sql' },
  @{ Pattern = 'enrich_mlc_us_filler_2026-07-16*.sql';  Dest = (Join-Path $repo 'sql'); Name = 'enrich_mlc_us_filler_2026-07-16.sql' },
  @{ Pattern = 'handoff_us_filler_mlc_2026-07-16*.md';  Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_us_filler_mlc_2026-07-16.md' }
)

foreach ($m in $moves) {
  $src = Get-ChildItem -Path $dl -Filter $m.Pattern -File -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host ("SKIP  no match: " + $m.Pattern); continue }
  Unblock-File -Path $src.FullName
  [System.IO.Directory]::CreateDirectory($m.Dest) | Out-Null
  $target = [System.IO.Path]::Combine($m.Dest, $m.Name)
  [System.IO.File]::Copy($src.FullName, $target, $true)
  Remove-Item -LiteralPath $src.FullName -Force
  Write-Host ("OK    " + $src.Name + "  ->  " + $target)
}
Write-Host "DONE"
```

## 4. 실행 순서

1. **`fix_omya_korea_dupe_2026-07-16.sql` 먼저** — 중복 정리가 우선입니다.
2. 검증 쿼리로 KR filler = 4행 확인.
3. `enrich_mlc_us_filler_2026-07-16.sql` 실행.
4. 검증 쿼리로 MLC contacts = 13행, website = `https://www.mlc.com` 확인.

## 5. 마무리 (commit + push)

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_omya_korea_dupe_2026-07-16.sql sql/enrich_mlc_us_filler_2026-07-16.sql docs/handoff/2026-07-16/handoff_us_filler_mlc_2026-07-16.md
git commit -m "fix: dedupe Omya Korea (was pre-existing as 'Omya (Korea)'); enrich: MLC domain move to mlc.com, PCC-exit conflict flag, 13 homepage contacts"
git push origin marinebiogroup
```

> **주의**: `git push origin marinebiogroup` = Railway 자동 배포 = **웹 즉시 반영**. push 전 `git status -sb` 확인.

---

## 6. 다음 배치 — 미국 filler 전수 업데이트 계획

"미국 충전제 제조사 정보를 다 업데이트"는 이번 한 번에 끝낼 규모가 아닙니다. batch14 로스터 기준 미국 관련 party는 **30건 이상**이고 대부분이 Specialty Minerals의 개별 공장 행입니다. 제안하는 순서:

**배치 A — 미국 독립계 (홈페이지 담당자 수집 대상)**
- `Thiele Kaolin Company` (조지아, 제지용 카올린 #1 독립사) ← MLC와 같은 방식으로 담당자 수집 가능성 높음
- `Huber Engineered Materials` (kaolin/PCC)
- `IMI Fabi` (미국 paper talc)
- `Omya (USA)`
- `Global Filler Corporation` (국적/실체 확인 필요 — 로스터에 국가 불명)

**배치 B — MTI 계열 정리**
- `Minerals Technologies Inc.` / `Specialty Minerals Inc.` / `Specialty Minerals (USA - Regional HQ)` + 미국 공장 20곳
- 공장 행에는 담당자가 없습니다. 실제 컨택은 본사/지역HQ에 붙여야 합니다. **공장 행은 컨택 수집 대상이 아니라 satellite 근거 데이터**로 취급하는 게 맞습니다.
- 중복 정리도 필요해 보입니다: `Specialty Minerals (USA - Lifford AL)`은 Lifford가 영국 버밍엄 지명이라 `Specialty Minerals (UK - Lifford Birmingham)`과 혼선 가능성.

**배치 C — 북미 인접**
- `Graymont`, `Carmeuse Canada`, `Sibelco Canada`, `Calidra`, `Carmeuse Mexico`

**먼저 해야 할 일**: 지금은 리포 파일로만 추정하고 있어서 이번 같은 사고가 또 납니다. Supabase에서 아래를 돌려 **현재 US filler 실제 목록을 주시면** 그걸 기준으로 정확히 작업하겠습니다.

```sql
select p.id, p.party_name, p.country_code, p.city, p.website,
       fp.supply_model, fp.evidence_level, fp.market_role,
       (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts
from app.parties p
left join app.filler_supplier_profile fp on fp.party_id = p.id
where p.party_type_id = 3 and p.deleted_at is null
  and (p.country_code = 'US' or p.party_name ilike '%USA%')
order by p.party_name;
```
