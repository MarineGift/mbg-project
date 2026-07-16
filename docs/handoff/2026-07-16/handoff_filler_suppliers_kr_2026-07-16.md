# Handoff — KR filler suppliers gap fix (2026-07-16)

## 1. 확인된 사실

리포(`MarineGift/mbg-project@marinebiogroup`)를 직접 받아 확인했습니다.

- `supabase/seed/01-parties-paper-industry.sql`에는 KR **제지사**(한솔제지, 무림, 유한킴벌리)와 KR 연구기관(KRICT, KITECH)이 들어 있습니다.
- 반면 `party_type_id = 3` (filler_supplier)에서 `country_code = 'KR'`인 행은 **리포 전체에 0건**입니다.
- 기존 filler 갭 보강 파일 `20260620370013_filler_supplier_gaps.sql`이 커버한 국가는 US(3) / BE(2) / JP(1) / ES(1) / DE(1) — **한국은 통째로 누락**.

→ 지적하신 내용이 맞습니다. 한국 충전제 제조사가 아예 없습니다.

## 2. 추가하는 4개사

| # | 회사 | 위치 | 광종 | supply_model | evidence |
|---|------|------|------|--------------|----------|
| 1 | **Omya Korea Inc.** (오미아코리아) | 서울(마포) HQ / 군산·안동·함백·온산·제천 5개 공장 | GCC+PCC | merchant | C |
| 2 | **Taekyung Industry Co., Ltd.** (태경산업) | 서울 HQ, KOSPI | GCC+PCC | merchant | C |
| 3 | **Taekyung BK Co., Ltd.** (태경비케이, 구 백광소재) | 충북 단양, KOSPI | PCC+GCC | **satellite** | **B** |
| 4 | **GMC Co., Ltd. (Korea)** (㈜지엠씨) | 삼척 광산 / 진천·울산 공장 | GCC | merchant | C |

### 왜 이 4개인가 (FCC 로열티 관점)

- **Omya Korea** — 1990년부터 가동, 건식 3 + 슬러리 2 = 5개 공장, 합산 **연 120만 톤 이상**, 자체 광산 5곳. 국내 최대 제지용 필러 공급사이자 한국 시장 1순위 타깃입니다. 본사 Omya는 이미 DB에 있으므로 family 관계로 붙습니다.
- **태경비케이** — 실질적으로 **가장 중요한 타깃**입니다. 이미 **한솔제지 장항공장에 On-Site PCC 플랜트**를 운영 중, 즉 satellite 모델을 실행하고 있어서 FCC 라이선싱 대화가 한 단계 앞에서 시작됩니다. 2000년 한국화이마테크(스미토모오사카시멘트·Fimatec 합작사)를 흡수합병해 제지용 초미립 중탄 라인 보유. 단양 생석회 연 128만 톤(국내 최대). 그래서 유일하게 `supply_model='satellite'` / `evidence_level='B'`로 넣었습니다.
- **태경산업** — 이미 "펄프 사용을 감소시키는 충진용 중탄 슬러리"를 마케팅 포인트로 내세우고 있습니다. FCC의 가치 제안(펄프 대체·고충진)과 메시지가 그대로 겹치므로 콜드 아웃리치 훅이 이미 준비되어 있는 셈입니다.
- **지엠씨** — 4개 중 가장 작지만(연매출 약 260억) 제지용 GCC 순수 사업자라 의사결정이 빠릅니다. 파일럿 파트너 후보로 넣었습니다.

### 검증 필요 항목 (notes에도 표기해 둠)

1. `GMC Co., Ltd. (Korea)` — 영문 법인명·웹사이트 미확인. 확인되면 UPDATE 필요.
2. 태경비케이 사명 변경 시점 "2021" — 2021년 자료에 이미 태경비케이로 나오지만 정확한 공시일은 미확인.
3. 태경산업 HQ 상세 주소(구 단위) 미기재 — city는 '서울'까지만.

### 의도적으로 제외

- **코스모화학** (국내 유일 TiO2) — 안료이지 제지 필러 주력이 아님. 필요하면 별도 배치로.
- **한국화이마테크** — 2000년 백광소재에 흡수합병되어 소멸. 별도 party로 넣지 않고 태경비케이 notes에 기록.
- **태경케미컬** — 산업용 가스(액체탄산). filler 아님. 다만 PCC/FCC 탄산화용 CO2 공급 관점에서 나중에 partner로 검토할 여지는 있음.

## 3. 파일

- `seed_filler_suppliers_kr_2026-07-16.sql` → `sql\`

내용: ① parties 4행 insert ② intro_ko/intro_en 백필 ③ filler_supplier_profile 4행 insert.
전부 `NOT EXISTS` 가드 — 몇 번 돌려도 안전합니다.

**Supabase SQL Editor 파서 대응 완료**: BEGIN/DO 블록 없음, 문자열 안에 `;` 없음, 문자열 안에 단독 `into` 없음, intro_en 전부 ASCII. 총 6개 독립 statement.

## 4. 파일 이동

### 방법 A — 유니버설 무버 (권장, 한 줄)

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### 방법 B — 인라인 무버 (폴백, 붙여넣기)

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'seed_filler_suppliers_kr_2026-07-16*.sql'; Dest = (Join-Path $repo 'sql');                      Name = 'seed_filler_suppliers_kr_2026-07-16.sql' },
  @{ Pattern = 'handoff_filler_suppliers_kr_2026-07-16*.md'; Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_filler_suppliers_kr_2026-07-16.md' }
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

## 5. 실행 순서

1. Supabase SQL Editor에서 `sql\seed_filler_suppliers_kr_2026-07-16.sql` 전체를 붙여넣고 실행.
2. 파일 하단 VERIFY 쿼리 2개를 **따로** 실행:
   - 4행, 전부 `country_code = KR`, satellite/B 1건 + merchant/C 3건
   - `select count(*) ... country_code = 'KR'` → 4 (기존 0)
3. URM Filler Supplier 목록 화면에서 KR 4건 노출 확인.

## 6. 마무리 (commit + push)

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/seed_filler_suppliers_kr_2026-07-16.sql docs/handoff/2026-07-16/handoff_filler_suppliers_kr_2026-07-16.md
git commit -m "seed: add 4 missing KR filler suppliers (Omya Korea, Taekyung Industry, Taekyung BK, GMC) + profiles + bilingual intros"
git push origin marinebiogroup
```

> **주의**: `git push origin marinebiogroup` = Railway 자동 배포 = **urm.marinebiogroup.com 웹에 즉시 반영**됩니다. 이번 건은 SQL 시드 파일 + 문서라 앱 동작 변화는 없지만, push 전에 `git status -sb`로 의도치 않은 파일이 섞이지 않았는지 확인하세요.

## 7. 다음 단계 제안

- 4개사 컨택 정보(contacts) 보강 — 특히 태경비케이 제지소재/영업 담당.
- `app.party_supply_links` 연결: 태경비케이 ↔ 한솔제지(장항) 이 링크는 On-Site 근거가 확실하므로 바로 넣을 수 있습니다. `mill_party_id` = 한솔제지, `filler_party_id` = 태경비케이.
- 일본(Shiraishi Calcium은 이미 있음) 외 아시아 갭 — 중국·대만·인도 filler도 같은 방식으로 점검 가치 있음.
