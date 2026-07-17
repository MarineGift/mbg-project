# Handoff — 폼 입력 가능해졌습니다. 마무리 (2026-07-17)

## 1. 오늘 완성된 것

**`contact_inquiry` 기계가 처음으로 돌아갑니다.** 027이 몇 주 전에 지어놓고 폼 0개였던 그 시스템입니다.

| | |
|---|---|
| **답변 6개** | `filler_safe` 태그, `short`/`medium`/`long`. 전부 자기 `target_length` 안에 들어감 (196/200 · 176/180 · 889/900 · 1858/1900) |
| **`long` variant** | 이 라이브러리에서 **첫 사용** |
| **바인딩 규칙** | `disclosure_level = 'public'` **AND** `tags @> ARRAY['filler_safe']` — **기본 거부** |
| **하드 블록** | `ip_portfolio` · `business_model` · `royalty_economics` — 프로젝트 자신의 NDA 스캔 규칙 위반 |
| **폼 2개** | **Artemyn**, **20 Microns** — DB 최초의 `contact_inquiry` 행 |

## 2. `fix_20microns_contact_2026-07-17.sql` → `sql\`

화면에 `Contacts 0 / Email - / Contact method - / Form URL -`로 떠 있던 회사가 **자기 컨택 페이지에 셋 다 공개하고 있었습니다.**

```
20microns.com/contact-us
  enquiry@20microns.com        ← 본 사업 문의 (LinkedIn·Facebook에서도 확인)
  investors@20microns.com      ← IR
  9-10, GIDC Industrial Estate, Waghodia 391760, Vadodara, Gujarat
  Tel +91 2668 292297 / 수신자부담 1800 233 2735
  "For product related assistance or inquiry submit your details below: Send"  ← 폼
```

**이게 filler 문제 전체의 모양입니다. 242곳 중 4곳만 컨택이 있는데, 정보가 없던 게 아니라 아무도 가져오지 않았습니다.**

### 이름은 안 붙였습니다

`enquiry@`는 **인박스지 사람이 아닙니다.** `full_name`은 null입니다. 어제 미리보기가 증명했습니다 — `geral.celbi` → "Geral Celbi", `info.jkpaper` → "Info Jkpaper", **16개 중 14개가 틀렸을 겁니다.**

**공개된 인박스 하나에 의도적으로 한 통 보내는 건 괜찮습니다. 거기에 사람이 있는 척하는 게 문제입니다.**

### FCC 적합도: 강함

- **PCC·GCC 생산 + 제지용 코팅안료 수출**(coating grade GCC, PaperIndex 기록)
- **이미 TiO2 부분 대체를 팝니다** — 고객이 *"비싼 투입재를 광물로 대체한다"*는 논리를 이미 사고 있습니다. **FCC 대화가 한 칸 앞에서 시작합니다**
- BSE·NSE 상장, 매출 약 $93M → **인도 공시가 임원 이름을 줍니다** (태경의 DART와 같은 경로)
- 인도는 제지 성장 시장이고 이 회사가 최대 백색광물 생산자

⚠️ **폼이 "product related assistance"로 프레이밍돼 있습니다 — 영업 큐로 읽힙니다.** `enquiry@`가 나은 문일 수 있고, 둘 다 시도해도 비용이 0입니다.

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
  @{ Pattern = 'fix_20microns_contact_2026-07-17*.sql'; Dest = (Join-Path $repo 'sql'); Name = 'fix_20microns_contact_2026-07-17.sql' },
  @{ Pattern = 'handoff_form_ready_2026-07-17*.md';     Dest = (Join-Path $repo 'docs\handoff\2026-07-17'); Name = 'handoff_form_ready_2026-07-17.md' }
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

**오늘 아직 커밋 안 된 것들이 있습니다. 날짜 폴더에 주의하세요 — `2026-07-17`입니다:**

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/ docs/handoff/2026-07-17/
git commit -m "seed: filler_safe answer set (6 answers, short/medium/long, first use of the long variant) - deny-by-default binding, royalty/IP/9000-ton answers hard-blocked; fix: Imerys exited paper in 2024 (sold to Artemyn under Flacks) so the coverage hole was not a hole; Artemyn IS that business - 17 CaCO3 plants, mislabelled as a kaolin merchant, now target #1; first two contact_inquiry forms (Artemyn, 20 Microns) + 20 Microns enquiry inbox"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영.

