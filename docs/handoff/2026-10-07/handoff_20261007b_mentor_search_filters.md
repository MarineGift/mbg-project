# Handoff 2026-10-07b — Mentors 다중 검색 조건

## 변경
1. NEW `src/components/parties/mentor-filter-panel.tsx` (client)
   - **Keyword** 검색: 이름·직함·회사·Bio·Why I Mentor·위치·모든 태그에서 검색. 단어 여러 개는 모두 포함(AND). 예: `paper materials`
   - **드롭다운 9종** (체크박스 + 건수, 옵션 8개 넘으면 옵션 내 검색):
     Expertise / Climatetech sector / Technologies / Product types / Startup stage / Availability /
     Engagement(In-person·Virtual·No preference) / Location(Boston·Texas/Houston·Canada·New York·Remote·Other) / MBG relevance(High·Medium·Low)
   - 같은 카테고리 안은 OR, 카테고리끼리는 AND. 선택 조건은 칩으로 표시, 개별 X / Clear all
   - 결과 건수 표시, URL 파라미터 기반이라 링크 공유·Saved view·페이지 이동 시 유지
2. `src/app/(app)/[partyType]/parties/page.tsx`
   - mentor 디렉토리에서만 `app.mentors` 전체 프로필 로드 → facet 생성 + 메모리 필터
   - URL: `mq`, `m_exp`, `m_sec`, `m_tech`, `m_prod`, `m_stage`, `m_avail`, `m_eng`, `m_loc`, `m_tier` (반복 가능)
   - mentor는 항상 메모리 경로 → 기본 MBG relevance 정렬이 확실히 적용, 건수(147 parties)가 필터 결과로 정확히 표시
   - 컬럼 정렬 링크가 relevant/greentown/멘토 필터를 유지
   - Expertise·Sector·Technologies·Product types는 2명 이상인 값만 옵션에 표시 (1명뿐인 자유기술 값은 Keyword로 검색)
- DB 변경 없음. tsc 오류 12건 = 기존 그대로 (신규 0)

## Mover (inline, PowerShell 붙여넣기)
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ n='parties-page';        e='.tsx'; d='src\app\(app)\[partyType]\parties'; t='page.tsx' },
  @{ n='mentor-filter-panel'; e='.tsx'; d='src\components\parties';            t='mentor-filter-panel.tsx' }
)
foreach ($m in $map) {
  $hits = Get-ChildItem -LiteralPath $Dl -File | Where-Object { $_.Name -like ($m.n + '*' + $m.e) } | Sort-Object LastWriteTime -Descending
  if (-not $hits) { Write-Output ('MISS  ' + $m.n + $m.e); continue }
  $src = $hits[0]
  Unblock-File -LiteralPath $src.FullName -ErrorAction SilentlyContinue
  $destDir = Join-Path $Repo $m.d
  [System.IO.Directory]::CreateDirectory($destDir) | Out-Null
  $dest = Join-Path $destDir $m.t
  [System.IO.File]::Copy($src.FullName, $dest, $true)
  $hits | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
  Write-Output ('MOVED ' + $src.Name + ' -> ' + $dest)
}
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

## Push
```powershell
cd C:\dev\mbg-project
git status -sb
git add "src/app/(app)/[partyType]/parties/page.tsx" src/components/parties/mentor-filter-panel.tsx docs/handoff
git commit -m "mentors: multi-criteria search (keyword + 9 facet filters)"
git push origin marinebiogroup
```
push 거부(non-fast-forward) 시: `git pull --rebase origin marinebiogroup` 후 다시 push.
