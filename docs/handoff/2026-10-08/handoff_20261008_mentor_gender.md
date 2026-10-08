# Handoff 2026-10-08 — Mentor gender (Male / Female / Unconfirmed) + neutral intros

## 변경
1. SQL `migration_20261008_mentor_gender.sql` — `app.mentors.gender` (male/female/unknown, 기본 unknown=미확인) + check 제약 + PostgREST reload
2. SQL `enrich_20261008_mentor_intro_neutral.sql` — 147명 소개 재입력: 영문 소개의 he/she/his/her/him 을 이름·their 로 바꿔 성별 중립화 (내용 동일). 멘토 이메일 포함 → .gitignore 로 커밋 제외됨
3. NEW `src/lib/actions/mentors.ts` — `setMentorGender(partyId, gender)` server action
4. NEW `src/components/parties/mentor-gender-toggle.tsx` — Male / Female / Unconfirmed 버튼 (즉시 저장, 실패 시 원복)
5. `src/components/parties/mentor-profile-card.tsx` — 헤더(LinkedIn/Email 아래)에 Gender 토글
6. `src/components/parties/mentor-filter-panel.tsx` + `src/app/(app)/[partyType]/parties/page.tsx` — Mentor search 에 **Gender** 드롭다운(Male / Female / Unconfirmed + 건수), URL `?m_gender=`
- 원칙: 이름으로 추정하지 않음. 본인 프로필 대명사·직접 확인 등 확인된 경우에만 Male/Female 입력
- tsc 오류 12건 = 기존 그대로

## 순서 (중요: SQL 먼저, push 나중)
1) Supabase: migration_20261008_mentor_gender.sql 실행 → unknown 147
2) Supabase: enrich_20261008_mentor_intro_neutral.sql 실행 → 147행
3) 파일 이동 + push

## Mover (inline)
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ n='mentors-actions';      e='.ts';  d='src\lib\actions';                    t='mentors.ts' },
  @{ n='mentor-gender-toggle'; e='.tsx'; d='src\components\parties';             t='mentor-gender-toggle.tsx' },
  @{ n='mentor-profile-card';  e='.tsx'; d='src\components\parties';             t='mentor-profile-card.tsx' },
  @{ n='mentor-filter-panel';  e='.tsx'; d='src\components\parties';             t='mentor-filter-panel.tsx' },
  @{ n='parties-page';         e='.tsx'; d='src\app\(app)\[partyType]\parties'; t='page.tsx' }
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
git add src/lib/actions/mentors.ts src/components/parties/mentor-gender-toggle.tsx src/components/parties/mentor-profile-card.tsx src/components/parties/mentor-filter-panel.tsx "src/app/(app)/[partyType]/parties/page.tsx" sql/migration_20261008_mentor_gender.sql docs/handoff
git commit -m "mentors: gender field (Male/Female/Unconfirmed) toggle + filter"
git push origin marinebiogroup
```
