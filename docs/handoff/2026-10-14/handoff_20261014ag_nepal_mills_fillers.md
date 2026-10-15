\xef\xbb\xbf# Handoff 2026-10-14 (ag) — 네팔 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014af_bhutan_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014ag_nepal_mills_fillers.sql` | 필러 1사, 밀 4곳(없을 때), 소개·메모, plant 블록 6 |

batch / source: `nepal_update_20261014` · 메모 표식 `NP check 2026-10-14`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: Shakti Minerals (석회석 분말 — 사료용 250 µm 미만, 제지용 아님). Sarswati Polymer(마스터배치)·인도 공급사 제외
- Mill profile 우선순위: 1 Nepal Pulp and Paper (IME, 75 t/일·연 2.1만 t, **공장 내 PCC 설비** — 설계·공급사 확인) · 2 Durga Pulps (100 t/일) · 3 Reliance Paper (인쇄용지 라인 7,500 t + 크라프트 3만 t) · 4 Everest Paper (농업부산물 30 t/일)
- 참고(있을 때만): Baba Paper, Bhrikuti (2011 폐쇄 — 제외)
- FCC 시나리오: 4개 밀의 인쇄용지 능력 기준 (기준 시나리오 합계 약 67,500 t 대상)
- 확인 안 된 웹사이트는 비워 둠 (Durga·Reliance·Everest)

## 3. 판단
- 네팔은 연 5만 t 필기·인쇄용지 수입 대체 중 — 소규모지만 인쇄용지 실증 시장
- NPPI 의 PCC 설비 공급업체가 다른 국가로의 FCC 확산 통로가 될 수 있음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014ag_nepal_mills_fillers.sql docs/handoff
git commit -m "data: Nepal mills (NPPI in-house PCC, Durga, Reliance, Everest) + intros + plant profiles"
git push origin marinebiogroup
```
