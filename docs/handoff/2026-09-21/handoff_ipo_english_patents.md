# IPO module — English data + KR patent register

**Date**: 2026-09-21 · **Requires**: `/ipo` rev.2 deployed (`aecbd77`)

## 1. What this does

| File | Where | What |
|---|---|---|
| `fix_ipo_module_english.sql` | `sql\` (commit) | Retranslates every stored row to English by code — phases, milestones, gates, metrics, criteria notes, KPIs, assumptions, scenarios, decision schedule, license-term template, advisor pipeline description. Idempotent; does not touch verdicts, statuses, snapshots, dates. Also removes duplicate template rows in `license_terms`. |
| `seed_ipo_module.sql` | `sql\` (commit, replaces the Korean one) | Same content, English, for fresh installs. |
| `paste_patents_kr.sql.txt` | **Downloads only — never commit** | Inserts the five KR patents. `.txt` so the mover ignores it. |
| `gantt_nasdaq_2029.html` | `docs\handoff\2026-09-21\` | Regenerated in English. |

## 2. Run order (Supabase SQL Editor)

```
1) fix_ipo_module_english.sql        → then reload /ipo; Timeline, Gates, Criteria all English
2) paste_patents_kr.sql.txt          → NOTICE: patents upserted: 5
3) SELECT * FROM app.v_patent_horizon;
   expect material 5 / foundational 2 / improvement 3 / earliest 2033-08-21 / min_remaining 6.9 / unrecorded 5
```

## 3. What the five patents say (as filed)

| Family | Role | KR no. | Filed | Expires | Registered owner (as granted) |
|---|---|---|---|---|---|
| FCC-PREFLOC | foundational | 10-1510313 | 2013-08-21 | **2033-08-21** | Chungnam National Univ. IUCF |
| FCC-NFC | foundational | 10-1535522 | 2014-07-09 | 2034-07-09 | Chungnam National Univ. IUCF |
| FCC-COATED | improvement | 10-1742962 | 2016-05-17 | 2036-05-17 | Chungnam National Univ. IUCF |
| FCC-FINES | improvement | 10-1910649 | 2017-04-06 | 2037-04-06 | Chungnam National Univ. IUCF |
| FCC-CHITIN | improvement | 10-2887327 | 2023-02-13 | 2043-02-13 | Marinepad Co., Ltd. (applicant) |

All five entered as `is_material = true`, `assignment_status = not_started` (transfer planned by 2026-10). Roles are my reading of the claims — flip any of them in the Patents tab.

## 4. Two findings that matter for the S-1

**Chain of title.** Four of the five were granted to Chungnam National University's IUCF, not to Marinepad. The transfer you are planning is Marinepad → MBG Inc. That assignment only gives clean title if CNU → Marinepad was itself executed and **recorded at KIPO**. If it was a license rather than an assignment, MBG will be a licensee, not an owner, and L4-01 cannot pass. Confirm the KIPO register for each of the four before October; if CNU still shows as owner, the October transfer needs CNU's signature, not Marinepad's.

**Remaining life.** The foundational patents expire 2033 and 2034 — 6.9 years from today, 3.5–4.5 years after a 2029/2030 listing. `kpi_patent_life` (≥ 10 yrs) will show **failing** as soon as you run the paste, and that is correct: the S-1 must disclose it. The position is carried by the improvement families (2036, 2037, 2043) and by whatever foreign counterparts and new filings exist. Add the US/EP/JP counterparts and any pending applications next — if there are none, that is the single biggest IP item to fix before an underwriter looks.

## 5. Move + commit

```powershell
$repo = "C:\dev\mbg-project"; $dl = Join-Path $env:USERPROFILE "Downloads"; $today = "2026-09-21"
$map = @(
  @{ base = "fix_ipo_module_english";  ext = "sql";  dest = "sql";                    name = "fix_ipo_module_english.sql" },
  @{ base = "seed_ipo_module";         ext = "sql";  dest = "sql";                    name = "seed_ipo_module.sql" },
  @{ base = "gantt_nasdaq_2029";       ext = "html"; dest = "docs\handoff\$today";    name = "gantt_nasdaq_2029.html" },
  @{ base = "handoff_ipo_english_patents"; ext = "md"; dest = "docs\handoff\$today";  name = "handoff_ipo_english_patents.md" }
)
foreach ($m in $map) {
  $src = Get-ChildItem -Path $dl -Filter "$($m.base)*.$($m.ext)" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host "MISS  $($m.base)"; continue }
  Unblock-File -Path $src.FullName -ErrorAction SilentlyContinue
  $destDir = Join-Path $repo $m.dest; [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
  [System.IO.File]::Copy($src.FullName, (Join-Path $destDir $m.name), $true); Write-Host "OK    $($m.name)"
}
```

```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/fix_ipo_module_english.sql sql/seed_ipo_module.sql docs/handoff/2026-09-21/
git commit -m "chore(ipo): English seed + retranslation script; English gantt"
git push origin marinebiogroup
```

`paste_patents_kr.sql.txt` stays in Downloads. Delete it after running.
