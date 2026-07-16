# Handoff — 일본 Filler 홈페이지 정밀 조사 (2026-07-16, 3차)

## 0. 감사 먼저 — 일본은 갭이 아닙니다

이번엔 **조사 전에 DB부터 확인**했습니다. 결론:

**일본은 이미 가장 잘 커버된 시장입니다.** 국내 메이커 9곳 + SMI 일본 2행 + 白石 말레이시아 1행.

| 회사 | uuid | 사이트 | 보강 상태 |
|---|---|---|---|
| 奥多摩工業 Okutama Kogyo | `8395314e` | okutama.co.jp | ❌ **website만** |
| 白石工業 Shiraishi Kogyo | `6cb04800` | shiraishi.co.jp | ❌ **website만** |
| 白石カルシウム Shiraishi Calcium | `e00f4fd0` | shiraishi.co.jp | ❌ **website만** |
| 丸尾カルシウム Maruo Calcium | `1be485ad` | maruo-cal.co.jp | ❌ **website만** |
| 備北粉化工業 Bihoku Funka | `844b4120` | bihokufunka.co.jp | ❌ **website만** |
| 日東粉化工業 Nitto Funka | `f24bb73a` | nittofunka.co.jp | ✅ batch12 |
| ファイマテック Fimatec | `21d35d02` | fmt.co.jp | ✅ batch12 |
| 日鉄鉱業 Nittetsu Mining | `92f57c52` | nittetsukou.co.jp | ✅ batch12 |
| 東洋電化工業 Toyo Denka | `ba067815` | toyodenka.co.jp | ✅ batch13 |

**정확히 이 구멍이 문제입니다.** batch1에서 website만 받고 batch12·13 보강 대상에서 빠진 5곳이, 하필 **일본에서 제지 관련성이 가장 높은 이름들**입니다. 이 파일이 딱 그 5곳을 채웁니다.

**INSERT가 하나도 없습니다.** 전부 uuid 타깃 UPDATE라 중복이 구조적으로 불가능합니다.

---

## 1. `enrich_jp_filler_homepage_2026-07-16.sql` → `sql\`

### 🎯 발견 1 — 奥多摩工業이 일본 제지용 PCC를 사실상 지배합니다

`okutama.co.jp/project/papermaking/` 원문:

> 現在、タマパールの販売地域は北海道から鹿児島まで日本全国にわたり、**製紙用では9割超と圧倒的なシェア**を占めています。

- **タマパール(TAMAPEARL)** = 자사 합성기술로 입경·입도를 제어한 PCC, 1975년 출시. 광택도·백색도·불투명도 우수 → 제지용 내전재·도공안료.
- 도쿄 오쿠타마에 **자체 석회석 광산**, 1974년 奥多摩化工 흡수합병으로 **채굴-화공-판매 일관체제**.
- 본사 도쿄 다치카와시.
- 기타: タマカルク(1995~, 배가스 처리제), タマブラン(폐수 중화·가성소다 대체), マスターズ.

### 🎯 발견 2 — Okutama에 satellite 신호가 있습니다

연혁에 **2002년 3월 「株式会社新潟ピーシーシー」(Niigata PCC) 설립**이 있습니다. 니가타에 PCC 전용 자회사를 세운다는 건 **온사이트/제지사 인접 모델**일 가능성이 높습니다 (니가타 = 北越 등 제지 벨트).

→ 근거가 "자회사 설립" 하나뿐이라 **`supply_model`을 satellite로 확정하지 않았습니다.** notes에 VERIFY 항목으로 남겼습니다. **니가타PCC의 납품처가 확인되면 supply_model=satellite / evidence_level=B로 올리고, 일본 FCC 1순위로 확정하면 됩니다.**

### ⚠️ 발견 3 — 白石 두 법인의 역할이 뒤바뀌어 있습니다

- **白石工業 (Shiraishi Kogyo)** = **제조사**. 6개 공장(白艶華·碓氷第一/군마, 不二·富士川/시즈오카, 土佐/고치, 開発/아마가사키). 2022년 7월 太陽化学工業 흡수합병. UFPCC/PCC/GCC.
- **白石カルシウム (Shiraishi Calcium)** = **판매·네트워크 법인**. 제조 안 함.

그런데 DB의 `Shiraishi Calcium`(e00f4fd0) 노트가 **"Japanese PCC pioneer"** 입니다 — 이건 **白石工業 설명**입니다. → 두 행 모두에 ROLE CORRECTION FLAG를 넣었습니다. 병합할지 역할만 고칠지는 판단이 필요합니다.

### ⚠️ 발견 4 — 白石는 제지 회사가 아닙니다

