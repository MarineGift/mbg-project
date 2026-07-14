# Handoff — Climate Investor Email Sequence (2026-07-13)

## 파일
- `20260713140000_climate_investor_sequence_create.sql` → repo `sql/`
- "Climate Investor Cold Outreach -- FCC" 시퀀스 생성 + climate 섹터 투자자 자동 일괄 등록
- 4-step: Day 0 (임팩트) · Day 4 (마켓 산수) · Day 9 (방어성/모트) · Day 15 (브레이크업)
- 병합 토큰: `{{contact.firstName}}` · 발송 전 `v_from_account_id` 확인 필수

## 실행 방법 (2가지 중 택1)
**A. Supabase SQL Editor** — 파일 전체를 붙여넣고 실행. NOTICE 로그 확인 후, 하단 검증쿼리 A~D 결과 확인.
**B. repo에 커밋 보관** — 아래 mover로 repo에 넣고 git push (SQL 자체는 push로 실행되지 않음, DB 반영은 A로).

## 사전 확인
1. `v_from_account_id`(기본값 = 기존 시퀀스와 동일 계정)가 발송하려는 계정이 맞는지.
2. 덱 커버가 아직 "June 2026"이면 발송 전 July로 수정.
3. 검증쿼리 D로 **이메일 없는 climate 투자자**를 먼저 확인 → 백필 후 재실행하면 등록됨(멱등).

## 파일 이동 (Downloads → repo `sql/`) — 그대로 복사·붙여넣기
```powershell
$base = '20260713140000_climate_investor_sequence_create'
$dl   = Join-Path $env:USERPROFILE 'Downloads'
$src  = Get-ChildItem -Path $dl -Filter "$base*.sql" -File |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Error "No $base*.sql in $dl"; return }
Unblock-File -Path $src.FullName
$destDir = 'C:\dev\mbg-project\sql'
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
$dest = Join-Path $destDir "$base.sql"
[System.IO.File]::Copy($src.FullName, $dest, $true)
if ($src.FullName -ne $dest) { Remove-Item -LiteralPath $src.FullName -Force }
Write-Host "Moved -> $dest"
```

## Finish (commit + push = 웹 자동 배포)
> push 하면 marinebiogroup 브랜치가 웹에 배포됩니다. 커밋 전 `git status -sb` 권장.
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/20260713140000_climate_investor_sequence_create.sql
git commit -m "sql: climate investor email sequence (4-step) + auto-enroll by climate sector"
git push origin marinebiogroup
```

## 발송 흐름 (등록 후)
- 시퀀스 워커가 `next_send_at` 기준으로 Day 0/4/9/15 자동 발송 (기존 워커/발신자 선택 로직 그대로).
- Quiet-hours / 오픈 트래킹 / 바운스 suppression 기존 설정 적용됨.
- 회신이 오면 해당 enrollment는 워커에서 stop 처리(기존 동작).

## 등록 대상 로직
`parties → investor_profile → investor_sector_focus → sectors.code='climate'` 인 투자자 중 이메일 있는 곳 전부. 이미 active/completed면 중복 등록 안 함(멱등).
