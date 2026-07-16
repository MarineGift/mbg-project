# Handoff — MLC 회사정보 수정 + 말레이시아 검증 (2026-07-16, 4차)

## 0. MLC 원인 — 제 가드 버그입니다

**contacts 13건과 website(mlc.com)는 정상 반영됐습니다.** 보내주신 파이프라인 export에서 확인했습니다. **intro(회사소개)만 안 바뀐 게 맞습니다.**

원인: `enrich_mlc_us_filler_2026-07-16.sql`의 intro UPDATE에 **`and p.intro_ko is null`** 가드를 걸었는데, MLC는 이미 `20260620190000_..._enrich_batch13.sql`에서 intro가 들어가 있었습니다. → **조용히 스킵.** 에러도 안 났습니다.

일본 파일에도 같은 가드를 썼습니다. 奥多摩·白石·丸尾·備北 4곳은 batch12/13 대상이 아니었으니 통과했을 겁니다. 다만 **검증 쿼리에서 `has_ko = true`가 5행 모두 나오는지 꼭 확인**해 주세요. 하나라도 false면 같은 이유입니다 — 알려주시면 강제 덮어쓰기 버전을 드리겠습니다.

**이후 모든 파일에서 이 가드를 뺐습니다.** 이번 두 파일은 무조건 덮어씁니다.

---

## 1. `fix_mlc_positioning_2026-07-16.sql` → `sql\`

1. **intro_ko/intro_en 강제 덮어쓰기** (가드 없음)
2. **기존 값을 notes에 보존** (롤백용): `supply_model="Merchant PCC + possible satellite"`, `market_role="Multi-state US (paper market explicit)"`, `evidence_level="B"`
3. **포지셔닝 반영**:
   - `supply_model` → `merchant GCC (PCC exited)`
   - `market_role` → `US lime leader - GCC merchant + PCC upstream (quicklime), PCC discontinued`
   - `onsite_pcc_evidence` → WITHDRAWN 표기

지난번엔 사람 판단이 필요하다고 보고 flag만 남겼는데, 이번에 판단을 주신 걸로 보고 반영했습니다. 근거는 **자사 웹폼 2곳의 명시적 문구**(샘플 요청 / 컴플라이언스 문서 요청)입니다 — stale한 markets/paper 페이지 1곳보다 우선한다고 봤습니다.

> **다만 여전히 MLC 사람에게 확인받은 건 아닙니다.** Dan Menniti(dtmenniti@mlc.com) 또는 Bill Wleklinski(wjwleklinski@mlc.com)에게 확인하시면 좋겠습니다. 롤백 SQL을 파일 하단에 넣어뒀습니다.

**한 가지 살려둔 각도**: MLC는 FCC 라이선싱 타깃으로는 우선순위가 낮아졌지만, **생석회·소석회는 PCC 제조의 필수 원료**입니다. `market_role`에 `PCC upstream (quicklime)`를 남겨 밸류체인 upstream 공급자로서의 가치는 유지했습니다. CSV를 보니 `Carmeuse USA`도 같은 취급(`Quicklime for PCC; PCC enabler`)이라 일관됩니다.

---

## 2. `enrich_my_filler_homepage_2026-07-16.sql` → `sql\`

### 🎯 발견 1 — Calrock은 독립 업체가 아닙니다. Zantat의 자매회사입니다

DB의 Calrock 평가는 **"Potential local supplier candidate only / Paper-grade: needs verification"** — 정체 불명 상태였습니다.

`zantat.com.my/production-plants.php` 원문:

> Three of which are strategically located in Ipoh, Perak, under Zantat Sdn Bhd and **its sister company, Calrock Sdn Bhd**, with a significant vast built up area of more than 220,000 sq.ft. and **48,305 sq.ft.** respectively.

→ **Calrock = Zantat 그룹 이포 3개 공장 중 하나.** 독립 사업자로 스코어링하면 안 됩니다. 접촉도 Calrock 단독이 아니라 Zantat 그룹 창구로 가야 합니다. 이 열린 플래그를 닫았습니다.

### 🎯 발견 2 — Zantat은 이제 상장사입니다

**Zantat Holdings Berhad, 부르사 ACE 마켓 2024년 3월 상장** (코드 **0301 / ZANTAT**, 공모가 RM0.25, 조달 약 RM1,820만). DB엔 이 정보가 없습니다.

→ **공개 재무·프로스펙터스가 있다**는 뜻이라, "family-owned 로컬 업체" 전제로 접근하던 것과 실사 난이도가 완전히 다릅니다.

- FY2024 매출 **RM1억190만** (전년 RM1억2,280만 대비 **-17.0%**), 순이익 RM45.4만 (**-93.3%**), 직원 약 216명
- 세그먼트: Production / **Bioplastic** / Others

### 🎯 발견 3 — 능력 수치가 낡았습니다

여기저기 인용되는 **6만 t/년 + Simpang Pulai 채석장**은 **옛 수치**입니다. 자사 공장 페이지 기준:

