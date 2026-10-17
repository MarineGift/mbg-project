# Handoff 2026-10-16 (zu) — 스웨덴 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zt_uk_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zu_sweden_mills_fillers.sql` | 필러 4, 밀 13(없을 때) + 배경 11(있을 때만), plant 블록, `app.country_markets` SE 행 |

batch / source: `sweden_update_20261016` · 메모 표식 `SE check 2026-10-16`

## 2. 반영
- **필러 (대부분 과거 이력, 전부 C)**: Omya Sweden (Nymölla 위성 PCC 1992·Persberg GCC·Lessebo PCC — 2004~2006 기록) · Imerys Husum PCC·Tunadal GCC (2004 투자 3,500만 유로, 2005 가동 — 2024 Flacks 매각 후 소유주 확인) · Imerys Köping GCC (2005 약 12만 t) · Nordkalk Köping (석회석·석회, 제지용 GCC 는 핀란드 Lappeenranta). MTI 추가 안 함. 과거 위성 PCC 는 현재 공급 확인 전이라 링크 미생성
- **밀 / 우선순위**: 1 Arctic Paper Munkedals (14.5만 t) · 2 Arctic Paper Grycksbo (20만 t) · 3 Holmen Braviken · 4 Holmen Hallsta · 5 Metsä Tissue Katrinefors (+Pauliström·Nyboholm) · 6 Essity Lilla Edet · 7 Stora Enso Fors (45.5만 t) · 8 Fiskeby (17만 t) · 9 SCA Munksund (40만 t) · 10 Nordic Paper Bäckhammar (15.9만 t)
  - 우선순위 없음: Stora Enso Skoghall (100만 t), SCA Obbola (72.5만 t), Holmen Iggesund
  - 배경 11: Billerud 5곳, Åmotfors, Säffle, Nymölla·Hylte (Stora Enso 매각), Ahlstrom, Rottneros
  - 펄프 생산능력(Skoghall 70만·Fors 22만·Bäckhammar 23만 t)은 판지·종이와 중복 합산 안 함
- **시장현황**: SE 행 high, FCC 3,450 ~ 17,250 t (Arctic Paper 기준)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zu_sweden_mills_fillers.sql docs/handoff
git commit -m "data: Sweden fillers + mills + country market row"
git push origin marinebiogroup
```
