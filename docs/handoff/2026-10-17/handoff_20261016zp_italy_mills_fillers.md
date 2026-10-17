# Handoff 2026-10-16 (zp) — 이탈리아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zo_ukraine_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zp_italy_mills_fillers.sql` | 필러 4, 밀 10(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` IT 행 |

batch / source: `italy_update_20261016` · 메모 표식 `IT check 2026-10-16`

## 2. 반영
- **필러**: Omya Italy 밀라노 (라이선시, B) · **Nicem** Casazza (CarboPaper BCM 8 D50 <2.0 μm — 독립 제지용 GCC, 공동생산 후보, B) · Fassa Bortolo Spresiano (제지 명시 미분 탄산칼슘) · Unicalce Lecco (석회 200만 t+, Carmeuse 통합 — PCC 원료). MTI Italy (공장 미확인) 추가 안 함
- **밀 / 우선순위**: 1 Fedrigoni Verona (특수지·고급 인쇄지, 그룹 19억 유로) · 2 Burgo Group (인쇄·코팅) · 3 **Favini** Rossano Veneto (1992 해조류 종이 Alga Carta — 공동개발 파트너, IP 확인 필요) · 4 Sofidel Porcari (그룹 200만 t+ 는 해외 포함이라 미집계) · 5 Lucart · 6 ICT (Foxy) · 7 RDM · 8 DS Smith Lucca (PM1 17.5만 + PM2 23.5만 = 41만 t)
  - 우선순위 없음: Smurfit Westrock Verzuolo, Cartiere del Garda
  - 배경(있을 때만): Cartiere Carrara, Pro-Gest, Cartiere Saci, Cartiera di Ferrara
  - Porcari 에 Sofidel·Lucart·DS Smith 3곳 → 소유사 정규식으로 분리
- **시장현황**: IT 행 high (2025 생산 780만 t, 151개 공장), FCC 산정 보류 (공장별 생산량 대부분 미공개)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zp_italy_mills_fillers.sql docs/handoff
git commit -m "data: Italy fillers + mills + country market row"
git push origin marinebiogroup
```

## 4. 실행 후
IT 는 예전 import 행이 많을 수 있음 → 결과 CSV 의 `other mill` 목록으로 중복 확인
