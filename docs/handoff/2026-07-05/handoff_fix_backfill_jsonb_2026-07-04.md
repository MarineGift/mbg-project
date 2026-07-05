# Handoff — 백필 JSONB 수정 + 커밋 재시도 (2026-07-04)

## 진단
1. **ERROR 42883 `unnest(jsonb)`**: `parties.interest_tags`는 text[]가 아닌 **jsonb** (TS 타입 string[]과 불일치, page.tsx의 jsonb 방어 주석과 일치). → `jsonb_array_elements_text` + `jsonb_typeof` 가드로 수정.
2. **커밋 무산**: `git add`에 존재하지 않는 `docs/handoff/2026-07-04/`가 포함 → pathspec 에러로 add 전체 중단 → 스테이징 0 → push no-op. **패치 7/7 + 빌드는 성공 상태.**

## 파일
- `sql/fix_backfill_interest_tags_jsonb.sql` (기존 backfill 파일 대체 — 기존 파일은 삭제 권장)

## 실행 순서
1. 파일 다운로드 후 범용 mover 실행 (fix_*.sql → sql\ 자동 라우팅):
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
2. Supabase SQL Editor에서 `fix_backfill_interest_tags_jsonb.sql` 실행 → (3) 미매핑 리포트 / (4) 분포 확인
3. 아래 커밋 재시도 블록 실행

## 개별 mover (예비용)

```powershell
$dl = Join-Path $env:USERPROFILE 'Downloads'
$src = Get-ChildItem -Path $dl -Filter 'fix_backfill_interest_tags_jsonb*.sql' |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Output 'ERROR: file not found in Downloads'; return }
Unblock-File -Path $src.FullName
$destDir = 'C:\dev\mbg-project\sql'
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
$dest = Join-Path $destDir 'fix_backfill_interest_tags_jsonb.sql'
[System.IO.File]::Copy($src.FullName, $dest, $true)
Remove-Item -Path $src.FullName -Force
Write-Output ('MOVED: ' + $dest)
```

## 커밋 재시도 (finish block — 존재하는 경로만 add)

```powershell
cd C:\dev\mbg-project
Remove-Item -LiteralPath 'sql\backfill_interest_tags_from_parties_column.sql' -ErrorAction SilentlyContinue
git status -sb
git add "src/app/(app)/[partyType]/parties/page.tsx" sql/fix_backfill_interest_tags_jsonb.sql tools/
git commit -m "feat(directory): TAGS sort + dropdown, ascending chips; fix backfill for jsonb interest_tags; universal mover"
git push origin marinebiogroup
```

> `tools/`에 move-downloads.ps1를 설치했다면 이번 커밋에 함께 포함됩니다. push = Railway 자동 배포.
