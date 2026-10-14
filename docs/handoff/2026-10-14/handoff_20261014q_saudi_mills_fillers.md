\xef\xbb\xbf# Handoff 2026-10-14 (q) — 사우디아라비아 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014p_taiwan_mills_fillers.md` (실행·푸시 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014q_saudi_mills_fillers.sql` | 필러 3사, 밀 3곳(없을 때), plant 블록 7 |

batch / source: `saudi_update_20261014`

## 2. 이미 있음
MEPCO, WARAQ, Obeikan, NAPCO(가공업체 — 대상 아님)

## 3. 반영
- 필러 (없을 때): Saudi Carbonate Company (리야드, GCC·PCC 약 20만 t, Omya·Jordan Carbonate 파트너 — IMFORMED 확인), Saudi Marble (제다, 약 8만 t), Arabian Carbonate (보고서 언급 — 검증 필요)
- 밀 (없을 때 생성): Saudi Paper Dammam, Juthor KAEC, Al-Faris Jeddah
- Mill profile 우선순위: 1 Saudi Paper (티슈 19만 t, PM5 2025-09 상업가동) · 2 Juthor (13.5~15.5 gsm 버진 페이셜 — MBG 15 gsm 시험과 가장 유사, TM6 2027 1Q로 연기) · 3 Al-Faris (100% 버진펄프 티슈) · 4 Obeikan (Duplex 22만 t) · 5 MEPCO (50만 t + PM5 45만 t 2027) · 6 WARAQ
- 참고: Gulf Paper Industries

## 4. 판단
- 보고서 PCC·GCC 섹션은 본문이 비어 있어 필러는 IMFORMED 공개자료로 확인한 2사 + 보고서 언급 1사만 기록
- 티슈·판지는 시험 데이터가 먼저 → FCC 시나리오 없음
- 확인된 밀–필러 공급관계 없음 → 링크 없음

## 5. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014q_saudi_mills_fillers.sql docs/handoff
git commit -m "data: Saudi fillers + mills + plant profiles"
git push origin marinebiogroup
```
