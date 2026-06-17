# Paper Mill 데이터 보강 — Omya · SMI 거래 제지사 (Batch 1)

작성: 2026-06-17 / 대상: `industry.supplier_mill_linkages` (filler_supplier ↔ paper_mill/company M:N)
적용 SQL: `supabase/migrations/20260617140000_industry_omya_smi_linkages_batch1.sql`
**적용 방법: Supabase SQL Editor에서 수동 실행** (repo push는 기록만; DB 반영 아님)

---

## 0. 왜 이 테이블인가

`industry.paper_mills`(552행)·`industry.supplier_mill_linkages`(817행) 중, "어느 제지사가 Omya/SMI와 거래하는가"의 정답은 **linkage 테이블**입니다. 진행 문서 기준 linkage의 `mill_pct ≈ 47.4%`(절반 이상이 mill FK 없이 raw 이름만) — 이게 "Paper Mill 정보 부족"의 실체입니다. 이번 배치는 **공개 1차 출처로 검증 가능한 관계만** 채웠습니다.

핵심 단서: **SMI(Specialty Minerals, Minerals Technologies 자회사)의 "satellite PCC plant"는 제지사 부지 안에 설치**됩니다. 즉 satellite plant 존재 = 그 제지사가 SMI 고객이라는 강한 증거이고, MTI 보도자료·SEC 8-K에 위치까지 공개됩니다. Omya도 on-site/near-site plant를 운영합니다.

---

## 1. Batch 1 — 검증된 16건 (SMI 14 + Omya 2)

증거등급: confidence A (1차 출처). evidence_level E1 = SEC/제조사 공식, E2 = 업계 1차 보도.

### SMI / Specialty Minerals (Minerals Technologies)

| 제지사 (paper company) | Mill / 위치 | 시장 | filler | 공급구조 | 용량·메모 | status |
|---|---|---|---|---|---|---|
| JK Paper Limited | Rayagada mill, Odisha | India | PCC | on-site satellite (JV) | ~46,000 mt/yr, 2011 | reported active (재확인) |
| Sabah Forest Industries (BILT) | Sipitang mill, Sabah | Malaysia | PCC | on-site satellite | 1 unit, 2003 | reported active (재확인) |
| Asia Pulp & Paper (APP China) | Dagang mill | China | PCC | on-site satellite (JV) | 4-unit, filling+coating | reported active (재확인) |
| Asia Pulp & Paper (APP China) | Suzhou mill | China | PCC | on-site satellite (JV) | 4-unit, 2005 | reported active (재확인) |
| West Coast Paper Mills Ltd | Dandeli mill, Karnataka | India | PCC | on-site satellite | ~35,000 t, 2011 | reported active (재확인) |
| Ballarpur Industries (BILT) | Ballarshah Unit, Maharashtra | India | PCC | on-site satellite (JV) | ~65,000 mt, Ashti도 공급, 2009 | reported active (재확인) |
| Ballarpur Industries (BILT) | Sewa Unit, Gaganapur, Orissa | India | PCC | on-site satellite (JV) | 15,000 mt, 2011 | reported active (재확인) |
| Phoenix Paper LLC (Shanying Intl) | Wickliffe mill, Kentucky | USA | PCC | on-site satellite | 35,000 t, 2020 재건 | active |
| Century Pulp & Paper (Century Textiles) | Lalkuan mill, Nainital | India | PCC | on-site satellite | 45,000 mt, 2020 | active |
| Suzano Papel e Celulose | Mucuri mill, Bahia | Brazil | PCC | on-site satellite | 확장 2010 | reported active (재확인) |
| Phoenix Pulp & Paper (Siam Cement Group) | Nam Phong mill, Khon Kaen | Thailand | PCC | on-site satellite | 2 units, 2008 | reported active (재확인) |
| ABC Paper Limited | Saila Khurd mill, Punjab | India | PCC | on-site satellite | 25,000 mt, 2012 | reported active (재확인) |
| Zhumadianshi Baiyun Paper | Suiping County, Zhumadian, Henan | China | PCC | on-site satellite | 50,000 mt, 2022 | active |
| International Paper | (IP mills 8곳, 미국·유럽) | USA(대표) | PCC | on-site satellite | MTI 최대 고객, 8개 공급계약(2015까지 연장) | long-term (재확인) |

