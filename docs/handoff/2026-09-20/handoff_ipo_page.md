# URM `/ipo` 페이지 — 핸드오프

**대상**: MarineBio Group Inc. / mbg-project (Next 14 · React 18 · Supabase)
**선행**: `migration_ipo_module.sql`, `seed_ipo_module.sql`, `seed_ipo_advisor_pipeline.sql` 적용 완료 (2026-09-20 확인)
**검증**: 6개 TS 파일 `tsc --strict` 통과 (Next/Supabase 스텁 기준). 리포 안에서는 `npm run typecheck` 로 최종 확인

---

## 1. 무엇이 생기나

사이드바에 **IPO** 메뉴. `/ipo` 아래 탭 4개:

| 탭 | 내용 | 입력 |
|---|---|---|
| 개요 | 6레벨 판정 · 미측정/미달/지연 카운트 · 단계 진척 · Conservative vs 실적 · 원장 vs GAAP · 판정 기록 | 판정 기록(분기/Gate1-3) |
| 일정 | 간트 — 66 마일스톤, 관문 ◆, 판정 창, IPO 창, 오늘선, 워크스트림 필터, 선행 강조 | 마일스톤 상태(행마다 셀렉트) |
| 판정 게이트 | L1–L6 게이트 28개, 연결 마일스톤 완료율 힌트, 사람이 verdict + 근거 입력 | 게이트 판정 |
| 요건·KPI | 법정요건 17 (대체·상향 접힘) · 내부 KPI 7 · **스냅샷 입력 폼** | metric 스냅샷 |

DB 원칙이 화면에도 그대로 있습니다: 숫자는 스냅샷 폼으로만 들어가고, 게이트는 근거 없이 판정할 수 없고(`unknown` 외에는 evidence 필수 — 서버·DB 양쪽 제약), 완료(`done`)로 바꾸면 `actual_date` 가 자동으로 오늘로 찍힙니다.

## 2. 파일

| 파일 | 리포 경로 |
|---|---|
| `ipo_page.tsx` | `src\app\(app)\ipo\page.tsx` |
| `ipo_actions.ts` | `src\app\(app)\ipo\actions.ts` |
| `ipo_gantt.tsx` | `src\app\(app)\ipo\ipo-gantt.tsx` |
| `ipo_gate_panel.tsx` | `src\app\(app)\ipo\gate-panel.tsx` |
| `ipo_snapshot_panel.tsx` | `src\app\(app)\ipo\snapshot-panel.tsx` |
| `ipo_milestone_status_select.tsx` | `src\app\(app)\ipo\milestone-status-select.tsx` |
| `patch_ipo_sidebar_nav.ps1` | `tools\patches\` (실행용) |
| `handoff_ipo_page.md` | `docs\handoff\2026-09-20\` |

파일명 접두사가 달라지는 이유: 다운로드 폴더에서 `page.tsx` 같은 이름은 충돌하므로 `ipo_` 접두사로 받고, 무버가 리포 안의 실제 이름으로 놓습니다.

## 3. 코드 관례

- 테이블·뷰 접근은 `reports/page.tsx` 와 같은 `.schema('app').from('xxx' as never)` + 결과 캐스트. `database.ts` 재생성 불필요.
- 뷰는 `security_invoker` 라 JWT 의 `organization_id` 로 자동 격리. 페이지에서 org 필터 없음.
- 서버 액션은 `revalidatePath('/ipo')`. 스냅샷은 `UNIQUE(metric_id, as_of)` 에 맞춰 `upsert` — 같은 날짜 재입력은 덮어쓰기.
- React 18 이라 `startTransition(async)` 대신 수동 pending. 비동기 섹션 컴포넌트는 `await Overview(...)` 로 호출(Next 14 + React 18 타입 제약).
- 간트는 `v_ipo_gantt` 행 그대로 그립니다. 마일스톤 `id` 는 뷰에 없어서 `ipo_milestones(id, code)` 를 따로 읽어 code 로 붙입니다.

## 4. 파일 이동 — 인라인 무버

`.tsx/.ts` 는 유니버설 무버의 접두사 규칙에 없으므로 이 블록을 씁니다. `.ps1` 과 `.md` 도 같이 처리합니다.

```powershell
$repo = "C:\dev\mbg-project"
$dl   = Join-Path $env:USERPROFILE "Downloads"
$today = "2026-09-20"

