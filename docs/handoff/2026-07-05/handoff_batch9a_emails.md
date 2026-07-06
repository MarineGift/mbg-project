# Handoff — Batch 9a Email Enrichment (2026-07-05)

## 산출물
| 파일 | 자동 라우팅 목적지 |
|---|---|
| `enrich_batch9a_emails.sql` | `sql\` |
| `handoff_batch9a_emails.md` | `docs\handoff\<오늘>\` |

## 범위 확정 (probe 결과)
Batch 9 전체 대기 = **67 firm / 8 source** (메모리의 32곳보다 확대 — wave 4 재단·wave 5 US 포함).
이번 **9a = wave 2 잔여(web_research_2026Q3) 10곳 + 재단(_phil) 7곳 = 17곳** 리서치 완료.

## 9a 판정 (검증 기준: 자사 사이트/공식 발표만 채택, 조작 금지)
**적용 9곳** — Voima(inka.mero@, MP·자사 compliance), Metsa Spring(niklas.vonweymarn@metsagroup.com, CEO·공식 보도자료), UB FIGG(sakari.saarela@unitedbankers.com, Partner·공식 보도자료), SWEN Blue Ocean(**blueocean@swen-cp.fr** 제안 접수 전용), Evonik VC(**pitch@evonik.com** pitch deck 전용), Schmidt Marine(info@), Grantham(info@ — 단 제안은 invitation-only), Icos(info@ — PEI+Mergr 교차확인), Prime Coalition(info@ — 실제 딜플로우는 이미 DB에 있는 Azolla Ventures 경유).

**리뷰 3곳(주석 처리)** — Katapult Ocean hello@katapult.vc, Propeller hello@propellervc.com(웜인트로 선호 명시), Rhapsody contact@rhapsodyvp.com. 단일 애그리게이터 출처라 2차 확인 후 주석 해제.

**제외 5곳(문서화)** — Collateral Good(폼만), Pivotal Ventures(비요청 제안 검토 안 함 명시), Bezos Earth Fund(자사: 비요청 제안 불가·그랜트 전용), Gates SIF(폼/추천만), Autodesk Foundation(공개 inbox 없음). 6/27 배치의 form-only 6곳(M Ventures 등)도 재조사 없이 유지.

## 실행 (⚠ SQL Editor Run이 DB를 바꾸는 유일한 단계)
1. mover: `powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1`
2. Supabase에서 `sql\enrich_batch9a_emails.sql` 실행 → 통합 검증 (contact 9 + whitelist 9 = 18행)

## 인라인 mover (fallback)
```powershell
$dl = "$env:USERPROFILE\Downloads"
$moves = @(
  @{ Pat = 'enrich_batch9a_emails*.sql'; Dest = 'C:\dev\mbg-project\sql\enrich_batch9a_emails.sql' },
  @{ Pat = 'handoff_batch9a_emails*.md'; Dest = ('C:\dev\mbg-project\docs\handoff\' + (Get-Date -Format 'yyyy-MM-dd') + '\handoff_batch9a_emails.md') }
)
foreach ($m in $moves) {
  $src = Get-ChildItem -Path $dl -Filter $m.Pat -File -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($null -eq $src) { Write-Host ("SKIP (not found): " + $m.Pat); continue }
  Unblock-File -Path $src.FullName -ErrorAction SilentlyContinue
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($m.Dest)) | Out-Null
  [System.IO.File]::Copy($src.FullName, $m.Dest, $true)
  Remove-Item -Path $src.FullName -Force
  Write-Host ("MOVED: " + $src.Name + " -> " + $m.Dest)
}
```

## Finish block (push까지 해야 웹 반영)
```powershell
cd C:\dev\mbg-project
git status -sb
git add sql/enrich_batch9a_emails.sql "docs/handoff/$(Get-Date -Format 'yyyy-MM-dd')/handoff_batch9a_emails.md"
git commit -m "feat(investors): batch 9a email enrichment - 9 verified contacts + whitelist"
git push origin marinebiogroup
```

## 다음: Batch 9b (잔여 43곳)
- `web_research_2026Q3_us` 12곳 (KDT, ADM Ventures, Elemental Impact, 1955 Capital…) + `_us2` 7곳 (MetaVC, LyondellBasell, Fine Structure…) — **AM fit 코어, 우선**
- `_ca_ny` 12곳 + `_kr` 10곳 + `_korea_us` 2곳(Carlyle·TPG — 콜드 메일 대상 아님, 스킵 후보)
