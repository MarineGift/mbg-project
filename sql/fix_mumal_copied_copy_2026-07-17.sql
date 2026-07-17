-- ============================================================
-- fix_mumal_copied_copy_2026-07-17.sql
--
-- MUMAL MICRONS - WEAK. And this row broke the method, which matters more than
-- the row does.
--
-- ------------------------------------------------------------
-- THE METHOD'S FIRST REAL HOLE: COPIED MARKETING COPY
--
-- Everything in this sweep rests on one assumption - a company's own website
-- describes that company. Maruo was disqualified because paper was missing from
-- ITS applications list. Artemyn became target number one because IT listed 17
-- carbonate plants. Okutama is strong because IT claims over 90 percent share.
--
-- Mumal's PCC page says:
--   "PCC is synthetically processed from naturally occurring high grade lime
--    stone. The major advantage of the product is its availability in different
--    bulk densities from 0.40 gms/cc to 0.9 gms/cc, with brilliant white color,
--    depending upon the requirement of end user."
--
-- Gulshan Polyols' PCC page, read earlier today, says:
--   "PCC is synthetically processed from naturally occurring high grade lime
--    stone. The major advantage of the product is its availability in different
--    bulk densities from 0.40 gms/cc to 0.9 gms/cc, with brilliant white color,
--    depending upon the requirement of end user."
--
-- IDENTICAL. Word for word, including the phrasing.
--
-- One copied the other, or both copied a common source. Either way, MUMAL'S PCC
-- PAGE IS NOT EVIDENCE THAT MUMAL MAKES PCC. A sentence that is somebody else's
-- sentence describes somebody else's plant.
--
-- This does NOT retroactively weaken Gulshan - that row stands on things no
-- competitor could copy: a dedicated Onsite/Satellite PCC Plant page, a Limca
-- Book of Records entry for the first on-site PCC plant in India, a BSE listing,
-- and a Locate Us page naming sites at a Papers Ltd. Boilerplate was the weakest
-- evidence there and the only evidence here.
--
-- THE RULE THIS ADDS: a claim on a company's site counts only if it is SPECIFIC
-- TO THAT COMPANY. Plant names, share figures, mine names, customer names, dated
-- events, named people. Generic process description is worth nothing - it is the
-- part that travels.
--
-- ------------------------------------------------------------
-- WHAT MUMAL SAYS ABOUT MUMAL, in its own non-boilerplate words:
--   "We have our own mines of quartz, talc powder and calcite and 6 nos of
--    processing unit at udaipur. Also, we are one of the pioneer manufacturer and
--    processor of high grade super snow white ULTRA FINE MICRONIZED calcium
--    carbonate both coated and uncoated powder with high purity specially for
--    FILLER MASTERBATCH, PVC PIPE, PVC BOARD AND PROFILE, PAINT, PAPER etc."
--
--   Their range: talc, white mineral powder, soapstone, calcium carbonate,
--   calcite, china clay, quartz/silica, dolomite, kaolin, feldspar. Ten minerals.
--   MICRONIZED - ground. Not precipitated.
--
-- SO mineral_class='gcc' IS RIGHT and market_role "Ultra-fine PCC producer" IS
-- WRONG. Same as Mississippi Lime: the role field lied and the class field told
-- the truth. fix_in_filler_batch1 flagged this row's class as suspect. Wrong
-- again, the same way. Correction written next to the flag, flag left in place.
--
-- SCALE, for the comparison that decides this:
--   Mumal - incorporated 2010, six grinding units at Udaipur, registered at
--     T-5 Panoramic Apartment, Fatehsagar Road. Managing Director Gopal Agrawal,
--     who also runs Deepak Mineral Grinders. THREE live websites -
--     mumalmicrons.in, mumalmicrons.com and mumalmicrons.co.in - with different
--     content.
--   Wolkem - SAME CITY, Udaipur. Founded 1972, over 2000 people, mines and plants
--     across seven Indian states, world's leading wollastonite producer, India's
--     first WGCC slurry producer.
--   Same town, same mineral, different universe.
--
-- One thing does cut the other way and it is recorded honestly: their PCC page
-- lists benefits including "Less the consumption of TiO2" and "Reduces the raw
-- material Cost". That is our argument, for the FIFTH time in this sweep after
-- Bihoku, 20 Microns, Zantat and MLC. But it is on the copied page. It is
-- somebody else's sentence too.
--
-- VERDICT WEAK: a small multi-mineral micronizer whose PCC claim rests on copied
-- text and whose own description says ground carbonate for masterbatch, PVC and
-- paint. Paper is in the list, at the end. Not marked 'no' - they do grind
-- ultrafine coated and uncoated carbonate and paper is named. But nothing here
-- supports a licence, and the row's PCC framing should not survive.
--
-- No contact route recorded.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set market_role = 'Small multi-mineral MICRONIZER at Udaipur, incorporated 2010 - talc, soapstone, calcite, china clay, quartz, dolomite, kaolin, feldspar and ground calcium carbonate. Six grinding units. Own mines of quartz, talc and calcite. Sells ultrafine coated and uncoated GROUND carbonate for filler masterbatch, PVC pipe and board, paint and paper. THE PCC CLAIM IS COPIED TEXT - see extra_data.',
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "weak", "reason": "A SMALL MULTI-MINERAL MICRONIZER whose PCC claim rests on COPIED TEXT. Their own non-boilerplate description says they have six grinding units at Udaipur, own mines of quartz, talc and calcite, and are a processor of ultra fine MICRONIZED calcium carbonate, coated and uncoated, specially for filler masterbatch, PVC pipe, PVC board and profile, paint and paper. Micronized means ground, not precipitated. Their range covers ten minerals - talc, soapstone, calcite, china clay, quartz, dolomite, kaolin, feldspar and more. Same shape as Kaolin (Malaysia). Paper is in the list, at the end. Not marked no - they do grind ultrafine coated carbonate and paper is named - but nothing here supports a licence.", "checked_at": "2026-07-17", "source": "mumalmicrons.co.in, mumalmicrons.in, indiamart profile", "source_type": "marketing"}, "copied_marketing_copy": {"what_happened": "Mumal PCC page and Gulshan Polyols PCC page carry the IDENTICAL sentence, word for word - PCC is synthetically processed from naturally occurring high grade lime stone. The major advantage of the product is its availability in different bulk densities from 0.40 gms/cc to 0.9 gms/cc, with brilliant white color, depending upon the requirement of end user.", "why_it_matters": "THIS BREAKS THE METHOD. Every verdict in this sweep rests on the assumption that a company website describes that company. Maruo was disqualified because paper was missing from ITS applications list. Artemyn became target one because IT listed 17 carbonate plants. A sentence that is somebody else sentence describes somebody else plant. Mumal PCC page is not evidence that Mumal makes PCC.", "does_it_weaken_gulshan": "NO. Gulshan stands on things no competitor could copy - a dedicated Onsite/Satellite PCC Plant page, a Limca Book of Records entry for the first on-site PCC plant in India, a BSE listing, and a Locate Us page naming sites at a Papers Ltd. Boilerplate was the weakest evidence there and it is the only evidence here.", "the_new_rule": "A CLAIM ON A COMPANY SITE COUNTS ONLY IF IT IS SPECIFIC TO THAT COMPANY. Plant names, share figures, mine names, customer names, dated events, named people. Generic process description is worth nothing - it is the part that travels.", "raised_at": "2026-07-17"}, "corrections": {"market_role_was_wrong": {"old": "Ultra-fine PCC producer", "why_wrong": "Their own description says MICRONIZED - ground - carbonate. The PCC page is copied from Gulshan.", "fixed_at": "2026-07-17"}, "my_flag_was_wrong_again": {"what": "fix_in_filler_batch1 flagged this row mineral_class=gcc as suspect BECAUSE market_role said ultra-fine PCC. Wrong culprit, same as Mississippi Lime - the role field lied and the class field told the truth. Twice today I trusted market_role over mineral_class and market_role was wrong both times.", "flag_left_in_place": "The contradiction is real and someone should see it. The correction sits next to it.", "raised_at": "2026-07-17"}}, "scale_comparison": {"mumal": "Incorporated 2010. Six grinding units at Udaipur. Registered at T-5 Panoramic Apartment, Fatehsagar Road, Dewali, Udaipur 313001. Managing Director Gopal Agrawal, who also runs Deepak Mineral Grinders. THREE live websites with different content - mumalmicrons.in, mumalmicrons.com, mumalmicrons.co.in.", "wolkem": "SAME CITY, Udaipur. Founded 1972. Over 2000 people. Mines and plants across seven Indian states. World leading wollastonite producer. India first WGCC slurry producer.", "point": "Same town, same mineral, different universe."}, "the_tio2_line": {"what": "Their PCC page lists benefits including Less the consumption of TiO2 and Reduces the raw material Cost - our argument, for the fifth time in this sweep after Bihoku, 20 Microns, Zantat and MLC.", "but": "It is on the COPIED page. It is somebody else sentence too.", "raised_at": "2026-07-17"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] WEAK - and this row broke the method. Mumal PCC page carries a sentence IDENTICAL to Gulshan Polyols PCC page, word for word. Copied marketing copy is not evidence. Their own description says six grinding units at Udaipur and ultra fine MICRONIZED (ground) carbonate for masterbatch, PVC, paint and paper, alongside ten other minerals. market_role said Ultra-fine PCC producer - corrected. mineral_class=gcc was right, and my earlier flag blamed it wrongly, same error as Mississippi Lime. NEW RULE - a claim on a company site counts only if it is SPECIFIC to that company. Generic process description travels.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'mumal'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.website, f.mineral_class,
--        left(f.market_role, 60)                                as market_role_now,
--        f.extra_data #>> '{fcc_fit,verdict}'                   as fcc_fit,
--        f.extra_data #>> '{copied_marketing_copy,the_new_rule}' as new_rule
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'mumal' and p.deleted_at is null;


-- ---------- WHAT THE COPIED COPY MEANS FOR THE ROWS ALREADY DONE ----------
-- Worth stating plainly, because it is a real exposure.
--
-- SAFE - these rest on company-specific facts that cannot be copied:
--   Artemyn      17 named carbonate plants, a named tech centre, named executives
--   Okutama      a share figure, named departments with phone numbers, a brand
--   Bihoku       named mines with tonnages, a named wet line, a BET figure
--   Shiraishi    named entities, an open testing laboratory, publication record
--   Gulshan      Limca 2010 record, dedicated satellite page, BSE listing, CIN
--   MLC          named PCC plants, named sites, a dated company history
--   Zantat       their own contact page naming their own partnership inbox
--   20 Microns   BSE/NSE listing, named brands, an enquiry inbox on their domain
--   Wolkem       first WGCC slurry in India, seven states, named associate
--
-- EXPOSED - rested partly on generic description:
--   Q-min        the banknote claim is specific and dated. Safe.
--   Calidra      two NAMED PCC plants and a 70 percent figure. Safe.
--   Huber        already downgraded for a related reason - I trusted a market
--                report over their literature.
--
-- The disqualifications are all safe by construction: they rest on what is
-- ABSENT from a company own list, and nobody copies an absence.
