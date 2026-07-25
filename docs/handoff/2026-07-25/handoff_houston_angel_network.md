# Handoff — Houston Angel Network (HAN) 지원 트랙 시딩

- 작성일: 2026-07-25
- 산출물: `seed_houston_angel_network.sql` → `sql\`
- 적용: Supabase SQL Editor (Railway 자동 실행 아님)
- 성격: **신규 생성 아님 / 기존 레코드 갱신 + 캠페인·딜·태스크 추가**

---

## 1. 왜 신규 시드가 아닌가

HAN은 이미 DB에 있습니다.

| 항목 | 기존 상태 | 출처 |
|---|---|---|
| `app.parties` | `Houston Angel Network` (organization, US/Texas/Houston) | `seed_form_only_investors.sql` (2026-07-09) |
| `preferred_contact_method` | `web_form` | 동일 |
| `contact_form_url` | `.../entrepreneurs` | 동일 |
| `app.contacts` | `samia@houstonangelnetwork.org` (Samia Ahsan, Managing Director) | `20260627100000_texas_investor_emails_research.sql` |
| 도메인 화이트리스트 | `houstonangelnetwork.org` | `20260627094000_texas_investor_domain_whitelist.sql` |

**문제:** 2026-07-09 시점 노트가 `"preferred raise 250K to 1.5M — 10만 달러 SAFE는 하한 미달, 라운드 확대 시 지원 권장"` 으로 남아 있습니다. 그 조건은 이미 충족됐습니다(현재 Series A $3M). 그대로 두면 파이프라인에서 계속 보류 사유로 읽힙니다. 이번 스크립트가 이 노트를 덮어씁니다.

---

## 2. 2026-07-25 웹 검증 결과 (houstonangelnetwork.org)

| 항목 | 내용 |
|---|---|
| 지원 자격 | pre-seed / seed / bridge / **Series A** — 지분·부채·전환사채 모두 가능 |
| 필수 조건 | 완성된 작동 프로토타입 + 시장 검증(파일럿·베타·매출). 산업 특성에 따라 예외 |
| 제외 업종 | 전문서비스·컨설팅, 부동산, 영화, 바·레스토랑·스파 |
| 지원비 | **$100** (Square 결제) — 피치 기회·투자 보장 없음 |
| 지원 경로 | Dealum 포털 (`app.dealum.com`) — proseeder 에서 이전됨 |
| 딜커미티 | Energy / Life Sciences / Consumer / Tech / Aerospace |
| 딜커미티 회의 | 매월 **마지막 주** |
| 내부 투표 | 매월 **첫째 수요일**, 3개사만 선정 |
| 피치 미팅 | 매월 **셋째 수요일** (7월·12월 없음), **8분 + Q&A 5분** |
| NDA | **체결하지 않음** |
| 구조 | HAN 법인은 투자·지분 없음. 회원 개별 또는 SPV(설립비 회사 부담) |
| 실사·협상 | HAN 미관여. 팔로업은 전적으로 창업자 책임 |
| 리더십 | Eric Alfuth (Chair), Mitra Miller (VP), Samia Ahsan (MD) |
| 주소 | 1801 Main Street, Suite 1300 Box 12, Houston TX 77002 |

### 목표 사이클 산정

7월은 피치가 없고, 8/19 슬롯은 지원 마감(7월 중순)이 이미 지났습니다. **첫 현실적 슬롯 = 2026-09-16.**

```
2026-08-14  지원서 제출 마감 (피치 1개월 전)
2026-08-24~ 딜커미티 리뷰 주간
2026-09-02  내부 회원 투표 (첫째 수)
2026-09-16  피치 미팅 (셋째 수)
--- 미선정 시 백업 사이클 ---
2026-10-07  투표 / 2026-10-21  피치
```

---

## 3. 스크립트가 하는 일

| # | 대상 | 내용 |
|---|---|---|
| 1 | `app.campaigns` | `Houston Angel Network (network)` 생성, 고정 id `d0000000-...-0000000000fb` (fc/fd/fe/ff 사용 중) |
| 2 | `app.campaign_materials` | HAN 지원 플레이북 체크리스트 **16건** (Eligibility / Application / Pitch Materials / Screening / Follow-up / Ecosystem) |
| 3 | `app.parties` | notes·intro_ko·intro_en·form URL 갱신 (stale 노트 제거) |
| 4 | `app.investor_profile` | 행 보장 + `priority = medium` + 섹터 3건 (advanced_materials / industrial / deep_tech) |
| 5 | `app.deals` | `Houston Angel Network - Sep 2026 pitch cycle`, investors 파이프라인 **backlog** 스테이지, campaign_id = ...fb |
| 6 | `app.tasks` | 사이클 고정 날짜 태스크 **11건** (America/Chicago, `-05`) |

전부 멱등입니다 — `on conflict do nothing` 또는 `not exists` 가드. 재실행 안전.

### 태스크 스케줄

| 기한 | 우선순위 | 태스크 |
|---|---|---|
| 08-03 | high | readiness 스코어카드 + $100 결제 |
| 08-07 | high | NDA 없는 상태의 FCC 특허 공개 경계 확정 |
| 08-07 | high | 타깃 딜커미티 결정 + 지원서 프레이밍 |
| 08-10 | medium | Rice Alliance / Ion / Capital Factory 웜패스 탐색 |
| 08-12 | high | HAN 지정 10슬라이드 순서로 8분 축약본 제작 |
| 08-12 | high | $27M 프리머니 방어 논리 정리 |
| **08-14** | **urgent** | **Dealum 지원서 제출** |
| 08-24 | high | 딜커미티 리뷰어 콜 대비 |
| 09-02 | high | 내부 투표 결과 확인 + 10월 재지원 판단 |
| **09-16** | **urgent** | **피치 미팅** |
| 09-17 | urgent | 사인업 시트 팔로업 (24시간 내) |

---

## 4. 판단이 필요한 지점 3가지

1. **`value_amount = 250000 USD` 는 가정값입니다.** $3M 라운드 안에서 HAN 회원 배정 목표로 임의 설정했습니다. 실제 목표가 다르면 딜 생성 후 UI에서 수정하세요.
2. **`priority = medium` 으로 뒀습니다.** 엔젤 네트워크가 $27M 프리머니 Series A를 리드할 가능성은 낮습니다. HAN의 실제 가치는 리드 자본이 아니라 휴스턴 로컬 신뢰도·Rice Alliance/Greentown 접점·SPV 부분 참여입니다. 리드 소스로 승격하려면 근거가 더 필요합니다.
3. **NDA 부재가 이번 건의 최대 리스크입니다.** 진행 중인 Kleannara 특허 대응 논리(자기모순 의견서, 분모 0 비교예 오류, 메인브랜치/펄프 치수 중첩)는 HAN 제출물과 구두 Q&A 어디에도 들어가면 안 됩니다. 08-07 태스크가 이걸 1페이지 메모로 확정하는 게이트입니다. **이 메모 전에는 지원서를 쓰지 마세요.**

### 검증하지 못한 정보

3rd-party 애그리게이터(startupintros, ContactOut)에 `회당 투자 $400K~$3.5M`, `밸류에이션 $10M 이하 선호` 같은 수치가 있으나 **HAN 공식 페이지에는 없습니다.** 시드에 반영하지 않았습니다. 사실이라면 $27M 프리머니가 실질 걸림돌이 되므로, 08-07 커미티 결정 전에 Samia Ahsan에게 직접 확인하는 게 $100을 아끼는 길입니다.

Mitra Miller 직함도 소스마다 President / Vice President 로 갈립니다. notes 에는 Vice President 로 기록했습니다.

연락처는 검증된 `samia@` 하나만 이미 DB에 있고, 추가 인물(Eric Alfuth, Mitra Miller)은 이메일을 추정하지 않고 **notes 텍스트로만** 남겼습니다. 필요하면 별도로 검증 후 시딩하세요.

---

## 5. 파일 이동

### ① 유니버설 무버 (권장, 한 줄)

```powershell
powershell -ExecutionPolicy Bypass -File "C:\dev\mbg-project\tools\move-downloads.ps1"
```

`seed_*.sql` → `sql\`, `handoff_*.md` → `docs\handoff\2026-07-25\` 로 자동 라우팅됩니다.

### ② 인라인 무버 폴백 (복붙 실행)

무버 스크립트가 없거나 실패할 때 아래를 PowerShell 창에 그대로 붙여넣으세요.

```powershell
$dl   = "$env:USERPROFILE\Downloads"
$repo = "C:\dev\mbg-project"

