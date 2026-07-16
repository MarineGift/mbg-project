# Handoff — US Tier 1: 두 가지 다른 종류의 오류 (2026-07-16, 8차)

## 0. 블록 2는 더 안 조르겠습니다

US 파이프라인 export에 `evidence_level`·`supply_model`·`market_role`·`contacts`가 다 있습니다. **이게 곧 US Tier 1 리스트입니다.** 블록 2 없이 진행했습니다.

US filler **30행**을 분해하면:

| 구분 | 수 | 처리 |
|---|---|---|
| SMI 개별 공장 행 | **19** | **컨택 대상 아님.** satellite 근거 데이터로 유지 (13곳이 on-site, 6곳 merchant) |
| 기업 단위 행 | **11** | 실제 검토 대상 |

지난번에 예상한 대로 **11행**으로 줄었습니다.

---

## 1. 🔴 발견 A — Thiele: 주장은 참인데 무관합니다

MLC·Zantat·白石은 **주장이 낡은** 케이스였습니다. Thiele은 **다른 종류**입니다.

**Thiele의 제지 주장은 사실입니다.** 75년간 미국 도공지 시장에 공급했고, 자사 사이트가 "industry leader in innovative products for paper and packaging"라고 하고, 샌더스빌에 **전용 제지 코팅 연구소**까지 있습니다. 북미 최대 확정 카올린 매장량. 전부 진짜입니다.

**문제는 정확성이 아니라 관련성입니다.**

> **Thiele은 카올린 회사입니다. PCC도 GCC도 없습니다.**
> **FCC는 Flexible Calcium Carbonate입니다.**

**FCC가 들어갈 탄산칼슘 공정이 아예 없습니다.** 라이선싱 대상이 될 수 없습니다. mbg가 노리는 CaCO3 필러의 **대체광물 경쟁자**입니다.

### 이게 테이블 전체의 문제를 드러냅니다

`evidence_level = A`는 **"제지에 공급하는가"**에 대한 답입니다. **"FCC 타깃으로 좋은가"**에 대한 답이 아닙니다. **두 질문이 이 테이블 전체에서 뒤섞여 있습니다.** Thiele은 전자에 A, 후자엔 해당 없음입니다.

그래서 `extra_data`에 두 질문을 **분리**해서 넣었습니다:

```json
{"paper_grade": {"claim":"yes", "source_type":"marketing", ...},
 "fcc_fit":     {"verdict":"no", "reason":"kaolin only - no PCC or GCC process for FCC to enter", ...}}
```

**보너스**: `market_role`이 문자 그대로 `"Sandersville, GA"`였습니다. **주소지, 역할이 아닙니다.** 교체했습니다.

**컨택**: MLC와 달리 **담당자를 홈페이지에 공개하지 않습니다.** 문의 폼 + 대표번호(+1 478-552-3951 / 877-544-3322)뿐입니다. MLC처럼 13명 뽑는 배치는 안 나옵니다.

### 같은 질문을 받아야 할 다른 행

- `Imerys USA` (39aeaeff) — `"Merchant (carbonate + kaolin coating)"` → **carbonate가 명시**돼 있어 다른 케이스. 타깃 유지
- `Huber Engineered Materials` (ce77920a) — `"Specialty minerals (kaolin, PCC)"` → **PCC 명시**. 타깃 유지
- `Kaolin (Malaysia) Sdn Bhd` (dae6be28) — 카올린 전업 → **같은 `fcc_fit: no` 가능성**. 다음 배치

---

## 2. 🔴 발견 B — SMI/MTI: 같은 회사가 4행, evidence가 A·B·C 동시

```
5ba57cb3  Minerals Technologies Inc.              NY      | C | merchant           | c=0
cd3dbf9e  Specialty Minerals Inc.                 NY      | C | merchant           | c=0
9f161ff5  Specialty Minerals (HQ)                 Bethlehem PA | A | On-site satellite PCC plants | c=3
fa423be1  Specialty Minerals (USA - Regional HQ)  null    | B | Satellite + merchant | c=0
```

`Minerals Technologies Inc.`는 NYSE 모회사(MTX), `Specialty Minerals Inc.`는 그 자회사입니다. **모회사 행 + SMI 행은 정당합니다.**

그런데 **`Specialty Minerals Inc.` / `Specialty Minerals (HQ)` / `Specialty Minerals (USA - Regional HQ)` 셋은 같은 회사일 가능성이 큽니다.** 그런데:

- **evidence가 A, B, C 세 개 동시**
- **supply_model이 서로 모순** (merchant vs satellite vs 둘 다)

### 원인은 제 Omya Korea 사고와 **똑같습니다**

gap 파일이 `Specialty Minerals (HQ)`가 이미 있는데 `Specialty Minerals Inc.`를 INSERT했습니다. **NOT EXISTS 가드가 party_name 완전일치**라 두 문자열이 달라서 안 부딪혔습니다.

그 파일 헤더에는 이렇게 적혀 있습니다:

> Note: 'Specialty Minerals Inc.' is distinct from existing 'Double A Specialty Minerals'

**엉뚱한 이웃을 확인한 겁니다.** 제가 `Omya (Korea)`를 안 보고 `Omya Korea Inc.`를 넣은 것과 같은 구조입니다.

### 이게 왜 제일 중요한가

**SMI는 이 파이프라인에서 가장 중요한 회사입니다.** 글로벌 satellite PCC 운영사이고, **FCC가 밀어내야 할 직접 인커번트**입니다.

