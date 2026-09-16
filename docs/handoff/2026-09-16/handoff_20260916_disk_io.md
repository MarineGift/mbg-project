# handoff_20260916_disk_io — Supabase Disk IO 예산 경고 대응

## 원인 (코드 확인 결과)
- 2026-09-15 추가된 `app.mail_folder_counts()`가 `app.communications` 전체를 폴더 노드마다 풀스캔함
  (OR 조인 + `LIKE '%@'||domain` → 인덱스 사용 불가, 메일 본문이 든 넓은 행을 계속 디스크에서 읽음).
- 사이드바(`mail-folder-nav.tsx`)가 이 RPC를 **탭마다 30초 간격** + 포커스/메일 도착 때마다 호출.
- 같은 날 대량 UPDATE/머지(웹사이트 정리, 파티 병합, 링크 백필)도 일일 IO 예산을 소모.
- 워커(mailrun 10s, sequence 60s, reminder 5m, mailcarrier IMAP IDLE)는 가벼운 편.

## 조치
1. `migration_20260916_mail_folder_counts_fast.sql`
   - inbound 전용 부분 커버링 인덱스 `idx_communications_inbound_folder` (index-only scan)
   - 함수 재작성: 동일 시그니처/동일 결과, 등호 조인(해시 조인)으로 1회 스캔
   - 로컬 PG16 검증: 41개 폴더 결과 완전 일치, 20k 행 기준 약 950ms → 53ms
   - `idx_mail_runs_active` (mailrun 10초 폴링용)
2. `patch_mail_folder_nav_poll.ps1` — 폴링 30s → 120s, 숨겨진 탭에서는 호출 안 함
3. `diag_20260916_disk_io.sql` — 읽기 전용 진단 (상위 IO 쿼리/풀스캔/테이블 크기/미사용 인덱스)

## 실행 순서
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\patches\patch_mail_folder_nav_poll.ps1
```
Supabase SQL Editor: migration 파일 → Ctrl+A → Run. 이어서 diag 파일 → Ctrl+A → Run → 결과 공유.

## 인라인 fallback (패치가 조용히 아무것도 안 할 때)
```powershell
$f = 'C:\dev\mbg-project\src\components\layout\mail-folder-nav.tsx'
$enc = New-Object System.Text.UTF8Encoding($false)
$s = [System.IO.File]::ReadAllText($f, $enc) -replace "`r`n", "`n"
$old1 = '    const timer = setInterval(load, 30_000)'
$new1 = '    const timer = setInterval(() => { if (document.visibilityState === ''visible'') load() }, 120_000)'
if ($s.Contains($new1)) { 'SKIP already patched' } elseif ($s.Contains($old1)) { $s = $s.Replace($old1, $new1).Replace('// Refresh on navigation, on a 30s timer,', '// Refresh on navigation, on a 120s timer (visible tab only),'); [System.IO.File]::WriteAllText($f, $s, $enc); 'OK patched' } else { 'ERROR anchor not found' }
```

## 커밋 / 배포
```powershell
cd C:\dev\mbg-project
git status -sb
git add src/components/layout/mail-folder-nav.tsx sql/migration_20260916_mail_folder_counts_fast.sql sql/diag_20260916_disk_io.sql tools/patches/patch_mail_folder_nav_poll.ps1 docs/handoff
git commit -m "perf: fast mail_folder_counts + slower sidebar poll (disk IO)"
git push origin marinebiogroup
```
push = Railway 자동 배포(웹 공개). SQL은 push와 별개로 Supabase에서 직접 실행해야 적용됨.

## 다음 확인
- 1~2일 뒤 경고 메일의 Disk IO(일별/시간별) 링크에서 그래프 확인.
- diag 결과에서 `2_seq_scans` 상위 테이블 → 추가 인덱스 후보.
- 대량 UPDATE/백필은 한 번에 몰지 말고 나눠 실행 (일일 예산).
- 코드 수정 후에도 예산이 계속 바닥나면 compute add-on 상향 검토.

## SaaS 표준 (유지)
RLS org-scoping, 엔티티 테이블 `created_by uuid default auth.uid()` + `created_at/updated_at`. 이번 변경은 인덱스/함수만 — 테이블 스키마 변경 없음.