## 4. 오늘의 방법 — 이게 남는 겁니다

**20 Microns가 방법을 보여줍니다:**

```
1. 홈페이지 contact 페이지를 직접 읽는다        ← 추측 아님
2. 이메일이 있으면 컨택으로 넣되 이름은 안 붙인다  ← 제네릭은 제네릭
3. 폼이 있으면 URL을 넣고 필드는 비워둔다        ← max_length를 지어내면 variant 시스템이 무의미
4. 상장사면 공시가 이름을 준다                  ← DART / 인도 filings
5. 다른 계열 인박스는 절대 쓰지 않는다           ← enquiry@20nano, info@silcol 등
```

**남은 76곳에 이걸 반복하면 됩니다.** 한 번에 5~8곳씩이 검증 가능한 단위입니다 — 83개를 한 파일에 넣으면 어느 URL이 틀렸는지 아무도 못 찾습니다.

## 5. 우선순위 — 다음에 열 순서

| # | 회사 | 왜 |
|---|---|---|
| **1** | **Artemyn** | 제지용 CaCO3 공장 **17곳**. 구 Imerys 제지 사업. 홈페이지가 *"investor, **partner**, or industry peer — our leadership team is ready to talk"*라고 직접 씁니다. **`Leadership` 페이지에 이름이 있고 `Par Moor, UK`가 P&B Lab입니다.** 폼보다 사람이 빠릅니다 |
| 2 | 20 Microns | ✅ 완료 |
| 3 | Zantat (MY) | evidence A, 부르사 상장 → 공시가 이름을 줌 |
| 4 | Q-min (TH) | evidence A, 태국 상장 |
| 5 | Gulshan Polyols (IN) | 인도 주요 PCC/WGCC, 다공장 |
| 6 | 丸尾 · 備北 · 日鉄鉱業 (JP) | 일본 로스터 9곳 전부 딜 0 |

## 6. 남아 있는 결정 둘

**① 제지기 규모 검증 문구** — *"validated at commercial mill scale on a production machine, in both GCC and PCC systems"*. `nda_achieved_full`(nda_only)에 있어서 안 넣었습니다. **`company_one_liner`는 이미 public으로 "in market"이라고 합니다.** 공개 가능하면 medium·long이 눈에 띄게 세집니다. 문장은 `seed_filler_form_answers` 8-a에 그대로 있습니다. **nda_only를 제 판단으로 public으로 올리지 않겠습니다.**

**② `ip_portfolio`를 `nda_only`로 올릴 것인가** — 프로젝트 자신의 스캔 규칙대로면 이미 라벨이 틀렸습니다(`Marinepad` + `500,000 USD`). 그런데 **investor 폼 4개가 `drafting`, 2개가 `submitted`**입니다. 뒤집으면 작성 중 필드가 조용히 비워질 수 있습니다. `fix_answer_library_filler_gate` 5번 블록에 무엇이 바인딩됐는지 보는 쿼리가 있습니다.

## 7. 이틀의 결론 한 줄

> **정보는 없던 게 아니라 가져오지 않은 것이었습니다.**

- filler 242곳 중 컨택 4곳 — **거의 전부가 홈페이지에 주소나 폼을 공개합니다**
- Artemyn — **17개 CaCO3 공장이 "kaolin 상인"으로 앉아 있었습니다**
- Imerys 커버리지 구멍 — **2년 전에 제지에서 나갔습니다**
- Omya·SMI — **`partner_names`가 처음부터 파트너라고 적어놨습니다**
- `party_supply_links` 15컬럼 컨벤션 — **6월부터 있었습니다**
- 폼 기계 — **027이 "mills included"로 지어놓고 놀고 있었습니다**

**제 오류 12개가 전부 같은 뿌리입니다: 확인할 수 있는 걸 확인하지 않고 추론했습니다.**

**그리고 규칙 하나가 반복해서 살렸습니다 — 조회 없이 쓰지 않는다.** 이름 유도 미리보기가 가짜 인물 14명을 막았고, `migration_027`을 읽은 게 중복 마이그레이션을 막았고, `partner_names`를 읽은 게 파트너에게 콜드 폼을 보내는 설계를 막았습니다.
