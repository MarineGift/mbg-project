# 제지사 폼 스윕 — 2026-07-17 최종 (앞선 판본 전부 폐기)

> **결론 한 줄: 폼 4개를 만들라고 하셔서 만들었고, 그게 오늘의 세 번째로 좋은 성과였습니다.**

---

## 1. 오늘 만든 것 — SQL 49개

```
폼 4 · 필드 32        한국제지 10 · Andhra 8 · TNPL 7 · Sylvamo 7
이메일 12             WCPM 8 · SPB 1 · Domtar 3
컨택 루트 16행         한솔 4 · Sylvamo Saillat 1 · Domtar 11
오염 제거 2행          BILT (bilt.com = 뉴욕 핀테크)
🔴 DNC 3행            Kleannara · 태경산업 · 태경BK — 처음으로 실제 적용
⭐ satellite 짝 10     Artemyn 8 (potential/medium) · Gulshan 2 (active)
```

---

## 2. ⭐ 오늘의 답 — 요청받은 것과 달랐습니다

홈페이지 아홉 곳을 열어 폼 넷을 만들었습니다. **아홉 곳 전부 이미 이름 붙은 필러 공급사와 짝지어져 있었습니다.**

```
Andhra Paper   ← SMI (India - Rajahmundry)   active
Seshasayee     ← SMI (India - Erode)         active · confidence high — 73개 중 유일
West Coast     ← SMI (India - Dandeli)       active
BILT           ← SMI (India - Ballarshah)    active
TNPL           ← Omya (India)                active
한국제지        ← Omya (Korea)                active   ← 첫 폼. 공급사가 FiberLean 공동소유주
한솔 장항       ← 태경BK                       active · medium
Sylvamo/Domtar ← SMI ×4 · Omya ×3 · Carmeuse · MLC · Imerys
```

**`Specialty Minerals (국가 - 마을)` 파티 행이 약 60개**, 공장당 하나씩 있었습니다 — Rajahmundry · Erode · Dandeli · Ballarshah · Cornwall · Saillat · Ticonderoga · Stockstadt · Figueira da Foz · Perawang · Shiraoi…

### 조인 하나가 스윕 아홉 개를 이겼습니다
**어제** artemyn.com 지도를 `extra_data`에 저장 → 공장 17곳, 마을 이름.
**오늘** 무관한 이유로 로스터 조회 → `Domtar - Marlboro Mill (Bennettsville, SC)`. Artemyn 지도에 그 마을이 있습니다.

| 플랜트 | 호스트 | 등급 |
|---|---|---|
| Bennettsville, SC | **Domtar - Marlboro Mill** | high ← 통제군 |
| Somerset, ME | **Sappi - Somerset Mill (Skowhegan)** | high/medium |
| Bhadrachalam, IN | **ITC Paperboards** | high/medium |
| Niigata, JP | **Hokuetsu Corporation** | high |
| Ledesma, AR | **Ledesma** | high |
| Balasore, IN | Emami Paper Mills | high/low/med |
| Husum, SE | Metsä Board Husum | low/medium |
| Yueyang, CN | Yueyang Forest & Paper | 등급링크 없음 |

**여덟 개 전부 `party_supply_links`에 없었습니다.** `potential`/`medium`으로 기록 — 마을 공유는 울타리 안이라는 증명이 아닙니다.
**Somerset이 방법론입니다** — `city`가 **Skowhegan**입니다. 이름 매칭이 잡았습니다.
**기존 `potential` 85개는 전부 confidence null·근거 없음.** 이 여덟이 **왜 존재하는지 말하는 첫 potential 링크**입니다.

### ⭐ Gulshan은 다릅니다 — 회사가 호스트를 지명합니다
```
Orient Paper & Industries Ltd.  Amlai    active · high    이름·도시 일치 + 회사 진술 + 2015
ITC PSPD - Tribeni Unit         Tribeni  active · medium  Hooghly(지구) vs Tribeni(마을) 간극
```
> *"This Onsite PCC plant was set up in 2015 at **Amlai**, Madhya Pradesh for **Orient paper Mills (OPM)**, a Birla Group Company"* — gulshanindia.com/manufacturing_unit.html

