# Handoff — 이름 없는 컨택 (2026-07-16, 10차)

## 0. `enrich_smi_contacts` 확인됨 ✅

두 CSV의 시간차가 증명합니다:

| 시각 | Specialty Minerals (HQ) |
|---|---|
| **15:20:22** | `3` bare contacts ← 실행 전 |
| **15:21:47** | **목록에서 사라짐** ← 실행 후 |

대신 `Södra Mörrum`이 100행 제한에서 밀려 들어왔습니다. **Sharad Mathur 3명 다 이름이 붙었습니다.**

---

## 1. 🔴 그런데 이 스캔이 훨씬 큰 걸 열었습니다

100행 전부 `bare_contacts = 1`. 그리고 **Limit 100에서 잘렸습니다** — 실제 총계는 모릅니다.

| 유형 | 수 |
|---|---|
| paper_mill (type 2) | **98** |
| **filler_supplier (type 3)** | **2 — `Omya (HQ)`, `Omya (Korea)`** |

### `Omya (Korea)`입니다

한국 **FCC 1순위 타깃**입니다. 공정위 의결 2019-109으로 확정됐고, GMC가 "외국계가 내수 80%"라고 증언한 그 회사입니다.

**그런데 유일한 컨택이 이름 없는 이메일 한 줄입니다.**

Sharad Mathur가 3개월 넘게 그렇게 앉아 있었던 것과 **똑같은 상태**입니다. 파이프라인 1순위 두 개(KR 1순위 Omya Korea, US 인커번트 SMI)가 **둘 다** 같은 이유로 못 쓰는 상태였습니다.

### 이게 왜 단순 정리 문제가 아닌가

이 프로젝트는 **이메일 시퀀스**를 돌립니다. `full_name`이 없으면 **개인화가 안 됩니다.**

> **이름 없는 컨택은 DB에 있으면서 동시에 사업에는 없습니다.**

98개 제지사도 마찬가지입니다 — UPM 계열 10곳, CMPC 계열 10곳, Norske Skog, Billerud, Södra, Arctic Paper, Altri... 전부 컨택이 1개씩인데 **전부 못 씁니다.**

---

## 2. `scan_bare_contacts_2026-07-16.sql` → `sql\`

**READ-ONLY.** 블록 6개. **따로따로** 실행하세요 (에디터는 첫 에러에서 전체 중단 + 마지막 문 결과만 표시).

| 블록 | 내용 |
|---|---|
| 1 | **진짜 총계** — Limit 없이. party_type별 |
| 2 | **출처** — `inbound_backfill_2026Q2`가 전부인지, 언제 들어왔는지 |
| 3 | **패턴 분류** — 이름을 기계적으로 뽑을 수 있나 |
| 4 | **filler 2행 실제 이메일** — Omya (HQ) / Omya (Korea). 최우선 |
| 5 | **⭐ 유도 미리보기** — 벌크 픽스가 *쓸* 값을 미리 보여줌 |
| 6 | 제네릭 주소 — 다른 처리가 필요한 것들 |

### 블록 5가 핵심입니다

`sharad.mathur@mineralstech.com` → `Sharad Mathur`. **조사 없이 기계적으로 나옵니다.** Ken Mueller도 그렇게 뽑았습니다.

`first.last@` 패턴이면 **웹 검색 한 번 없이 벌크로 채울 수 있습니다.** 블록 5는 **아무것도 쓰지 않고** 무엇을 쓸지만 보여줍니다. 결과 보내주시면 그때 UPDATE 파일을 만들겠습니다.

> **조회 결과 없이 쓰기 파일 안 만듭니다.** 그 규칙 어겨서 오늘 세 번 틀렸습니다.

### 알려진 한계 — 미리 말씀드립니다

`initcap()`은 `mcdonald` → `Mcdonald`, `oconnor` → `Oconnor`가 됩니다. `van.der.berg` 같은 복합 성은 정규식에 아예 안 걸려서 수동 분류로 빠집니다.

**`Mcdonald`가 완벽하진 않지만 `null`보다 낫습니다.** 다만 이건 판단이 필요한 부분이라 여쭙습니다 — 그냥 두는 게 나으면 말씀해 주세요.

### 블록 6은 다른 문제입니다

`info@`, `sales@` 같은 주소에 **사람 이름을 붙이면 안 됩니다.** `General inbox` 같은 라벨을 주거나 `contact_type_id`를 조정해서 시퀀스 파이프라인이 **건너뛰게** 해야 합니다. `Dear null`을 보내는 것보다 안 보내는 게 낫습니다.

---

## 3. 이동 · 실행 · 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'scan_bare_contacts_2026-07-16*.sql';  Dest = (Join-Path $repo 'sql'); Name = 'scan_bare_contacts_2026-07-16.sql' },
  @{ Pattern = 'handoff_bare_contacts_2026-07-16*.md'; Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_bare_contacts_2026-07-16.md' }
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

**실행 — 블록 4와 5를 먼저 보내주세요**

1. **블록 4** — Omya (Korea) 이메일. 가장 빨리 값이 나오는 한 줄
2. **블록 5** — 유도 미리보기. 이게 괜찮으면 벌크 픽스를 만듭니다
3. 블록 1·2·3 — 규모 파악
4. 블록 6 — 제네릭 처리 방향

**마무리**

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/scan_bare_contacts_2026-07-16.sql docs/handoff/2026-07-16/handoff_bare_contacts_2026-07-16.md
git commit -m "scan: bare contacts (100+ parties with 1 nameless email each incl. Omya Korea = KR #1 target); name-derivation preview before any bulk write"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 4. 오늘 발견한 것의 공통점

| 유형 | 사례 |
|---|---|
| 낡은 마케팅 | MLC, Zantat, 白石 |
| 관련성 혼동 | Thiele (`fcc_fit ≠ paper_grade`) |
| 구조적 중복 | SMI/MTI 4행, Omya Korea, Taekyung ×2 |
| 평가 누락 | 奥多摩 등 JP top 5 |
| **접근 불가** | **이름 없는 컨택 100+** |

전부 **"DB에 데이터는 있는데 쓸 수 없다"**는 한 가지 문제의 다른 얼굴입니다. 그리고 다섯 개 다 **조용히** 실패합니다 — 에러가 안 납니다. 그래서 몇 달을 갑니다.

## 5. 아직 안 받은 것 — 두 개뿐입니다

1. **`scan_us_smi_mti_structure` 블록 1·2** — 4행 병합 파일의 전제. 파일은 이제 리포에 있고 컬럼명도 패치됐습니다
2. **일본 `has_ko` 5행** — 다음에 안 주시면 그냥 강제 덮어쓰기 파일을 만들겠습니다. 덮어써서 손해 볼 게 없습니다
