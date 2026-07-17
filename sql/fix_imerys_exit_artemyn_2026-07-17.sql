-- ============================================================
-- fix_imerys_exit_artemyn_2026-07-17.sql
--
-- YOU WERE RIGHT ABOUT IMERYS, AND THE REASON YOU WERE RIGHT IS THE FINDING.
--
-- Imerys press release, July 2024: "Imerys today announces that it has completed
-- the disposal of its assets serving the paper market to an affiliate of Flacks
-- Group, a US investment firm, for a net equity value close to 150 million euros
-- ... approximately 900 employees in 24 plants in the Americas and Asia, as well
-- as certain locations in Europe. In 2023, they generated approximately 370
-- million euros in sales."
--
-- IMERYS LEFT THE PAPER MARKET TWO YEARS AGO. Your instinct that Imerys reads as
-- kaolin rather than calcium carbonate is exactly right, and the reason is that
-- they SOLD the calcium-carbonate-for-paper business. Imerys SA itself is still
-- French and still listed on Euronext as NK - it was the paper assets that went
-- to a US buyer, not the company.
--
-- SO YESTERDAY'S "IMERYS COVERAGE HOLE" WAS NOT A HOLE. I wrote that eight
-- Imerys rows with zero deals was a gap on the number 3 global producer. They
-- have zero deals because they are not in this business. The database is
-- recording assets that were sold in 2024 - Imerys Korea at evidence A, Imerys
-- China at 11 processing plants. Same failure as MLC still positioned on PCC
-- after exiting it, Zantat on a stale capacity figure, Shiraishi on old
-- marketing. And as with those, the wrong rows are the A and B ones. C is honest
-- because C admits it is a guess.
--
-- THE BUSINESS IS CALLED ARTEMYN. AND IT IS ALREADY IN THIS DATABASE.
--
--   7868456a-bd64-4de2-9930-74cd21db8dea
--   Artemyn | country_code null | evidence B
--   market_role "Merchant (kaolin/mineral solutions)"
--   website artemyn.com/industries/pulp-paper-board-packaging/
--   contacts 0, deals 0
--
-- Artemyn IS the former Imerys paper business: kaolin, GCC, PCC and talc, 24
-- plants, ~900 staff, ~370M euros of sales, now owned by a Flacks Group
-- subsidiary. A market report describes it as "a France-based industrial
-- minerals company specializing in the production and supply of calcium
-- carbonate, including precipitated calcium carbonate ... for paper, board,
-- coatings".
--
-- The database calls it a kaolin merchant. That is the Thiele trap running
-- backwards. Thiele really is kaolin with no CaCO3 line, so fcc_fit no was
-- correct. Artemyn is LABELLED kaolin and is in fact the largest paper-grade
-- calcium carbonate asset to change hands in years.
--
-- WHY ARTEMYN IS A SERIOUS FCC TARGET, not just a correction:
--   * 24 plants already making GCC and PCC for paper - the exact infrastructure
--     FCC runs on
--   * newly independent, so it needs its own product story rather than a
--     corporate parent's
--   * owned by an investment group, which means someone is looking for
--     differentiation and value creation on a 370M euro asset
--   * not Omya, not Specialty Minerals, not Taekyung - it is outside every
--     exclusion you set
--
-- IDEMPOTENT. uuid and name targeted. NOTHING IS INSERTED or DELETED.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) IMERYS - out of paper, out of scope ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "no", "reason": "Imerys COMPLETED THE DISPOSAL OF ITS PAPER-MARKET ASSETS IN JULY 2024, selling them to an affiliate of Flacks Group, a US investment firm, for a net equity value near 150 million euros. Those assets - kaolin, GCC, PCC and talc for paper and board, about 900 staff across 24 plants in the Americas and Asia plus some European sites, roughly 370 million euros of 2023 sales - now trade as ARTEMYN, party 7868456a-bd64-4de2-9930-74cd21db8dea. Imerys SA remains French and Euronext-listed as NK, but it is no longer a paper filler producer. Route any FCC approach to Artemyn.", "checked_at": "2026-07-17"}, "staleness_flag": {"raised_at": "2026-07-17", "concern": "This row records assets sold in July 2024. Evidence levels and market_role text predate the divestiture and should not be trusted for paper. Imerys Korea at evidence A and Imerys China at 11 processing plants are both describing a business Imerys no longer owns.", "source": "Imerys press release, imerys.com/media-room/press-releases/imerys-completes-disposal-its-assets-serving-paper-market", "source_type": "disclosure"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[imerys-exit 2026-07-17] NOT AN FCC TARGET. Imerys completed the sale of its paper-market assets to a Flacks Group affiliate in July 2024. The business is now Artemyn. My note of 2026-07-16 calling eight Imerys rows with zero deals a coverage hole on the world number 3 producer was WRONG - the zero is correct, they left the market. Keep these rows for market history and for the non-paper minerals business. Do not enrol them in FCC outreach and do not build a contact_inquiry form for them.',
    updated_at = now()
from app.parties p
where f.party_id = p.id
  and p.party_name ~* 'imerys'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[imerys-exit 2026-07-17]%';


-- ---------- 2) ARTEMYN - say what it actually is ----------
update app.parties p
set country_code = coalesce(p.country_code, 'FR'),
    website      = 'https://www.artemyn.com',
    intro_ko = 'Imerys가 2024년 7월 미국 투자그룹 Flacks Group 자회사에 매각한 제지 사업 전체가 독립한 회사. 순자기자본 기준 약 1억 5천만 유로에 거래됐고, 앞서 2022년 Syntagma Capital과의 협상 단계에서는 어언아웃 포함 기업가치 3억 9천만 유로로 제시됐던 자산이다. 프랑스 기반이며 카올린·GCC·PCC·탈크를 생산해 제지·판지용 충전제와 코팅제로 공급한다. 미주·아시아에 공장 24곳과 유럽 일부 거점, 직원 약 900명, 2023년 매출 약 3억 7천만 유로. ★★FCC 관점 최상위권: ① 이미 제지용 GCC·PCC를 만드는 공장 24곳을 보유 — FCC가 그대로 올라갈 인프라다 ② 모회사에서 분리돼 독립한 지 얼마 안 돼 자체 제품 서사가 필요하다 ③ 투자그룹 소유라 3억 7천만 유로 자산의 차별화와 가치 창출을 찾는 주체가 존재한다 ④ Omya·Specialty Minerals·태경 어디에도 해당하지 않는다. ⚠️DB 기록 정정: market_role이 "Merchant (kaolin/mineral solutions)"로 돼 있었으나 이는 사업의 일부만 본 것이다. 시장 보고서는 Artemyn을 "탄산칼슘, PCC 포함, 제지·판지·코팅용을 생산·공급하는 프랑스 기반 산업광물 회사"로 기술한다. ⚠️DB의 Imerys 행 8개는 2024년에 팔린 자산을 기록하고 있다.',
    intro_en = 'The entire former Imerys paper business, spun out as an independent company when Imerys sold it to an affiliate of the US investment group Flacks Group in July 2024 for a net equity value close to 150 million euros. The same assets had earlier been offered to Syntagma Capital at an enterprise value of 390 million euros including an earn-out. France-based, producing kaolin, GCC, PCC and talc supplied as fillers and coating agents for paper and board. Around 900 employees across 24 plants in the Americas and Asia plus several European sites, with roughly 370 million euros of sales in 2023. TOP-TIER FCC TARGET - first, it already operates 24 plants making paper-grade GCC and PCC, which is precisely the infrastructure FCC runs on. Second, it is newly separated from a corporate parent and needs a product story of its own. Third, an investment group owns it, so somebody is actively looking for differentiation and value creation on a 370 million euro asset. Fourth, it is not Omya, not Specialty Minerals and not Taekyung, so it sits outside every exclusion. DATABASE CORRECTION - market_role read "Merchant (kaolin/mineral solutions)", which captured only part of the business. A market report describes Artemyn as a France-based industrial minerals company specialising in the production and supply of calcium carbonate, including precipitated calcium carbonate, for paper, board and coatings. Note also that the eight Imerys rows in this database are recording assets sold in 2024.',
    updated_at = now()
