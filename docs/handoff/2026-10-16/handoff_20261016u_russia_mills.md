# Handoff 2026-10-16 (u) — 러시아 제지사 + 위성 PCC 링크 (보류: 제재 검토)

> 앞 문서: `handoff_20261016t_russia_fillers.md` (먼저 실행)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016u_russia_mills.sql` | 밀 10(없을 때) + 배경 8(있을 때만), plant 블록, 공급 링크 2, RU 시장현황 갱신 (on_hold 유지) |

batch / source: `russia_mills_20261016` · 메모 표식 `RU check 2026-10-16` · 모든 메모에 제재 검토 문구

## 2. 반영
- **밀 / 우선순위**: 1 Syktyvkar LPK (구 Mondi, 2025 매출 829억 루블) · 2 Svetogorsk PPM (구 IP, SvetoCopy·Ballet) · 3 Ilim Koryazhma (공장 전체 130만 t+ — 펄프 포함이라 capacity 미입력) · 4 KAMA Krasnokamsk (FBB 24만 + LWC·오프셋 8.9만 = 32.9만 t) · 5 Hayat Russia Alabuga (14만 t, 러시아 합계 28만 t) · 6 Syktyvkar Tissue Group (8.5만 t, 2개 사이트 1행, 2024 Syktyvkar LPK 인수) · 7 Solikamskbumprom · 8 Arkhangelsk PPM (펄프 100만 t 미입력)
  - 우선순위 없음: Segezha PPM (sack kraft 38.4만 t), Volga Balakhna (약 50만 t)
  - 배경(있을 때만): Ilim Bratsk·Ust-Ilimsk, Sokol, Kondopoga, Kamenskaya, Sukhonsky, Polotnyano-Zavodskaya, Balakhninskaya, Syassky
- **공급 링크** (historical / medium): Omya Syktyvkar PCC → Syktyvkar LPK, Omya Svetogorsk PCC → Svetogorsk PPM — t 시드의 필러 행이 있어야 연결됨
- **시장현황**: RU 행 on_hold 유지, 제지사 내용 반영

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016u_russia_mills.sql docs/handoff
git commit -m "data: Russia mills + satellite PCC links (on hold, sanctions review)"
git push origin marinebiogroup
```
