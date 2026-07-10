# Handoff — Batch 9b 리서치 중간 상태 (2026-07-05)

## 9a 완료 확인
DB 검증 18행(contact 9 + whitelist 9), commit `f24013d` push 완료. **단, 9a SQL을 Supabase에서 아직 실행 전이면 실행 필요** (git push는 DB를 바꾸지 않음).

## 9b-1 조사 결과 (7곳 — 이번 세션)
| Firm | 판정 | 근거/노트 |
|---|---|---|
| Koch Disruptive Technologies | **form-only** | 공개 pitch 이메일 없음. Koch 계열 폼 전용. Capital Factory 파트너 계열은 웜인트로 각도 검토 |
| LyondellBasell Ventures | **form-only** | 직접 CVC inbox 없음. **LYB는 Chrysalix·Infinity Recycling의 LP** — 둘 다 이미 DB에 연락처 있음 → 실질 접근은 그 경유 |
| MetaVC Partners | **이메일 없음** | 소형 펀드($62M), 사이트에 공개 주소 없음 |
| Elemental Impact | **form-only** | get-in-touch 폼 + legal@만 공개. 코호트 지원 사이클로 접수 |
| Cantos Ventures | **리뷰** | ops@cantos.vc (Crunchbase 단일 출처, ops용 — pitch 적합성 낮음) |
| (참고) 6/27 form-only 6곳 | 유지 | M Ventures, Holcim MAQER, Henkel, GC Ventures, Mitsui 321FORCE, Taiwania |
| (참고) 9a 리뷰 3곳 | 유지 | Katapult hello@katapult.vc / Propeller hello@propellervc.com / Rhapsody contact@rhapsodyvp.com |

**패턴 결론**: US CVC·소형 딥테크 펀드는 공개 이메일을 거의 안 둠 → 이 구간은 폼 제출 또는 웜인트로가 정석. 콜드 이메일 캠페인 필터는 9a까지 확보분으로 이미 유효.

## 9c 잔여 워크리스트 (다음 세션)
- `_us2` 잔여 4: Fine Structure Ventures, Innovation Endeavors, Obvious Ventures, Overture VC, Third Sphere
- `_us` 잔여 7: 1955 Capital, ADM Ventures, Compound VC, Humba, Osage UP, Overlay, Ponderosa, Refactor, Seabird
- `_ca_ny` 12곳 / `_kr` 10곳 (Bluepoint·FuturePlay 등 KR 펀드는 공개 이메일 확률 높음)
- `_korea_us` 2곳 (Carlyle·TPG) — **콜드 대상 아님, 스킵 확정 권장**

## 커밋
```powershell
cd C:\dev\mbg-project
git add "docs/handoff/$(Get-Date -Format 'yyyy-MM-dd')/handoff_batch9b_research_status.md"
git commit -m "docs(investors): batch 9b research status - form-only findings, 9c worklist"
git push origin marinebiogroup
```
mover: `powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1`

## 인라인 mover (fallback)
```powershell
$dl = "$env:USERPROFILE\Downloads"
$src = Get-ChildItem -Path $dl -Filter 'handoff_batch9b_research_status*.md' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($src) {
  Unblock-File $src.FullName -ErrorAction SilentlyContinue
  $dest = 'C:\dev\mbg-project\docs\handoff\' + (Get-Date -Format 'yyyy-MM-dd') + '\handoff_batch9b_research_status.md'
  [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($dest)) | Out-Null
  [System.IO.File]::Copy($src.FullName, $dest, $true); Remove-Item $src.FullName -Force
  Write-Host ("MOVED: " + $src.Name)
} else { Write-Host 'SKIP (not found)' }
```

## 다른 대기 과제
- Paper Mills / Filler Suppliers 중복 정리 (probe-then-merge 프레임 준비됨)
- Pangaea 미팅 **수요일 7/8 9:30 PDT** — pre-meeting 이메일 **월요일 오전 발송** (수정본 준비됨, one-pager PDF 첨부)
