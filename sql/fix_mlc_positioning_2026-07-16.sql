-- ============================================================
-- fix_mlc_positioning_2026-07-16.sql
--
-- BUG I SHIPPED: enrich_mlc_us_filler_2026-07-16.sql set intro_ko/intro_en with
-- the guard "and p.intro_ko is null". MLC already had an intro from
-- 20260620190000_filler_supplier_profile_enrich_batch13.sql, so the update was
-- SILENTLY SKIPPED. The website and the 13 contacts landed fine (confirmed in
-- the 2026-07-16 pipeline export - website mlc.com, contacts 13), but the
-- company intro never changed. That is exactly what was reported.
--
-- This file OVERWRITES the intro unconditionally (no null guard) and applies
-- the PCC-exit positioning that was previously only left as a flag.
--
-- EVIDENCE for the PCC exit (mlc.com read 2026-07-16, contact page modified
-- 2026-03-27): the live sample-request form and the compliance-document form
-- BOTH state that PCC products are no longer sold by MLC. The markets/paper
-- page still mentions merchant PCC at Ste. Genevieve, but it is the older page.
-- Two explicit transactional statements outweigh one stale marketing page.
-- STILL UNCONFIRMED BY A HUMAN AT MLC - ask Dan Menniti or Bill Wleklinski.
--
-- Prior values are preserved in profile notes so this is fully reversible.
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) INTRO - forced overwrite ----------
update app.parties p
set intro_ko = '1907년 설립된 미국 최대 석회 기업(비상장, 지주사 HBM Holdings, 매출 약 3.76억 달러, 직원 약 750명, 미국 lime 시장 약 10.4%). 미주리주 세인트루이스 본사. Ste. Genevieve(미주리)에 아메리카 대륙 최대 석회 설비를 두고 Calera(AL)·Verona(KY)·Vicksburg(MS)·Weirton(WV)·Chester(SC)·Mobile(AL)·Prairie du Rocher(IL)·Bridgeville(PA) 등 12개 이상 공장/터미널을 운영한다. 영국 Singleton Birch를 보유하고 2026년 1월 Burnett을 인수했다. 도메인은 mississippilime.com에서 mlc.com으로 이전했고 현재 MLC로 d/b/a 사용 중이다. ★핵심: 2026년 7월 기준 자사 웹폼(샘플 요청·컴플라이언스 문서 요청) 두 곳 모두에 「PCC 제품은 더 이상 판매하지 않는다」고 명시되어 있어 PCC 사업에서 철수한 것으로 판단된다. 과거 제지용 Magnum Fill 70% 슬러리와 Magnum Gloss PCC는 단종된 것으로 보인다. 현재 GCC는 CalCarb 브랜드로 유지하나 등급이 아스팔트·농업·광산 분진·유리·사료용 중심이고 제지용 필러 등급이 없다. 따라서 FCC 로열티 라이선싱 타깃으로서의 우선순위는 낮다. 다만 생석회·소석회는 PCC 제조의 필수 원료이므로 PCC 밸류체인의 upstream 공급자로서는 여전히 유효하다.',
    intro_en = 'Founded 1907, the largest US lime producer (private, held by HBM Holdings, about 376 million dollars revenue, roughly 750 employees, around 10.4 percent of the US lime market). HQ in St. Louis, Missouri, with the largest lime facility in the Americas at Ste. Genevieve, Missouri, plus twelve or more plants and terminals including Calera AL, Verona KY, Vicksburg MS, Weirton WV, Chester SC, Mobile AL, Prairie du Rocher IL and Bridgeville PA. Owns Singleton Birch in the UK and acquired Burnett in January 2026. The domain moved from mississippilime.com to mlc.com and the company now trades as MLC. KEY POINT - as of July 2026 both live web forms, sample request and compliance document request, state that PCC products are no longer sold by MLC, so the company is judged to have left the PCC business. The legacy paper products Magnum Fill 70 percent slurry and Magnum Gloss PCC appear discontinued. CalCarb GCC continues, but the listed grades target asphalt, agriculture, mine rock dust, glass and feed rather than paper filler. MLC therefore ranks low as an FCC royalty licensing target. It remains relevant as an upstream supplier to the PCC value chain, since quicklime and hydrated lime are essential PCC raw materials.',
    updated_at = now()
where p.id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid
  and p.party_type_id = 3
  and p.deleted_at is null;

-- ---------- 2) PRESERVE the prior positioning before changing it ----------
update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[pre-pccexit-values 2026-07-16] Prior values kept for rollback - supply_model was "Merchant PCC + possible satellite", market_role was "Multi-state US (paper market explicit)", evidence_level was "B".',
    updated_at = now()
where f.party_id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[pre-pccexit-values 2026-07-16]%';

-- ---------- 3) APPLY the PCC-exit positioning ----------
update app.filler_supplier_profile f
set supply_model  = 'merchant GCC (PCC exited)',
    market_role   = 'US lime leader - GCC merchant + PCC upstream (quicklime), PCC discontinued',
    supplier_type = coalesce(f.supplier_type, 'Lime and GCC producer'),
    evidence_level = 'B',
    onsite_pcc_evidence = 'WITHDRAWN 2026-07-16 - MLC web forms state PCC products are no longer sold. Any earlier on-site/satellite PCC read is treated as historical until a human at MLC confirms otherwise.',
    updated_at = now()
where f.party_id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid
  and f.deleted_at is null
  and f.supply_model is distinct from 'merchant GCC (PCC exited)';

-- ---------- 4) VERIFY ----------
-- select p.party_name, p.website, fp.supply_model, fp.market_role, fp.evidence_level,
--        left(p.intro_ko, 60) as ko_head
-- from app.parties p join app.filler_supplier_profile fp on fp.party_id = p.id
-- where p.id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid;
-- expect supply_model = 'merchant GCC (PCC exited)' and ko_head starting with 1907

-- ---------- 5) ROLLBACK ----------
-- update app.filler_supplier_profile
-- set supply_model = 'Merchant PCC + possible satellite',
--     market_role  = 'Multi-state US (paper market explicit)',
--     evidence_level = 'B', onsite_pcc_evidence = null
-- where party_id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid;