shiraishi.co.jp가 내세우는 **4대 분야는 자동차자재·산업자재·생활자재·식품아그리/헬스케어** — **제지가 헤드라인에 없습니다.** 고무·수지·식품 중심입니다.

즉 **"일본 PCC = 白石"라는 인식은 제지 맥락에선 과대평가**입니다. 제지 PCC는 奥多摩입니다.

> 다만 훅이 하나 있습니다: **2024년 3월 NEDO 채택 —「신규 탄산염화 기술 및 부생성물을 활용한 경질탄산칼슘 제조기술 개발」**. FCC와 기술 접점이 있어 대화 진입점으로 쓸 수 있습니다.

### 나머지 2곳

**丸尾カルシウム (JP 2순위)** — 효고현 아카시시, 1926년 창업(도료용 白亜에서 출발). PCC(1931~)+GCC(土浦 1966~) 종합, 九州カルシウム(후쿠오카, 연결자회사)에서 표면처리 GCC. 용도에 **제지 명시**. **탄산칼슘 종합메이커 중 유일한 상장사**. 한국·중국·동남아·북미·남미·EU 수출. **"사업의 근간을 연구개발에 둔다"**고 명시 — 라이선싱 대화 수용도가 높을 수 있습니다.

**備北粉化工業** — 오카야마현 니이미시. **GCC 전업** ("당사는 중질탄산칼슘을 취급"). 자체 광산 2곳: **唐櫃광산**(니이미, 갱내 지하 100m, 열변성 결정질 고품위, **매장량 약 1억 톤**) + **大滝根광산**(후쿠시마, 동일본 커버). 용도에 제지 명시. FCC 관점 제약은 **PCC 설비 없음**, 강점은 고순도 결정질 원석 + 1억 톤 매장량.

---

## 2. 파일 이동

### 방법 A — 유니버설 무버 (권장)

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

### 방법 B — 인라인 무버 (폴백)

```powershell
$ErrorActionPreference = 'Stop'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$repo = 'C:\dev\mbg-project'

$moves = @(
  @{ Pattern = 'enrich_jp_filler_homepage_2026-07-16*.sql'; Dest = (Join-Path $repo 'sql'); Name = 'enrich_jp_filler_homepage_2026-07-16.sql' },
  @{ Pattern = 'handoff_jp_filler_2026-07-16*.md';          Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_jp_filler_2026-07-16.md' }
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

## 3. 실행

1. Supabase SQL Editor에서 전체 붙여넣고 실행 (4개 statement).
2. 검증 쿼리 → 5행, 전부 `has_ko = true`, city 채워짐.
3. 파일 하단의 **FULL JP PICTURE 쿼리**를 돌려서 결과를 보내주세요. 다음 배치 기준이 됩니다.

## 4. 마무리 (commit + push)

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/enrich_jp_filler_homepage_2026-07-16.sql docs/handoff/2026-07-16/handoff_jp_filler_2026-07-16.md
git commit -m "enrich: JP fillers homepage-verified (Okutama paper PCC 90%+ / Niigata PCC satellite signal, Shiraishi role swap + weak paper fit, Maruo, Bihoku GCC-only)"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 5. 다음 배치 후보 (JP)

리포에 **전혀 없는** 일본 업체들입니다. 다만 **리포에 없다 ≠ DB에 없다** — Omya Korea 사고가 정확히 그거였습니다. 위 FULL JP PICTURE 쿼리 결과를 받은 뒤에 판단하겠습니다.

| 후보 | 관련성 |
|---|---|
| **矢橋工業 Yabashi Industries** | 기후 석회석/GCC 대형 |
| **カルファイン Calfine** | 제지용 PCC 전업 — 확인 가치 높음 |
| **宇部マテリアルズ Ube Material** | 석회/마그네시아 |
| 竹原化学工業 / 三共製粉 | 중소 CaCO3 |
| 神島化学工業 Konoshima | 무기소재 |
| 日本ミストロン / 富士タルク | 제지용 탈크 |
| 松村産業 / 土屋カオリン | 탈크·카올린 |

우선순위는 **カルファイン(Calfine)** 입니다. 제지용 PCC 전업이면 奥多摩 다음 타깃이 됩니다.

### 그리고 우선 확인할 관계 데이터

- `Specialty Minerals FMT (Japan - Shiraoi, Hokkaido)`와 `Fimatec`(21d35d02)의 관계 — SMI×Fimatec JV로 보입니다. 계열 매핑 필요.
- **奥多摩工業 ↔ 新潟PCC ↔ 니가타 제지사** 링크. 확인되면 `app.party_supply_links`에 `mill_party_id`/`filler_party_id`로 연결 가능합니다.
