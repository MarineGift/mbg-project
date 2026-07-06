# Handoff — Batch 9c-2 (US 잔여 14곳) 완료 (2026-07-06)

## 결과: 확정 3 / 리뷰 2 / form-only 9 — **9c 전체 트랙 종결**

**확정 (SQL 적용):**
| Firm | Email | 근거 |
|---|---|---|
| Osage University Partners | info@oup.vc | 공식 contact 페이지 (최고 등급) |
| Obvious Ventures | info@obvious.com | PEI+Crunchbase+가이드 3중, world-positive 테마 fit |
| Overture VC | info@overture.vc | Crunchbase (climate·industrial, Boundary Stone 정책지원) |

**리뷰 2 (주석):** Compound `info@compound.vc`(공식 사이트에 이메일 존재하나 마스킹 — local part 추정, 요검증) · Humba(**GP Leo Polovets 본인이 "pitch 이메일은 내 LinkedIn에 공개"라고 언급 — LinkedIn에서 주소 확보 필요**, 콜드 수용적 하우스)

**form-only 9 (폼 제출 가치 높은 순):**
1. **Ponderosa** — oceans·forestry 전문, 15일 의사결정 폼 = **최상급 fit, 최우선 제출 권장**
2. **Refactor** — 폼이 solo GP inbox 직행 (Solugen 백커)
3. **1955 Capital** — sustainable manufacturing + 아시아 bridging (LanzaTech 계열 투자)
4. Seabird(SOA ocean 펀드) · Overlay(2026 waste&materials 펀드) · Third Sphere(deck 폼) · Fine Structure(F-Prime 산하) · Innovation Endeavors · ADM Ventures

**⚠ 이름충돌 함정 (절대 사용 금지):** `marco@adm-ventures.com`(스위스 자문사) · `seabirdventures@gmail.com`(알래스카 보트투어)

## 실행
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
Supabase에서 `enrich_batch9c2_us_emails.sql` 실행 → 검증 SELECT **6행** (contact 3 + whitelist 3). 매칭은 이름 패턴 + investor_profile 존재 조건 (wave source 문자열 비의존).

## 9a~9c 누적 현황
- 콜드 이메일 확보: 9a 9 + 9c-1 8 + 9c-2 3 = **확정 20** (+리뷰 12건 대기)
- form-only 문서화: ~21곳 → 웜인트로/폼 트랙으로 분리
- 다음 정리 후보: 리뷰 12건 2차 출처 일괄 확인 세션

## 커밋 (finish block)
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/enrich_batch9c2_us_emails.sql "docs/handoff/$(Get-Date -Format 'yyyy-MM-dd')/handoff_batch9c2_us.md"
git commit -m "feat(investors): batch 9c-2 US residual emails (3 applied, 2 review, 9 form-only) - 9c track complete"
git push origin marinebiogroup
```

## 인라인 mover (fallback)
```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{f='enrich_batch9c2_us_emails*.sql'; d='C:\dev\mbg-project\sql\enrich_batch9c2_us_emails.sql'},
  @{f='handoff_batch9c2_us*.md';        d=('C:\dev\mbg-project\docs\handoff\' + (Get-Date -Format 'yyyy-MM-dd') + '\handoff_batch9c2_us.md')}
)
foreach ($m in $map) {
  $src = Get-ChildItem -Path $dl -Filter $m.f -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($src) {
    Unblock-File $src.FullName -ErrorAction SilentlyContinue
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($m.d)) | Out-Null
    [System.IO.File]::Copy($src.FullName, $m.d, $true); Remove-Item $src.FullName -Force
    Write-Host ("MOVED: " + $src.Name)
  } else { Write-Host ("SKIP (not found): " + $m.f) }
}
```

## ⚠ 오늘의 최우선
- **Pangaea pre-meeting 이메일 — 오늘(월 7/6) 오전 발송** (수 7/8 9:30 PDT 미팅, 수정본+one-pager PDF 준비됨)
- 9c-1 SQL(`enrich_batch9c_kr_cany_emails.sql`)이 아직 Supabase 미실행이면 함께 실행
