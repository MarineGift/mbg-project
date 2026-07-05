# Handoff — 투자사 중복 탐지 v2 (GROUP BY 수정) (2026-07-04)

## 수정
`ERROR 42803 norm.party_name must appear in GROUP BY` — 정규화 키로 그룹핑하면서 원본 party_name을 그대로 select해서 발생. v2는 **계산 키를 서브쿼리에서 만들고**(key_name/domain/email/base), 바깥 쿼리는 그 키로 GROUP BY + 나머지는 전부 array_agg → 에러 해소.

## 파일: `sql/fix_investor_dupe_detect_v2.sql` (READ ONLY, 4개 결과셋)
(기존 v1 대체 — sql\에서 v1 삭제 권장)

| # | 탐지 | 예시 |
|---|---|---|
| A | 법인접미사 제거 후 **완전 동일** | 8VC / 8VC, **Accel** / Accel Management Company LLC (접미사 management·llc 제거 시 동일) |
| B | **동일 website 도메인** | 같은 회사 다른 표기 |
| C | **동일 email** | |
| D | 로마숫자·펀드번호까지 제거한 **base 동일** | 5AM Ventures / 5AM Ventures II (→ website·city로 별개펀드 여부 판단) |

스크린샷의 Accel vs Accel Management Company, LLC 는 A(또는 D)에서 잡혀야 정상 — 둘 다 Palo Alto/California/VC라 병합 유력 후보입니다.

## 실행 & 회신
1. `powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1`
2. Supabase에서 실행 → 4개 결과셋 각각 CSV Export
3. 회신 주시면 → 진짜 중복만 확정 → 병합 SQL(2단계) 생성

## 병합 시 규칙 (2단계 예고)
- canonical = ids 배열 첫 번째(profile 있음 우선 → 오래된 것)
- 자식 관계(deals/engagements/tasks/mail/sector_focus/interest_tags 등) 전부 canonical로 재지정 후 중복행 **soft-delete**(deleted_at) — hard-delete 안 함
- 정보 병합: canonical의 빈 필드(website/email/city/intro 등)를 중복행 값으로 보충

## 개별 mover (예비)
```powershell
$dl = Join-Path $env:USERPROFILE 'Downloads'
$src = Get-ChildItem -Path $dl -Filter 'fix_investor_dupe_detect_v2*.sql' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Output 'ERROR: not found'; return }
Unblock-File -Path $src.FullName
$destDir = 'C:\dev\mbg-project\sql'
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
[System.IO.File]::Copy($src.FullName, (Join-Path $destDir 'fix_investor_dupe_detect_v2.sql'), $true)
Remove-Item -Path $src.FullName -Force; Write-Output 'MOVED'
```
