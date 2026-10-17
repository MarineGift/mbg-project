# Handoff 2026-10-16 (zzf) — 슬로베니아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zze_switzerland_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzf_slovenia_mills_fillers.sql` | 필러 3, 밀 5(없을 때) + 배경 1(있을 때만), plant 블록, `app.country_markets` SI 행 |

batch / source: `slovenia_update_20261016` · 메모 표식 `SI check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: **Calcit d.o.o. Stahovica** (유럽 제지용 GCC 약 20%·2위 — 회사 발표, 매출 80% 제지, 2025 매출 1.019억 유로, WIG Wietersdorfer 50%·CHL 50%, HydroPlex·CalPlex·CoverPlex, 2017 UPM Augsburg·Plattling·Ettringen 공급 — FCC 라이선스 후보 1, B). 가드 슬로베니아 한정 → BG Calcit JSC 행과 분리 확인. IAK Kresnice (석회·암석분말), InterCal Slovenija / Apnenec (석회, Wietersdorfer 계열). 제지용 PCC 없음
  - 기존 충전제 파트너와의 NDA·관계 확인 후 Calcit 접촉 메모
- **밀 / 우선순위**: 1 Goričane Medvode (고급 저평량 특수지) · 2 Papirnica Vevče (라벨·유연포장, Brigl & Bergmeister) · 3 Paloma (티슈 8.7만 t, SHP — BA SHP Celex 와 같은 그룹) · 4 MM Količevo (BM3 30만 t, FBB·WLC) · 5 Radeče Papir Nova (보안용지)
  - 배경: Vipap Videm Krško (2025-12 생산 중단, 2026-02-25 파산, 2026-05 상장 폐지)
- **시장현황**: SI 행 medium, FCC 2,610 ~ 19,350 t
- 공급 링크: Calcit → UPM 독일 3개 공장은 DE 행이라 이 시드(SI 범위)로는 생성 불가 → 메모만

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzf_slovenia_mills_fillers.sql docs/handoff
git commit -m "data: Slovenia fillers + mills + country market row"
git push origin marinebiogroup
```

## 4. 후속
- 크로아티아(HR) 조사 시: Calcit Lika (Gospić) 필러 행, STARAC
- NL 보완 시: Calcit Zeeland (Terneuzen) 필러 행
