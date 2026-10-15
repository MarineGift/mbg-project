\xef\xbb\xbf# Handoff 2026-10-15 (d) — 라오스 제지공장·필러

> 앞 문서: `handoff_20261015c_cambodia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261015d_laos_mills_fillers.sql` | 필러 3사, 밀 3곳(없을 때), 소개·메모, plant 블록 3 |

batch / source: `laos_update_20261015` · 메모 표식 `LA check 2026-10-15`

## 2. 반영 (회사소개 → intro, 상세 → 메모)
- 필러: MCS Mining Industry Lao (캄무안 Thakhek, 태국계, GCC 325~2,500 mesh + 석회 — 태국 영사관 자료로 공장 확인), Viet Lao Stone (제지용 사양 공개, 라오스 가공공장 건설 중), Dong Nhan Stone 라오스 공장 (2025-10 착공). 라오스 제지용 PCC 공장 없음. S K Chemical(무역) 제외
- Mill profile 우선순위: 1 Sun Paper Laos (포장용지 80만 t — 150만 t 중 종이는 80만 t뿐) · 2 Khamhung (베트남 수출 원지) · 3 Asia Paper Mill (티슈)
- Namalat Paper Bag (종이백 가공) 추가 안 함
- 확인 안 된 웹사이트(Sun Paper) 비워 둠

## 3. 판단
- Sun Paper Laos 는 산둥 본사 의사결정 — 중국 Sun Paper Yanzhou(SMI 위성 PCC) 와 그룹 단위 접근 (카드 approach)
- 포장용지 중심 — 강도 시험 후 물량 산정. 시나리오·링크 없음
- MCS: 태국 네트워크와 연계한 지역 생산 모델 후보

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261015d_laos_mills_fillers.sql docs/handoff
git commit -m "data: Laos fillers (MCS) + mills (Sun Paper Laos, Khamhung) + intros + plant profiles"
git push origin marinebiogroup
```
