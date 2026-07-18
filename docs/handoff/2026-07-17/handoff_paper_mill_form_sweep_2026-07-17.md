# 제지사 폼 스윕 — 2026-07-17 (아침 판본 폐기, 이걸로 대체)

> **결론 한 줄: 폼 4개·필드 32개를 만들었고, 그 과정에서 아침에 제가 쓴 숫자 셋과 migration_028 헤더가 죽었습니다.**

---

## 1. 🔴 먼저, 죽은 숫자들

아침 핸드오프는 **폐기하세요.** 아래가 이유입니다.

| 제가 쓴 것 | 실제 | 어떻게 틀렸나 |
|---|---|---|
| 폼 코호트 **63행** | **757행** | sql/에 커밋된 배치 3개(56+6+1)를 세고 코호트라 했습니다. **배치 1·4~16은 적용됐고 커밋만 안 됐습니다.** `plant_supply_links`(파일 있고 미적용)의 **거울상** — 리포지토리를 스키마로 읽었습니다 |
| **`868/888 = 97.7%` 도달 가능** | **~15%** | 이메일 **114** + 폼URL **20** = 천장 **134/888**. 868에서 757개 마커를 빼면 114쯤. **`email=null` 자리표시자를 컨택으로 셌습니다.** 이 문장은 **제가 migration_028 헤더에 썼고 오늘 계획 전체를 그 위에 올렸습니다** |
| 엉뚱한 등급 **56행** | **≥306행** | high 포함 187곳에 마커 159 / low·none만 329곳에 마커 **306**. 규모를 **6배** 과소평가 |
| "757은 **수십 개**로 접힘" | **612 브랜드** | 19% 접힙니다. KC/IP 56→2는 **규칙이 아니라 예외**였고, 저는 예외 하나로 전체를 추정했습니다. **일이 쉬워 보이는 방향으로 틀렸습니다** |

> **어제 오류의 반대쪽 신발입니다.** `4/242`는 **분모**가 틀렸고(행≠회사), `868/888`은 **분자**가 틀렸습니다(행≠컨택). **두 번 다 이미 적혀 있어서 믿었습니다.**

**➡️ 해야 할 일: migration_028 헤더의 97.7% 문장을 고치세요.** 마이그레이션 헤더의 틀린 숫자는 마이그레이션보다 오래 삽니다.

### 도구도 둘 죽었습니다
- **`domain_normalized`** — 757행에 값이 **19개**. 수집 키로 사망.
- **`party_name !~ ' - '`** (회사 필터) — 로스터 명명 규칙이 **섞여 있습니다**. `Hansol Paper - Cheonan`은 대시가 있고 `Sappi Ehingen`·`Mondi Steti`·`Navigator Setúbal`은 없습니다. 그래서 스윕 목록 248이 여전히 공장투성이입니다. high 47행은 실제로 **25개 회사쯤**.
- **`t.category` 42703** — `app.party_types`엔 `category`/`label_en`이 없습니다. 그건 **`app.paper_types`** 컬럼입니다. 덤프에서 `app.parties` 바로 앞 블록을 읽고 party_types인 줄 알았습니다. **`parties.party_type_id`가 SMALLINT인데 제가 읽은 테이블 id는 uuid** — 그것만 봤어도 잡혔습니다. **PART A에 추가.**

---

## 2. ⭐ 그 실수가 찾아낸 것

**`app.paper_types.filler_relevance`** — 큐레이션된 룩업 컬럼, `app.paper_mill_paper_types(mill_party_id, paper_type_id, is_primary)`로 제지사에 연결됨.

**어제 "스키마가 못 재는 여섯 축"에 등급을 넣었습니다. 잽니다.** 안 열어봤을 뿐입니다 — Artemyn이 kaolin 상인으로 앉아 있던 것과 같은 실패. 어휘: `high / medium / low / none`.

```
888 제지사
  high 포함        187   이메일 29  URL 7   마커 159
  low/none만       329   이메일 15  URL 5   마커 306
  등급 링크 없음    238   이메일 47  URL 8   마커 185   ← 27%. 가장 잘 닿는 밴드를 분류 못 함
```

---

