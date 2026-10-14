\xef\xbb\xbf# Handoff 2026-10-14 (i) — 인도네시아 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014g_china_mills_fillers.md` (+ h: Wuzhou 추가 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014i_indonesia_mills_fillers.sql` | 필러 4사(없을 때) + 인도네시아 밀 11곳 plant 블록 |

batch / source: `indonesia_update_20261014`

## 2. 이미 있어서 건드리지 않은 것
SMI 위성 PCC 2곳(Perawang unit 1·2) → PT Indah Kiat Perawang 링크, APP·APRIL·FajarPaper·Suparma 밀 행

## 3. 추가
- 필러: Omya (Indonesia) — 2023 수마트라 on-site GCC 발표(고객·능력 미공개) / PT Dwi Selo Giri Mas (Sidoarjo) / PT Aneka Sumberbumi Jaya (Bandar Lampung, GCC 12만 t) / PT Supersonic Chemical Industry (Gunungkidul). 주소·전화는 notes 에만 (보고서 출처)
- Mill profile 우선순위: 1 Indah Kiat Perawang · 2 APRIL Kerinci (PaperOne 115만 t + BoardOne 120만 t) · 3 Pindo Deli · 4 Tjiwi Kimia · 5 Pura Group
- 참고 행: Indah Kiat Serang·Tangerang, FajarPaper, Suparma, Adiprima, Lontar Papyrus
- FCC 시나리오: APRIL PaperOne(115만 t)만. Indah Kiat 수치는 2019년 회사 전체라 공장 단위 시나리오 없음

## 4. 보고서 대비 판단
- Perawang PCC: 2017 MTI 계획 265 kt(기존 100→140 + 신규 125) 를 카드에 기록, 실제 가동 확인 필요로 표시
- Perawang 의사결정: MTI–APP 합작사(PT Sinar Mas Specialty Minerals) — 기술 승인·로열티 지급 주체 확인을 approach 에 기록
- Lontar Papyrus 는 APP 계열 (보고서 표의 Mondi 표기는 오기)
- 보고서 전체 시장 시나리오는 DB 에 넣지 않음

## 5. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014i_indonesia_mills_fillers.sql docs/handoff
git commit -m "data: Indonesia fillers + mill plant profiles (APP, APRIL)"
git push origin marinebiogroup
```
