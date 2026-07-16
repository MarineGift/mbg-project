# Handoff — 커버리지가 뒤집혀 있습니다 (2026-07-16, 17차)

## 1. 마지막 그림

```
딜 151개  =  Omya 국가법인 40  +  SMI 국가법인 43  +  SMI 공장 65  +  연락가능 3
딜 0개    =  회사 90개
```

**딜 0인 90개 안에 있는 것들:**

| | |
|---|---|
| **Imerys 계열 8개 전부** | Korea · HQ · **China(가공공장 11곳 + 테크센터)** · India · USA · Brazil · Canada · Mexico<br>**글로벌 3위 사업자입니다** |
| **SMI 외 satellite 운영사 전부** | **태경비케이**(KR, 한솔 장항 온사이트 — DB가 이미 아는 관계)<br>**Double A Specialty Minerals**(TH, `on-site PCC supplier`)<br>**Fimatec**(JP, `GCC slurry incl. satellite concept`) |
| 일본 로스터 9개 전부 | **奥多摩**(자사 홈페이지 기준 제지용 9할 초과) · 白石工業 · 丸尾 · 日鉄鉱業 · 備北 · 東洋電化 · 日東粉化 |
| 인도 10 · 중국 9 · 한국 7 · 폴란드 6 · 터키 5 | |
| **MLC** | **컨택 13명 — filler 중 유일하게 사람이 있는 회사** |
| evidence A인데 딜 0 | Imerys Korea · **Q-min**(TH) · Surint Omya(TH) · Thiele(정당 — `fcc_fit: no`) · Zantat |

**캠페인이 쓸모없는 곳에 깊이 팠습니다** — 라이선스에 서명할 수 없는 개별 공장 65개.
**그리고 중요한 곳에 0입니다** — 글로벌 3위, satellite 운영사 4곳 중 3곳.

## 2. 🎯 satellite 운영사가 핵심인 이유

**FCC는 제지 PCC를 대체·개선합니다. 이미 온사이트 satellite PCC를 돌리는 회사에는 이미 있습니다:**

- 공정
- 제지사와의 관계
- **capex 모델** — FCC가 그대로 슬롯인할 자리

**로스터 전체에서 가장 자연스러운 라이선시입니다. DB에 4곳 있습니다. 캠페인엔 1곳뿐입니다.**

| | 국가 | ev | 컨택 | 딜 |
|---|---|---|---|---|
| **Specialty Minerals (HQ)** | US | A | **3** | **1** |
| **태경비케이** | KR | B | **0** | **0** |
| **Double A Specialty Minerals** | TH | B | **0** | **0** |
| **Fimatec** | JP | B | **0** | **0** |

**태경비케이는 DB가 이미 한솔 장항 온사이트 PCC 관계를 알고 있습니다.** 오늘 그 supply_link를 컨벤션에 맞춰 채웠습니다. **그런데 딜도 컨택도 없습니다.**

## 3. `scan_fcc_target_ranking_2026-07-16.sql` → `sql\`

**캠페인이 이랬어야 할 목록을 만듭니다. 아무것도 쓰지 않습니다.**

| 블록 | |
|---|---|
| **1** | **랭킹 전체** — Tier 1 satellite 운영사 / Tier 2 PCC·GCC 생산자(ev A·B) / Tier 3 / Tier 4 롱테일 |
| **2** | **Tier 1만** — 가장 중요한 넷 |
| **3** | **Imerys 구멍** — 8행, 컨택 0, 딜 0 |
| **4** | **컨택 커버리지** — evidence 등급별 |

### 제외 기준 — 전부 오늘 확립된 것들

```
party_name ~ ' - '                        → 공장은 서명할 수 없음
party_name ~ '(Global'                    → 추상
extra_data.fcc_fit.verdict = 'no'         → Thiele (카올린, CaCO3 라인 없음)
market_role ~ 'no direct presence|theoretical|no commercial entity'
market_role ~ 'holding company|not the licensing counterparty'   → MTI
market_role ~ 'not an independent supplier'                      → Calrock (Zantat 자매사)
```

