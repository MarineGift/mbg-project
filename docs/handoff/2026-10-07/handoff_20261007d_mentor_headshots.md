# Handoff 2026-10-07d — Mentor headshots: fallback + rehost tool

## 변경
1. NEW `src/components/parties/mentor-headshot.tsx` (client)
   - 사진 URL이 없거나, airtable.com 링크이거나, 로딩 실패(onError) 시 → 졸업모자 아이콘 표시. 깨진 이미지+alt 텍스트가 더 이상 안 보임
2. `src/components/parties/mentor-profile-card.tsx` — `<img>` 블록을 `<MentorHeadshot>`로 교체
3. NEW `tools/rehost-mentor-headshots.mjs` — Airtable CSV export의 사진을 Supabase Storage `mentor-headshots`(public)로 옮기고 `app.mentors.headshot_url` 갱신
   - 매칭: 이메일 → 이름. 이미 재호스팅된 멘토는 건너뜀(`--all`로 강제), `--dry`로 미리보기
   - 파일명 `<mentor_id>.<ext>`, upsert. 버킷 없으면 생성
   - Airtable 다운로드 링크는 export 후 약 2시간이면 만료 → CSV 받자마자 실행
- DB 스키마 변경 없음. tsc 오류 12건 = 기존 그대로

## 사진 받는 방법
Greentown 담당자에게 멘토 테이블 CSV export 요청 (Name, Email, Headshot 컬럼 포함). 받으면:
```powershell
cd C:\dev\mbg-project
node --env-file=.env.local tools\rehost-mentor-headshots.mjs "$env:USERPROFILE\Downloads\<export>.csv" --dry
node --env-file=.env.local tools\rehost-mentor-headshots.mjs "$env:USERPROFILE\Downloads\<export>.csv"
```
`FAIL ... HTTP 410/403 (link expired?)` 가 나오면 CSV를 다시 export 받아 재실행.

## Mover (inline)
```powershell
$Repo = 'C:\dev\mbg-project'
$Dl   = Join-Path $env:USERPROFILE 'Downloads'
$map = @(
  @{ n='mentor-headshot';           e='.tsx';     d='src\components\parties'; t='mentor-headshot.tsx' },
  @{ n='mentor-profile-card';       e='.tsx';     d='src\components\parties'; t='mentor-profile-card.tsx' },
  @{ n='rehost-mentor-headshots';   e='.mjs.txt'; d='tools';                  t='rehost-mentor-headshots.mjs' }
)
foreach ($m in $map) {
  $hits = Get-ChildItem -LiteralPath $Dl -File | Where-Object { $_.Name -like ($m.n + '*' + $m.e) -and ($m.n -ne 'mentor-headshot' -or $_.Name -notlike 'mentor-headshots*') } | Sort-Object LastWriteTime -Descending
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
git add src/components/parties/mentor-headshot.tsx src/components/parties/mentor-profile-card.tsx tools/rehost-mentor-headshots.mjs docs/handoff
git commit -m "mentors: headshot fallback + Airtable rehost tool"
git push origin marinebiogroup
```