**Artemyn은 마을을 줬고 Gulshan은 이름을 줍니다.** 증거 등급이 다릅니다. **Orient가 오늘 가장 강한 짝이고, 페이지 한 장 걸렸습니다.**
**ITC는 4행이 나왔습니다** — 먼저 나온 Bhadrachalam에 걸었으면 **매너 좋은 Saica 오류**였습니다. `city`가 막았습니다(나머지 셋은 텔랑가나·타밀나두).
**⛔ ITC·TNPL·BILT·Shree Krishna는 안 걸었습니다** — Gulshan 자기 페이지가 `supplying PCC`로 따로 씁니다. **상인 공급은 satellite가 아닙니다.**

---

## 3. 🔴 시장 구조 — 숫자 하나

```
SMI 34 + Omya 27 + Imerys 3  =  high 등급 짝 78개 중 64개 = 82%
```
**SMI는 FulFill을 팔고 Omya·Imerys는 FiberLean을 공동 소유합니다.** `seed_filler_form_answers`가 답변을 밋밋하게 쓴 이유였고, 이제 규모가 나왔습니다.

---

## 4. 🔴 DNC — 있는데 안 먹고 있었습니다

`fix_adverse_parties_dnc`는 커밋돼 있었고 내용이 맞았고, 태경BK는 `false`였습니다.
**원인**: statement 1 `notes` 문자열 안의 **`where` 두 개**. **파스 실패가 스크립트 전체를 취소.** 트랩은 1번에만 있는데 셋 다 안 먹은 게 증거입니다. **어제 `&&`와 같은 실패 모드, 다른 언어.**

```
Kleannara(2) · 태경산업(3) · 태경BK(3)   전부 true, 03:42:33
세 행 모두  enrolments 0 · deals 0 · form_rows 0
```
**🔴 Kleannara: `contacts 1 · emails 0`** = `Form 입력` 마커. **248 목록 선발 기준을 그대로 통과하는 프로필**이었습니다. **막은 건 가드가 아니라 "한국 제외"입니다. 운입니다.**

---

## 5. 🔴 목록이 틀렸습니다 — 인도 5곳 적중 2/5

| | 실제 | 목록 |
|---|---|---|
| Andhra · TNPL | 폼만, 이메일 0 | ✅✅ |
| BILT ×2 | 웹사이트가 뉴욕 핀테크 | ❌ |
| West Coast | 이메일 8, **폼 자체가 없음** | ❌ |
| SPB | 전무실 이메일, 캡차 폼 | ❌ |

**"우리 DB에 이메일 없음"으로 골랐습니다. 필터가 잰 건 우리 구멍입니다.**

**⭐ TNPL만 연구 루트가 있습니다** — `INSTITUTES / UNIVERSITY / RESEARCH CENTER`. 한솔·한국제지·Andhra·Sylvamo 전부 없습니다. **국영이라 더 중요합니다** — 국영은 입찰로만 삽니다.
**🔴 차단 클래스 셋**: HubSpot 임베드(Artemyn) · CF7 캡차(SPB·TNPL) · **Pardot+쿠키게이트(Domtar)**. 셋 다 **페이지를 열어서** 알았습니다.
**⛔ `Supplier Diversity`(Sylvamo)는 우리 옵션이 아닙니다** — 소수자·여성 소유 기업 프로그램.
**⭐ 등급이 가장 맞는 회사가 기술 문이 가장 적습니다** — Sylvamo·Domtar 둘 다 R&D 컨택 0.

---

## 6. Claude의 실수 — 아홉 번, 한 종류

