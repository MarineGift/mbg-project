# Handoff — 6월의 좋은 작업, 2003년의 근거, 그리고 제 빈 행 (2026-07-16, 14차)

## 0. 이건 블록 1이 아니라 블록 5였습니다

`app.deals`가 아니라 **`app.party_supply_links`** 결과입니다. 그런데 훨씬 값진 게 나왔습니다.

---

## 1. ✅ 6월에 누군가 아주 좋은 작업을 했습니다

```
818ecd2b   filler = Specialty Minerals (HQ)
           mill   = International Paper Company (979a84eb)
           link_type: active | confidence: high
           product_grade: PCC filler-grade
           volume_estimate: "8 satellite plants (US & EU)"
           notes: "...| src: SEC 8-K"
           extra_data.source: "SEC 8-K"
           extra_data.evidence_url: sec.gov/.../000089101403000027/ex99iprelease.htm
           extra_data.batch: "omya_smi_batch1"  researched_at: 2026-06-17
```

**SMI ↔ International Paper의 8개 온사이트 satellite를 SEC 8-K 근거로 기록**했습니다. provenance 어휘로 **`disclosure`** — 제가 오늘 종일 "이 DB엔 없다"고 한 그 등급입니다. 있었습니다.

그리고 `app.party_supply_links`가 제 생각보다 훨씬 풍부합니다:

| 컬럼 | |
|---|---|
| `link_type` / `confidence` | active / high |
| `active_since` / `active_until` | 시계열 |
| `volume_estimate` / `product_grade` | 규모·등급 |
| `notes` | 파이프 구분 + `src:` 접미 |
| `extra_data` | batch / source / link_kind / evidence_url / researched_at / supply_structure |

**이미 확립된 컨벤션이 있었습니다.**

## 2. 🔴 그런데 그 8-K는 2003년 문서입니다

`000089101403000027` — 가운데 **`03`이 2003년**입니다.

- `researched_at: 2026-06-17` ← 조사는 지난달
- **근거는 23년 전** ← 그런데 `link_type: active`, `confidence: high`

International Paper는 2003년 이후 공장을 대거 정리했습니다 — **Ticonderoga, Jay, Androscoggin** 전부 매각되거나 문을 닫았습니다. **"8개 satellite"는 지금 거의 확실히 안 맞습니다.**

**오늘 종일 쫓던 그 패턴입니다.** MLC·Zantat·白石과 **똑같은 형태** — 확신에 찬 기록이 낡은 문서 위에 서 있는. 다만 이번엔 filler_supplier_profile이 아니라 **supply_link 쪽**입니다.

**confidence는 안 내렸습니다.** 확인 없이 내리는 것도 추측입니다. `extra_data.staleness_flag`로 우려를 기록하고 확인 경로(MTI 10-K 세그먼트 공시 + mineralstech.com satellite 목록)를 남겼습니다.

## 3. 🔴 그리고 제 실수를 발견했습니다

`fix_taekyung_dupes_2026-07-16.sql`에서 제가 `party_supply_links`에 넣은 행:

```sql
insert into app.party_supply_links (mill_party_id, filler_party_id, organization_id)
```

**세 컬럼뿐입니다.** 스키마를 몰라서 최소한만 넣었습니다.

**에러 없이 실행됐습니다. 그래서 아무도 눈치 못 챕니다.**

한솔 장항 ↔ 태경비케이 링크에 `link_type`도 `confidence`도 `product_grade`도 `notes`도 `extra_data`도 **전부 null**입니다. 6월 컨벤션 대비 **껍데기**입니다.

`fix_supply_link_taekyung_enrich_2026-07-16.sql`이 이걸 컨벤션에 맞춥니다.

### confidence를 `medium`으로 넣었습니다 — 일부러

기존 SMI 행은 `high`입니다. **제 행은 그럴 자격이 없습니다.**

한솔 장항 링크의 출처는 **다른 party의 intro 안에 있던 문장**이고, 태경비케이 자신의 `supply_model`이 뒷받침할 뿐입니다. **내부 기록 두 개가 서로 동의하는 건 1차 출처가 아닙니다.**

`extra_data.caveat`에도 명시했습니다: *"Recorded from an internal note, NOT a primary source. Confirm with Hansol or Taekyung BK before treating as established."*

### 문을 따로 쪼갰습니다

`link_type`과 `confidence`가 enum일 수 있는데 유효 멤버를 모릅니다. `'active'`/`'medium'`이 없으면 에러가 납니다. **그래서 별도 문으로 뺐습니다** — 실패해도 블록 1은 이미 커밋된 뒤이고, 컬럼이 null로 남는 건 공정한 결과입니다.

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
  @{ Pattern = 'fix_supply_link_taekyung_enrich_2026-07-16*.sql'; Dest = (Join-Path $repo 'sql'); Name = 'fix_supply_link_taekyung_enrich_2026-07-16.sql' },
  @{ Pattern = 'handoff_supply_links_2026-07-16*.md';             Dest = (Join-Path $repo 'docs\handoff\2026-07-16'); Name = 'handoff_supply_links_2026-07-16.md' }
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

1. **블록 0 (pre-flight)** — 제 행이 정말 비어 있는지
2. 블록 1 → 2 → 3 → 4 **하나씩**. 2·3은 enum 때문에 에러 가능성 있음 — 나면 알려주세요
3. **블록 5 (검증)** — 이건 그 자체로 볼 가치가 있습니다. **DB 전체 supply_link 목록**입니다. 몇 개나 있고, 그중 몇 개가 2003년 8-K보다 오래된 근거 위에 서 있는지

**마무리**

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_supply_link_taekyung_enrich_2026-07-16.sql docs/handoff/2026-07-16/handoff_supply_links_2026-07-16.md
git commit -m "fix: my Hansol-Taekyung supply link had only 3 columns - brought up to the omya_smi_batch1 convention (confidence medium, not high - internal note is not a primary source); flag SMI-International Paper link as source-stale (active/high on a 2003 SEC 8-K)"
git push origin marinebiogroup
```

> **주의**: push = Railway 자동 배포 = 웹 즉시 반영. `git status -sb` 먼저.

---

## 5. 오늘 배운 것 하나 더

제가 오늘 **"리포에 없다 = DB에 없다"**로 세 번 틀렸습니다. 그리고 방금 **"내가 모른다 = 없다"**로 또 틀렸습니다.

- `party_supply_links`에 컬럼이 3개뿐인 줄 알고 3개만 넣었습니다 → 실제로는 15개 컬럼에 확립된 컨벤션이 있었습니다
- `disclosure` 등급 근거가 DB에 없다고 종일 말했습니다 → SEC 8-K가 6월부터 있었습니다

**둘 다 조회 한 번이면 알 수 있었습니다.** 그리고 둘 다 **에러가 안 났습니다.**

## 6. 남은 것 — 여전히 하나

**`scan_smi_deals` 블록 1**:

```sql
select d.* from app.deals d
where d.party_id in ('5ba57cb3-a5bb-4fd1-8750-342eb2cc25f1'::uuid,
                     'cd3dbf9e-bb61-4fda-81aa-9d914a5a5658'::uuid,
                     '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid,
                     'fa423be1-6482-4147-beae-179d118f48d9'::uuid);
```

딜 4개가 중복 행 4개에 흩어져 있고 **3개는 커뮤니케이션 0인 행**에 붙어 있습니다. 이거 보기 전엔 병합 안 씁니다.
