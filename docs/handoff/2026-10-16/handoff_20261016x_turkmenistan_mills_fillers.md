# Handoff 2026-10-16 (x) — 투르크메니스탄 제지사·충전제 + 시장현황 행

> 앞 문서: `handoff_20261016w_uzbekistan_mills_fillers.md`

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261016x_turkmenistan_mills_fillers.sql` | 필러 1, 밀 2(없을 때) + 배경 5(있을 때만), plant 블록, `app.country_markets` TM 행 |

batch / source: `turkmenistan_update_20261016` · 메모 표식 `TM check 2026-10-16`

## 2. 반영
- **필러**: Magdanly 건설자재공장 PCC (2019, 도료용, 소형 국영) — 가동·능력 미확인
  - 추가 안 함: Koytendag 방해석 5만 t (입찰만, 완공 미확인), Turkmenmermer (석재), Ak Gaya (건자재), 해외 공급사 (이란 Arosha·MAD KOOHZAD 는 제재 — 조달 경로로 쓰지 않도록 시장현황에 명시)
- **밀**: 1 Blue Hills / Gök Depeler Gökdepe (복사·오프셋, 수입 버진 펄프, 설계 1.44만 t, 2026 월 1,200 t — Gök Depeler 별도 행 만들지 않음) · 2 Toprak / NowaEco Yashlyk (재생 사무·포장용지, 2013 계획 일 25 t 은 메모만)
  - 배경(있을 때만): Tere, MONA, Rowaç/Aýla (티슈 — 초지기 미확인), Türkmengala 지관, Derýa ýoly Ekoston (스톤페이퍼)
- **시장현황**: TM 행 low, FCC 720 ~ 1,440 t

## 3. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261016x_turkmenistan_mills_fillers.sql docs/handoff
git commit -m "data: Turkmenistan filler + mills + country market row"
git push origin marinebiogroup
```