```
코호트 63           → 757        sql/를 DB로 읽음
도달가능 97.7%       → ~15%       자리표시자를 컨택으로 셈. 그 문장을 028 헤더에 쓴 게 저입니다
엉뚱한 등급 56       → ≥306
"수십 개로 접힘"      → 612 브랜드
"링크는 몇 개뿐"      → 109        제 파일 주석에 예측을 써놨습니다
"SMI NewQuest 없음" → active로 있었음
"다른 머신 같다"      → 아니었음     git status 목록으로 머신을 추론
"운영사 6곳"         → 1곳         SMI는 이미 공장 행 60개
Gulshan 가설 3개     → 3개 다 빔   (단 가설로 명시 — 프로세스가 돈 것)
```
**전부 이미 있던 데이터로 확인 가능했고, 확인 전에 단언했습니다. 대부분 일이 쉬워 보이는 방향입니다.**

**기타**: `t.category` 42703(`paper_types`를 `party_types`로 오독 — id 타입만 봤어도 잡힘) · `filler_use_intensity ~* 'high'`(본 적 없는 어휘로 필터) · **verify를 전부 주석으로**(`Success. No rows returned` 3회) · **스캔 블록 순서 거꾸로**(통째 실행 시 마지막만 보임 → Artemyn 크로스매치가 두 번 안 보임)

**살린 규칙**: 추측 URL 안 씀 · `max_length` 안 지어냄 · 스니펫으로 이메일 안 넣음(SPB `mdoff@`, Trident) · 이웃 인박스 안 붙임(Andhra) · 공장에 폼 행 안 만듦 · 마케팅 9명(TNPL)·실명 13명(Domtar) 안 넣음 · `Supplier Diversity` 안 씀 · **`product_grade` 안 채움** · **상인 공급을 satellite로 승격 안 함**(Gulshan)

### 🆕 오늘 확정된 규칙 넷
> **① fix 파일의 마지막 문장은 주석이 아닌 `select`.** `Success. No rows returned`가 구조적으로 불가능해집니다.
> **② 스캔 파일의 마지막 블록은 질문.** 통째 실행 시 마지막 result set만 보입니다.
> **③ 문자열 안 SQL 키워드 금지는 장식이 아닙니다.** DNC가 그것 때문에 하루 종일 안 먹었습니다.
> **④ 쿼리가 무엇을 결정할지는 쓰되, 무엇을 말할지는 쓰지 않는다.**

---

## 7. [PENDING] — 순서가 오늘 바뀌었습니다

### 🔴 1순위 · 인도 로스터 구멍 — 폼 스윕이 아닙니다
```
Magnum Papers Ltd.            없음   Gulshan 첫 온사이트, Limca 2010
Silvertone Pulp & Paper Mill  없음   Muzaffarnagar UP 2013, Gulshan이 전체 이름 명시
Trident Limited               없음   Barnala 밀짚 제지, 인도 대형사
```
**인도 이름 넷을 찔러 셋이 없습니다.** 888행 중 인도 22행인데 Trident가 없습니다.
**인도는 이틀간 잰 모든 지표에서 1위입니다** — 어제 필러 4/7 STRONG, 오늘 등급 적합 6/6. **그런데 로스터에 그 회사들이 없습니다.**
→ 인도 제지사 이름을 더 찔러보고, 없는 것부터 채우세요. **홈페이지 스윕보다 훨씬 쌉니다.**

### 2순위 · satellite 짝 확인 한 건 (사람 일)
**Sappi Somerset** 또는 **Domtar Marlboro**. 둘 다 US·high·운영사가 파트너 접근 환영.
**확인된 짝 하나가 나머지 아홉을 합친 것보다 값집니다** — 입지 추론이 명명된 구성이 됩니다.

### 3순위 · 제지사 답변 세트 + 게이트
`filler_safe`는 반대 방향 범주 오류(필러사=경쟁자, 제지사=고객). **단 반론이 약하지 않습니다**: **한국제지 피칭 = Omya 도달. 한솔 장항 = 태경BK 도달.** 톤이 아니라 **게이트**가 필요합니다.

### 4순위 · `max_length` 32개 (브라우저 필요)
서버 fetch로 5전 5패 — `maxlength`는 서버 응답에 없습니다. **모델을 바꿔도 안 됩니다.** 캡차 소급 확인(Andhra·한솔)도 같은 문제.

