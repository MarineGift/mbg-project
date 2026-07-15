# handoff_2026-07-15_unions_and_landmine.md

이전: handoff_2026-07-15_climate_tuesday_snap.md → 이 문서
상태: DB/리포/문서 정합. 미해명 0건. tsc 15건/5파일 = 기준선 (이번 세션 증감 0).

## 완료 (커밋 4개)

- **[미결 5 종결] TS 유니온 3개 ↔ DB enum 완전 일치** (9b6288f, 1063b43)
  - `SequenceStatus` +'draft' / `EnrollmentStatus` +'failed' / `SequenceSendStatus` +'pending' +'bounced'
  - DB 실측으로 확정: `app.email_sequence_status` 4값, `app.enrollment_status` 5값, `app.send_status` 5값 — 전부 TS와 1:1.
  - 유니온 수정이 숨은 UI 공백을 노출 → `party-sequence-panel.tsx` STATUS_CONFIG에 `failed` 뱃지 추가 (9408269).
    failed enrollment(Planet A류)가 패널에 떠도 이제 안 깨진다.
- **[미결 2 종결] FCC Climate Tech day_offset 0,0 지뢰 제거** (fd23f25 + DB 적용·검증)
  - 근본 원인: step_order=1의 day_offset이 7 대신 0으로 입력된 오타.
    형제 시퀀스 FCC Seed(922b57e2)의 0/7/14/21이 의도 패턴을 증명.
  - 이중 제거: ① status → archived (뇌관), ② offset 0→7 (폭약). 부활시켜도 안전.
  - 검증 완료: 81a3cd10 = archived, 0/7/14/21.
- **[미결 7 일부] 종결 시퀀스 2개 아카이브** (같은 fix SQL §3, DB 적용·검증)
  - "15 min..." active본(151d5454, 전원 terminal 31건) + Intel Inside(ceccfb05, 전원 completed 9건) → archived.
  - **active 시퀀스는 이제 정확히 1개**: Climate Investor Cold Outreach -- FCC (63737c08, 0/7/14/21, 무손상).

## 핵심 발견 (다음 세션 주의)

1. **step_order 기수 혼재**: 시퀀스마다 0-기반(FCC Climate Tech/Seed/15min/High Priority)과
   1-기반(Climate--FCC, Intel Inside)이 섞여 있다. `step_order > 1` 같은 조건은 지뢰 탐지를 놓친다
   (이번 세션 LANDMINE 플래그가 실제로 놓쳤음). 항상 `LAG(...) IS NOT NULL` 기준으로.
2. **enum typname**: 시퀀스 status의 타입명은 `sequence_status`가 아니라 **`email_sequence_status`**.
   `email_sequences.status`/`enrollments.status`/`sends.status` 전부 enum (CHECK는 stage21에서 DROP됨).
3. `enrollment_status`에 text 리터럴 COALESCE 시 22P02 — `e.status::text`로 풀 것.

## 다음 발송 (변동 없음)

7/21(화) 09:00 PT = 16:00 UTC, Climate step 2, 40통. 워커 자동(60초 폴링). 발송 후 헬스 뷰 실측.
이후 7/28 62통(step3 22 + 40), 8/4 62통.

## 미결 (갱신)

1. 7/21 09:00 PT 발송 관찰 (40통) → 헬스 뷰 실측
2. ~~FCC Climate Tech day_offset 0,0~~ **종결** (fd23f25)
3. IP 49.254.118.167 Trend Micro delisting + SPF/DKIM/DMARC
4. 타임존: 09:00 PT = 유럽 18:00 / 도쿄 01:00. app.parties에 country 없음(42703) → 백필 선행. 백로그
5. ~~phase21b.ts 유니온~~ **종결** (9b6288f, 9408269, 1063b43 — 유니온 3개 + UI 공백)
6. E-3 quiet-hours 무방비 쓰기 = 우선순위 하향 유지
7. 시퀀스 이름 중복 → **아카이브로 실질 해소** (active 1개만 잔존). World Fund 8/4 재개 감시 /
   Lowercarbon 이중 노출 / tsc 15건 5파일은 잔존

## 파일 배치

이 문서: `docs\handoff\2026-07-15\handoff_2026-07-15_unions_and_landmine.md`

유니버설 무버 한 줄:
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```

인라인 fallback:
```powershell
$src = Get-ChildItem "$env:USERPROFILE\Downloads" -Filter "handoff_2026-07-15_unions_and_landmine*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $src) { Write-Host "NOT FOUND in Downloads"; exit 1 }
Unblock-File $src.FullName
$destDir = "C:\dev\mbg-project\docs\handoff\2026-07-15"
[System.IO.Directory]::CreateDirectory($destDir) | Out-Null
$dest = Join-Path $destDir "handoff_2026-07-15_unions_and_landmine.md"
[System.IO.File]::Copy($src.FullName, $dest, $true)
Remove-Item $src.FullName
Write-Host "MOVED: $dest"
```

마무리:
```powershell
cd C:\dev\mbg-project
git status -sb
git add docs\handoff\2026-07-15\handoff_2026-07-15_unions_and_landmine.md
git commit -m "docs: session handoff - union/enum alignment + FCC Climate Tech landmine defusal"
git push origin marinebiogroup
```
push = Railway 자동 배포 (문서만, 실동작 무변).
