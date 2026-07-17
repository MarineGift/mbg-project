# 충전제 홈페이지 스윕 완료 — 2026-07-17

> **결론 한 줄: 파이프라인 상단이 통째로 틀려 있었고, 회사 홈페이지 한 장씩이 그걸 고쳤습니다.**

---

## 1. 무엇이 바뀌었나

### 아침의 Tier 1 (scan_fcc_target_ranking)
```
SMI · 태경BK · Double A · Fimatec
```
- **SMI** — `partner_names`에 파트너로 적혀 있었음 (티슈 트랙)
- **태경BK** — EP4579034 공동 출원인. **8월 일본 이의신청 상대**
- **Fimatec** — SMI 기술 라이선스 위에 서 있음

### 저녁의 실제 상단
```
Artemyn(TOP) + 인도 넷 — 20 Microns · Gulshan · Wolkem · Kunal
```
**다섯 다 이미 DB에 있었습니다. 아무도 열어보지 않았습니다.**

---

## 2. 스물여섯 곳 열어서

| 판정 | 회사 | 근거 (전부 자기 사이트) |
|---|---|---|
| **TOP** | **Artemyn** | CaCO3 공장 17곳 · Par Moor P&B Lab · **Chris Nutbeem** 실명 |
| **STRONG** | **奥多摩工業** | **일본 제지 PCC 90%+**. 컨택 페이지가 **부서별로 분리** |
| **STRONG** | **Gulshan Polyols** | **6번째 satellite 운영사**. Limca 2010 = 인도 최초 온사이트 PCC |
| **STRONG** | **Mississippi Lime** | **7번째 satellite 운영사**. PCC 공장 2개. **컨택 13개 보유** |
| **STRONG** | **Wolkem** | **인도 최초 WGCC 슬러리**. 2000명, 7개 주 |
| **STRONG** | **Kunal Calcium** | **PCC 연 5만톤**. 자기 페이지가 *"replacement of more expensive pulp fiber"* |
| **STRONG** | **備北粉化工業** | *"中性抄紙化には最適なフィラー填料… コストダウンも実現"* |
| **STRONG** | **白石グループ** | UFPCC+PCC+GCC · **개방시험실** · 논문 발표 |
| **STRONG** | **20 Microns** | BSE·NSE. **TiO2 대체를 이미 판매** |
| **STRONG** | **Zantat** | 자기 컨택 페이지가 `sales@`를 **"partnership collaborations"** 창구로 지정 |
| moderate | Q-min | GCC 전용·플라스틱 우선. **단 태국 지폐 1999~** |
| moderate | Huber | 초미립 GCC. 제지는 태그라인에만 |
| moderate | Calidra | PCC 공장 2개 — **아르헨티나**, 70% 페인트 |
| moderate | Ashapura | **두 행이 한 회사**. 진짜 GCC + **파일럿 플랜트** |
| **재검토** | **Fimatec · F.M.T.(TH)** | **HOLD 철회됨** — SMI가 고객이면 얽힘 논리 무효 |
| weak | Mumal Microns | **복사된 카피** |
| weak | Shikhar Microns | 1500 mesh. About에 제지 없음. **SEO 블로그** |
| **out** | 丸尾 · 竹原 | CaCO3인데 **용도 목록에 제지 없음** (둘 다 아카시) |
| **out** | 日鉄鉱業 · Carmeuse | 필러 제조사의 **공급자** |
| **out** | IMI Fabi · Thiele | **탄산칼슘 라인 없음** (탈크 / 카올린) |
| **out** | Kaolin (Malaysia) | **1000 mesh ≈ 13µm** vs 필러 2µm |
| **out** | Imerys ×3 · Maaden | 2024 제지 철수 / 보크사이트·카올린·마그네사이트 |

### 국가별 적중률
```
인도    4 / 7 실제 회사   ← 압도적
일본    3 / 7
미국    1 / 4
말레이  1 / 2
사우디  0 / 1 (확인분)
멕시코  0 / 3
```

---

## 3. 🔴 반드시 알아야 할 것

### ① `market_role`이 세 번 거짓말했고 `mineral_class`가 세 번 맞았습니다
| | role | 실제 |
|---|---|---|
| MLC | *"PCC upstream"* | **PCC 공장 2개 + satellite** |
| Mumal | *"Ultra-fine PCC producer"* | 미분쇄상 |
| Ashapura | *"Paper/specialty kaolin"* | 분쇄 GCC |

