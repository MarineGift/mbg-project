# Handoff 2026-10-16 (zf) — 북마케도니아 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016ze_albania_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zf_northmacedonia_mills_fillers.sql` | 필러 4, 밀 1(없을 때) + 배경 6(있을 때만), plant 블록, `app.country_markets` MK 행 |

batch / source: `northmacedonia_update_20261016` · 메모 표식 `MK check 2026-10-16`

## 2. 반영
- **필러**: A&N Mikrogranulat Gostivar (5 μm D97, 제지 명시, 2023~2024 신규 라인 — 후보 1, B) · IGM Vratnica Vizbegovo (미분 방해석, 2011 제지 고객 이력) · Omya Minerali (MK) (디렉터리 등재만, 확인 필요) · Mermeren Kombinat Prilep (SIVEC 대리석, 원료). TITAN Usje·Vardar Dolomit 추가 안 함. 제지용 PCC 없음
- **밀**: 1 Paper Mill Kočani (UNITRADE CLUSTER, 재생 골심지·Schrenz·봉투·지관원지, 폐지 투입 1.5만 t — 생산능력 아님)
  - 배경(있을 때만): DS Smith AD Skopje, Miskom (골판지 1.5만 t, 강도시험실), Fustelarko Borec, Evropa 92, Sofija Print, Superior-ER
- MEL Macedonian Paper Mills 는 그리스 회사 (GR 행)
- **시장현황**: MK 행 low, FCC 750 ~ 1,500 t (가정)

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zf_northmacedonia_mills_fillers.sql docs/handoff
git commit -m "data: North Macedonia fillers + mill + country market row"
git push origin marinebiogroup
```
