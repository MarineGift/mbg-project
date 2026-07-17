-- ============================================================
-- fix_shikhar_seo_content_2026-07-17.sql
--
-- SHIKHAR MICRONS - WEAK. Their About page says one thing and their blog says
-- another, and the About page is the company.
--
-- ------------------------------------------------------------
-- THE COMPANY DESCRIBING ITSELF, shikharmicrons.com/about/:
--   "We are a premier manufacturer of MICRONIZED calcium carbonate (calcite) and
--    dolomite powder, serving industries such as PAINTS, PLASTICS, RUBBER,
--    DETERGENTS, and POLYMERS."
--
-- PAPER IS NOT IN THAT LIST. Five industries named, and paper is not one.
--
--   "With multiple factories across India, we operate advanced production units
--    equipped with RAYMOND MILLS, BALL MILLS, VERTICAL ROLLER MILLS, and fully
--    automatic powder coating machines."
--   "Founded by Mr. Tilak Jain in 1997, our company draws on over 27 years of
--    expertise in MINERAL GRINDING and quality control."
--
-- A grinding operation. Raymond mills, ball mills, vertical roller mills.
--
-- ------------------------------------------------------------
-- AND THE NUMBER SETTLES IT. Their GCC is offered at 100 to 1500 MESH.
--   100 mesh is roughly 149 microns. 1500 mesh is roughly 10 microns.
--   Paper filler GCC runs 60 to 90 percent BELOW 2 MICRONS.
-- Their finest grade is about five times coarser than the coarsest paper filler.
-- Same disqualification as Kaolin (Malaysia), whose limit was 1000 mesh - roughly
-- 13 microns. SECOND TIME a specification settles a row in one line. Ten microns
-- can go to board or serve as a coating extender. It cannot go in the filler slot
-- of a fine paper machine, and no licence changes that.
--
-- ------------------------------------------------------------
-- SO WHY DOES PAPER APPEAR AT ALL? BECAUSE OF SEO CONTENT.
--
--   shikharmicrons.com/blog/ground-calcium-carbonate-paper-industry/ is a full
--   article about GCC in papermaking. And it reads:
--     "India has established itself as a global leader in Ground Calcium
--      Carbonate manufacturing, with companies like Shikhar Microns setting
--      industry standards for quality, innovation, and customer service."
--     "This comprehensive guide explores what makes a reliable GCC manufacturer
--      and how to choose the right partner for your industrial applications."
--     "A good GCC manufacturer should have ISO certifications, consistent quality
--      (>=98% CaCO3), advanced manufacturing equipment..."
--
--   That is search-engine content. It describes an INDUSTRY and a BUYING GUIDE,
--   not this company's product line. It never says Shikhar sells paper filler
--   grades - it says GCC is used in paper, which is true of the mineral, not of
--   the seller.
--
-- THIRD VARIANT OF THE SAME PROBLEM, and it is worth naming all three:
--   MUMAL   - copied another company's marketing text word for word.
--   HUBER   - a market report claimed a PCC line their own literature denies, and
--             I repeated the report as fact.
--   SHIKHAR - SEO content describing the industry rather than the company.
-- All three are TEXT ATTACHED TO A COMPANY THAT IS NOT ABOUT THAT COMPANY. The
-- rule from Mumal holds and now covers all three: a claim counts only if it is
-- specific to that company. An article about how to choose a GCC supplier is not
-- a claim about this supplier.
--
-- ------------------------------------------------------------
-- A SMALL OVERCLAIM ON THEIR OWN ABOUT PAGE, worth noting because it is the kind
-- of thing that inflates a row:
--   "Founded by Mr. Tilak Jain in 1997" - but the same page says "Shikhar Microns
--   (MIA, Alwar) SINCE 2011". 1997 is the founder's career, not this company.
--   Mr Tilak Jain runs three businesses: Mahavir Minerals (MIA Alwar, since
--   1998), Shikhar Microns (MIA Alwar, since 2011) and Tilak Microns (Bidiyad,
--   Makrana). Another entity cluster, like Ashapura's three and Shiraishi's two.
--
-- VERDICT WEAK, not 'no': they do list paper on the product page and they do make
-- coated calcite, so the mineral is right. But the About page names five
-- industries without paper, and the grind stops at ten microns. Nothing here
-- supports a licence.
--
-- No contact route recorded - eighth non-target today.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set market_role = 'Mineral GRINDER at Alwar and Makrana, Rajasthan - micronized calcite, dolomite, limestone, GCC and stearic-coated grades, 100 to 1500 mesh. Raymond mills, ball mills, vertical roller mills. Their About page names paints, plastics, rubber, detergents and polymers - NOT paper. The paper content on their site is SEO blog material about the industry, not a product claim.',
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "weak", "reason": "THEIR ABOUT PAGE DOES NOT NAME PAPER, AND THE GRIND STOPS AT TEN MICRONS. Their own About page says they are a manufacturer of micronized calcium carbonate (calcite) and dolomite powder serving PAINTS, PLASTICS, RUBBER, DETERGENTS and POLYMERS - five industries, and paper is not one. Their GCC is offered at 100 to 1500 mesh, which is roughly 149 microns down to roughly 10 microns. Paper filler GCC runs 60 to 90 percent below 2 MICRONS, so their finest grade is about five times coarser than the coarsest paper filler. Ten microns can go to board or serve as a coating extender - it cannot go in the filler slot of a fine paper machine, and no licence changes that. Same disqualification as Kaolin (Malaysia) at 1000 mesh. Not marked no - paper appears on the product page and they do make coated calcite, so the mineral is right - but nothing here supports a licence.", "checked_at": "2026-07-17", "source": "shikharmicrons.com/about/, /products/ground-calcium-carbonate/", "source_type": "marketing"}, "why_paper_appears_at_all": {"the_answer": "SEO CONTENT. shikharmicrons.com/blog/ground-calcium-carbonate-paper-industry/ is a full article about GCC in papermaking, and it reads as a buying guide - India has established itself as a global leader in GCC manufacturing, with companies like Shikhar Microns setting industry standards, and This comprehensive guide explores what makes a reliable GCC manufacturer and how to choose the right partner.", "why_it_is_not_evidence": "It describes an INDUSTRY and a BUYING GUIDE, not this company product line. It never says Shikhar sells paper filler grades - it says GCC is used in paper, which is true of the mineral, not of the seller.", "raised_at": "2026-07-17"}, "third_variant_of_the_mumal_problem": {"the_three": {"mumal": "copied another company marketing text word for word", "huber": "a market report claimed a PCC line their own literature denies, and I repeated the report as fact", "shikhar": "SEO content describing the industry rather than the company"}, "what_they_share": "All three are TEXT ATTACHED TO A COMPANY THAT IS NOT ABOUT THAT COMPANY.", "the_rule_still_holds": "A claim counts only if it is specific to that company. An article about how to choose a GCC supplier is not a claim about this supplier.", "raised_at": "2026-07-17"}, "small_overclaim_on_their_own_page": {"what": "Founded by Mr. Tilak Jain in 1997 - but the same page says Shikhar Microns (MIA, Alwar) SINCE 2011. 1997 is the founder career, not this company.", "entity_cluster": "Mr Tilak Jain runs three businesses - Mahavir Minerals (MIA Alwar, since 1998), Shikhar Microns (MIA Alwar, since 2011) and Tilak Microns (Bidiyad, Makrana). Another entity cluster, like Ashapura three and Shiraishi two.", "why_noted": "It is the kind of thing that inflates a row.", "raised_at": "2026-07-17"}, "what_they_actually_make": {"products": ["Calcite Powder - 200 to 1500 mesh, 98.5%+ CaCO3, Alwar and Makrana", "Dolomite Powder", "Limestone Powder", "Ground Calcium Carbonate - 100 to 1500 mesh, 97-99% CaCO3, Alwar", "Coated Calcite Powder - stearic acid", "Coated Dolomite Powder - stearic acid", "Mineral Fillers"], "equipment": "Raymond mills, ball mills, vertical roller mills, fully automatic powder coating machines", "locations": "Alwar and Makrana, Rajasthan - multiple factories"}, "contactability": {"not_recorded": "Eighth non-target today whose contact route stays out of this database."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] WEAK. Their own About page names paints, plastics, rubber, detergents and polymers - NOT paper - and describes 27 years of MINERAL GRINDING with Raymond mills, ball mills and vertical roller mills. Their GCC stops at 1500 mesh, roughly 10 microns, against a sub-2-micron paper filler spec - the Kaolin (Malaysia) disqualification again, second time a number settles a row. The paper material on their site is an SEO blog article about the industry, not a product claim - the third variant of the Mumal problem after copied copy and a market report. Note - founded 1997 is the founder career, the company itself dates to 2011, and Mr Tilak Jain runs three businesses (Mahavir Minerals, Shikhar Microns, Tilak Microns).',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'shikhar'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.website, f.mineral_class,
--        left(f.market_role, 60)              as market_role_now,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'shikhar' and p.deleted_at is null;