$map = @(
  @{ base = "ipo_page";                    ext = "tsx"; dest = "src\app\(app)\ipo"; name = "page.tsx" },
  @{ base = "ipo_actions";                 ext = "ts";  dest = "src\app\(app)\ipo"; name = "actions.ts" },
  @{ base = "ipo_gantt";                   ext = "tsx"; dest = "src\app\(app)\ipo"; name = "ipo-gantt.tsx" },
  @{ base = "ipo_gate_panel";              ext = "tsx"; dest = "src\app\(app)\ipo"; name = "gate-panel.tsx" },
  @{ base = "ipo_snapshot_panel";          ext = "tsx"; dest = "src\app\(app)\ipo"; name = "snapshot-panel.tsx" },
  @{ base = "ipo_milestone_status_select"; ext = "tsx"; dest = "src\app\(app)\ipo"; name = "milestone-status-select.tsx" },
  @{ base = "patch_ipo_sidebar_nav";       ext = "ps1"; dest = "tools\patches";     name = "patch_ipo_sidebar_nav.ps1" },
  @{ base = "handoff_ipo_page";            ext = "md";  dest = "docs\handoff\$today"; name = "handoff_ipo_page.md" }
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

## 5. 사이드바 패치

한 줄:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\dev\mbg-project\tools\patches\patch_ipo_sidebar_nav.ps1"
```

인라인 폴백 (PS 5.x 에서 `-File` 이 조용히 아무것도 안 할 때):

```powershell
$path = "C:\dev\mbg-project\src\components\layout\sidebar.tsx"
$s = [System.IO.File]::ReadAllText($path).Replace("`r`n", "`n"); $orig = $s
if ($s -notmatch "Landmark,") { $s = $s.Replace("  BarChart3,`n} from 'lucide-react';", "  BarChart3,`n  Landmark,`n} from 'lucide-react';") }
$r = "  { href: '/reports',  labelKey: 'reports',   icon: BarChart3, label: 'Reports' },"
$i = "  { href: '/ipo',      labelKey: 'ipo',       icon: Landmark,  label: 'IPO' },"
if ($s -notmatch "href: '/ipo'") { $s = $s.Replace($r, $r + "`n" + $i) }
if ($s -eq $orig) { Write-Host "SKIP  already patched" } else { [System.IO.File]::WriteAllText($path, $s); Write-Host "OK    sidebar patched" }
```

`label: 'IPO'` 를 명시했으므로 next-intl 메시지 파일은 건드리지 않습니다.

## 6. 확인

```powershell
cd C:\dev\mbg-project
npm run typecheck
npm run dev
```

`http://localhost:3000/ipo` — 개요 탭에 6레벨 전부 `incomplete`, 미측정 12, 열린 관문 38 이 보이면 정상. 일정 탭에서 `F-IP-03 JP 이의신청` 을 `완료` 로 바꿔보면 간트 막대가 흐려지고 개요의 P0 완료 수가 1이 됩니다.

## 7. 마무리

```powershell
cd C:\dev\mbg-project
git status -sb
git add "src/app/(app)/ipo" src/components/layout/sidebar.tsx `
        tools/patches/patch_ipo_sidebar_nav.ps1 `
        docs/handoff/2026-09-20/handoff_ipo_page.md
git commit -m "feat(ipo): /ipo 페이지 - 대시보드·간트·게이트 판정·스냅샷 입력"
git push origin marinebiogroup
```

`push` 는 Railway 자동 배포를 트리거합니다. 이 페이지 코드에는 UUID·특허·요율이 없으니 그대로 커밋해도 됩니다.

## 8. 남은 것 (이번 범위 밖)

- 특허 입력 화면 — `patents` 는 SQL Editor 로 입력. 실제 특허번호는 리포에 넣지 않으므로 화면이 있어야 편해집니다.
- 로열티 정산 원장 입력 화면 — 2027 Q3 첫 정산 전까지는 불필요.
- 자문사 파티 ↔ 마일스톤 연결(`ipo_milestone_parties`) 화면 — 2028 H2 주간사 롱리스트 때.
