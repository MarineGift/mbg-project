\xef\xbb\xbf# Handoff 2026-10-14 (af) — 부탄 제지기업·석회석 업체 (낮은 우선순위)

> 앞 문서: `handoff_20261014ae_srilanka_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014af_bhutan_mills_fillers.sql` | 필러 3사, 밀 1곳(없을 때), 소개·메모, plant 블록 1 |

batch / source: `bhutan_update_20261014` · 메모 표식 `BT check 2026-10-14`

## 2. 반영
- 필러: Nortak (240·300 mesh 석회석 분말 인도 수출), RSA Limestone Unit (푼촐링), Jigme Flux (Lhaki, 백운석 소성 — 고순도 PCC 아님). 제지용 PCC·GCC 생산업체 없음. Tamang(백운석)·De-Keeling(오래된 명부) 제외
- 밀: Eco-Tech Bhutan (Jigmeling, 재생 크라프트 50 t/일, 폐지 부족으로 저가동) — 인도 Assam 의 Eco Tech Papers 와 다른 회사
- 수제종이(Jungshi, Tagma, Mangala) 추가하지 않음

## 3. 판단
- 부탄은 인도 동북부 시장의 원료 후보지 정도 — 사업개발 인력 투입 우선순위 낮음
- 시나리오·링크 없음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014af_bhutan_mills_fillers.sql docs/handoff
git commit -m "data: Bhutan limestone fillers + Eco-Tech Bhutan mill (low priority)"
git push origin marinebiogroup
```