**`fix_in_filler_batch1`의 플래그가 매번 범인을 잘못 지목했습니다.** 플래그는 남기고 정정을 옆에 붙였습니다.

**단 Calidra는 `mineral_class='lime'`이 틀렸습니다 (PCC+GCC).** → **두 필드 다 못 믿습니다. 어느 쪽으로도 필터하지 마세요.**

### ② 스윕 방법의 구멍 — "회사에 붙었지만 그 회사 얘기가 아닌 텍스트"
| | |
|---|---|
| **Mumal** | Gulshan의 문장을 **한 글자도 안 틀리고 복사** |
| **Huber** | 시장 리포트가 회사 자료를 이김 — **Claude의 실수** |
| **Shikhar** | 산업을 파는 **SEO 블로그** |

> **규칙: 주장은 그 회사에만 해당될 때만 증거입니다.**
> 공장 이름 · 점유율 · 광산 이름 · 날짜 · 실명 · 브랜드.
> **일반 공정 설명은 값 0 — 그게 여행하는 부분입니다.**

**인도 PCC 보일러플레이트 확인**: `"bulk densities from 0.40 gms/cc to 0.9 gms/cc"` → **Gulshan · Mumal · Kunal 셋 다 보유. 셋 누구에 대해서도 아무 말 안 함.**

**탈락 판정은 전부 안전합니다** — 회사 목록에서 **뭐가 없는지**에 근거. **없음은 복사되지 않습니다.**

### ③ `242`는 회사 수가 아닙니다
```
Yamama Cement / Saudi Cement    ← 두 상장사가 한 행
Mexalit / Cemex Minerals        ← 두 회사, website·evidence 둘 다 null
Ashapura ×2                     ← 같은 Minechem
F.M.T. (Thailand)               ← Fimatec 자회사
Imerys ×3                       ← 같은 회사
```
**`4/242` 컨택 커버리지의 분모부터 틀렸습니다.** 인도는 9행 = **8개 회사**.

### ④ 스키마가 못 재는 여섯 축
```
광물이 틀림     Thiele(kaolin) · IMI Fabi(talc)
시장이 틀림     丸尾 · 竹原
체인 위치       日鉄鉱業 · Carmeuse
등급이 틀림     Kaolin(MY) · Shikhar   ← 쿼리로 잡히는 유일한 축
이해충돌        태경 (분쟁 상대)
이중 역할       Carmeuse (Ventures = 투자자 가능성)
```
**아홉 중 하나만 숫자로 잡힙니다. 나머지는 목록에서 뭐가 빠졌는지 읽어야 합니다.**

---

## 4. Claude의 실수 (기록)

- **`&&`를 PS 5.x에 씀** → 파스 실패가 **블록 전체를 취소** → 무버가 안 돌아 커밋 누락
- **채팅에 실행 가능한 SQL 조각** → `party_type_id=3` 가드를 뺀 채 실행됨. **피해 0이었지만 운**
  → **규칙 확정: 실행 가능한 SQL은 파일에만.**
- **`parties_contact_form_url_chk` 23514** — URL 추측 거부해놓고 `web_form` 선언
- **Huber 과잉 주장** — 시장 리포트를 회사 자료 위에
- **`market_role`을 3번 믿음**
- **파일 개수 오산** (15이라 했으나 13) — 카운트 체크가 잡음
- **커밋 누락 3회** — 배치2 / `&&` 블록 / 6개 파일(그중 하나는 커밋 메시지가 있다고 주장)

**살린 규칙**: 조회 없이 쓰기 파일 안 만듦 · 폼 필드/max_length 안 지어냄 · 제네릭 인박스에 이름 안 붙임 · **비타깃에 컨택 루트 기록 안 함(8회)**

---

## 5. [PENDING]

### 즉시
1. **Artemyn — LinkedIn** `linkedin.com/company/artemyn` → **Chris Nutbeem** (VP Innovation, Par Moor).
   **특정 인간에게 닿는 유일한 경로.** ⚠️ **CEO Nilesh Shah에게 가면 안 됨** — 자기 약력이 *"expansion **beyond its legacy in paper and board**"*
2. **폼 필드 미기록 3곳** — Artemyn(HubSpot 임베드) · 20 Microns · Gulshan. **Subject 드롭다운 미확인**
3. **컨택 URL 한 번만 보면 끝나는 곳**: 備北(사이트 2개 동시 응답) · 白石 · **Wolkem**(`contactus_inter.htm`) · **Kunal**

