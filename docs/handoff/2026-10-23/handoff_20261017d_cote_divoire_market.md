# Handoff 2026-10-17 (d) — 코트디부아르 충전제·제지사 + 시장현황 행

> 앞 문서: `handoff_20261017c_burkina_market.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261017d_cote_divoire_market.sql` | 필러 1, 밀 1(없을 때, 우선순위 없음) + 배경 7(있을 때만), plant 블록, `app.country_markets` CI 행 (priority none) |

batch / source: `cote_divoire_update_20261017` · 메모 표식 `CI check 2026-10-17` · 국가코드 `CI` (이름의 `'` 는 SQL 에서 `''` 로 이스케이프 확인)

## 2. 반영
- **필러 (C)**: Gypse Abidjan (Zenith Industrial 2020 프로젝트 — Raymond 밀 3 t/h, 100~200 mesh, 설비사 자료만 — 실재·가동 확인 필요, 제지용으로는 굵음). SODEMI (국영 광업, 실험실) 연락 메모. 튀니지 MBS 수입. 제지용 PCC·GCC 없음, Omya·Lhoist 공장 없음
- **밀**: Nouvelle MICI-EMBACI Koumassi (골판지·인쇄·PP 포대 + 폐골판지 재생 펄프 → 파트너 제지사 공급 — 어느 초지기인지 추적)
  - 배경: ACIPAC (Yopougon, 티슈 원지 가공·노트·크라프트 봉투, 3개 공장 500명+), SATOCI (LOTUS·SANITEX·PAPYRUS·LILAS — 가봉 SATOGA 와 브랜드 겹침), SONACO, SIVEM (크라프트 포대, Smurfit·Billerud 원지), AFRIPACK, SIEMPA, La Nouvelle de Papier
- **시장현황**: CI none — 말리·부르키나·가봉의 주 공급국이지만 가공 거점. 실제 FCC 대상은 ACIPAC·SATOCI·SIVEM 원지 공급사와 MICI-EMBACI 파트너 제지사

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261017d_cote_divoire_market.sql docs/handoff
git commit -m "data: Cote d'Ivoire filler + mill + market row"
git push origin marinebiogroup
```
