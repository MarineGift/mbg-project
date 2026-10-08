# Handoff 2026-10-07 — 멘토 리스트 업데이트 (Mentors_2026.xlsx)

## 내용
Greentown Labs 멘토 export `Mentors_2026.xlsx` (147명, 전원 Accept)를 URM 멘토 DB에 반영.
- SQL 2개 (순서대로 실행, pglast 검증):
  - `sql/backfill_20261007a_mentors_2026_stage.sql` — 스테이징 적재 (데이터는 base64 JSON)
  - `sql/backfill_20261007b_mentors_2026_apply.sql` — 반영 + 스테이징 drop
- 1차 단일 파일은 42P01 실패: Bio 문자열 안의 from/into/where 단어를 Supabase 에디터가 문장 경계로 오인 → base64로 해결
- DB 스키마 변경 없음, 프런트 변경 없음

## SQL이 하는 일
1. 스테이징 테이블 `app.stg_mentor_import_20261007` 생성 → 147행 적재 (실행 끝에 drop)
2. 신규 멘토 (기존 app.mentors에 이메일/이름 없음) → mentor party + mentors row 생성
3. 전체 147명 프로필 업데이트 (이메일 우선, 없으면 이름 매칭):
   title, company, notes(Bio), why_mentor, expertise(+Other 자유기술), sector_focus, product_types,
   technologies, startup_stage_focus, availability, preferred_engagement, location, linkedin_url
   - 빈 값은 기존 데이터를 지우지 않음 (coalesce)
   - LinkedIn: `https://www.linkedin.com/in/...` 로 정규화. `/in/` 없는 잘못된 URL(Adam de Sola Pool, Sankhadeep Sarkar, Tony Paradiso)은 기존 값 유지
4. 이메일 contact 없으면 생성, 기존 contact의 빈 phone/title/linkedin 채움
5. Greentown Labs Houston `has_mentor` 링크 + `Greentown Labs Houston` interest tag
- 헤드샷은 건드리지 않음 (export는 Airtable 링크, 기존 것은 Storage로 재호스팅됨). 신규 멘토 헤드샷은 필요 시 별도 재호스팅
- DB에 있는데 export에 없는 멘토는 그대로 둠 (비활성화 안 함)
- 미반영: 심사 내부 데이터(red flags, AI 점수, reviewer), 고객 유형, 참여 형태(engagement types) — 필요하면 컬럼 추가

## 실행
Supabase SQL Editor → a 파일 전체 Ctrl+A → Run (staged_rows = 147 확인) → 에디터 비우고 b 파일 전체 Ctrl+A → Run.
VERIFY 기대값: mentor_profiles >= 147, profiles_updated_now ~147, mentors_without_party = 0,
greentown_links >= mentor_profiles 수, with_technologies / with_why_mentor 대폭 증가.

## 주의 (Public repo)
SQL 파일에 멘토 147명 이메일·전화번호가 들어 있음 → **Git에 커밋하지 않음**. 로컬 `sql\`에만 보관.

## Mover (inline, PowerShell 붙여넣기)
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
fallback:
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ n='backfill_20261007a_mentors_2026_stage'; e='.sql'; d='sql'; t='backfill_20261007a_mentors_2026_stage.sql' },
  @{ n='backfill_20261007b_mentors_2026_apply'; e='.sql'; d='sql'; t='backfill_20261007b_mentors_2026_apply.sql' },
  @{ n='handoff_20261007_mentors_2026_update'; e='.md'; d='docs\handoff\2026-10-07'; t='handoff_20261007_mentors_2026_update.md' }
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
```

## Push (handoff만)
```powershell
cd C:\dev\mbg-project
git status -sb
git add docs/handoff/2026-10-07/handoff_20261007_mentors_2026_update.md
git commit -m "docs: mentor list update from Mentors_2026.xlsx"
git push origin marinebiogroup
```
push 거부(non-fast-forward) 시: `git pull --rebase origin marinebiogroup` 후 다시 push.
