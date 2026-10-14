\xef\xbb\xbf# Handoff 2026-10-14 (p) — 대만 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014n_korea_mills_fillers.md` (+ o: KR 메모·한솔 블록, Omya (Korea) 메모 직접 실행)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014p_taiwan_mills_fillers.sql` | 필러 5사, 밀 7곳(없을 때), plant 블록 12 |

batch / source: `taiwan_update_20261014`

## 2. 반영
- 필러 (없을 때): Lih Hsiang (PCC·GCC, 과거 월 1.8만 t), Diamond Quantum / DIACAL (제지용 PCC, 2026-07 Yuncheng 고객 승계), An Jung Minerals (이란 대리석 GCC), Chu Shin / APEX (건식 GCC — 제지용 습식 아님, 베트남 공장), Tai Yang Industry (굴껍데기 PCC 기술)
- **Yuncheng Chemical 은 추가하지 않음** — 2026-07-31 탄산칼슘 생산 전면 중단 (Diamond Quantum 메모에 기록)
- Omya·MTI·Artemyn: 대만 제지용 공장 미확인 → 추가 없음
- 밀 (없을 때 생성): 중화펄프 Chiutang·Hualien·Taitung, Cheng Loong Chupei, YFY Qingshui 티슈, Jih Sun, Kuan Yuan
- Mill profile 우선순위: 1 CHP Chiutang · 2 CHP Hualien · 3 CHP Taitung · 4 Cheng Loong Chupei · 5 YFY Qingshui(티슈) · 6 Jih Sun · 7 Kuan Yuan · 8 Longchen Erlin
- 참고: Taiwan Scott, Cheng Loong Tayuan·Houli, Hsing Chung

## 3. 판단
- 공장별 생산능력 공개 수치 없음 → FCC 시나리오 없음
- 확인된 밀–필러 공급관계 없음 → 링크 없음
- 보고서의 공장 규모별 가상 시나리오는 DB 에 넣지 않음

## 4. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014p_taiwan_mills_fillers.sql docs/handoff
git commit -m "data: Taiwan fillers + mills + plant profiles"
git push origin marinebiogroup
```
