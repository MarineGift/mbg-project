# 제지사 폼 스윕 — 2026-07-17 최종 (앞선 두 판본 폐기)

> **결론 한 줄: 폼 4개·필드 32개를 만들었고, 그게 오늘의 두 번째로 좋은 성과였습니다. 첫 번째는 조인 하나였습니다.**

---

## 1. 오늘 만든 것

```
폼 4개 · 필드 32개     한국제지 10 · Andhra 8 · TNPL 7 · Sylvamo 7
이메일 12개            WCPM 8 · SPB 1 · Domtar 3
컨택 루트 (폼 행 없음)   한솔 4공장 · Sylvamo Saillat · Domtar 11행
오염 제거              BILT ×2  (bilt.com = 뉴욕 핀테크)
그룹 관계              Andhra ↔ WCPM  (사무소 6곳·전화 2개 일치)
🔴 DNC                 Kleannara · 태경산업 · 태경BK — 처음으로 실제 적용됨
⭐ satellite 짝 8개     Artemyn — high 6개. 홈페이지 0장.
```

---

## 2. ⭐ 하루의 답: 조인 하나가 스윕 아홉 개를 이겼습니다

홈페이지 아홉 곳을 열어 폼 넷을 만들었습니다. 그 사이에:

**어제** artemyn.com 자기 지도를 읽어 `filler_supplier_profile.extra_data`에 저장 → 탄산칼슘 공장 17곳, 마을 이름으로.
**오늘** 무관한 이유로 제지사 로스터를 조회 → `Domtar - Marlboro Mill (Bennettsville, SC)`.
**Artemyn 지도에 `Bennettsville, SC, US`가 있습니다.** 인구 8천, 제지공장 하나.

마을+국가로 조인했더니 **여덟 개**가 나왔고 **여섯 개가 `high`** 입니다:

| 플랜트 | 호스트 제지공장 | 등급 |
|---|---|---|
| Bennettsville, SC | **Domtar - Marlboro Mill** | high ← 통제군, 눈으로 선확인 |
| Somerset, ME | **Sappi - Somerset Mill (Skowhegan)** | high/medium |
| Bhadrachalam, IN | **ITC Paperboards** | high/medium |
| Niigata, JP | **Hokuetsu Corporation** | high |
| Ledesma, AR | **Ledesma** | high |
| Balasore, IN | Emami Paper Mills | high/low/med |
| Husum, SE | Metsä Board Husum | low/medium |
| Yueyang, CN | Yueyang Forest & Paper | 등급링크 없음 |

**여덟 개 전부 `party_supply_links`에 없었습니다.**

**왜 이게 폼보다 큰가**: FCC의 배치 단위는 회사가 아니라 **짝**입니다. 제지공장 울타리 안의 satellite 플랜트가 FCC가 물리적으로 만들어질 자리입니다 — 운영사가 공정을 돌리고 제지사가 담 너머로 씁니다. **몇 년 걸리는 부분이 이미 끝나 있습니다.** FCC는 그 플랜트가 뭘 만드는지만 바꿉니다.
그 구성이 이미 있던 유일한 짝이 **한솔 장항 + 태경BK**이고, 오늘 03:42에 `do_not_contact`가 켜졌습니다. **이 여덟은 닿을 수 있는 쪽의 같은 구성입니다.** 그리고 Artemyn은 필러 1순위이며 자기 홈페이지가 *"our leadership team is ready to talk"* 라고 씁니다.

**`potential` / `medium`으로 기록했습니다. 사실이 아니라 후보로.** 근거는 마을 공유일 뿐이고 울타리 안이라는 증명이 아닙니다 — Artemyn 자기 기록이 `medium, 사이트별 확인 요`라 했고 그 문장은 지금도 맞습니다.
**기존 `potential` 85개는 전부 confidence가 null이고 근거가 없습니다.** 이 여덟이 **왜 존재하는지 말하는 첫 potential 링크**입니다.

**Somerset이 어떻게 맞았는지가 방법론입니다** — `city`가 **Skowhegan**입니다. 도시 매칭은 놓쳤고 이름 매칭이 잡았습니다.

**Artemyn 기존 링크 4개는 회사행이고 confidence C입니다** — `Sappi (Europe)` · `Metsä Board` · `Lecta` · `MM Board & Paper`. 신규는 공장 이름 + 플랜트 이름 + 근거. **Sappi·Metsä는 같은 관계가 두 입도로 중복** — 사람이 정리할 일.

---

## 3. 🔴 시장 구조 — 숫자 하나

