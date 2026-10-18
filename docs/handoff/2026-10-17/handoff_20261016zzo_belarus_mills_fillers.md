# Handoff 2026-10-16 (zzo) — 벨라루스 제지사·충전제 + 시장현황 행 (제재 보류)

> 앞 문서: `handoff_20261016zzn_estonia_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016zzo_belarus_mills_fillers.sql` | 필러 2, 밀 6(없을 때, 우선순위 없음) + 배경 3(있을 때만), plant 블록, `app.country_markets` BY 행 (priority none) |

batch / source: `belarus_update_20261016` · 메모 표식 `BY check 2026-10-16` · 수정된 생성기 사용

## 2. 반영 — 제재 보류
- 모든 행 메모 끝에 `SANCTIONS: screen owner, OFAC and EU lists, banking and export-control rules before any contact (US company).` → 참고 데이터로만 보관, plant priority 없음, approach "Hold - sanctions screening first."
- **필러 (C)**: Krasnoselskstroymaterialy (Belarusian Cement Company, 백악·석회) · SabiAn (합성 CaCO3 공급 — 제조사·공장 불명). BSTU 개질 GCC 연구(2016) 메모. 시멘트 공장 추가 안 함. 제지용 PCC·GCC 제조사 미확인
- **밀 (우선순위 없음)**: Dobrush Geroy Truda (GC1·GC2 코팅 백판지, 신규 판지 라인 설계 20만 t — split) · Shklov Newsprint (신문·오프셋·장식 원지) · Spartak Shklov (티슈 원지, 신규 2.4만 t — split) · Slonim Albertin (판지·티슈) · Svetlogorsk PCM (펄프·라이너) · Krasnaya Zvezda Chashniki (Svetlogorsk 자회사)
  - Shklov 의 Spartak·신문용지 공장 → 소유사 정규식 분리
  - 배경: Goznak Borisov (보안용지), Exclusive Grodno, Pukhovichi
- **시장현황**: BY 행 none, FCC 산정 없음

## 3. 미결 항목 연결
- 이전 미결 3번 "마케팅 세그먼트 패치 (제재국 캠페인 제외)" 대상: IR, CU, RU (+ VE, SY) → **BY 추가 필요**

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016zzo_belarus_mills_fillers.sql docs/handoff
git commit -m "data: Belarus fillers + mills + market row (sanctions hold)"
git push origin marinebiogroup
```