## 3. 오늘 만든 것 — 폼 4 · 필드 32

| 회사 | 국가 | 필드 | 문 | 캡차 | 필수마크 |
|---|---|---|---|---|---|
| **한국제지** | KR | **10** | `고객문의 > 기타` — **FAQ가 지정** | 미확인 | 마크와 개인정보 고지가 **모순** |
| **Andhra Paper** | IN | **8** | `Become Our Supplier` → `Chemicals` | 미확인 | 없음 |
| **TNPL** | IN | **7** | **`Institutes / University / Research Center`** | 🔴 **있음** | 없음 |
| **Sylvamo** | US | **7** | `Other` (약하게) | **없음** | **있음 — 오늘 유일** |

**컨택 루트만(폼 행 없음)**: 한솔 4공장 + Sylvamo Saillat = 5행 — *공장은 서명 못 하고, 폼 행은 워크리스트 항목입니다*
**이메일 9개**: WCPM 8 + SPB `edoff@` 1
**오염 제거**: BILT ×2

### ⭐ TNPL — 두 로스터 30여 곳 중 유일한 연구 루트
```
한솔      전체/제품/한솔루션/투자/채용/기타          연구 없음
한국제지   제품/구입/시험성적/채용/사보/기타           연구 없음
Andhra    Chemicals/Fuels/Spares/Packaging/…       연구 없음
Sylvamo   Branding/Careers/…/Sustainability/Other  연구 없음
TNPL      INSTITUTES / UNIVERSITY / RESEARCH CENTER  ← 있음
```
매번 "맞는 옵션 없고 덜 틀린 옵션만"이었고 전부 영업/구매로 갔습니다.
**TNPL은 국영기업(타밀나두 주정부)이라 더 중요합니다** — 국영은 **입찰로만** 삽니다. 연구 문이 나은 게 아니라 **구매 문이 닫혀 있는 겁니다.**

---

## 4. 🔴 목록 자체가 기소당했습니다 — 인도 5곳 적중 2/5

| | 실제 | 목록 |
|---|---|---|
| Andhra Paper | 폼만, 이메일 0 | ✅ |
| TNPL | 폼만, 이메일 0 (**오늘 17:51 갱신된 페이지에 0**) | ✅ |
| **BILT ×2** | **웹사이트가 뉴욕 핀테크** | ❌ |
| **West Coast** | **이메일 8개, 폼 자체가 없음** | ❌ |
| **SPB** | **전무실 이메일 + 캡차 폼** | ❌ |

248 목록은 **"우리 DB에 이메일 없음"** 으로 골랐습니다. **필터가 잰 건 그쪽 문이 아니라 우리 구멍입니다.**
→ **폼을 찾아 스윕하면 이메일이 나옵니다.** 요청보다 나은 결과지만, **"폼 표적 248"은 폼 표적 개수가 아닙니다.** 같은 비율이면 실제 **~100곳**.

---

## 5. 🔴 반드시 알아야 할 것

### ① `bilt.com`은 뉴욕 핀테크입니다
인도 high 6곳 중 **2곳**이 **Bilt Technologies, Inc.**(임대료 리워드, 푸터 `NMLS ID 2527740`)를 가리켰습니다. 진짜는 **`biltpaper.in`** — 추측이 아니라 **BILT 자기 SEBI 공시**(2024.12.30, NSE/BSE) 레터헤드이고 **그 PDF가 그 도메인에서 서빙**됩니다.
🔴 **`info@bilt.com` 절대 발송 금지** — 옛 공시에 있고 **도메인이 공시 사이에 넘어갔습니다.** Saica는 이탈리아 경쟁사로 갈 뻔했고 이건 **미국 소비자금융사**로 갈 뻔했습니다. **컨택 행이 없어서 안 보낸 것뿐입니다.**
**판정: 지금 표적 아님** — 2026.5.11 제80기 주총에서 CIRP 완료(**9주 전**), Finquest 소유, 직원 **189명**, 공장 1개 재가동. 등급 적합 완벽, 타이밍 불가. **1년 뒤 재검토.**