### 5순위 · Artemyn 미매칭 9곳
```
Capitan Bermudez AR · Limeira BR · Pirai BR · Amritsar IN
Bhigwan IN · Silvassa IN · Miyagi JP · Tunadal SE · Kaohsiung TW
```
`name_hits_any_country = 0` 전부. **1순위와 같은 병입니다** — 로스터 구멍이거나 satellite 아닌 상인 사이트.

### 결정 대기 (사람)
```
Andhra ↔ WCPM 병합 (사무소 6곳·전화 2개 일치)
BILT ×2 병합 (Sewa는 BGPPL 법인)
Artemyn 링크 중복 — Sappi(Europe)/Metsä Board 회사행(C) vs 신규 공장행
KC/IP 56행 철회 여부 — 306의 일부
TNPL `Institutes` vs `Potential Supplier` · Sylvamo `Other` vs `Sustainability`
migration_028 헤더의 97.7% 정정
```

### 안 연 문
```
ITC Bhadrachalam        인도 7번째 메이저. 248 목록에 없어 한 번도 안 열었음
SPB mdoff@ (사장실)      locations 페이지. 스니펫이라 안 넣음
Gulshan Trident(2026.3) 뉴스 애그리게이터. gulshanindia.com에 없음
Sylvamo/Domtar sales-and-purchase-policies · WCPM rd-qc·tender·management-team
```

### 마지막 · 폼 스윕 재개
```
CN 8 high · US 4 · TH 3 · DE 3 · FR 3
스킵    SE 15 · GB 12 · IT 9 (등급 다 매겨졌고 high 0) + high 0인 29개국 = 90곳
별건    332행(45%) 웹사이트 없음 → 스윕 불가 · 89곳 등급 링크 · 135곳 필러 링크 누락
```
**오늘 요청받은 작업이 마지막입니다. 그 이유는 데이터에 있습니다.**

---

## 8. 파일 이동 + 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
Get-ChildItem sql\*2026-07-17*.sql | Measure-Object | Select-Object -ExpandProperty Count
git status --porcelain
git add sql/ docs/handoff/2026-07-17/
git commit -m "Gulshan: named hosts not inferred towns. 2 active links - Orient Paper Amlai (high) and ITC Tribeni (medium, district vs town). The 6-operator job was 1: only Artemyn had a footprint array, SMI already has ~60 plant rows. 3 roster holes found by probing 4 Indian names - Magnum, Silvertone, Trident all absent from 888. Handoff reordered: India roster holes are priority 1, the form sweep is last"
git push origin marinebiogroup
```
> **개수 49.** 핸드오프는 같은 파일명이라 덮어써집니다 — **의도입니다.**

---

## 9. 결론

> **정보는 없던 게 아니라 가져오지 않은 것이었습니다.** — 어제 필러 핸드오프의 마지막 줄. 오늘 그게 **우리 자신에게** 적용됐습니다.

- **홈페이지 아홉 곳을 열었고, 아홉 곳 전부 이미 짝지어져 있었습니다**
- **Artemyn 지도는 어제부터 `extra_data` 안에 있었습니다.** 조인 하나 = 짝 여덟 개, 홈페이지 0장
- **Gulshan은 호스트를 이름으로 말합니다.** 페이지 한 장 = 오늘 가장 강한 짝
- **DNC는 문자열 안 `where` 두 개 때문에 하루 종일 안 먹었습니다.** Kleannara를 막은 건 **"한국 제외"** 였습니다
- **bilt.com** — 인도 최상급 표적 2곳이 **뉴욕 핀테크**를 가리켰습니다
- **82%** — FCC가 겨냥하는 짝을 FiberLean·FulFill 보유자가 쥐고 있습니다
- **인도 이름 넷 중 셋이 로스터에 없습니다.** 가장 좋은 나라의 회사들이 없습니다

> **어제는 스물여섯 번 중 스물여섯 번, 회사 페이지가 DB를 이겼습니다.**
> **오늘은 DB가 회사 페이지 아홉 장을 이겼고, 그다음 회사 페이지 한 장이 DB의 구멍 셋을 찾았습니다.**
> **어느 쪽도 조회하지 않아서 몰랐을 뿐입니다.**
