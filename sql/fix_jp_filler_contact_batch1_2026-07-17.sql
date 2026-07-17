-- ============================================================
-- fix_jp_filler_contact_batch1_2026-07-17.sql
--
-- Japanese filler suppliers, batch 1 of the homepage sweep. Three companies read
-- directly from their own sites. One of the three should NOT be a target, and
-- only opening the page revealed it.
--
-- WHY BATCHES OF THREE TO SIX AND NOT SEVENTY-EIGHT
-- Each company costs one or two searches plus a judgement about whether the
-- mineral is even aimed at paper. Maruo took two searches to disqualify. A single
-- file with 78 companies in it would be unverifiable - when one URL is wrong,
-- nobody could find which. Small batches stay checkable, which is the only
-- reason any of today's corrections were catchable at all.
--
-- ------------------------------------------------------------
-- 1. MARUO CALCIUM - NOT A PAPER COMPANY. Do not target.
--    maruo-cal.co.jp lists its applications in its own navigation, on every
--    page: synthetic resin (sealants, adhesives, plastisol, film, plastics),
--    paint and ink, rubber, food additives, pharmacopoeia, other.
--    PAPER IS NOT THERE. Maruo is a sealant and resin PCC house.
--    This is the Thiele pattern again - right mineral, wrong market. Thiele was
--    kaolin with no CaCO3. Maruo is CaCO3 with no paper. Both are honest
--    companies that simply do not intersect FCC.
--    It has a form (/html/General_Inquiry.html) and an address
--    (soumu@maruo-cal.co.jp, which is General Affairs, not technical). Neither
--    is recorded, because recording a contact route for a company we should not
--    contact is how a wrong target becomes a sent message.
--
-- 2. BIHOKU FUNKA KOGYO - STRONG. Paper is core.
--    Its homepage lists paper among its markets, and its product page says the
--    company developed high-quality calcium carbonate PIGMENT FOR PAPERMAKING.
--    The wet-ground line is described as the optimal filler for NEUTRAL
--    PAPERMAKING, high solids, and - in their words - achieving COST REDUCTION.
--    That is the FCC argument in their own marketing language, already aimed at
--    their own customers. GCC primary, plus pharmacopoeia-grade PCC. Owns its
--    limestone - the Karato mine at Niimi holds roughly 100 million tonnes.
--
-- 3. SHIRAISHI GROUP - STRONG, and structurally split.
--    shiraishi.co.jp lists PAPER among its applications and makes UFPCC, PCC and
--    GCC. 22 group companies, 44 sites. It runs an OPEN TESTING LABORATORY and
--    publishes at conferences - a company that publishes can read our two ACS
--    papers and judge FCC on the public record, which is exactly the door the
--    filler_safe answers are written for.
--    TWO ENTITIES share the Osaka HQ: Shiraishi Kogyo Kaisha (the manufacturer)
--    and Shiraishi Calcium Kaisha (a trading company). Same split shape as
--    Taekyung Industrial / Taekyung BK - and that shape produced duplicate rows
--    twice already this session. Check which one this database holds before
--    contacting either.
--
-- NO FORM URLS ARE INVENTED. Bihoku's site was rebuilt - the old structure
-- (/index.html, /contact2.html, copyright 2015) and a new one (/pages/N/, updated
-- this month) both answer on the same domain, and I will not guess which contact
-- page is live. Shiraishi's contact URL did not surface at all. Both need one
-- look from a browser.
--
-- IDEMPOTENT. Name-targeted. No contacts or forms are inserted - this batch
-- records findings only.
--
-- FIRST RUN FAILED - 23514 parties_contact_form_url_chk. Fixed below. Nothing
-- from the first attempt landed, because the SQL Editor aborts the whole script
-- on the first error, so this file simply replaces it.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) MARUO - disqualify ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "no", "reason": "PAPER IS NOT A MARUO MARKET. The applications list in maruo-cal.co.jp own site navigation, repeated on every page, reads - synthetic resin (sealants, adhesives, plastisol / film / plastics), paint and ink, rubber, food additives, pharmacopoeia, other. No paper. Maruo is a sealant and resin PCC producer. Right mineral, wrong market - the same shape as Thiele Kaolin, which is real kaolin with no CaCO3 line.", "checked_at": "2026-07-17", "source": "maruo-cal.co.jp product navigation", "source_type": "marketing"}, "contactability": {"note": "A product enquiry form exists at /html/General_Inquiry.html and soumu@maruo-cal.co.jp is published, but soumu is General Affairs, not a technical route. DELIBERATELY NOT RECORDED as a contact - this company is not a target, and a recorded contact route on a non-target is how a wrong target becomes a sent message.", "checked_at": "2026-07-17"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] NOT AN FCC TARGET. Opened maruo-cal.co.jp - the applications list has no paper. Sealant and resin PCC. TSE-listed with an IR section, subsidiaries Kyushu Calcium (GCC manufacturing) and a Shanghai trading arm. Keep the row for market intelligence. Do not build a form and do not enrol.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'maruo'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 2) BIHOKU - strong ----------
-- NOTE: preferred_contact_method is NOT set here, and that is the fix.
-- The first run threw 23514 on parties_contact_form_url_chk. Migration 027 makes
-- the two badge columns coherent BY CONSTRUCTION - you cannot declare web_form
-- while leaving contact_form_url null, because the badge reads only those two
-- columns and a form-based party with no form URL means nothing.
-- The constraint is right and I was wrong. I refused to guess Bihoku's contact
-- URL (correct - the site has two live structures) and then declared web_form
-- anyway (incorrect). Those are the same decision and I made it both ways.
-- preferred_contact_method stays null until someone confirms the real URL.
update app.parties p
set website      = coalesce(p.website, 'https://www.bihokufunka.co.jp'),
    country_code = coalesce(p.country_code, 'JP'),
    city         = coalesce(p.city, 'Niimi'),
    region       = coalesce(p.region, 'Okayama'),
    phone_e164   = coalesce(p.phone_e164, '+81867722158'),
    updated_at = now()
