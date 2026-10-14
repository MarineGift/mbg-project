\xef\xbb\xbf# Handoff 2026-10-14 (n) — 한국 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014m_vietnam_mills_fillers.md` (실행·푸시 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014n_korea_mills_fillers.sql` | 링크 확인·추가 2, 필러 메모 4, Omya Hankook Chemical, 밀 생성(없을 때) 7, plant 블록 15 |

batch / source: `korea_update_20261014`

## 2. 이미 있음
Omya Korea Inc., Taekyung Industry, Taekyung BK, GMC, 한솔 공장들, 무림, 깨끗한나라, 한국제지, Taekyung BK → 한솔 장항 PCC 링크(2026-07 내부 메모 근거)

## 3. 반영
- **Taekyung BK → 한솔 장항: 공시로 확인** — 장항 PCC 슬러리 공장 2025 생산 52,210 t, 2026 1Q 가동률 97.1% (태경산업 연결 분기보고서 2026-05-15). volume·confidence high 기록, caveat 교체
- **Omya Hankook Chemical (온산)** 필러 행 + → 한국제지 온산 링크 (active / medium, 2004 합작, 파이프라인 위성 PCC)
- 메모 추가: Omya Korea (5개 공장·120만 t+, KFTC 2017 제지용 GCC 시장 1,121억 원·3사), Taekyung Industry (GCC 545,220 t — 광양·괴산·온산), Taekyung BK (단양2 10,393 t, 장항 52,210 t), GMC (진천·울산·삼척 백운광산, 2011 24만 t 체제)
- 밀 생성(없을 때): 무림페이퍼 진주, 무림P&P 울산, 무림SP 대구, 한국제지 온산·현풍, 깨끗한나라 청주, 삼정펄프
- Mill profile 우선순위: 1 무림 진주·울산 (**진행 중 계정** — 3자 NDA, 9,000 t/yr, Omya 생산) · 2 한솔 장항 · 3 한국제지 온산 · 4 한솔 천안 · 5 한솔 신탄진 · 6 무림SP · 7 깨끗한나라 · 8 삼정펄프
- 참고: 한국제지 현풍, 한솔 대전, 아세아제지, 신대양제지, 전주페이퍼, 태림페이퍼
- FCC 시나리오: 무림 진주(361,590 t)·무림P&P(479,350 t)·한국제지 온산(600,000 t)

## 4. 주의
- 한솔 장항 접근 시 Taekyung BK(두 번째 충전제 제조사)와 기술 공유 전 기존 Omya NDA 독점·공개범위 확인 — 카드 approach 에 기록
- 9,000 t 는 확정 로열티가 아닌 상업화 프로그램 — 30,000 t 수치는 사용하지 않음

## 5. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014n_korea_mills_fillers.sql docs/handoff
git commit -m "data: Korea fillers, links (Taekyung BK Janghang confirmed, Omya Hankook), mill plant profiles"
git push origin marinebiogroup
```
