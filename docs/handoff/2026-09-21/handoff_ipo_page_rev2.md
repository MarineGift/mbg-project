# URM `/ipo` 페이지 rev.2 — 영어 UI · 사이드바 섹션 · 특허 등록

**작성일**: 2026-09-21 · **선행**: rev.1 (`44169f4`) 적용 완료
**검증**: 7개 TS 파일 `tsc --strict --noUncheckedIndexedAccess` 통과 (리포와 같은 옵션)

## 1. 바뀐 것

| 항목 | 내용 |
|---|---|
| 사이드바 | 상단 IPO 항목을 빼고, **PIPELINES 바로 아래 "NASDAQ IPO" 섹션**에 `IPO Readiness` 링크. Nasdaq Listing Advisors 를 보던 자리에서 한 칸 아래 |
| UI 언어 | 탭·제목·표 머리·버튼·플레이스홀더·상태값 전부 영어. DB 에 든 마일스톤 제목·게이트 질문(한국어)은 데이터라 그대로 |
| Patents 탭 | 신규. 특허별 등록·수정·삭제 + material 지평 요약(최소 잔여기간, 최조·최후 만료, 미등록 건수) |
| 186행 | `noUncheckedIndexedAccess` 에러 수정 포함 |
| 개요 | "Numbers to watch" 그리드 4열로 정렬 수정 |

탭: **Overview · Timeline · Readiness Gates · Criteria & KPIs · Patents**

## 2. Patents 탭 사용

`+ Add patent` → family_code(`FCC-BASE`, `FCC-UPG-01` …) · family_role(foundational / improvement / application_specific) · 국가 · 출원/등록번호 · 만료예정일 · MBG Inc 이전 상태(recorded 면 등록일 필수) · material 여부.

서버가 막는 것: material 인데 만료예정일 없음, `recorded` 인데 recordation_date 없음. 이 둘이 없으면 L4 게이트와 잔여기간 KPI 가 계산되지 않기 때문입니다.

입력하면 즉시 살아나는 것: 개요의 "Material patent min. life" / "Material patents unrecorded", KPI `kpi_patent_life`(≥10년), L4-01·L4-02 게이트의 판정 근거.

**실제 특허번호는 이 화면으로만 넣습니다.** 리포·시드·핸드오프 어디에도 적지 않습니다.

## 3. 파일 → 리포

```powershell
$repo = "C:\dev\mbg-project"
$dl   = Join-Path $env:USERPROFILE "Downloads"
$today = "2026-09-21"

$map = @(
  @{ base = "ipo_page";                    ext = "tsx"; dest = "src\app\(app)\ipo"; name = "page.tsx" },
  @{ base = "ipo_actions";                 ext = "ts";  dest = "src\app\(app)\ipo"; name = "actions.ts" },
  @{ base = "ipo_gantt";                   ext = "tsx"; dest = "src\app\(app)\ipo"; name = "ipo-gantt.tsx" },
  @{ base = "ipo_gate_panel";              ext = "tsx"; dest = "src\app\(app)\ipo"; name = "gate-panel.tsx" },
  @{ base = "ipo_snapshot_panel";          ext = "tsx"; dest = "src\app\(app)\ipo"; name = "snapshot-panel.tsx" },
  @{ base = "ipo_milestone_status_select"; ext = "tsx"; dest = "src\app\(app)\ipo"; name = "milestone-status-select.tsx" },
  @{ base = "ipo_patents_panel";           ext = "tsx"; dest = "src\app\(app)\ipo"; name = "patents-panel.tsx" },
  @{ base = "patch_ipo_sidebar_section";   ext = "ps1"; dest = "tools\patches";     name = "patch_ipo_sidebar_section.ps1" },
  @{ base = "handoff_ipo_page_rev2";       ext = "md";  dest = "docs\handoff\$today"; name = "handoff_ipo_page_rev2.md" }
)

foreach ($m in $map) {
  $pattern = "$($m.base)*.$($m.ext)"
  $src = Get-ChildItem -Path $dl -Filter $pattern -File -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $src) { Write-Host "MISS  $pattern"; continue }
  Unblock-File -Path $src.FullName -ErrorAction SilentlyContinue
  $destDir = Join-Path $repo $m.dest
  [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
  $destPath = Join-Path $destDir $m.name
  [System.IO.File]::Copy($src.FullName, $destPath, $true)
  Write-Host "OK    $($m.base).$($m.ext) -> $($m.dest)\$($m.name)"
}
```

Downloads 에 rev.1 파일이 남아 있으면 `(1)` 붙은 최신본이 선택됩니다(LastWriteTime 기준). 확실히 하려면 옛 `ipo_*` 파일을 먼저 지우십시오.

## 4. 사이드바 패치

```powershell
powershell -ExecutionPolicy Bypass -File "C:\dev\mbg-project\tools\patches\patch_ipo_sidebar_section.ps1"
```

기대 출력 `OK    sidebar: IPO moved to its own section under Pipelines`. `SKIP` 이면 이미 적용, `FAIL` 이면 앵커가 달라진 것이니 sidebar.tsx 를 보내 주십시오. 인라인 폴백은 같은 파일 본문을 그대로 붙여넣으면 됩니다(변수 선언부터 끝까지).

## 5. 확인 · 커밋

```powershell
cd C:\dev\mbg-project
npm run typecheck        # ipo 관련 에러 0 (기존 12건은 별개)
npm run dev              # http://localhost:3000/ipo — 사이드바 Pipelines 아래 "NASDAQ IPO › IPO Readiness"
```

```powershell
git status -sb
git add "src/app/(app)/ipo" src/components/layout/sidebar.tsx `
        tools/patches/patch_ipo_sidebar_section.ps1 `
        docs/handoff/2026-09-21/handoff_ipo_page_rev2.md
git commit -m "feat(ipo): English UI, sidebar section under Pipelines, Patents tab"
git push origin marinebiogroup
```

## 6. 다음

Patents 탭에 실제 FCC 특허 패밀리를 넣으면 개요·KPI·L4 가 채워집니다. 국가별로 KR 기초특허 → US/EP/JP 대응특허 → 개량 출원 순으로 넣고, EPO TPO(2026-08-13 제출)·JP 이의신청(10/27) 은 해당 경쟁 출원이 아니라 **우리 특허의 challenge_note** 가 아닌 별도 사건이므로, L4-05 게이트 근거에 적으십시오.
