# Handoff — 미리보기가 저를 살렸고, SMI는 생각보다 나쁩니다 (2026-07-16, 13차)

## 1. ✅ 일본 — 완전히 깨끗합니다. 이 스레드 닫습니다

11행 전부 `has_ko` / `has_en` **true**:

奥多摩(Okutama Kogyo) · 白石工業(Shiraishi Kogyo Kaisha) · 白石カルシウム(Shiraishi Calcium) · 丸尾(Maruo Calcium) · 備北(Bihoku Funka Kogyo) · Fimatec · 日鉄鉱業 · 日東粉化 · 東洋電化 · SMI Japan ×2

**null 가드 버그 없었습니다.** 제가 네 번 여쭤본 게 기우였습니다 — 그 5곳은 batch12/13 대상이 아니어서 intro가 비어 있었고, 그래서 가드를 통과했습니다. MLC만 걸린 게 맞습니다.

## 2. 🎯 이름 유도 — 미리 본 게 이번 세션 최고의 결정이었습니다

16행 중 **14행이 틀렸을 겁니다**:

| email | 제가 쓰려던 값 | 실제 |
|---|---|---|
| `geral.celbi@altri.pt` | "**Geral** Celbi" | ❌ 포르투갈어 "일반" |
| `kontakt.sdt@leipa.de` | "**Kontakt** Sdt" | ❌ 독일어 "연락" |
| `info.jkpaper@jkmail.com` | "**Info** Jkpaper" | ❌ |
| `marketing.itcpspd@itc.in` | "**Marketing** Itcpspd" | ❌ |
| `communication.golbey@norskeskog.com` | "**Communication** Golbey" | ❌ |
| `info.saugbrugs@norskeskog.com` | "**Info** Saugbrugs" | ❌ |
| `info.mpe@mitsubishi-paper.com` | "**Info** Mpe" | ❌ |
| **`edgar.habich@omya.com`** | **"Edgar Habich"** | ✅ |
| **`jaehoon.cho@omya.com`** | **"Jaehoon Cho"** | ✅ |

제 정규식 `^[a-z]{2,}\.[a-z]{2,}$`가 **점 찍은 제네릭**을 사람 이름으로 봤습니다. 블록 3의 제네릭 필터는 맨 `info@`만 잡았지 `info.jkpaper@`는 못 잡았습니다.

**벌크로 돌렸으면 실존 제지사 14곳에 "Info Jkpaper"라는 가짜 인물이 생겼습니다.** 그리고 시퀀스가 그 이름으로 메일을 보냈을 겁니다.

> **"조회 결과 없이 쓰기 파일 안 만든다"는 규칙이 오늘 세 번은 틀리게 했고, 한 번은 살렸습니다.**

**벌크 UPDATE는 없습니다.** 진짜 사람 둘만 개별로 처리합니다.

## 3. `fix_omya_contacts_2026-07-16.sql` → `sql\`

- `1aaf22de` **jaehoon.cho@omya.com** → Jaehoon Cho, `is_primary = true`
- `f87eb652` **edgar.habich@omya.com** → Edgar Habich, `is_primary = true`

**직함은 안 넣었습니다.** 두 사람 다 검색해도 동명이인만 나왔습니다. **없는 직함을 지어내는 게 CRM이 거짓말을 시작하는 방식입니다.** `title_text`는 1차 출처가 나올 때까지 null입니다. LinkedIn 확인 후 접촉하세요.

### 🔴 그런데 이 스캔의 진짜 헤드라인은 따로 있습니다

**컨택이 하나라도 있는 filler는 딱 4곳입니다:**

| 회사 | 컨택 |
|---|---|
| Mississippi Lime | **13** |
| Specialty Minerals HQ | 3 |
| Omya (HQ) | 1 |
| Omya (Korea) | 1 |

**전체 filler 파이프라인에 18명.** Thiele·Imerys USA·Huber·IMI Fabi·Carmeuse·태경비케이·태경산업·GMC·Zantat·奥多摩·丸尾·備北·白石 — **전부 0명**입니다.

**그리고 가장 잘 커버된 곳이 사업을 접은 MLC입니다.**

> **이 파이프라인의 병목은 보강이 아니라 컨택 확보입니다.** 오늘 하루 종일 데이터 품질을 고쳤는데, 정작 라이선싱 타깃 대부분에 연락할 사람이 없습니다.

## 4. 🚨 `scan_smi_deals_2026-07-16.sql` → `sql\` — 병합 파일이 아직 아닌 이유

블록 1·2 결과:

