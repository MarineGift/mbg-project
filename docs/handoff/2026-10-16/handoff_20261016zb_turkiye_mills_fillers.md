# Handoff 2026-10-16 (zb) — 튀르키예 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016za_georgia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zb_turkiye_mills_fillers.sql` | 필러 7, 밀 16(없을 때), plant 블록, `app.country_markets` TR 행 |

batch / source: `turkiye_update_20261016` · 메모 표식 `TR check 2026-10-16` · 제지기업 보고서 2개 버전 중 최신 기준

## 2. 반영
- **필러**: Omya Turkey (4개 공장, 라이선시) · Adaçal Emirdağ (독립 PCC 실제 가동 — 라이선스 후보, B) · Esen Mikronize Tuzla (건식 70만 t + 슬러리 10만 t — FCC 공동생산 후보 1, B) · Mikron'S Niğde (TURKCARB 제지용, 제지사 승인, B) · Aydın Madencilik Gemlik (AY 103 코팅·AY 106 Wet-end, B) · Niğtaş / Mikrokal (파일럿 설비) · Ottocarb. PERO Minerals 추가 안 함
- **밀 / 우선순위**: 1 Alkim Kemalpaşa (9만 t+, 복사·오프셋) · 2 Mopak Dalaman · 3 Kartonsan (BM2 16만 t) · 4 Lila Ergene (27.1만 t) · 5 Aktül Pamukova (21만 t) · 6 Sanipak Yalova (그룹 25만 t 이 행에만) · 7 Batı Kipaş Söke (130만 t) · 8 Europap Tezol Torbalı (14.2만 t)
  - 우선순위 없음: Modern Karton (200만 t), OYKA (10만 t), Varaka (30만 t 설계), KMK (11만 t), Kıvanç (Adana PM1 2024), Hamburger Containerboard, Viking (4만 t), Hayat Kimya
- **시장현황**: TR 행 high, FCC 21,825 ~ 43,650 t
- 기존 TR 행이 많을 수 있음 → 실행 결과 CSV 의 `other mill` 목록으로 중복 확인 필요

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zb_turkiye_mills_fillers.sql docs/handoff
git commit -m "data: Turkiye fillers + mills + country market row"
git push origin marinebiogroup
```
