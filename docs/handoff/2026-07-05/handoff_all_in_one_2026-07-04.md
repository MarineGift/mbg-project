# Handoff — 올인원: interest tags v2 + JSONB 백필 + 진단 (2026-07-04)

## 문제
`app.interest_tag_aliases` 미존재(42P01) = **v2 마이그레이션 미실행 상태에서 백필 먼저 실행**. 순서 의존성 제거를 위해 단일 파일로 통합.

## 해결: 파일 하나만 실행
`sql/fix_interest_tags_all_in_one.sql` — **선행 조건 없음, 순서 없음, 멱등.**
- [A] v2 전체: 테이블(aliases 포함)·RLS·정식 태그 22종·동의어 병합(deep_tech_seed→deep_tech)·wave2~6 배정
- [B] JSONB 레거시 백필: `parties.interest_tags` → 정규화 테이블 (+백필로 유입된 동의어 재병합)
- [C] 진단: 분포 / 미매핑(900) / **wave4 존재 체크** (found=false면 wave4 시드 실행)

이전 파일 3종(v1, v2, fix_backfill_jsonb)은 이 파일로 대체 — sql\에서 정리 권장.

## 실행
1. 다운로드 → mover:
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
2. Supabase SQL Editor에서 `fix_interest_tags_all_in_one.sql` **한 번 실행**
3. 결과 확인: C1에서 deep_tech_seed 소멸 + deep_tech ≥ 18 / C3에서 found=false 있으면 wave4 시드 실행 후 이 파일 재실행(멱등)

## 개별 mover (예비용)

```powershell
$dl = Join-Path $env:USERPROFILE 'Downloads'
$src = Get-ChildItem -Path $dl -Filter 'fix_interest_tags_all_in_one*.sql' |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Output 'ERROR: file not found in Downloads'; return }
Unblock-File -Path $src.FullName
$destDir = 'C:\dev\mbg-project\sql'
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
$dest = Join-Path $destDir 'fix_interest_tags_all_in_one.sql'
[System.IO.File]::Copy($src.FullName, $dest, $true)
Remove-Item -Path $src.FullName -Force
Write-Output ('MOVED: ' + $dest)
```

## Finish block

```powershell
cd C:\dev\mbg-project
Remove-Item -LiteralPath 'sql\migration_interest_tags_normalize.sql','sql\migration_interest_tags_normalize_v2.sql','sql\fix_backfill_interest_tags_jsonb.sql','sql\backfill_interest_tags_from_parties_column.sql' -ErrorAction SilentlyContinue
git status -sb
git add sql/ "src/app/(app)/[partyType]/parties/page.tsx" tools/
git commit -m "feat(db): interest tags all-in-one (v2 + jsonb backfill + diagnostics); TAGS UI sort+dropdown; universal mover"
git push origin marinebiogroup
```

> push = Railway 자동 배포. 커밋 전 `git status -sb`로 스테이징 확인.