### 결정 대기
4. **Fimatec·F.M.T. HOLD 철회 파일** — 낼까요? Fimatec은 日本製紙 시라오이 안에서 온사이트 PCC를 돌리는 실제 satellite 운영사
5. **MLC 컨택 13개 출처 검증** — 어제 local-part에서 가짜 인물 14명 나올 뻔함. `enrich_mlc_us_filler_2026-07-16` 출처
6. **Ashapura 두 행 병합** — 같은 Minechem. 병합은 사람 결정
7. **슬래시 행 4개 분리** — `Yamama/Saudi Cement`, `Mexalit/Cemex` 등
8. **사우디 3곳 미확인** — Arabian Cement · Saudi Lime · Yamama/Saudi Cement. 열린 질문만 기록, 판정 안 찍음
9. **Carmeuse Ventures** — 석회 인접 탈탄소 스타트업에 자본. **투자자 각.** 홈페이지 문장 하나. **맨데이트 미확인 — 이걸로 편지 쓰면 안 됨**
10. **제지기 규모 검증 문구 공개 여부** — `nda_achieved_full`(nda_only). 공개 가능하면 medium·long이 세짐
11. **`ip_portfolio`를 nda_only로?** — 자체 규칙상 라벨 틀림. 단 investor 폼 4 drafting / 2 submitted

### 남은 스윕
```
중국 9 · 폴란드 6 · 말레이 3 · 터키 5 · 기타 ~30
한국 5 = 어제 완료 (seed_filler_suppliers_kr / fix_kr_filler_finish)
```

---

## 6. 상대가 우리 논리를 먼저 말한 6회

| | |
|---|---|
| 備北 | *"中性抄紙化には最適なフィラー填料… **コストダウン**も実現"* |
| 20 Microns | **TiO2 부분 대체를 이미 판매** |
| Zantat | 경영 이념이 *"**Providing Cost-saving Solution** to Create Value"* |
| MLC | Magnum Fill 브로셔: *"**Cost savings by reducing or extending TiO2 use**"* |
| **Kunal** | *"reduce paper making costs through the **replacement of more expensive pulp fiber**"* |
| Mumal | 같은 문장 — **단 복사본** |

> **설득할 필요가 없는 사람들입니다. 이미 그 사업을 하고 있고, FCC는 천장을 올리는 겁니다.**

---

## 7. 파일 이동 + 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

**폴백 (인라인 무버):**
```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$dest = 'C:\dev\mbg-project\docs\handoff\2026-07-17'
$src = Get-ChildItem -Path $dl -Filter 'handoff_filler_sweep_complete_2026-07-17*.md' -File -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Host "SKIP  no match"; return }
Unblock-File -Path $src.FullName
[System.IO.Directory]::CreateDirectory($dest) | Out-Null
$target = [System.IO.Path]::Combine($dest, 'handoff_filler_sweep_complete_2026-07-17.md')
[System.IO.File]::Copy($src.FullName, $target, $true)
Remove-Item -LiteralPath $src.FullName -Force
Write-Host ("OK    " + $target)
```

**마무리 (`&&` 금지 — 줄 분리):**
```powershell
cd C:\dev\mbg-project
Get-ChildItem sql\*2026-07-17*.sql | Measure-Object | Select-Object -ExpandProperty Count
git status -sb
git add sql/ docs/handoff/2026-07-17/
git commit -m "handoff: filler homepage sweep complete - 26 opened, pipeline top inverted"
git push origin marinebiogroup
```

> **push = Railway 자동 배포 = 웹 즉시 반영.**
> **날짜 폴더 `2026-07-17` 확인.** 오늘 SQL은 **29개**여야 함.

---

## 8. 결론

> **정보는 없던 게 아니라 가져오지 않은 것이었습니다.**

- **Artemyn** — CaCO3 공장 17곳이 *"kaolin 상인"*으로 앉아 있었음
- **Imerys 커버리지 구멍** — 구멍이 아니라 **2024년 제지 철수**
- **奥多摩** — 일본 제지 PCC 90% 사업자가 컨택 0
- **MLC** — 유일한 미국 STRONG이 *"PCC upstream"*으로 적혀 있었음. **아무도 안 열어볼 설명**
- **satellite 운영사** — 넷이 아니라 **일곱**. 셋을 오늘 찾았고 셋 다 이미 DB에 있었음
- **인도** — 진짜 회사 7곳 중 4곳이 STRONG. **로스터에서 가장 높은 적중률**

> **DB가 못 잡은 것을 회사 자기 웹페이지 한 장이 매번 잡았습니다. 스물여섯 번 중 스물여섯 번.**