**각 줄이 오늘 하루의 발견 하나씩입니다.**

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
  @{ Pattern = 'scan_fcc_target_ranking_2026-07-16*.sql'; Dest = (Join-Path $repo 'sql'); Name = 'scan_fcc_target_ranking_2026-07-16.sql' },
  @{ Pattern = 'handoff_coverage_inversion_2026-07-16*.md'; Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_coverage_inversion_2026-07-16.md' }
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

**실행: 블록 2 먼저.** Tier 1 넷이 오늘의 결론입니다.

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/scan_fcc_target_ranking_2026-07-16.sql docs/handoff/2026-07-16/handoff_coverage_inversion_2026-07-16.md
git commit -m "scan: coverage inversion - campaign has 65 SMI plant deals and zero on Imerys (global #3, 8 rows) or on 3 of the 4 satellite PCC operators; ranked target list with exclusions derived from today's findings"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 5. 오늘 하루

시작은 제가 **"KR filler 0건"**이라고 잘못 말한 것이었습니다.

**제가 오늘 만든 오류:**

| | |
|---|---|
| 1 | KR filler 0건 주장 → 실제 9행 |
| 2 | Omya Korea 중복 생성 |
| 3 | 태경비케이 중복 생성 |
| 4 | 태경산업 중복 생성 |
| 5 | Imerys Korea 완전 누락 |
| 6 | MLC intro에 null 가드 → 조용히 스킵 |
| 7 | `c.title` / `c.decision_maker` → 42703 (정답이 **제 파일 안에** 있었음) |
| 8 | `party_supply_links`에 3컬럼만 INSERT → 15컬럼 컨벤션 존재 |
| 9 | 채팅에 인용용 SQL을 코드블록으로 → 두 번 실행시킴 |
| 10 | `v_email_do_not_send` 패치 제안 → 뷰의 성격을 오해 |

**전부 같은 뿌리입니다: 확인할 수 있는 걸 확인하지 않고 추론했습니다.**

**그리고 규칙 하나가 저를 살렸습니다:**

> **조회 결과 없이 쓰기 파일을 만들지 않는다.**

이름 유도 미리보기 16행 중 14행이 틀렸습니다. 벌크로 돌렸으면 실존 제지사 14곳에 **"Info Jkpaper"**라는 가짜 인물이 생겼고 시퀀스가 그 이름으로 메일을 보냈습니다.

**세 번 틀리게 했고 한 번 살렸는데, 그 한 번이 나머지 셋을 합친 것보다 컸습니다.**

## 6. 오늘 찾은 실패 유형 — 여섯 개, 전부 조용합니다

| 유형 | 사례 |
|---|---|
| 낡은 마케팅 | MLC(PCC 철수 후에도 PCC 포지셔닝) · Zantat · 白石 |
| 관련성 혼동 | Thiele — 주장은 참인데 FCC와 무관 |
| 구조적 중복 | Omya Korea · 태경 ×2 · SMI/MTI 4행 |
| 평가 누락 | JP top 5 — website만 받고 모든 배치에서 스킵 |
| 접근 불가 | 이름 없는 컨택 100+ |
| **잘못된 연결** | **Saica → Burgo 경쟁사 인박스** |

**여섯 개 다 에러를 안 냅니다. 그래서 몇 달을 갑니다.**

그리고 여섯 번째만 **능동적으로 해롭습니다** — 나머지는 기회를 놓치는 것이고, 이건 경쟁사에게 정보를 주는 겁니다.

## 7. 오늘의 진짜 결론

> **병목은 데이터 품질이 아니라 컨택입니다.**

filler 전체에서 컨택이 있는 회사는 **4곳, 18명**입니다:

| | |
|---|---|
| Mississippi Lime | 13 — **그런데 PCC를 접었습니다** |
| Specialty Minerals HQ | 3 — Sharad Mathur 포함 |
| Omya (HQ) | 1 |
| Omya (Korea) | 1 |

**그리고 그 18명 중 5명이 오늘 아침까지 이름이 없었습니다.**

**가장 잘 커버된 곳이 사업을 접은 회사입니다.**

하루 종일 데이터를 고쳤습니다. 고칠 가치가 있었습니다 — Saica는 경쟁사에게 메일을 보낼 뻔했고, 유령 딜 148개가 파이프라인 숫자를 5000% 부풀리고 있었습니다.

**그런데 내일 아침에도 연락할 수 있는 사람은 5명입니다.**

## 8. 남은 것

1. **`entity_enrollment` 소스** — enroll 전 가드용. `src/lib` 아래 grep
2. **148개 버킷 결정** — `scan_fcc_campaign_triage` 블록 1
3. **컨택 확보** — Tier 1의 태경비케이·Double A·Fimatec, 그리고 **Omya (USA)**(evidence A, 컨택 0)
4. **Imerys Korea 검증** — evidence A인데 **공정위 2019-109 피심인이 아닙니다.** 한국 제지용 GCC 역할이 미확인이고 A가 과대평가일 수 있습니다