$moves = @(
  @{ Pattern = "seed_houston_angel_network*.sql";   Dest = (Join-Path $repo "sql") },
  @{ Pattern = "handoff_houston_angel_network*.md"; Dest = (Join-Path $repo "docs\handoff\2026-07-25") }
)

foreach ($m in $moves) {
  $src = Get-ChildItem -Path $dl -Filter $m.Pattern -File -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host "SKIP (not found): $($m.Pattern)"; continue }

  Unblock-File -Path $src.FullName -ErrorAction SilentlyContinue
  [void][System.IO.Directory]::CreateDirectory($m.Dest)

  $target = [System.IO.Path]::Combine($m.Dest, ($m.Pattern -replace '\*',''))
  [System.IO.File]::Copy($src.FullName, $target, $true)
  Remove-Item -LiteralPath $src.FullName -Force
  Write-Host "MOVED -> $target"
}
```

---

## 6. 적용 절차

1. 위 무버 실행
2. Supabase SQL Editor 에서 `sql\seed_houston_angel_network.sql` 전체 붙여넣기 → Run
3. 파일 하단 **V1~V4 검증 쿼리** 실행 — 기대값:
   - V1: campaign 1건, checklist 16건
   - V2: `notes` 가 `Verified 2026-07-25` 로 시작, 100K 관련 문구 사라짐
   - V3: deal 1건 / stage `backlog` / task_count 11
   - V4: 08-03 ~ 09-17 태스크 11건이 날짜순 정렬
4. `urm.marinebiogroup.com` → Deals → Investors 파이프라인에서 backlog 카드 확인

> `app.deals.campaign_id` 는 NOT NULL 이라 캠페인(...fb)이 먼저 생성돼야 딜이 들어갑니다. 스크립트 순서가 그렇게 잡혀 있으니 **부분 실행하지 말고 전체를 한 번에** 돌리세요.

---

## 7. Finish block

```powershell
cd C:\dev\mbg-project
git status -sb

git add sql/seed_houston_angel_network.sql
git add docs/handoff/2026-07-25/handoff_houston_angel_network.md

git commit -m "seed: Houston Angel Network Series A application track (campaign + deal + Sep 2026 cycle tasks)"

git push origin marinebiogroup
```

⚠️ `git push origin marinebiogroup` 는 Railway 자동 배포를 트리거합니다 — 푸시하는 순간 `urm.marinebiogroup.com` 에 웹으로 공개됩니다. 커밋 전에 `git status -sb` 로 의도치 않은 파일이 섞이지 않았는지 확인하세요.

DB 변경은 SQL Editor 에서 별도로 적용해야 합니다. 푸시만으로는 반영되지 않습니다.
