\xef\xbb\xbf# Handoff 2026-10-05 — Pipeline 보드 검색 + 피드백 붙여넣기 일괄 업데이트

## 문제
Investors 보드(280 deals)에서 특정 투자사를 찾기 어렵고, 투자사 피드백(Pass 등)을 하나씩 열어 단계 이동 + 메모 기록해야 했음.

## 변경
1. **보드 검색창** (헤더, `Search investor / deal`)
   - deal 이름 또는 deal에 연결된 회사 이름으로 즉시 필터 (Kanban / Calendar / Gantt 모두 적용, Esc = 지우기)
2. **Bulk update 버튼** → 피드백 붙여넣기 모달 (NEW `bulk-update-modal.tsx`)
   - 한 줄에 한 투자사: `이름: 피드백` (번호 `1.` / `-` 허용, 줄바꿈 이어쓰기는 앞 투자사 메모에 합쳐짐)
   - **Match investors** → 줄마다 보드의 deal과 매칭 (가장 최근 활동 deal 1개 기본 체크, 여러 개면 체크박스로 선택)
   - 단계 자동 추정: passing / not a fit / outside their scope / declined → **Passed**, on hold / revisit → Hold, meeting → Meeting, 그 외 = 단계 유지
   - 이름 칸 수정 후 포커스 아웃 → 재검색. 단계·메모도 수정 가능
   - **Apply** → 단계 이동 + deal 타임라인에 note(`Investor feedback - moved to Passed`, 전문은 notes) 기록, last_activity_at 갱신
3. NEW server action `bulkUpdateDeals` (`pipelines/[code]/actions.ts` 끝에 추가)
   - engagement type: code `note` 우선, 없으면 첫 active type
   - party_id = lead company (회사 화면에도 기록 노출), stage_id_at_time = 최종 단계
   - 행별 독립 처리, 실패는 행 옆에 빨간 글씨로 표시
- DB 변경 없음 (SQL 불필요). tsc: 신규 오류 0 (기존 12건 그대로)

## 이번 피드백 적용 방법 (배포 후)
Investors 보드 → **Bulk update** → 아래 붙여넣기 → Match investors → 확인 → Apply
```
1. InnoEnergy: passing, as they don't have sector expertise in pulp and paper. They also shared some feedback on the deck, noting the slides were a bit hard to track and the ordering was unclear. Worth a look as you finalize the updated version.
2. Evergreen Climate Innovations: outside their geographic scope, though they mentioned it would otherwise be interesting for them.
3. Diamond Edge Ventures: not a fit for their parent company, Mitsubishi Chemical, as MarineBio's materials supply chain doesn't overlap with theirs.
```
- 3건 모두 Passed로 자동 추정됨. 매칭 안 되면(노란 경고) 이름을 짧게 (예: `Diamond Edge`) 수정해서 재검색

## TODO
- InnoEnergy 덱 피드백(슬라이드 흐름/순서 불명확) → 덱 업데이트 시 반영

## Mover (inline, PowerShell 붙여넣기)
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ n='kanban-client';          e='.tsx'; d='src\app\(app)\pipelines\[code]'; t='kanban-client.tsx' },
  @{ n='bulk-update-modal';      e='.tsx'; d='src\app\(app)\pipelines\[code]'; t='bulk-update-modal.tsx' },
  @{ n='pipeline-board-actions'; e='.ts';  d='src\app\(app)\pipelines\[code]'; t='actions.ts' }
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
git add "src/app/(app)/pipelines/[code]/kanban-client.tsx" "src/app/(app)/pipelines/[code]/bulk-update-modal.tsx" "src/app/(app)/pipelines/[code]/actions.ts" docs/handoff
git commit -m "pipelines: board search + bulk update from pasted investor feedback"
git push origin marinebiogroup
```
push 거부(non-fast-forward) 시: `git pull --rebase origin marinebiogroup` 후 다시 push.