-- ============================================================
-- INDIA IS FINISHED. SEVEN COMPANIES IN NINE ROWS.
--
--   20 Microns       STRONG   BSE/NSE listed, PCC+GCC, sells TiO2 replacement
--   Gulshan Polyols  STRONG   BSE listed, sixth satellite operator, Limca 2010
--   Wolkem           STRONG   India first WGCC slurry, 2000 people, 7 states
--   Kunal Calcium    STRONG   dedicated PCC 50,000 t/yr, sells fibre replacement
--   Ashapura         moderate one company in two rows, real GCC, pilot plants
--   Mumal Microns    weak     copied PCC copy, multi-mineral grinder
--   Shikhar Microns  weak     1500 mesh, About page has no paper, SEO blog
--   Imerys India     no       exited paper in 2024
--
-- FOUR STRONG OUT OF SEVEN REAL COMPANIES. The best rate in the roster by a
-- distance - Japan 3 of 7, USA 1 of 4, Malaysia 1 of 2, Saudi 0 of 1, Mexico 0
-- of 3.
--
-- AND THE FOUR ARE NOT SMALL. Two are listed. One runs satellite PCC plants at
-- paper mills. One makes 50,000 tonnes of PCC a year and already tells its
-- customers that PCC replaces expensive pulp fibre.
--
-- THIS INVERTS WHERE THE SESSION STARTED. This morning the pipeline's top was
-- Specialty Minerals, Taekyung BK, Double A and Fimatec - one of them a partner,
-- one an adverse party in a live dispute, one entangled. The real top is Artemyn
-- plus these four, and every one of them was already in this database, and nobody
-- had opened them.
-- ============================================================