### Omya

| 제지사 | Mill / 위치 | 시장 | filler | 공급구조 | 메모 | status |
|---|---|---|---|---|---|---|
| Domtar (Paper Excellence) | Nekoosa mill, Wisconsin | USA | PCC | on-site (Omya 설계·소유·운영) | 27,500 dry t/yr, 2024-09 가동 | active |
| Domtar (Paper Excellence) | Rothschild mill, Wisconsin | USA | PCC | near-site (Nekoosa plant에서 공급) | 2020 폐쇄된 지역 공급사 대체 | active |

> 주의: 2003~2012년 발표된 건은 "발표 시점 기준 가동"이며 2026 현재 운영/소유 변동 가능 — `current_status`에 "(verify current 2026)"로 표시. 최근 건(2020~2024)은 active.

---

## 2. 출처 (evidence URL)

- JK Paper — MTI: investors.mineralstech.com (.../india-jk-paper)
- Sabah Forest Industries — MTI: investors.mineralstech.com (.../sabah-forest)
- APP China Dagang/Suzhou — SEC 8-K FY2004: sec.gov/Archives/edgar/data/0000891014/...ex99_appagr.htm
- West Coast Paper — Business Wire 2011-01-21
- BILT Ballarshah — Papermart (2009)
- BILT Sewa — MTI: investors.mineralstech.com (.../another-satellite-pcc-plant-india)
- Phoenix Paper (Wickliffe) — MTI: investors.mineralstech.com (.../phoenix-paper-rebuild-and)
- Century Pulp & Paper — MTI: investors.mineralstech.com (.../century-pulp-paper-install)
- Suzano (Mucuri) — SEC 8-K FY2009
- Phoenix Pulp & Paper (Thailand) — MTI: investors.mineralstech.com (.../phoenix-pulp-paper-company)
- ABC Paper — MTI: investors.mineralstech.com (.../india-abc)
- Baiyun Paper — MTI: investors.mineralstech.com (.../baiyun-paper-construct)
- International Paper (8 plants) — SEC 8-K FY2003: sec.gov/Archives/edgar/data/0000891014/...ex99iprelease.htm
- Domtar Nekoosa / Rothschild (Omya) — domtar.com/nekoosa-mill-pcc-plant

(전체 URL은 SQL 파일의 `supplier_evidence_url` 컬럼에 그대로 들어 있음.)

---

## 3. SQL 동작 / 안전장치

- **idempotent**: 재실행해도 중복 INSERT 없음 (`NOT EXISTS`로 market_code + mill_site_raw + supplier 접두 매칭 검사).
- **blind-safe**: Omya/SMI는 이름으로 `filler_supplier_id` 해석. paper_company/mill은 prefix-containment **스칼라 서브쿼리(LIMIT 1)**로만 매칭 → fan-out/오매칭 없음. 매칭 실패 시 FK는 NULL, `*_raw` 컬럼에 데이터 보존(기존 52% 미매칭 행과 동일 패턴).
- **reversible**: 모든 행 `assessment_scope = 'mbg-research-2026-06 (omya/smi batch1)'` 태그. 파일 하단 ROLLBACK 쿼리로 일괄 삭제 가능.
- STEP 0(사전 점검)·STEP 4(검증) SELECT는 주석 처리 — 필요 시 단독 실행.

실행 순서: ① SQL Editor에서 STEP 0 주석 해제 후 실행 → Omya/SMI 행 이름 확인 → ② 본 트랜잭션 실행 → ③ STEP 4로 검증.

---

## 4. 다음 배치 후보 (Batch 2+)

- **International Paper의 8개 mill 개별 식별** (북미가 SMI 네트워크 핵심; 10-K Properties / 과거 보도자료로 mill명 확정 → company-level 1행을 mill-level 여러 행으로 분해).
- 유럽 SMI satellite (Stora Enso, Sappi, UPM, Mondi, Burgo 등) 개별 mill.
- Omya 추가 on-site/near-site (유럽·아시아 GCC 슬러리 공급 포함).
- Imerys / Schaefer Kalk / Carmeuse 등 다른 filler supplier로 확장.
- (선택) 매칭된 company 하위로 `industry.paper_mills` 행 신규 INSERT — 단, company FK 확정 후 검토 실행 권장(blind INSERT는 중복 위험).
