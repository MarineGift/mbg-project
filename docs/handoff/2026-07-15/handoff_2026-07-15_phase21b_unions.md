# handoff_2026-07-15_phase21b_unions.md

이전: handoff_2026-07-15_climate_tuesday_snap.md → 이 문서
작업: 미결 5번 종결 — `src/types/phase21b.ts` 유니온 2개 수정

## 변경 내용 (파일 1개, 라인 2개)

| 타입 | 변경 전 | 변경 후 |
|---|---|---|
| `SequenceStatus` | `'active' \| 'paused' \| 'archived'` | `'draft' \| 'active' \| 'paused' \| 'archived'` |
| `EnrollmentStatus` | `'active' \| 'paused' \| 'completed' \| 'cancelled'` | `... \| 'failed'` 추가 |

근거: DB에 `draft` 시퀀스와 `failed` enrollment(Planet A, 07-13 수동 은퇴 + D-1 체계화)가 실존하는데 TS 유니온이 이를 표현하지 못함. UI/워커가 이 상태를 읽는 순간 타입 불일치.

주의: 순수 타입 파일이므로 런타임 무영향. 단, 기존에 `EnrollmentStatus`를 switch-exhaustive 하게 처리하는 코드가 있으면 `'failed'` 분기 누락으로 새 tsc 오류가 생길 수 있음 — 그 오류는 **버그를 드러낸 것**이니 반갑게 수정.

## ① 유니버설 무버 (한 줄)

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

## ② 개별 인라인 무버 (fallback — 그대로 붙여넣기)

```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "patch_phase21b_status_unions*.ps1" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Host "NOT FOUND in Downloads"; exit 1 }
Unblock-File $src.FullName
$destDir = "C:\dev\mbg-project\tools\patches"
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
$dest = Join-Path $destDir "patch_phase21b_status_unions.ps1"
[System.IO.File]::Copy($src.FullName, $dest, $true)
Remove-Item $src.FullName
Write-Host "MOVED: $dest"
```

## ③ 패치 실행

```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_phase21b_status_unions.ps1
```

기대 출력:
```
[1] SequenceStatus  : PATCHED (+'draft')
[2] EnrollmentStatus: PATCHED (+'failed')
DONE: C:\dev\mbg-project\src\types\phase21b.ts written (UTF-8 no BOM, LF).
```
(두 번 돌리면 ALREADY PATCHED — 정상)

## ④ 검증

```powershell
cd C:\dev\mbg-project
npx tsc --noEmit
```
- phase21b 관련 오류 소멸 확인. 기존 15건/5파일은 그대로 남는 게 정상 (미결 7).
- `'failed'` 분기 누락으로 **새** 오류가 뜨면 해당 switch/매핑에 분기 추가 후 재실행.

## ⑤ 마무리 (finish block)

```powershell
cd C:\dev\mbg-project
git status -sb        # 변경 파일 2개 확인: src\types\phase21b.ts, tools\patches\patch_phase21b_status_unions.ps1
git add src\types\phase21b.ts tools\patches\patch_phase21b_status_unions.ps1
git commit -m "fix(types): add 'draft' to SequenceStatus, 'failed' to EnrollmentStatus (phase21b)"
git push origin marinebiogroup
```

⚠️ push = Railway 자동 배포 → urm.marinebiogroup.com 에 즉시 반영.

## 남은 미결 (이 작업 후)

1. 7/21(화) 09:00 PT 발송 40통 관찰 → 헬스 뷰 실측
2. FCC Climate Tech day_offset 0,0 지뢰
3. IP 49.254.118.167 Trend Micro delisting + SPF/DKIM/DMARC
4. 타임존 백로그 (country 백필 선행)
6. E-3 quiet-hours (하향 유지)
7. 시퀀스 이름 중복 / World Fund 8/4 감시 / Lowercarbon 이중 노출 / tsc 15건 5파일
