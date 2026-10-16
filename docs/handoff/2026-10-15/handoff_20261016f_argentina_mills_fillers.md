# Handoff 2026-10-16 (f) — 아르헨티나 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016e_ecuador_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016f_argentina_mills_fillers.sql` | 필러 6, 밀 12(없을 때) + 배경 1, plant 블록, 공급 링크 1, `app.country_markets` AR 행 |

batch / source: `argentina_update_20261016` · 메모 표식 `AR check 2026-10-15`

## 2. 반영
- **필러**: Calidra Los Berros · Calidra La Laja (San Juan PCC, 제지 공급 명시 — FCC 라이선스 후보 1) · Omya Argentina (라이선시, 구 Huber Zárate 위성 PCC 2003 비가동) · Dolomita Alta Gracia (PCC + 일 500 t 분쇄) · Verdol Córdoba (일 450 t) · FGH Los Berros (PCC)
  - Calidra 가드는 사이트명 포함 (`calidra.*los berros` 등) — 멕시코 Calidra 행과 섞이지 않음
  - Imerys (2005 PCC 약 5만 t) 는 현재 상태 미확인으로 추가 안 함
- **밀 / 우선순위**: 1 Ledesma (바가스 인쇄·필기 13만 t+) · 2 Softys Zárate · 3 Papelera San Andrés de Giles · 4 Papel Prensa San Pedro · 5 Papelera del NOA (그룹 8.4만 t) · 6 Cartocor Arroyito·Ranelagh·Mendoza·Luján, Papel Misionero Capioví · 7 Celulosa Argentina Capitán Bermúdez·Zárate (2025-07 생산 중단, 채무조정)
  - 펄프 설비능력(Papel Prensa 17만, Papel Misionero 9만, Celulosa 19.4만)은 종이 능력이 아니라 capacity 에 넣지 않음
  - 배경: Arauco Argentina (펄프 전용)
- **공급 링크**: Omya → Celulosa Argentina Zárate (historical / medium)
- **FCC Base**: Ledesma 13만 t × 50% × 5% = 3,250 t
- **시장현황**: AR 행 high, FCC 3,250 ~ 6,500 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016f_argentina_mills_fillers.sql docs/handoff
git commit -m "data: Argentina fillers + mills + country market row"
git push origin marinebiogroup
```
