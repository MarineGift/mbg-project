# Paper Mill 공급관계 보강 — Omya · SMI (Batch 1, app.* 기준)

작성: 2026-06-17 / 타깃: **`app.party_supply_links`** (`mill_party_id` ↔ `filler_party_id`)
적용 SQL: `supabase/migrations/20260617150000_app_party_supply_links_omya_smi_batch1.sql`
**적용: Supabase SQL Editor에서 실행** (push는 기록만)

---

## 0. 정정 — 데이터는 industry.*가 아니라 app.*

처음엔 `industry.supplier_mill_linkages`를 타깃으로 잡았으나, 라이브 DB에 `industry.*` 스키마 자체가 없었습니다(설계만 됨, SQL Editor 미실행). 진단 결과 실제 구조는:

- 제지사 = `app.parties` (party_type=`paper_mill`, id=2), 이름 컬럼 `party_name`. **약 600+ mill이 이미 등록**돼 있음.
- 공급사 = `app.parties` (party_type=`filler_supplier`, id=3). **Omya(국가별)·Specialty Minerals(국가+plant별)가 이미 등록**돼 있고, SM은 satellite 위치와 1:1로 맞는 plant 변형까지 있음 (예: `Specialty Minerals (India - Rayagada)`, `(Malaysia - Sipitang)`, `(USA - Wickliffe KY)`).
- 거래관계 = `app.party_supply_links` (`mill_party_id`, `filler_party_id`, `link_type`, `link_type`(상태 텍스트: active/potential/pilot/historical), `product_grade`, `volume_estimate`, `confidence`, `active_since/until`, `notes`, `extra_data` jsonb).

즉 **빠진 건 둘을 잇는 link 행**뿐이었습니다. 그래서 이번 배치는 이름 해석 없이 **실제 UUID 양쪽을 직접 연결**합니다(가장 안전·정확).

---

## 1. 적용되는 14건 (실 UUID 연결)

리서치 16건 중 14건이 양쪽 party가 존재해 즉시 연결됩니다. 모두 confidence=high(1차 출처), link_type=active.

| 제지사 (mill_party) | 공급사 (filler_party) | link_type | 용량 | active_since |
|---|---|---|---|---|
| JK Paper Limited | Specialty Minerals (India - Rayagada) | pcc_satellite | ~46,000 mt/yr | 2012 |
| Sabah Forest Industries | Specialty Minerals (Malaysia - Sipitang) | pcc_satellite | 1 unit | 2003 |
| West Coast Paper Mills Ltd. | Specialty Minerals (India - Dandeli) | pcc_satellite | ~35,000 t/yr | 2011 |
| Ballarpur Industries Ltd. | Specialty Minerals (India - Ballarshah) | pcc_satellite | ~65,000 mt/yr | 2010 |
| BILT Sewa Unit | Specialty Minerals (India - Gaganapur) | pcc_satellite | ~15,000 mt/yr | 2011 |
| Phoenix Paper LLC | Specialty Minerals (USA - Wickliffe KY) | pcc_satellite | ~35,000 t/yr | 2019 |
| Century Pulp & Paper | Specialty Minerals (India - Lalkuan) | pcc_satellite | ~45,000 mt/yr | 2020 |
| Suzano Papel e Celulose | Specialty Minerals (Brazil) | pcc_satellite | satellite (Mucuri) | 2010 |
| Phoenix Pulp & Paper | Specialty Minerals (Thailand) | pcc_satellite | ~2 units | 2008 |
| ABC Paper Limited | Specialty Minerals (India - Saila Khurd) | pcc_satellite | ~25,000 mt/yr | 2012 |
| Zhumadian Baiyun Paper Co. | Specialty Minerals (China) | pcc_satellite | ~50,000 mt/yr | 2022 |
| International Paper Company | Specialty Minerals (HQ) | pcc_satellite | 8 plants (US&EU), company-level | — |
| Domtar - Nekoosa Mill (WI) | Omya (USA) | pcc_onsite | ~27,500 dry t/yr | 2024-09 |
| Domtar - Rothschild Mill (WI) | Omya (USA) | pcc_nearsite | Nekoosa 공급 | 2024-09 |

각 행의 `extra_data`에 `evidence_url`·`supply_structure`·`source`·`batch=omya_smi_batch1` 저장. 출처: MTI/Specialty Minerals 보도자료, SEC 8-K, Business Wire, Domtar/Omya 공식.

### 보류 2건 (대응 mill party 없음)
- APP China **Dagang** mill / APP China **Suzhou** mill — SM filler 변형(`China - Dagang/Tianjin`, `China - Suzhou`)은 있으나, 매칭되는 paper_mill party가 없음 → mill party 신설 후 batch에 추가 예정.

---

## 2. SQL 안전장치

- **정확**: 양쪽 모두 진단으로 확인한 실제 UUID 사용 (이름 해석 없음).
- **idempotent**: `NOT EXISTS (mill_party_id, filler_party_id, deleted_at IS NULL)` — 재실행해도 중복 없음.
- **reversible**: 전 행 `extra_data->>'batch' = 'omya_smi_batch1'`. 하단 ROLLBACK로 soft-delete.
- VERIFY SELECT 포함(주석) — 적용 후 mill·filler·evidence 확인.

실행: SQL Editor에 붙여넣고 Run → 14건 insert → VERIFY 주석 해제해 확인.

---

## 3. 다음 배치 후보 (Batch 2) — 매우 풍부

라이브에 **Specialty Minerals USA plant 변형이 mill 위치 그대로** 다수 존재 → satellite-at-mill 고신뢰 매칭이 바로 가능:
- `SM (USA - Rumford ME)` ↔ ND Paper Rumford
- `SM (USA - Biron WI)` ↔ ND Paper Biron
- `SM (USA - Escanaba MI)` ↔ Billerud Escanaba
- `SM (USA - Spring Grove PA)` ↔ Pixelle Spring Grove
- `SM (USA - Ticonderoga NY)` ↔ Sylvamo Ticonderoga
- `SM (USA - Jay ME)` ↔ (구 IP Androscoggin / Pixelle, 2023 폐쇄 → link_type=historical)
- 그 외 Adams MA, Barretts MT, Bucksport ME, Chillicothe OH, Sartell MN, Ste. Genevieve MO, Wisconsin Rapids WI 등 — 각 mill party 확인 후 연결.

유럽 SM plant 변형(Finland Lappeenranta/Oulu/Tervakoski/Äänekoski, France Saillat/Arches, Germany Stockstadt, Sweden Hallstavik, UK Kemsley, Portugal Figueira 등)도 인접 mill과 매칭 가능. APP Dagang/Suzhou mill party 신설 + 연결. Omya 추가 on-site/merchant. 이후 Imerys로 확장.

(원하시면 batch 2도 동일 방식 — 실 UUID로 연결 — 으로 만들어 드립니다.)