- 공장 4곳: 이포(페락) 3곳 + 케퐁(KL) 1곳
- 2011년 신공장이 **플라스틱·도료·제지용** CaCO3 분말 특화, 2014년 2차·2017년 3차 증설 → **합산 32만 MT**
- 석회석 광구 2곳, 채굴권 **2068년·2070년**까지, 25에이커, 추정 매장량 **약 2,200만 톤**
- 제품: GCC, CaCO3 디스퍼전, **카올린 디스퍼전**, **초미립 PCC 분말 가공**, 바이오플라스틱 컴파운드
- 2002년 라텍스 장갑용 CaCO3 디스퍼전 국내 최초 도입 → 그 유산이 지금도 주력

### ⚠️ 발견 4 — Zantat도 MLC와 같은 패턴입니다

DB 노트는 **"Paper-grade: YES (explicit). top Malaysian domestic GCC supplier for paper"** 입니다.

그런데 **상장 법인 기준 현행 사업 설명**은 전방시장을 이렇게 씁니다:

> plastics, paints and coatings, **glove production**, and rubber manufacturing

**제지가 없습니다.** 자사 공장 페이지엔 제지가 있지만 그 페이지가 오래된 쪽입니다. **MLC와 똑같은 구조** — 마케팅 페이지는 옛 포지션, 현행 공시는 다른 얘기.

→ 이번엔 **`market_role`을 제지 중심으로 쓰지 않았습니다.** `MY top-3 CaCO3 producer (Bursa ACE listed) - GCC + dispersions`로 두고, 제지 비중 확인을 VERIFY로 남겼습니다. 장갑·플라스틱이 주력이라면 FCC 우선순위가 내려갑니다.

### 아직 못 닫은 MY 플래그

솔직히 말씀드리면 이번엔 **Zantat + Calrock 2건만** 검증했습니다. 나머지는 열려 있습니다:

| 회사 | uuid | 현재 플래그 |
|---|---|---|
| Uniko Calcium Carbonate Industry | `331739e4` | "paper linkage needs verification" |
| Kaolin (Malaysia) Sdn Bhd | `dae6be28` | "less paper-explicit than Omya/Zantat" |
| Shiraishi Calcium Malaysia | `f55d50a2` | "unverified paper-market role" |
| Omya (Malaysia) | `fbca4410` | Volza 기준 **MY 최대 CaCO3 수출사 (45%, 1,180 shipments)** — 실은 여기가 MY 1순위일 가능성 |
| Specialty Minerals (Malaysia) | `98daf450` | "Theoretical only; no Malaysia commercial entity" |
| Specialty Minerals (Malaysia - Sipitang) | `52f22cbe` | 사바 — SFI 제지공장 온사이트 가능성 |

**힌트 하나**: Zantat이 **카올린 디스퍼전**을 한다는 게 확인됐으니, `Kaolin (Malaysia) Sdn Bhd`와의 관계도 볼 여지가 있습니다.

---

## 3. 파일 이동

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'fix_mlc_positioning_2026-07-16*.sql';        Dest = (Join-Path $repo 'sql'); Name = 'fix_mlc_positioning_2026-07-16.sql' },
  @{ Pattern = 'enrich_my_filler_homepage_2026-07-16*.sql';  Dest = (Join-Path $repo 'sql'); Name = 'enrich_my_filler_homepage_2026-07-16.sql' },
  @{ Pattern = 'handoff_mlc_fix_my_filler_2026-07-16*.md';   Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_mlc_fix_my_filler_2026-07-16.md' }
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

## 4. 실행

1. `fix_mlc_positioning_2026-07-16.sql` 실행 → 검증 쿼리로 `supply_model = 'merchant GCC (PCC exited)'`, intro가 "1907년"으로 시작하는지 확인. **URM 화면에서 MLC 회사소개가 바뀌었는지 눈으로 확인.**
2. `enrich_my_filler_homepage_2026-07-16.sql` 실행 → 2행 intro 확인.
3. **일본 파일 검증 쿼리도 한 번 돌려주세요** — `has_ko`가 5행 모두 true인지. false면 같은 가드 버그입니다.
4. 파일 하단 **FULL MY PICTURE 쿼리** 결과를 보내주시면 나머지 6개 MY 플래그를 정리하겠습니다.

## 5. 마무리 (commit + push)

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_mlc_positioning_2026-07-16.sql sql/enrich_my_filler_homepage_2026-07-16.sql docs/handoff/2026-07-16/handoff_mlc_fix_my_filler_2026-07-16.md
git commit -m "fix: MLC intro force-overwrite (null-guard bug) + PCC-exit positioning applied; enrich: MY fillers verified (Calrock = Zantat sister co, Zantat Holdings Bursa ACE listed, capacity 320k MT not 60k)"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 6. 반복 패턴 하나 — 짚고 갑니다

MLC, Zantat, 白石 — **세 건 모두 같은 구조**였습니다.

> DB에 저장된 포지셔닝은 **회사의 옛 마케팅 문구**에서 왔고, **현행 공시/거래 폼**을 보면 다른 얘기를 한다.

`filler_supplier_profile`의 제지 적합성 평가 상당수가 이 위험을 안고 있을 수 있습니다. 특히 `evidence_level='C'`(= merchant 추정)로 깔린 행들이 그렇습니다.

제안: 다음 배치에서 **"paper-grade: YES"로 기록된 행 중 근거가 자사 마케팅 페이지뿐인 것**을 뽑아 현행 공시 기준으로 재검증하는 스윕을 한 번 돌리는 게 좋겠습니다. FCC 타깃 랭킹의 신뢰도가 여기 걸려 있습니다.
