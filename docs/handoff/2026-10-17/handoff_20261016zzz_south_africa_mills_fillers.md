# Handoff 2026-10-16 (zzz) — 남아프리카공화국 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016zzy_kenya_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzz_south_africa_mills_fillers.sql` | 필러 3, 밀 10(없을 때) + 배경 2(있을 때만), plant 블록, `app.country_markets` ZA 행 |

batch / source: `south_africa_update_20261016` · 메모 표식 `ZA check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: **Idwala Carbonates** (Kulubrite Extra·PFG·2~45, Kulucote — 현지 제지용 GCC, 등급 숫자는 D50 아님 — 후보 1, B) · **Omya Idwala SA** (2020 Omya·Idwala 합작 유통, 현지 GCC + **수입** SC PCC — 라이선시 B, Multifill·FiberLean 경쟁 메모) · Kalkor (GCC·PCC 공급, C). Idwala·Omya Idwala 가드 분리 확인. 현지 제지용 PCC 공장 없음
- **밀 / 우선순위**: 1 Mondi Merebank Durban (UWF·Rotatrim 27만 t) · 2 Sappi Stanger (바가스 UWF 8.2만 + 티슈 2.8만 = 11만 t — 이집트 QPIC 바가스와 연계) · 3 Twinsaver (Kliprivier·Bellville) · 4 Mpact Springs (백색 코팅 판지 13.7만 t) · 5 Mondi Richards Bay (Baywhite) · 6 Neopak Rosslyn (PM3 8.5만 t — split)
  - 우선순위 없음: Sappi Ngodwana (35만 t), Sappi Tugela (20만 t), Mpact Felixton (21.5만 t), Kimberly-Clark SA
  - 배경: Sappi Saiccor (용해펄프 89만 t), Mpact Piet Retief
- **시장현황**: ZA 행 medium, FCC 10,560 ~ 19,000 t. KwaZulu-Natal 클러스터 (Idwala GCC + Merebank + Stanger)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzz_south_africa_mills_fillers.sql docs/handoff
git commit -m "data: South Africa fillers + mills + country market row"
git push origin marinebiogroup
```

## 4. 파일 접미사
다음은 `seed_20261016zzza_...` (zzz 뒤, 이름순 유지)
