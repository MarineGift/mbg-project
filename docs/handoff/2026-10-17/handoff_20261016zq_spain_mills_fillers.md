# Handoff 2026-10-16 (zq) — 스페인 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zp_italy_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zq_spain_mills_fillers.sql` | 필러 4, 밀 9(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` ES 행 |

batch / source: `spain_update_20261016` · 메모 표식 `ES check 2026-10-16`

## 2. 반영
- **필러**: **Calmit Llierca** Argelaguer (구 Cales de Llierca, 2026 사명 변경, Calcinor 계열 — 1977년부터 CALPREC PCC, 첫 고객 제지사 — 후보 1, B. Calcinor 는 별도 PCC 공장으로 세지 않음) · **Reverté Minerals** Albox (+Castellet, 제지 코팅용 GCC·슬러리 — B) · Omya Spain 바르셀로나 (사무소, 라이선시, B) · TRICALSA Arganda del Rey
- **밀 / 우선순위**: 1 Torraspapel (Lecta, Zaragoza 외 3곳 — 한 행) · 2 ICT Ibérica El Burgo de Ebro (15만 t) · 3 Gomà-Camps La Riba (원지 6만 t — 완제품 6.5만 t 은 중복이라 미합산) · 4 Sofidel Buñuel · 5 Essity Allo · 6 Saica El Burgo de Ebro (131만 t) · 7 Hinojosa Alquería · 8 Smurfit Westrock Sangüesa (9만 t)
  - 우선순위 없음: Saica Zaragoza (56.5만 t)
  - 배경(있을 때만): Papelera de Sarrià, Northwood Dicepa, DS Smith Dueñas (구 Europac), Smurfit Mengíbar·Nervión
  - 같은 도시(El Burgo de Ebro: ICT·Saica / Zaragoza: Torraspapel·Saica) → 소유사 정규식으로 분리. 첫 생성 때 Saica 이름 가드가 두 공장에 같이 걸려 수정함
- **시장현황**: ES 행 high (2025 631만 t), FCC 6,300 ~ 10,500 t (티슈 2곳 기준)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zq_spain_mills_fillers.sql docs/handoff
git commit -m "data: Spain fillers + mills + country market row"
git push origin marinebiogroup
```