where p.id = '7868456a-bd64-4de2-9930-74cd21db8dea'::uuid
  and p.deleted_at is null;


-- ---------- 3) ARTEMYN profile ----------
update app.filler_supplier_profile f
set market_role   = 'Independent merchant - former Imerys paper business (kaolin + GCC + PCC + talc), 24 plants',
    mineral_class = 'CaCO3 (PCC/GCC) + kaolin + talc',
    supply_model  = coalesce(f.supply_model, 'Merchant (paper and board fillers and coatings)'),
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "top tier", "reason": "24 plants already producing paper-grade GCC and PCC - the infrastructure FCC runs on. Newly independent from Imerys as of July 2024 and needs its own product story. Investment-group owned, so there is an owner actively seeking differentiation on a 370m euro asset. Outside every exclusion - not Omya, not Specialty Minerals, not Taekyung.", "checked_at": "2026-07-17"}, "ownership": {"parent": "Flacks Group affiliate (US investment group)", "acquired": "2024-07", "net_equity_value_eur_m": 150, "prior_offer": "Syntagma Capital, 2022, EV 390m EUR incl. earn-out - not completed", "source_type": "disclosure", "source_url": "https://www.imerys.com/media-room/press-releases/imerys-completes-disposal-its-assets-serving-paper-market"}, "scale": {"plants": 24, "employees": 900, "revenue_eur_m_2023": 370, "footprint": "Americas and Asia plus certain European sites"}, "prior_record_error": {"was": "Merchant (kaolin/mineral solutions), country_code null, evidence B", "why_wrong": "Described only the kaolin slice. This IS the former Imerys paper filler business, GCC and PCC included. Recorded 2026-07-17."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[artemyn 2026-07-17] IDENTITY CORRECTED. This is the former Imerys paper business, sold to a Flacks Group affiliate in July 2024 and now independent. It was filed here as a kaolin merchant with a null country, which is the Thiele trap in reverse - Thiele genuinely is kaolin with no CaCO3 line and fcc_fit no was right, whereas Artemyn was LABELLED kaolin while being the largest paper-grade calcium carbonate asset to change hands in years. evidence B understates this badly. Raise it once a named contact confirms the position. Contacts today - zero.',
    updated_at = now()
where f.party_id = '7868456a-bd64-4de2-9930-74cd21db8dea'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[artemyn 2026-07-17]%';


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.country_code, p.website,
--        f.evidence_level, f.mineral_class,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit,
--        (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts,
--        (select count(*) from app.deals d where d.party_id = p.id and d.deleted_at is null) as deals
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'imerys|artemyn' and p.deleted_at is null
-- order by p.party_name;
-- EXPECT - every Imerys row fcc_fit 'no', Artemyn 'top tier', FR, contacts 0.


-- ---------- 5) WHAT THIS DOES TO THE TARGET LIST ----------
-- 83 targets minus 5 Imerys rows = 78. But the list gains nothing and loses
-- nothing that mattered, because Artemyn was already in it - sitting at evidence
-- B under the wrong description, with no contact and no deal, ranked below
-- companies a fraction of its size.
--
-- The ranked list from scan_fcc_target_ranking sorted on evidence_level, and
-- evidence_level measures how well a company has been researched. Artemyn had
-- been researched badly, so it ranked badly. That is the same defect as
-- yesterday's finding that evidence_level has no correlation with whether anyone
-- can be reached - the ladder measures our own effort and nothing about the
-- target.
--
-- Artemyn should be first or second on the filler contact_inquiry list.
