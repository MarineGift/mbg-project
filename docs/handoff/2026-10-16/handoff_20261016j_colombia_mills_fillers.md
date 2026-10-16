# Handoff 2026-10-16 (j) — 콜롬비아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016i_peru_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016j_colombia_mills_fillers.sql` | 필러 6, 밀 14(없을 때) + 배경 1(있을 때만), plant 블록, `app.country_markets` CO 행 |

batch / source: `colombia_update_20261016` · 메모 표식 `CO check 2026-10-15`

## 2. 반영
- **필러**: Omya Andina Guarne (Omyacarb F-CG D50 1 μm, 라이선시) · Microminerales (Puerto Triunfo) · Procomin (Madrid, Cundinamarca) · Colminerales · Minerales y Triturados del Caribe (위탁 분쇄) · Procesadora de Minerales Andina (월 1,500 t)
  - 추가 안 함: Barahona (CALPREC PCC 유통). 제지용 PCC 공장·MTI 거점 없음
- **밀 / 우선순위**: 1 Propal Yumbo·Guachené (바가스 인쇄·필기) · 2 Papeles Nacionales Pereira · 3 Essity Cajicá 7만 t·Medellín 3만 t (2026-08부터 Cajicá 로 이전) · 4 Unibol Soledad · 5 Kimberly-Clark Puerto Tejada·Barbosa · 6 Smurfit Westrock Cali 32만 t (판지 7만 t 만 FCC 시나리오) · 7 Cartones América Cali · 8 Papelsa Barbosa, Empacor Bogotá
  - Smurfit Barbosa 12.7만·Barranquilla 7.7만 t 은 우선순위 없음 (멕시코와 같은 기준 — 판지 라인만 우선순위)
  - 배경: Corrugados de Colombia (가공)
- **시장현황**: CO 행 high, FCC 3,000 ~ 6,500 t (Propal 톤수 미공개로 제외)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016j_colombia_mills_fillers.sql docs/handoff
git commit -m "data: Colombia fillers + mills + country market row"
git push origin marinebiogroup
```