### ② ⭐ Andhra ↔ West Coast는 같은 책상입니다
```
하이데라바드  "1-89/3/B/40 to 42/KS/107/A, 1st Floor, MSR Block, Krishe Sapphire"
             → 도어 넘버가 한 글자도 안 틀림
콜카타 · 뉴델리 · 뭄바이 · 첸나이 · 벵갈루루  → 6곳 일치
전화 033-71500500 · 011-40110101            → 완전 동일
```
**양쪽 자기 컨택 페이지로 확정.** Andhra는 사무소 8곳에서 **이메일 0**, WCPM은 **같은 책상에서 8개**.
**⛔ westcoastpaper.com 주소를 Andhra 행에 안 붙였습니다.** 같은 건물은 비슷한 이름보다 **약한** 근거입니다. 노트만. **병합은 사람 결정.**

### ③ 🔴 캡차 — 폼 시스템이 담을 수 없는 사실
SPB·TNPL 둘 다 Contact Form 7 + 캡차. **WordPress 인도 제지사 2/2.**
`input_kind`는 `fill/check/select_option/upload`뿐이고 **캡차 멤버는 없어야 맞습니다** — **브라우저 앞 사람 외엔 제출 불가**라는 뜻이니까요. TNPL엔 **필드(seq 70)로 기록**해서 `v_application_field_status`에 차단 요인이 행으로 보이게 했습니다.
**➡️ 뒤로 적용 필요: 한국제지·Andhra·한솔은 전부 서버 사이드로 읽었고, 클라이언트 렌더 캡차는 안 보였을 겁니다.**

### ④ ⛔ `Supplier Diversity`는 우리 옵션이 아닙니다
Sylvamo Topic에 있습니다. **소수자·여성 소유 기업 프로그램**입니다. 구매에 닿으려고 고르면 **가지지 않은 지위를 상장사에, 문서로, 윤리·컴플라이언스 인접 폼에서 주장**하는 겁니다. 지름길이 아니라 허위표시.

### ⑤ ⭐ 등급이 가장 맞는 회사가 기술 문이 가장 적습니다
```
한국제지    R&D 페이지 + 1단계에서 미팅 약속하는 납품 절차
West Coast  R&D/QC + Tender
TNPL        연구소 라우팅 옵션
Artemyn     Par Moor — paper & board lab
Sylvamo     없음. 기술 페이지 0, 랩 0
```
Sylvamo 홈페이지가 이유를 씁니다 — *"exclusive focus on the promise of paper … long-term value for **shareowners**"*. IP가 2021년 **성숙 자산 현금화**로 분사시켰습니다.
**읽기 두 갈래, 미해결**: R&D 없는 회사는 **직접 안 만들고 라이선스**하거나 **아예 평가 안 합니다.**

### ⑥ 국가별 정렬이 최대어를 숨겼습니다
Sylvamo는 BR·SE·US·FR로 쪼개져 어느 나라 상위에도 안 나옵니다. **브랜드로 본 블록 2가 찾았습니다.** 다중행 브랜드 **24개 전부 이메일 0** — IP·KC·WestRock·Georgia-Pacific·Oji·Nippon Paper. **114개 이메일은 전부 소형 단일행 제지사에 있습니다.**

---

## 6. Claude의 실수 (기록)

- **`t.category` 42703** — 스키마 파일 열어놓고 옆 블록 읽음. **PART A가 존재하는 이유가 그것**
- **`filler_use_intensity ~* 'high'`** — 본 적 없는 어휘를 필터. **행이 나왔을 거고 맞아 보였을 것**
- **63 vs 757** — sql/를 DB로 읽음
- **97.7%** — 자리표시자를 컨택으로 셈. **그 문장을 028 헤더에 쓴 게 저입니다**
- **"수십 개로 접힘"** — 예외 하나로 전체 추정. **쉬워 보이는 방향**
- **verify를 전부 주석으로 냄** → `Success. No rows returned`를 세 번 보고 세 번 다 아무것도 모름

**살린 규칙**: 추측 URL 안 씀 · `max_length` 안 지어냄 · 스니펫으로 이메일 안 넣음(SPB `mdoff@`) · 이웃 인박스 안 붙임(Andhra) · 공장에 폼 행 안 만듦(한솔4·Saillat) · 마케팅 9명 안 넣음(TNPL) · **`Supplier Diversity` 안 씀**