```
SMI     34  ┐
Omya    27  ├─  high 등급 짝 78개 중 64개 = 82%
Imerys   3  ┘
```
**SMI는 FulFill을 팔고, Omya와 Imerys는 FiberLean을 공동 소유합니다.**
`seed_filler_form_answers`가 답변을 밋밋하게 쓴 이유였고, **이제 규모가 나왔습니다: FCC가 겨냥하는 짝의 82%를 경쟁 섬유대체 기술 보유자가 쥐고 있습니다.**

**그리고 `Specialty Minerals (국가 - 마을)` 파티 행이 약 60개, 공장당 하나씩 있습니다** — Rajahmundry · Erode · Dandeli · Ballarshah · Gaganapur · Cornwall · Saillat · Ticonderoga · Stockstadt · Figueira da Foz · Perawang · Shiraoi …

**오늘 홈페이지를 연 아홉 곳 전부가 이미 짝지어져 있었습니다:**
```
Andhra Paper   ← SMI (India - Rajahmundry)   active
Seshasayee     ← SMI (India - Erode)         active · confidence high — 73개 중 유일
West Coast     ← SMI (India - Dandeli)       active
BILT           ← SMI (India - Ballarshah)    active
TNPL           ← Omya (India)                active
한국제지        ← Omya (Korea)                active   ← 오늘 처음 만든 폼. 공급사가 FiberLean 공동소유주
한솔 장항       ← 태경BK                       active · medium
Sylvamo/Domtar ← SMI ×4 · Omya ×3 · Carmeuse · MLC · Imerys
```

---

## 4. 🔴 DNC — 있는데 안 먹고 있었습니다

`fix_adverse_parties_dnc_2026-07-17.sql`은 sql/에 커밋돼 있었고 **내용이 맞았고**, 태경BK는 `do_not_contact = false`였습니다.

**원인**: statement 1의 `notes` 문자열 안에 **`where`가 두 개**.
> *"...it sits in the roster **where** 868 of 888 parties already have a contact and **where** the outreach machine is live."*

**파스 실패가 스크립트 전체를 취소했습니다.** 트랩은 1번에만 있는데 셋 다 안 먹은 게 그 증거입니다. **어제 `&&`가 블록 전체를 취소시킨 것과 같은 실패 모드, 다른 언어.** 문구를 바꾸자 셋이 한 번에 들어갔습니다.

```
Kleannara(type 2) · 태경산업(3) · 태경BK(3)    전부 true, 03:42:33
세 행 모두  enrolments 0 · deals 0 · form_rows 0
```
**아무것도 안 나갔습니다** — 이번엔 단언이 아니라 **다시 재서** 확인했습니다.

**🔴 Kleannara: `contacts 1 · emails 0`.** 그 모양은 `Form 입력` 마커입니다. 즉 **248 스윕 목록 선발 기준(이메일 없음 → 폼이 유일한 문)을 그대로 통과하는 프로필**이었습니다.
**막은 건 가드가 아니라 "한국 제외"였습니다.** 설계가 아니라 운입니다. 오늘 그 문장을 두 번 씁니다.

---

## 5. 🔴 목록이 틀렸습니다 — 인도 5곳 적중 2/5

| | 실제 | 목록 |
|---|---|---|
| Andhra Paper | 폼(구매 벤더), 이메일 0 | ✅ |
| TNPL | 폼(**연구 루트 有**), 이메일 0 | ✅ |
| BILT ×2 | **웹사이트가 뉴욕 핀테크** | ❌ |
| West Coast | **이메일 8, 폼 자체가 없음** | ❌ |
| SPB | **전무실 이메일, 캡차 폼** | ❌ |

248 목록은 **"우리 DB에 이메일 없음"** 으로 골랐습니다. **필터가 잰 건 우리 구멍입니다.**

### ⭐ TNPL — 30여 곳 중 유일한 연구 루트
```
한솔      전체/제품/한솔루션/투자/채용/기타                      연구 없음
한국제지   제품/구입/시험성적/채용/사보/기타                       연구 없음
Andhra    Chemicals/Fuels/Spares/Packaging/Services/Waste/Wood  연구 없음
Sylvamo   Branding/…/Sustainability/Supplier Diversity/Other     연구 없음
TNPL      INSTITUTES / UNIVERSITY / RESEARCH CENTER              있음
```
**국영기업(타밀나두 주정부)이라 더 중요합니다** — 국영은 입찰로만 삽니다. 연구 문이 나은 게 아니라 **구매 문이 닫혀 있습니다.**

### 🔴 차단 클래스 셋 — 전부 페이지를 열어서 알았습니다
```
HubSpot 임베드          Artemyn        필드 못 읽음
Contact Form 7 캡차     SPB · TNPL     사람이 브라우저 앞에 필요
Pardot + 쿠키 게이트    Domtar         필드 못 읽음
```
`input_kind`에 캡차 멤버가 없고 **없는 게 맞습니다** — 자동 제출 불가라는 뜻이니까요. TNPL엔 **필드(seq 70)로** 기록해 `v_application_field_status`에 행으로 보이게 했습니다.

