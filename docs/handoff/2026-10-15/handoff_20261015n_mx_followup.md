# Handoff 2026-10-15 (n) — 미결 1·2 확인 완료 + 멕시코 후속 정정

> 앞 문서: `handoff_20261015m_mexico_mills_fillers.md`

## 1. 프로브 결과 (scan_20261015l, 시드 실행 후 재실행)
| 항목 | 결과 |
|---|---|
| migration_20261015k | 컬럼 3개 · `country_markets_ai_url_check` 제약 정상. 36개국 중 ChatGPT 링크 34, Claude 0, Gemini 0 |
| 이스라엘 (y) | 밀 2 + 필러 3 신규, plant 블록 5, historical 링크 2, IL 시장행 low |
| 요르단 (z) | 밀 1 + 필러 6 신규, plant 블록 4, JO 시장행 medium |
| Lebanese Calcium Carbonate | 1행만 존재 (124ba0aa…) — **중복 없음, 종결** |

## 2. 멕시코 시드 (m) 결과
- 기존 행에 매칭 (신규 생성 안 함): Omya (Mexico), Specialty Minerals (Mexico), Bio Pappel — Scribe (plant 2 + intro 채움)
- 신규 필러 6: Terrazo, Reverté Durango, ICC, ATSA, ONIC, LEDSA
- 신규 사이트 밀 19: Pondercel, Cartones Ponderosa, Papel San Francisco, KCM ×6, Essity ×3, Convertipap, Smurfit Westrock ×6 (그룹 행 KCM·Essity·Smurfit·Copamex 는 그대로 — 사이트 행과 공존)
- 배경 밀 8곳은 URM 에 없어서 변화 없음
- 링크: 기존 `Specialty Minerals (Mexico) -> Copamex` (그룹 행) + 신규 `-> Copamex - Pondercel` (historical / medium) 둘 다 유지
- MX 시장행 high 정상

## 3. 정정 — `sql/fix_20261015n_mx_calidra_market_text.sql`
- 기존 Calidra 행 프로필이 **PCC + GCC + lime** 인데 시드 문구가 "lime only" → MX 시장행 `sections.fillers` 다시 씀 (Imerys Mexico, Carmeuse Mexico, Mexalit 포함)
- LEDSA 메모의 잘못된 Calidra 문구 삭제, Calidra 에 MX 메모 1회 추가

## 4. 참고
- 기존 MX 밀 중 plant 블록 없는 행: Absormex CMPC Tissue (Monterrey), Bio Pappel Atenquique·Durango·McKinley·Titán, International Paper Mexico, PCM, Potosi — 보고서에 자료 없음, 다음 조사 대상
- `sql/scan_20261015l_pending_and_mx_probe.sql` 가 커밋에 안 들어감 — 파일 위치 확인 후 add

## 5. 남은 미결
3 제재국 캠페인 제외 패치 · 4 Market 탭 sections_ko · 5 CountryPeersPanel 컬럼 · 6 fix_20260919c untracked · 7 필리핀 BOI 밀 · Claude/Gemini 링크 입력