### 🆕 오늘 확정된 규칙
> **모든 fix 파일의 마지막 문장은 주석이 아닌 `select`.**
> Supabase는 마지막 result set을 보여줍니다. 거기 verify를 두면 `Success. No rows returned`가 **구조적으로 불가능**해집니다. BILT부터 적용, 첫 판에 작동.

---

## 7. [PENDING]

### 즉시
1. **`max_length`** — 32개 필드 전부 null. **5개사 5전 5패**, 서버 fetch로 안 나옵니다. **브라우저 필요.** 최소 한국제지 `제목`·`내용` 둘
2. **캡차 소급 확인** — 한국제지·Andhra·한솔
3. **한솔 회사행** — `scan_paper_mill_form_cohort` **블록 6** 아직 미실행. 결과 주시면 폼 파일 한 줄
4. **migration_028 헤더** 97.7% 문장 정정

### 결정 대기
5. **제지사 답변 세트** — `filler_safe`는 반대 방향 범주 오류(필러사=경쟁자, 제지사=고객). **단 반론이 약하지 않음**: 제지사는 자기 PCC 공급사에 다 말합니다. **한솔 장항 피칭 = 태경BK 도달.** 톤이 아니라 **게이트**가 필요
6. **한솔 KR vs EN 폼** — 필드가 다름, 하나만 등록 가능
7. **Andhra ↔ WCPM 병합** · **BILT ×2 병합**(둘 다 biltpaper.in, 단 Sewa는 BGPPL 법인)
8. **KC/IP 56행 철회** 여부 — 306의 일부
9. **TNPL `Institutes` vs `Potential Supplier`** — 전자는 학술용일 수 있음
10. **Sylvamo `Other` vs `Sustainability`** — 후자는 보고 기능이지 평가 기능이 아님

### 리드 (사실 아님)
11. **⭐ SMI NewQuest India** — MTI의 **SEC 공시(2009.4.23)**: SMI가 **BILT Ballarshah 안에 연 65,000톤 satellite PCC**, **합작사 소유**. 이 DB satellite 명단 7곳에 없음. **17년 전 + 회생 겪음. 상태 미확인.** 폼 작업이 아니라 **satellite 작업**
12. **SPB `mdoff@`**(사장실) · `cmo@` · `spbtn@` — locations 페이지. **스니펫이라 안 넣음. 열어야 함.** 배치 최고 주소일 가능성
13. **Sylvamo `sales-and-purchase-policies`** — 사이트에서 유일한 구매 모양 페이지, 미개봉
14. **WCPM `rd-qc` · `latest-tender` · `management-team`** — 미개봉

### 남은 스윕
```
Domtar (CA/US, high 8/10, 회사행 1, 이메일 0)   ← 다음
CN 8 high (17곳 중) · US 4 · TH 3 · DE 3 · FR 3
스킵 후보  SE 15 · GB 12 · IT 9 (전부 등급 있고 high 0) + high 0인 29개국 = 90곳
별건 ①  332행(45%) 웹사이트 없음 → 영원히 스윕 불가
별건 ②  89곳 등급 링크 백필 — 스윕보다 훨씬 쌈
```

---

## 8. 파일 이동 + 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

