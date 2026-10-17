# Handoff 2026-10-16 (zzg) — 오스트리아 제지사·충전제·PCC 링크 + 시장현황 행

> 앞 문서: `handoff_20261016zzf_slovenia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzg_austria_mills_fillers.sql` | 필러 4, 밀 11(없을 때) + 배경 7(있을 때만), plant 블록, 링크 2, `app.country_markets` AT 행 |

batch / source: `austria_update_20261016` · 메모 표식 `AT check 2026-10-16` · 수정된 생성기 사용

## 2. 반영
- **필러**: Omya Austria Gummern (GCC, Golling PCC 2000년대 초 약 8만 t — 라이선시 B) · **Omya Hausmening 위성 PCC** (Mondi Neusiedler 연계 2001, 2005 약 4.2만 t — B satellite, 별도 행) · **CALMIT Bad Ischl** (CALPREC PCC, Starnkogel 석회석 98%, 2026-01 2,500만 유로 신규 설비 — 독립 PCC 라이선스 후보 B. 이름에 CALPREC 넣지 않아 ES Calmit Llierca 가드와 분리, 그룹 관계 확인 메모) · Shiraishi-Omya Golling (나노 PCC, 접착제용 — 제지 아님)
- **밀 / 우선순위**: 1 Mondi Neusiedler (UWF, 3대, 18만 t — 최신 협회치, 과거 33만 t) · 2 Sappi Gratkorn (91만 t, 펄프 25만 t 미합산) · 3 Essity Ortmann (13만 t) · 4 Brigl & Bergmeister (SI Vevče 같은 그룹) · 5 Lenzing Papier · 6 Norske Skog Bruck (LWC 47만 t) · 7 MM Frohnleiten (59만 t) · 8 delfort Traun
  - 우선순위 없음: Papierfabrik Wattens (링크용), Heinzel Steyrermühl (크라프트 15만 t, 신문용지에서 전환), Hamburger Pitten (45만 t)
  - 배경: Laakirchen (SC → 포장용지), Salzer, Nettingsdorf, Frantschach, Pöls/Starkraft, Rondo Ganahl, Merckens
- **링크**: Omya Hausmening → Mondi Neusiedler (active·medium, 2001~, 확인 필요) · SCHAEFER KALK (DE 행) → Papierfabrik Wattens (historical, 2003)
- **시장현황**: AT 행 high, FCC 36,600 ~ 61,000 t (Mondi + Sappi + Essity × 3~5%)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzg_austria_mills_fillers.sql docs/handoff
git commit -m "data: Austria fillers + mills + PCC links + country market row"
git push origin marinebiogroup
```
