# Handoff — Batch 9c-1 (KR + CA/NY 이메일) + Mill/Supplier 중복 탐지 probe (2026-07-05)

## 이번 세션 산출물 (3개, Downloads → mover로 자동 라우팅)
| 파일 | 용도 | 목적지 |
|---|---|---|
| `enrich_batch9c_kr_cany_emails.sql` | KR wave6 + CA/NY wave8 이메일 8건 + whitelist 8건 | sql\ |
| `fix_mill_supplier_dupe_detect.sql` | Paper Mills / Filler Suppliers 중복 탐지 (READ ONLY) | sql\ |
| `handoff_batch9c_kr_cany.md` | 본 문서 | docs\handoff\ |

## 9c-1 리서치 결과 (24곳: KR 12 + CA/NY 12)
**확정 8 (공식 채널 검증 — SQL에 즉시 적용):**
| Firm | Email | 근거 |
|---|---|---|
| Kolon Investment | yjkim721@kolon.com | 공식 투자문의 페이지 — "사업계획서를 이 이메일로" 명시 (최고 등급) |
| Primer Sazze | info@primersazze.com | 공식 사이트 contact |
| Strong Ventures | info@strongvc.com | Crunchbase + 피치 가이드 이중 확인, deck 접수 명시 |
| Samsung Ventures | sv.a@samsung.com | 공식 LinkedIn — 글로벌 스타트업 inbound (미국 법인 채널) |
| 645 Ventures | ideas@645ventures.com | Crunchbase + 가이드 |
| Contour Venture Partners | matt@contourventures.com | 공식 contact 페이지 (Matt Gorin, MP) |
| Great Oaks VC | info@greatoaksvc.com | Crunchbase |
| LifeSci Venture Partners | info@lifesciventure.com | 공식 사이트 General Inquiries |

**리뷰 10 (단일 출처 — SQL에 주석 처리, 2차 확인 후 해제):**
Bluepoint `magellan@bluepoint.ac`(2023 프로그램용) · Big Basin `ideas@bigbasincapital.com` · Aju IB `info@ajuib.com`(미국법인) · Goodwater `info@goodwatercap.com` · SBVA `b_plan@softbank.co.kr`(⚠구 도메인, 리브랜딩 후 유효성 불확실) · Base10 `purpose@base10.vc` · LifeX `contact@lifex.vc` · Point72 `ideas@p72.vc` · True `connect@trueventures.com`(공식은 Pitch Us 폼) · Primary `sam@primary.vc`(개인 주소, 요검증)

**form-only 6:** FuturePlay / LG Technology Ventures / Altos(웜인트로 하우스) / SR One / Sands Capital / Novo Holdings — 콜드 이메일 대상 제외, 폼 제출 또는 웜인트로 트랙.

**패턴 확인:** 9b 결론 유지 — KR 펀드는 공개 이메일 확률이 실제로 높았음 (12곳 중 확정 4 + 리뷰 5). US 대형·기관계는 form-only.

## 실행 순서
```
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
```
1. Supabase에서 `enrich_batch9c_kr_cany_emails.sql` 실행 → 마지막 SELECT가 **contact 8 + whitelist 8 = 16행**이면 성공. (KR 시드가 아직 미실행이면 contact 행이 4에 그침 — wave6/wave8 시드 먼저 실행)
2. Supabase에서 `fix_mill_supplier_dupe_detect.sql` 실행 (READ ONLY) → **(0) party_type 코드 census부터 확인** — probe의 A~C는 코드를 ('buyer','filler','paper_mill','mill','supplier','paper_company')로 넓게 걸어놨으니 census에 없는 코드는 무시됨. 결과 6개 세트를 CSV로 회신.
3. 회신 받으면 투자사 v9와 동일 구조(트랜잭션 + probe 기반 REPARENT + soft-delete)의 병합 SQL을 생성. `party_supply_links` 재지정이 핵심 자식 — (D) 결과가 병합 시 pair 중복 방지 로직에 들어감. "각 공장" 표준 주의: 같은 이름·다른 도시는 병합 대상 아님.

## 9c-2 잔여 (다음 세션 — US 14곳)
- `_us2` 5: Fine Structure Ventures, Innovation Endeavors, Obvious Ventures, Overture VC, Third Sphere
- `_us` 9: 1955 Capital, ADM Ventures, Compound VC, Humba, Osage UP, Overlay, Ponderosa, Refactor, Seabird
- 리뷰 10건의 2차 출처 확인도 9c-2에서 병행 권장
- `_korea_us` (Carlyle·TPG) 스킵 확정

## 커밋 (finish block)
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/enrich_batch9c_kr_cany_emails.sql sql/fix_mill_supplier_dupe_detect.sql "docs/handoff/$(Get-Date -Format 'yyyy-MM-dd')/handoff_batch9c_kr_cany.md"
git commit -m "feat(investors): batch 9c-1 KR+CA/NY emails (8 applied, 10 review) + mill/supplier dupe probe"
git push origin marinebiogroup
```
push가 있어야 웹 배포에 반영됩니다 (로컬 mover만으로는 미반영).

## 인라인 mover (fallback — 파일별)
```powershell
$dl = "$env:USERPROFILE\Downloads"
$map = @(
  @{f='enrich_batch9c_kr_cany_emails*.sql';  d='C:\dev\mbg-project\sql\enrich_batch9c_kr_cany_emails.sql'},
  @{f='fix_mill_supplier_dupe_detect*.sql';  d='C:\dev\mbg-project\sql\fix_mill_supplier_dupe_detect.sql'},
  @{f='handoff_batch9c_kr_cany*.md';         d=('C:\dev\mbg-project\docs\handoff\' + (Get-Date -Format 'yyyy-MM-dd') + '\handoff_batch9c_kr_cany.md')}
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

## ⚠ 다른 대기 과제
- **Pangaea 미팅 수요일 7/8 9:30 PDT — pre-meeting 이메일은 내일(월 7/6) 오전 발송** (수정본 + one-pager PDF 첨부 준비됨)
- 9a/9b SQL이 Supabase에서 아직 미실행이면 함께 실행