그 회사의 evidence가 지금 **A이자 B이자 C**입니다. 랭킹 쿼리가 어느 행을 잡느냐에 따라 답이 달라집니다.

`scan_us_smi_mti_structure_2026-07-16.sql`이 이걸 진단합니다. **READ-ONLY**입니다 — 이번엔 조회 결과 없이 병합 파일을 만들지 않겠습니다. (그 규칙을 어겨서 세 번 틀렸습니다.)

| 블록 | 내용 |
|---|---|
| 1 | 4행 나란히 비교 |
| 2 | **FK 부착 현황** — 어느 행을 지울 수 있는지 결정. HQ에 contacts 3이라 keeper 후보 |
| 3 | HQ의 담당자 3명 정체 |
| 4 | **mineralstech.com 전 국가** — 기업 단위 행 vs 공장 행 분리. CN·IN에도 같은 문제가 있는지 |
| 5 | **일반형** — gap 파일이 기존 행 위에 덮어쓴 모든 케이스. Omya Korea와 SMI Inc.의 공통 형태를 쿼리로 |

---

## 3. US 기업 단위 11행 현황

| evidence | 회사 | c | 상태 |
|---|---|---|---|
| **A** | Omya (USA) | 0 | ⚠️ **미조사.** "Merchant + onsite/satellite (recent)" — US 실질 1순위 후보인데 아무 근거 없음 |
| **A** | Specialty Minerals (HQ) | 3 | ⚠️ 4행 구조 문제의 keeper 후보 |
| **A** | Thiele Kaolin | 0 | ✅ **이번에 처리** — fcc_fit=no |
| B | Mississippi Lime (MLC) | 13 | ✅ 처리 완료 (PCC 철수) |
| B | Imerys USA | 0 | carbonate 명시 → 타깃 유지, 미조사 |
| B | Carmeuse USA | 0 | upstream(생석회). MLC와 같은 취급이라 일관됨 |
| B | IMI Fabi | 0 | 미조사 (탈크 계열) |
| B | SMI (USA - Regional HQ) | 0 | 4행 구조 문제 |
| C | Huber Engineered Materials | 0 | PCC 명시 → 타깃 유지, 미조사 |
| C | Minerals Technologies Inc. | 0 | 모회사 행 |
| C | Specialty Minerals Inc. | 0 | 4행 구조 문제 |

**다음 우선순위는 `Omya (USA)`입니다.** evidence A인데 contacts 0, 조사 전무. 한국에서 오미아코리아가 1순위로 나왔고 GMC가 "외국계 80%"라고 증언한 그 오미아입니다. US에서도 같은 위치일 가능성이 높습니다.

---

## 4. 이동 · 실행 · 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'enrich_thiele_kaolin_2026-07-16*.sql';        Dest = (Join-Path $repo 'sql'); Name = 'enrich_thiele_kaolin_2026-07-16.sql' },
  @{ Pattern = 'scan_us_smi_mti_structure_2026-07-16*.sql';   Dest = (Join-Path $repo 'sql'); Name = 'scan_us_smi_mti_structure_2026-07-16.sql' },
  @{ Pattern = 'handoff_us_tier1_2026-07-16*.md';             Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_us_tier1_2026-07-16.md' }
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

**실행**

1. `enrich_thiele_kaolin` 전체 실행 (3개 문) → 검증 쿼리로 `mineral_class = kaolin`, `fcc_fit = no` 확인
2. `scan_us_smi_mti_structure` **블록 1·2·3** 실행 → **결과 보내주세요.** 그걸 받아야 병합 파일을 만듭니다
3. 여유 되면 블록 4·5도 — 다른 나라에 같은 4행 문제가 있는지

**마무리**

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/enrich_thiele_kaolin_2026-07-16.sql sql/scan_us_smi_mti_structure_2026-07-16.sql docs/handoff/2026-07-16/handoff_us_tier1_2026-07-16.md
git commit -m "enrich: Thiele Kaolin - paper claim true but fcc_fit=no (kaolin, no CaCO3 line); scan: SMI/MTI 4-row structural dupe (evidence A/B/C on one company)"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 5. 오늘 정리된 오류의 종류 — 네 가지입니다

| 종류 | 사례 | 문제 |
|---|---|---|
| **낡은 마케팅** | MLC, Zantat, 白石 | 주장이 옛 페이지에서 옴. 현행 공시는 다른 얘기 |
| **관련성 혼동** | **Thiele** | 주장은 참인데 FCC와 무관. "제지 공급"과 "FCC 타깃"을 한 필드로 답함 |
| **구조적 중복** | **SMI/MTI**, Omya Korea, Taekyung ×2 | 이름 완전일치 가드 실패 → 같은 회사 여러 행, evidence 모순 |
| **평가 누락** | 奥多摩 등 JP top 5 | website만 받고 모든 배치에서 스킵. 에러 없음 |

**네 가지 다 랭킹을 망가뜨리는데 원인이 전부 다릅니다.** `extra_data`의 `paper_grade` + `fcc_fit` 분리가 앞의 두 개를 잡고, 도메인+이름 스캔이 세 번째를, 블록 4(never assessed)가 네 번째를 잡습니다.

## 6. 아직 안 받은 것

- **일본 `has_ko` 5행 확인** — MLC와 같은 null 가드 버그 여부. 네 번째 요청이라 이번이 마지막입니다. 안 주시면 그냥 강제 덮어쓰기 파일을 만들어 드리겠습니다 (덮어써서 손해 볼 게 없습니다)