where p.party_name ~* 'bihoku' and p.party_type_id = 3 and p.deleted_at is null;

update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "strong", "reason": "Paper is a core Bihoku market, not an afterthought. The homepage lists paper among its product uses and the site states the company developed high-quality calcium carbonate PIGMENT FOR PAPERMAKING. The wet-ground line is marketed as the optimal filler for NEUTRAL PAPERMAKING with high solids content, and the site explicitly claims it achieves COST REDUCTION - that is the FCC argument written in their own words to their own customers. Owns its limestone at the Karato mine, Niimi, about 100 million tonnes, plus the Otakine mine in Fukushima.", "checked_at": "2026-07-17", "source": "bihokufunka.co.jp", "source_type": "marketing"}, "contactability": {"form_exists": true, "issue": "SITE WAS REBUILT AND BOTH VERSIONS ANSWER. The old structure at /index.html and /contact2.html carries a 2015 copyright. A newer structure at /pages/N/ was updated this month. I will NOT guess which contact page is live - open the site and confirm. The new pages carry the line - estimates, questions and consultations are welcome.", "phone": "+81 867-72-2158", "checked_at": "2026-07-17"}, "products": {"primary": "GCC (heavy calcium carbonate) - Softon and BF series, Lighton series, wet-ground products", "also": "Japanese Pharmacopoeia precipitated calcium carbonate and food-additive grade (Calmigen), made at the Tetta plant under a clean room, food-additive GMP 2003, Halal 2016, FSSC22000 2019", "fineness": "wet-dried line reaches roughly 11 m2/g BET"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] STRONG FCC TARGET. Bihoku sells paper-grade CaCO3 pigment and markets its wet line as the optimal neutral-papermaking filler that cuts cost. They already tell their customers the story FCC extends. Contact form exists but the site has two live structures - confirm the current contact URL before recording it.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'bihoku'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 3) SHIRAISHI - strong, and check the entity split ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "strong", "reason": "shiraishi.co.jp lists PAPER among its applications and the group makes UFPCC, PCC and GCC. It runs an OPEN TESTING LABORATORY and publishes at conferences and in journals. A company that publishes can assess our two ACS papers on the public record before any commercial conversation - which is precisely the door the filler_safe answer set is written for. Founded 1909 on the inventor of the carbon-dioxide synthesis route for CaCO3, patented 1914.", "checked_at": "2026-07-17", "source": "shiraishi.co.jp product and group pages", "source_type": "marketing"}, "entity_split": {"warning": "TWO ENTITIES SHARE THE OSAKA HQ - Shiraishi Kogyo Kaisha, the MANUFACTURER, and Shiraishi Calcium Kaisha, a TRADING company. Same shape as Taekyung Industrial and Taekyung BK, which produced duplicate rows in this database twice. Check which entity is held here before contacting either, and do not create the second one without checking for it first.", "raised_at": "2026-07-17"}, "scale": {"group_companies": 22, "sites": 44, "europe": "PCC manufacture and sales at Gummern, Austria", "china": "Shanghai office"}, "contactability": {"form_url": null, "note": "Contact URL did not surface in search. Needs one look from a browser. The group site is large and well maintained, so a contact route certainly exists."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] STRONG FCC TARGET. Paper is a listed application, UFPCC + PCC + GCC, open testing laboratory, publishes research. Entity split - Shiraishi Kogyo (manufacturer) vs Shiraishi Calcium (trading). Check which one is in this database before contacting. Contact URL not yet found.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'shiraishi|白石'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.country_code, p.city, p.preferred_contact_method,
--        p.contact_form_url,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit,
--        left(f.extra_data #>> '{fcc_fit,reason}', 70) as why
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'maruo|bihoku|shiraishi|白石' and p.deleted_at is null
-- order by p.party_name;
-- EXPECT - Maruo 'no', Bihoku 'strong', Shiraishi 'strong'.


-- ---------- 5) WHAT THIS BATCH COST AND WHAT IT BOUGHT ----------
-- Three companies, five searches. One disqualified before anyone wasted a
-- message on it, two confirmed as real targets with the reason recorded in their
-- own words rather than mine.
--
-- Maruo is the point. It sat in the target list at evidence B with a plausible
-- profile, and it makes precipitated calcium carbonate, and it is completely
-- wrong for FCC. Nothing in the database would have caught that. Only the
-- navigation bar on its own website did.
--
-- Remaining Japanese rows to sweep - Nittetsu Mining, Fimatec, Okutama Kogyo,
-- Takehara Chemical, and the rest of the JP nine. Then Zantat (MY, Bursa-listed),
-- Q-min (TH, listed), Gulshan Polyols (IN).
--
-- And ahead of all of them - Artemyn. 17 carbonate plants, a P&B lab at Par Moor,
-- named people on its leadership page, and a homepage that says its leadership
-- will talk to partners. That one does not need a form at all.
