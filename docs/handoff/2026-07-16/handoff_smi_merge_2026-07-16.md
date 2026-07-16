# Handoff — 자동화가 중복 행을 먹고 파이프라인 숫자를 만들었습니다 (2026-07-16, 15차)

## 1. 타임스탬프가 사건을 그대로 보여줍니다

2026-07-02, **16분 사이**:

| 시각 | party | source | stage |
|---|---|---|---|
| **19:56:23** | **Specialty Minerals (HQ)** | **`manual`** | **42316f1f** |
| 20:04:07 | Minerals Technologies Inc. | `entity_enrollment` | 5e8737cc |
| 20:12:22 | SMI (USA - Regional HQ) | `entity_enrollment` | 5e8737cc |
| 20:12:22 | Specialty Minerals Inc. | `entity_enrollment` | 5e8737cc |

**19:56에 사람이 손으로 딜을 하나 만들고 스테이지를 진전시켰습니다.** 그리고 **`entity_enrollment` 자동화가 조건에 맞는 party 행마다 딜을 찍었습니다** — 그중 셋이 같은 회사인 줄 모른 채로.

**이건 딜 4개짜리 이야기가 아닙니다.**

> **중복 행을 파이프라인 숫자로 변환하는 프로세스**가 돌고 있습니다.

오늘 찾은 중복 전부 — Omya Korea, 태경비케이, 태경산업, Specialty Minerals Inc. — 가 같은 처리의 후보였습니다. 캠페인 `e0000000-...-0000000e`가 SMI 너머로 얼마나 부풀어 있는지 모릅니다.

### 한 가지 운이 좋았습니다

MTI·SMI Inc.·Regional HQ는 **컨택이 0명**입니다. 그래서 메일이 물리적으로 못 나갔습니다.

**Omya (Korea)는 그렇지 않습니다** — `jaehoon.cho@omya.com`이 있습니다.
**그리고 Saica는 오늘 오후까지 경쟁사 인박스를 달고 있었습니다.**

## 2. `fix_smi_mti_merge_2026-07-16.sql` → `sql\`

딜 4개 전부 `value_amount` null, `extra_data` `{}`, **`last_activity_at` = `created_at`** — 수동 딜 포함 **아무것도 진행된 게 없습니다.** 그래서 유령 3개를 지워도 잃는 작업이 없습니다.

**전부 soft delete입니다.** `deleted_at` 지우면 복구됩니다.

| | 행 | 처리 |
|---|---|---|
| **KEEP** | `9f161ff5` **Specialty Minerals (HQ)** | 컨택 3(Sharad Mathur) + comms 36 + engagements 27 + SEC 8-K supply link + 수동 딜. **진짜 관계** |
| **REMOVE** | `cd3dbf9e` Specialty Minerals Inc. | gap 파일이 베이스 위에 얹은 중복. 유령 딜 외엔 아무것도 없음 |
| **KEEP (딜만 제거)** | `5ba57cb3` Minerals Technologies Inc. | **진짜 별개 법인** — NYSE 모회사(MTX). 행은 유지. **딜은 제거** — FCC 라이선스는 자회사 SMI가 서명하지 지주사가 하지 않습니다. 둘 다 두면 이중 계산 |
| **FLAG** | `fa423be1` SMI (USA - Regional HQ) | **건드리지 않았습니다** (유령 딜만 제거) |

### `fa423be1`을 안 건드린 이유

**keeper와 이 행은 둘 다 베이스 로스터(`industry.v11_4`)에서 왔습니다.** 즉 로스터 자체가 글로벌 HQ와 리전 HQ를 **의도적으로 따로** 모델링합니다 — `Specialty Minerals (Japan)`과 `Specialty Minerals FMT (Japan - Shiraoi)`를 나눈 것과 같은 방식입니다.

**저는 그 모델을 모릅니다. 추측 안 하겠습니다.**

- **병합 반대**: 로스터 분리가 의도적이고 다른 나라도 같은 형태일 수 있음
- **병합 찬성**: keeper가 이미 Bethlehem PA인데 그게 **바로 SMI Americas HQ**입니다. 두 행이 같은 사무실을 가리킴

