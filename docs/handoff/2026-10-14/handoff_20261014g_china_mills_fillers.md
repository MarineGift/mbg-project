\xef\xbb\xbf# Handoff 2026-10-14 (g) — 중국 제지공장·필러 업데이트

> 앞 문서: `handoff_20261014f_india_mills_fillers.md` (실행·푸시 완료)

## 1. 파일
| 파일 | 내용 |
|---|---|
| `sql/seed_20261014g_china_mills_fillers.sql` | 필러 3사(없을 때), SMI→Sun Paper Yanzhou 링크, 중국 밀 10곳 plant 블록 |

batch / source: `china_update_20261014`

## 2. 이미 있어서 건드리지 않은 것
SMI 위성 → Gold East(Dagang)·Gold Huasheng(Suzhou)·Nine Dragons Beihai·Zhefeng Quzhou, SMI GCC → Asia Symbol Rugao, Guangxi Huana 필러 행

## 3. 추가
- 필러: Omya (China) — 2023 계획 6개 공장(GCC 광시·광둥·산둥, PCC 산둥 2·푸젠 1), 인도네시아 포함 약 100만 t / Guangxi Huarui (GCC 분말, 주로 플라스틱) / Guangxi Guigang Huitong (PCC·GCC 분말). Sanxin 은 정보 부족으로 제외
- 링크: SMI → Sun Paper Yanzhou — 확인: 2014 코팅용 PCC 위성 10만 t + 2015 충전용 PCC 위성 10만 t, FulFill 기술 파트너십 포함
- Mill profile 우선순위: 1 Sun Paper Yanzhou · 2 Gold East · 3 Asia Symbol Shandong · 4 Nine Dragons Beihai · 5 Gold Huasheng · 6 Bohui · 7 Wuzhou Special · 8 Lee & Man Chongqing(티슈 트랙)
- 참고 행: Chenming (2025 순손실 약 83억 위안 — 재무 회복 후 접근), Shanying (재생 포장지 — 장기)
- FCC 시나리오: 단일 인쇄 라인 능력이 확인된 Nine Dragons Beihai(40만 t)·Wuzhou(30만 t)만

## 4. 보고서 대비 판단
- Sun Paper: MTI FulFill(충전량 최대 50% 증가)을 이미 쓰는 고객 → FCC 는 FulFill 대비 우위를 같은 초지기에서 실증해야 함 (카드 pitch 에 기록)
- 시장 전체 시나리오(1,875만 t × 투입률)는 DB 에 넣지 않음 — 밀 단위만 기록
- 밀 행은 새로 만들지 않음 → 검증 결과 `MISSING` 은 공유 후 개별 추가

## 5. 이동 · 커밋
```powershell
powershell -ExecutionPolicy Bypass -File C:\dev\mbg-project\tools\move-downloads.ps1
cd C:\dev\mbg-project
git status -sb
git add sql/seed_20261014g_china_mills_fillers.sql docs/handoff
git commit -m "data: China fillers + SMI Sun Paper link + China mill plant profiles"
git push origin marinebiogroup
```
