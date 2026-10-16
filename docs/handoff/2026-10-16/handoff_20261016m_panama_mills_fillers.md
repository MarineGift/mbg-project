# Handoff 2026-10-16 (m) — 파나마 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016l_cuba_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016m_panama_mills_fillers.sql` | 필러 1, 밀 2(없을 때) + 배경 4(있을 때만), plant 블록, `app.country_markets` PA 행 |

batch / source: `panama_update_20261016` · 메모 표식 `PA check 2026-10-15`

## 2. 반영
- **필러**: Calizas Finas Chiriquí (CaCO3 95%+, 4~325 mesh, 제지 명시, 2025 아루바 수출). CALPRO (CaCO3 최소 70%, 자체 생산 불명) 추가 안 함. Carbotico 는 코스타리카 행
- **밀**: 1 Papelera Istmeña / GrandBay (재생 티슈, 톤수 미공개 — 과테말라 GrandBay PAINSA 와 같은 그룹) · 2 Industria Panameña de Papel Chilibre (Empresas Galindo, 월 2,300 t = 27,600 t/년)
  - 배경(있을 때만): La Reforma (Pacora 가공), Industria Papelera del Caribe (미확인), Papelería Comercial (가공), Empresas Galindo (그룹 행)
- **시장현황**: PA 행 low, FCC 828 ~ 1,380 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016m_panama_mills_fillers.sql docs/handoff
git commit -m "data: Panama filler + mills + country market row"
git push origin marinebiogroup
```