**여기 로스터 형태가 임의적이라고 말씀해 주시면 접겠습니다.**

## 3. `scan_entity_enrollment_2026-07-16.sql` → `sql\` — 진짜 질문

**READ-ONLY.**

| 블록 | 내용 |
|---|---|
| 1 | **FCC Licensing 캠페인 규모** — source별 딜 수, 그중 생성 후 한 번도 안 건드려진 수 |
| 2 | **유령 딜의 일반형** — 컨택 0 + 커뮤니케이션 0인 party에 붙은 딜 전수. **길게 나오면 파이프라인 숫자가 허구입니다** |
| 3 | **같은 자동화가 이메일 시퀀스도 enroll했나** — 딜은 컨택 없으면 무해합니다. **시퀀스는 아닙니다** |
| 4 | 아직 남아 있는 이중 계산 — 같은 도메인·같은 국가에 둘 다 열린 딜 |
| 5 | **정직한 파이프라인 숫자** — filler 딜을 "연락할 사람이 있는가"로 쪼갬 |

### 블록 5가 아플 겁니다

컨택이 있는 filler는 **4곳뿐**입니다 (MLC 13 · SMI HQ 3 · Omya HQ 1 · Omya Korea 1). 나머지 딜은 전부 **"연락할 사람 없음"** 버킷에 들어갑니다.

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
  @{ Pattern = 'fix_smi_mti_merge_2026-07-16*.sql';        Dest = (Join-Path $repo 'sql'); Name = 'fix_smi_mti_merge_2026-07-16.sql' },
  @{ Pattern = 'scan_entity_enrollment_2026-07-16*.sql';   Dest = (Join-Path $repo 'sql'); Name = 'scan_entity_enrollment_2026-07-16.sql' },
  @{ Pattern = 'handoff_smi_merge_2026-07-16*.md';         Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_smi_merge_2026-07-16.md' }
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

1. `fix_smi_mti_merge` **블록 0 (pre-flight)** → 딜 4행, `deleted_at` 전부 null 확인
2. 블록 1~5 실행 → 블록 6 검증: **SMI (HQ) live deal 1, MTI 0, Regional HQ 0, SMI Inc. party_live false**
3. `scan_entity_enrollment` **블록 1·2** → 결과 보내주세요. **캠페인 전체가 부풀어 있는지가 여기서 나옵니다**

**마무리**

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_smi_mti_merge_2026-07-16.sql sql/scan_entity_enrollment_2026-07-16.sql docs/handoff/2026-07-16/handoff_smi_merge_2026-07-16.md
git commit -m "fix: SMI/MTI merge - entity_enrollment stamped FCC deals onto 3 duplicate rows 16min after 1 manual deal; phantoms + duplicate party soft-deleted, MTI kept as parent without a deal, Regional HQ flagged for decision; scan: is the whole FCC campaign inflated by duplicates"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 5. 오늘 하루가 이어집니다

아침에 **"KR filler가 0건"**이라고 잘못 말한 데서 시작했습니다. 그 오해가 seed를 낳았고, seed가 중복 3개를 낳았습니다.

그리고 지금 알게 된 건, **중복이 조용히 앉아 있지 않는다**는 겁니다:

```
중복 행  →  entity_enrollment  →  유령 딜  →  파이프라인 숫자
중복 행  →  (컨택이 있었다면)  →  시퀀스 enroll  →  같은 사람에게 두 번 발송
잘못된 연결  →  (Saica)      →  경쟁사가 우리 제안을 읽음
```

**데이터 오류가 데이터에 머물지 않습니다.** 자동화가 그걸 먹고 행동으로 바꿉니다.

제가 오늘 만든 중복 3개가 그래서 단순 실수가 아니었습니다. Omya Korea에는 컨택이 있습니다.

## 6. 남은 것

- **`scan_entity_enrollment` 블록 1·2** — 캠페인이 얼마나 부풀었나
- **`fa423be1` 판단** — 로스터의 HQ/Regional HQ 분리가 의도적인가
- **`v_email_do_not_send` 정의** — 제네릭 인박스 제외 + email 기준 중복 제거 패치용