### ⛔ `Supplier Diversity`는 우리 옵션이 아닙니다
Sylvamo Topic에 있습니다. 소수자·여성 소유 기업 프로그램입니다. 구매에 닿으려고 고르면 **가지지 않은 지위를 상장사에, 문서로, 윤리·컴플라이언스 인접 폼에서 주장**하는 겁니다.

### ⭐ 등급이 가장 맞는 회사가 기술 문이 가장 적습니다
```
한국제지    R&D 페이지 + 1단계에서 미팅 약속하는 납품 절차
West Coast  R&D/QC + Tender
TNPL        연구소 라우팅 옵션
Artemyn     Par Moor — paper & board lab
Sylvamo     없음        ┐  북미 최대 UWF 생산자 둘 다
Domtar      없음        ┘  공정 평가자에게 가는 길을 공개 안 함
```

---

## 6. Claude의 실수 (기록) — 일곱 번

```
코호트 63              → 757      sql/를 DB로 읽음
도달 가능 97.7%         → ~15%     자리표시자를 컨택으로 셈. 그 문장을 028 헤더에 쓴 게 저입니다
엉뚱한 등급 56          → ≥306
"수십 개로 접힘"         → 612 브랜드
"링크는 몇 개뿐"         → 109       제 파일 주석에 예측을 써놨습니다
"SMI NewQuest 없음"    → active로 있었음
"다른 머신 같다"         → 아니었음   git status 목록으로 머신을 추론
```
**전부 이미 작성돼 있던 쿼리를 돌리기 전에 단언한 것들입니다.** 여섯이 **일이 쉬워 보이는 방향**으로 틀렸습니다.

**추가 실수**: `t.category` 42703(`app.paper_types`를 `party_types`로 오독 — id 타입만 봤어도 잡힘) · `filler_use_intensity ~* 'high'`(본 적 없는 어휘로 필터) · **verify를 전부 주석으로 냄**(`Success. No rows returned`를 세 번 보고 세 번 다 모름) · **스캔 파일 블록 순서를 거꾸로**(통째 실행 시 마지막 것만 보임 → Artemyn 크로스매치가 두 번 안 보임)

**살린 규칙**: 추측 URL 안 씀 · `max_length` 안 지어냄 · 스니펫으로 이메일 안 넣음(SPB `mdoff@`) · 이웃 인박스 안 붙임(Andhra) · 공장에 폼 행 안 만듦 · 마케팅 9명 안 넣음(TNPL) · 실명 13명 안 넣음(Domtar) · `Supplier Diversity` 안 씀 · `product_grade` 안 채움

### 🆕 오늘 확정된 규칙 넷
> **① fix 파일의 마지막 문장은 주석이 아닌 `select`.** Supabase는 마지막 result set을 보여줍니다. `Success. No rows returned`가 구조적으로 불가능해집니다.
> **② 스캔 파일의 마지막 블록은 질문.** 같은 이유, 반대쪽 끝. 다섯 개를 거꾸로 만들었습니다.
> **③ 문자열 안에 SQL 키워드 금지는 장식이 아닙니다.** DNC가 그것 때문에 하루 종일 안 먹었습니다.
> **④ 쿼리가 무엇을 결정할지는 쓰되, 무엇을 말할지는 쓰지 않는다.**

---

## 7. [PENDING]

### 즉시
1. **사이트 하나만 확인** — **Sappi Somerset** 또는 **Domtar Marlboro**. 둘 다 US·high·운영사가 파트너 접근 환영. **확인된 satellite 짝 하나가 나머지 일곱을 합친 것보다 값집니다** — 입지 추론이 명명된 구성이 됩니다
2. **`scan_satellite_host_crossmatch` 블록 2** — 매칭 안 된 Artemyn 공장 **아홉 개**(Capitan Bermudez · Limeira · Pirai · Tunadal · Amritsar · **Bhigwan** · Silvassa · Miyagi · Kaohsiung). 각각 **로스터에 없는 제지공장**이거나 **satellite가 아닌 상인 사이트**. Bhigwan은 BILT Graphic Paper Products일 가능성
3. **나머지 satellite 운영사 6곳도 같은 처리** — SMI·태경BK(불가)·Double A·Fimatec·Gulshan·MLC. `footprint` 배열이 있는지부터
4. **migration_028 헤더의 97.7%** 정정