| 행 | source | ev | cont | **deal** | comm | engag |
|---|---|---|---|---|---|---|
| **Specialty Minerals (HQ)** | `industry.v11_4` | **A** | 3 | **1** | **36** | **27** |
| Minerals Technologies Inc. | `filler_gap_2026Q3` | C | 0 | **1** | 0 | 0 |
| SMI (USA - Regional HQ) | `industry.v11_4` | B | 0 | **1** | 0 | 0 |
| Specialty Minerals Inc. | `filler_gap_2026Q3` | C | 0 | **1** | 0 | 0 |

**딜이 4개입니다.** 법인은 2개인데. 그리고 **3개는 커뮤니케이션 0, 인게이지먼트 0인 행에** 붙어 있습니다 — 관계 이력에서 분리된 유령 딜입니다.

**정리 문제가 아닙니다. 파이프라인이 쪼개져 있습니다.** SMI 딜을 세는 모든 리포트가 **4개**로 세고 있는데 실제 관계는 **1개**입니다.

출처 분포도 낯익습니다: 베이스 로스터(`industry.v11_4`)에 HQ와 Regional HQ가 이미 있었고, `filler_gap_2026Q3`가 그 위에 MTI와 SMI Inc.를 얹었습니다. **Omya Korea·태경 ×2와 정확히 같은 형태** — gap 파일이 자기가 못 보는 베이스 로스터 위에 INSERT.

### 딜 4개를 보기 전엔 병합 안 씁니다

딜을 눈감고 재지정하거나 삭제하면 **파이프라인 숫자가 조용히 바뀌고 아무도 이유를 못 댑니다.**

블록 1은 `select d.*`입니다 — 일부러요. `app.deals` 스키마를 모르는데 컬럼명을 지어내는 게 오늘 아침 `c.title` 42703을 만든 짓입니다.

| 블록 | 내용 |
|---|---|
| 1 | **딜 4개 전체 행** (`select *`) |
| 2 | **SMI만의 문제인가** — 딜은 있는데 comms도 contacts도 없는 party 전수 |
| 3 | **gap 파일이 베이스 위에 얹은 모든 케이스** — 버그의 일반형 |
| 4 | 9f161ff5가 실제로 가진 것 (36 comms + 27 engagements의 기간) |
| 5 | 9f161ff5의 supply_link 1건 — 어느 제지사인가 |

## 5. 이동 · 실행 · 마무리

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 폴백:

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'fix_omya_contacts_2026-07-16*.sql'; Dest = (Join-Path $repo 'sql'); Name = 'fix_omya_contacts_2026-07-16.sql' },
  @{ Pattern = 'scan_smi_deals_2026-07-16*.sql';    Dest = (Join-Path $repo 'sql'); Name = 'scan_smi_deals_2026-07-16.sql' },
  @{ Pattern = 'handoff_omya_smi_deals_2026-07-16*.md'; Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_omya_smi_deals_2026-07-16.md' }
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

1. `fix_omya_contacts` 전체 (2개 문) → 검증으로 Jaehoon Cho / Edgar Habich, `title_text` null 확인
2. `scan_smi_deals` **블록 1**만 먼저 → **결과 보내주세요.** 그게 병합 파일의 전제입니다
3. 블록 2·3 — 다른 나라에도 같은 유령 딜이 있는지

**마무리**

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_omya_contacts_2026-07-16.sql sql/scan_smi_deals_2026-07-16.sql docs/handoff/2026-07-16/handoff_omya_smi_deals_2026-07-16.md
git commit -m "fix: name the 2 real Omya contacts (Jaehoon Cho = Omya Korea's only contact, KR #1 target) - no bulk update, 14 of 16 derivations would have invented fake people; scan: 4 SMI deals across duplicate rows = split pipeline"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 6. 제네릭 인박스 — 시퀀스 쪽 문제입니다

`info.saugbrugs@` 3개 Norske Skog 행, `marketing.itcpspd@` 4개 ITC 행, `info.jkpaper@` 3개 JK Paper 행, `geral.celbi@` 2개 Altri 행에 붙어 있습니다.

**형제 party를 한 시퀀스에 enroll하면 한 인박스에 거의 똑같은 콜드메일이 3~4통 갑니다.** DKIM 없음 / DMARC p=none / PTR 불일치 상태에서요.

올바른 해결은 컨택이 아니라 **시퀀스 레이어**입니다 — 제네릭 로컬파트 제외 + **party가 아니라 email 기준으로 enrollment 중복 제거**.

**`v_email_do_not_send` 정의를 보내주시면 패치를 쓰겠습니다.** 발송 로직을 추측으로 건드리지 않겠습니다.

## 7. 남은 것 — 하나뿐입니다

**`scan_smi_deals` 블록 1** — 딜 4개의 정체. 그거면 SMI 병합을 씁니다.