**폴백 (인라인 무버 — 오늘 13개 전부):**
```powershell
$ErrorActionPreference = 'Stop'
$dl  = Join-Path $env:USERPROFILE 'Downloads'
$sql = 'C:\dev\mbg-project\sql'
$doc = 'C:\dev\mbg-project\docs\handoff\2026-07-17'
$map = @(
  @{ N='scan_paper_mill_form_cohort_2026-07-17.sql';        D=$sql },
  @{ N='scan_paper_mill_reachability_2026-07-17.sql';       D=$sql },
  @{ N='scan_paper_mill_sweep_worklist_2026-07-17.sql';     D=$sql },
  @{ N='scan_mill_form_writes_verify_2026-07-17.sql';       D=$sql },
  @{ N='fix_hankuk_paper_contact_form_2026-07-17.sql';      D=$sql },
  @{ N='fix_hansol_paper_contact_route_2026-07-17.sql';     D=$sql },
  @{ N='fix_andhra_paper_contact_form_2026-07-17.sql';      D=$sql },
  @{ N='fix_bilt_wrong_website_2026-07-17.sql';             D=$sql },
  @{ N='fix_wcpm_emails_and_andhra_link_2026-07-17.sql';    D=$sql },
  @{ N='fix_spb_email_over_form_2026-07-17.sql';            D=$sql },
  @{ N='fix_tnpl_contact_form_2026-07-17.sql';              D=$sql },
  @{ N='fix_sylvamo_contact_form_2026-07-17.sql';           D=$sql },
  @{ N='handoff_paper_mill_form_sweep_2026-07-17.md';       D=$doc }
)
foreach ($m in $map) {
  $base = [System.IO.Path]::GetFileNameWithoutExtension($m.N)
  $ext  = [System.IO.Path]::GetExtension($m.N)
  $src = Get-ChildItem -Path $dl -Filter ($base + '*' + $ext) -File -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host ("SKIP  " + $m.N); continue }
  Unblock-File -Path $src.FullName
  [System.IO.Directory]::CreateDirectory($m.D) | Out-Null
  $target = [System.IO.Path]::Combine($m.D, $m.N)
  [System.IO.File]::Copy($src.FullName, $target, $true)
  Remove-Item -LiteralPath $src.FullName -Force
  Write-Host ("OK    " + $target)
}
```

> **아침 판본 핸드오프는 같은 파일명이라 덮어써집니다. 그게 의도입니다** — 63행과 97.7%가 남아 있으면 안 됩니다.

**실행 순서 (SQL Editor, 블록 단위로 따로):**
```
전부 이미 실행·검증 완료 (7/7 · 2/2 · 2/2 · 1/1 · 1/1 · 2/2)
미실행:  scan_paper_mill_form_cohort  블록 6  ← 한솔 회사행. 이것만 남았습니다
```

**마무리 (`&&` 금지 — 줄 분리):**
```powershell
cd C:\dev\mbg-project
Get-ChildItem sql\*2026-07-17*.sql | Measure-Object | Select-Object -ExpandProperty Count
git status -sb
git add sql/ docs/handoff/2026-07-17/
git commit -m "paper mill form sweep: 4 forms 32 fields (Hankuk/Andhra/TNPL/Sylvamo), BILT domain contamination, WCPM-Andhra shared offices, cohort 63 was 757"
git push origin marinebiogroup
```

> **push = Railway 자동 배포 = 웹 즉시 반영.**
> 아침 핸드오프가 오늘 SQL 29개라 했고 **12개 추가 = 41개**여야 합니다. 아니면 커밋 누락입니다. **어제 3회 있었습니다.**

---

## 9. 결론

> **필러는 닿을 데가 없었고(242 중 4), 제지사는 닿는 척을 하고 있었습니다(868 중 757이 주소 없는 자리표시자).**

- **한국제지** — *"고객센터 > 고객문의 > **기타**로 문의 바랍니다."* 자기 FAQ에 있었습니다. 몇 년째 거기 있었습니다
- **필드 32개** — 어제 Artemyn에서 0개였습니다. **차이는 HubSpot 임베드냐 서버 렌더링이냐 하나뿐이었습니다**
- **bilt.com** — 인도 최상급 표적 2곳이 **뉴욕 핀테크**를 가리켰습니다. 로스터는 **한때 맞았습니다**
- **Andhra ↔ WCPM** — 도어 넘버가 한 글자도 안 틀립니다. **DB에 그 관계를 담을 컬럼이 없습니다**
- **Sylvamo** — 등급이 가장 순수한 회사에 **기술 문이 하나도 없습니다**
- **목록 적중 2/5** — "이메일 없음"은 그쪽 사실이 아니라 **우리 사실**이었습니다

> **어제는 스물여섯 번 중 스물여섯 번이었습니다. 오늘은 여섯 번 중 여섯 번이고, 그중 넷은 폼이 답이 아니라고 말했습니다.**