### 결정 대기
5. **제지사 답변 세트** — `filler_safe`는 반대 방향 범주 오류(필러사=경쟁자, 제지사=고객). **단 반론이 약하지 않음**: 제지사는 자기 PCC 공급사에 다 말합니다. **한국제지 피칭 = Omya 도달. 한솔 장항 피칭 = 태경BK 도달.** 톤이 아니라 **게이트**가 필요
6. **Artemyn 링크 중복** — `Sappi (Europe)`/`Metsä Board`(회사행, C) vs 신규 공장행. 정리는 사람 결정
7. **Andhra ↔ WCPM 병합** · **BILT ×2 병합**(Sewa는 BGPPL 법인)
8. **KC/IP 56행 철회** 여부 — 306의 일부
9. **TNPL `Institutes` vs `Potential Supplier`** · **Sylvamo `Other` vs `Sustainability`**
10. **`max_length` 32개 전부 null** — 5개사 5전 5패. 브라우저 필요

### 안 연 문
```
ITC Bhadrachalam        인도 7번째 메이저. 248 목록에 없어서 한 번도 안 열었음
SPB  mdoff@ (사장실)     locations 페이지. 스니펫이라 안 넣음. 배치 최고 주소일 가능성
Sylvamo sales-and-purchase-policies · Domtar 동명 페이지 · Domtar pulp-contact-request
WCPM rd-qc · latest-tender · management-team
```

### 남은 스윕 (우선순위 하락)
```
CN 8 high · US 4 · TH 3 · DE 3 · FR 3
스킵      SE 15 · GB 12 · IT 9 (등급 다 매겨졌고 high 0) + high 0인 29개국 = 90곳
별건 ①    332행(45%) 웹사이트 없음 → 영원히 스윕 불가
별건 ②    89곳 등급 링크 백필 · 135곳 필러 링크 누락 (JP 17 · CN 13 · US 10 · DE 9 · IN 8)
```
**high 등급 제지사가 필러를 안 사고 존재할 수 없습니다. 135는 누락된 링크지 공급사 없는 제지사가 아닙니다.**

---

## 8. 파일 이동 + 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

**마무리 (`&&` 금지 — 줄 분리):**
```powershell
cd C:\dev\mbg-project
Get-ChildItem sql\*2026-07-17*.sql | Measure-Object | Select-Object -ExpandProperty Count
git status --porcelain
git add sql/ docs/handoff/2026-07-17/
git commit -m "Artemyn satellite hosts: one join beat nine homepage sweeps. 8 named pairs, 6 high grade, none in party_supply_links - Domtar Marlboro, Sappi Somerset, ITC Bhadrachalam, Hokuetsu, Ledesma, Emami, Metsa Husum, Yueyang. Recorded as potential/medium with a stated basis - the first 85 potential links have none. SMI+Omya+Imerys hold 82% of high-grade pairs and own FulFill and FiberLean"
git push origin marinebiogroup
```

> **push = Railway 자동 배포 = 웹 즉시 반영.**
> **개수 46**이어야 합니다 (커밋된 44 + `scan_satellite_host_match` + `fix_artemyn_host_links`). 아니면 숫자만 주세요.
> 핸드오프는 같은 파일명이라 덮어써집니다. **의도입니다** — 63행과 97.7%가 남으면 안 됩니다.

---

## 9. 결론

> **정보는 없던 게 아니라 가져오지 않은 것이었습니다.** — 어제 필러 핸드오프의 마지막 줄. 오늘 그게 우리 자신에게 적용됐습니다.

- **홈페이지 아홉 곳을 열었고, 아홉 곳 전부 이미 이름 붙은 필러 공급사와 짝지어져 있었습니다**
- **Artemyn satellite 지도는 어제부터 `extra_data` 안에 있었습니다.** 조인 하나가 짝 여덟 개를 냈고 **홈페이지는 0장**이었습니다
- **DNC는 문자열 안의 `where` 두 개 때문에 하루 종일 안 먹었습니다.** Kleannara를 막은 건 가드가 아니라 **"한국 제외"** 였습니다
- **bilt.com** — 인도 최상급 표적 2곳이 **뉴욕 핀테크**를 가리켰습니다. 로스터는 **한때 맞았습니다**
- **82%** — FCC가 겨냥하는 짝을 FiberLean·FulFill 보유자가 쥐고 있습니다
- **제 숫자 일곱 개가 죽었고 여섯이 쉬워 보이는 방향이었습니다**

> **어제는 스물여섯 번 중 스물여섯 번, 회사 페이지가 DB를 이겼습니다.**
> **오늘은 한 번, DB가 회사 페이지 아홉 장을 이겼습니다. 아무도 조회하지 않았을 뿐입니다.**
