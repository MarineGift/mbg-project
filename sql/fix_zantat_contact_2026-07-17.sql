-- ============================================================
-- fix_zantat_contact_2026-07-17.sql
--
-- THE CLEAREST INVITATION IN THE ENTIRE SWEEP, in Zantat's own words on
-- zantat.com.my/contact.php:
--
--   "We welcome inquiries regarding potential BUSINESS OPPORTUNITIES AND
--    PARTNERSHIP COLLABORATIONS. feel free to connect with us for more
--    information and discussion at sales@zantat.com.my"
--
-- The company itself designates sales@ as the partnership door. That is the
-- opposite of 20 Microns, whose form is framed as "product related assistance"
-- and reads like a sales queue. Here the word partnership is theirs, not mine.
--
-- AND THEIR BUSINESS CONCEPT IS THE FCC ARGUMENT ALREADY:
--   "Providing Cost-saving Solution to Create Value"
-- Third time this sweep a target's own marketing states the case before we do -
-- Bihoku on neutral papermaking and cost reduction, 20 Microns on TiO2
-- replacement, Zantat on cost-saving as the whole company concept.
--
-- WHAT THEY ARE
--   Malaysia's leading producer of high-grade calcium carbonate powder and
--   dispersions, since 1986. Top 3 in Malaysian CaCO3. Owns a quarry at Simpang
--   Pulai, Ipoh. Serves rubber, paint, coatings, plastics and PAPER.
--   Products span GCC and PCC in both powder and dispersion form, plus talc.
--   Brands - Zancarb 3NC/OG, Zancarb 3C/3CG, Supercarb, Superlite, Zancarb CC-R,
--   TW280, Superlite W55-2, WG-3, Zancarb Z80.
--   Pioneered CaCO3 dispersion as a latex glove filler in 2002 - the first in
--   the country. A company that invented a new filler application for a new
--   industry is a company that takes filler innovation seriously.
--
-- CONTRADICTION FOUND, NOT RESOLVED.
--   This database says "MY top-3 CaCO3 producer (BURSA ACE LISTED)".
--   Zantat's own material and two profile services describe it as "a FAMILY-
--   OWNED company spanning two generations of decision makers".
--   Both can be true if a family firm listed recently and kept control. But I am
--   not asserting either, because guessing at a company's ownership is how the
--   Imerys rows ended up describing assets sold in 2024, and how Artemyn sat here
--   as a kaolin merchant. Flagged for one check.
--   If it IS listed, Bursa filings name the directors - the same route that would
--   work for 20 Microns via Indian filings. The site has a Board of Directors
--   page either way.
--
-- A capacity figure of 60,000 tonnes per annum appears in a third-party
-- directory. NOT RECORDED - directory capacity numbers are exactly the kind of
-- stale figure this session has been correcting all week.
--
-- WEAK LEAD, RECORDED AS WEAK: one low-quality directory lists "Calrock" among
-- Zantat's business activities. There is a Calrock row in this database that was
-- excluded from targeting. If Calrock is a Zantat brand rather than an
-- independent company, that row is a duplicate of this one. Single low-quality
-- source, so this is a lead to check, not a finding.
--
-- The inbox is generic and stays that way. full_name is null. sales@ is a queue,
-- not a person - the same rule that stopped the bulk derivation inventing
-- fourteen people from local-parts yesterday.
--
-- preferred_contact_method is NOT set. I do not know the allowed values of
-- parties_preferred_contact_method_chk, and an hour ago I guessed at the
-- neighbouring constraint and threw 23514. Not twice.
--
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) Address and phone from their own contact page ----------
update app.parties p
set country_code = coalesce(p.country_code, 'MY'),
    city         = coalesce(p.city, 'Kuala Lumpur'),
    phone_e164   = coalesce(p.phone_e164, '+60353571853'),
    updated_at = now()
where p.party_name ~* 'zantat' and p.party_type_id = 3 and p.deleted_at is null;


-- ---------- 2) The partnership inbox they named themselves ----------
insert into app.contacts
  (organization_id, party_id, contact_type_id, email, is_primary, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, p.id, 2,
       'sales@zantat.com.my', true, 'homepage',
       'GENERIC INBOX - not a person, full_name deliberately null. Zantat designates this address ITSELF on zantat.com.my/contact.php as the route for potential business opportunities and partnership collaborations. Their word, not ours. zantat@zantat.com.my is the general address on the same page and is the fallback. hr@zantat.com.my is recruitment and must not be used. HQ - Lot 1013-B, Jalan 2/32A, 6.5 Miles, Kepong Industrial Area, Jalan Kepong, 52100 Kuala Lumpur. Plant - PT24571 and PT21289, Kaw. Industri Batu Kapur Keramat Pulai, 31300 Kampung Kepayang, Perak, tel +605 357 1853 and +605 357 1463.'
from app.parties p
where p.party_name ~* 'zantat' and p.party_type_id = 3 and p.deleted_at is null
  and not exists (select 1 from app.contacts c
                  where c.party_id = p.id and c.email = 'sales@zantat.com.my' and c.deleted_at is null);


-- ---------- 3) Profile ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "strong", "reason": "Makes GCC and PCC in both powder and dispersion form and lists PAPER among its industries. Its stated business concept is Providing Cost-saving Solution to Create Value - the FCC argument is already the company slogan. It pioneered calcium carbonate dispersion as a latex glove filler in 2002, the first in Malaysia, so it has a record of inventing new filler applications rather than only shipping grades. Owns its quarry at Simpang Pulai, Ipoh. Outside every exclusion.", "checked_at": "2026-07-17", "source": "zantat.com.my", "source_type": "marketing"}, "contactability": {"partnership_inbox": "sales@zantat.com.my", "why_this_one": "Zantat names this address itself for potential business opportunities and partnership collaborations. Compare 20 Microns, whose form is framed as product related assistance and reads like a sales queue. This is the clearest invitation found in the sweep.", "general_inbox": "zantat@zantat.com.my", "do_not_use": "hr@zantat.com.my - recruitment", "hq": "Lot 1013-B, Jalan 2/32A, 6.5 Miles, Kepong Industrial Area, Jalan Kepong, 52100 Kuala Lumpur", "plant": "PT24571 and PT21289, Kaw. Industri Batu Kapur Keramat Pulai, 31300 Kampung Kepayang, Perak", "phone": "+605 357 1853 / +605 357 1463", "site_note": "www.zantat.com.my is a JavaScript app. The older pages at zantat.com.my/contact.php still respond and carry the addresses.", "checked_at": "2026-07-17"}, "products": {"range": "GCC dispersion, PCC dispersion, GCC powder, PCC powder, talc", "brands": ["Zancarb 3NC / OG", "Zancarb 3C / 3CG", "Supercarb", "Superlite", "Zancarb CC-R", "TW280", "Superlite W55-2", "WG-3", "Zancarb Z80"], "industries": "rubber, paint, coatings, plastics, paper", "first": "first in Malaysia to develop calcium carbonate dispersion as a latex glove filler, 2002"}, "unresolved": {"ownership_conflict": {"this_database_says": "Bursa ACE listed", "the_company_says": "a family-owned company spanning two generations of decision makers, since 1986", "status": "NOT RESOLVED. Both can be true if a family firm listed recently and kept control, but I am not asserting either. Guessing at ownership is how the Imerys rows ended up describing assets sold in 2024. If it IS listed, Bursa filings name the directors. The site has a Board of Directors page regardless.", "raised_at": "2026-07-17"}, "capacity_not_recorded": "A third-party directory states 60,000 tonnes per annum. Deliberately not written to this profile - directory capacity figures are exactly the stale-number problem being corrected elsewhere in this database.", "calrock_lead": {"claim": "One low-quality directory lists Calrock among Zantat business activities.", "why_it_matters": "There is a separate Calrock row in this database, excluded from targeting. If Calrock is a Zantat brand rather than an independent company, that row duplicates this one.", "evidence": "single low-quality source - a LEAD to check, not a finding"}}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] STRONG FCC TARGET with the clearest door in the sweep. Zantat itself designates sales@zantat.com.my for business opportunities and partnership collaborations. GCC + PCC, powder + dispersion, paper among its industries, own quarry at Simpang Pulai. Company concept is literally Providing Cost-saving Solution to Create Value. UNRESOLVED - this database says Bursa ACE listed, the company says family-owned across two generations. Check before writing anything that assumes either.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'zantat'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.country_code, p.city, p.phone_e164,
--        c.email, c.full_name, c.is_primary,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit
-- from app.parties p
-- left join app.contacts c on c.party_id = p.id and c.deleted_at is null
-- left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'zantat' and p.deleted_at is null;
-- EXPECT - MY, Kuala Lumpur, sales@zantat.com.my with full_name NULL, 'strong'.


-- ---------- 5) THE SWEEP ----------
--   Maruo Calcium      no     - sealant and resin PCC, paper not in its list
--   Bihoku Funka       STRONG - paper-grade CaCO3, neutral papermaking, cost-down
--   Shiraishi Group    STRONG - paper listed, UFPCC+PCC+GCC, open testing lab
--   Okutama Kogyo      STRONG - 90%+ of Japanese paper PCC, departments named
--   Fimatec            HOLD   - on-site PCC runs on Specialty Minerals technology
--   F.M.T. (Thailand)  HOLD   - Fimatec subsidiary
--   Nittetsu Mining    no     - limestone miner, sells rock by the centimetre
--   20 Microns         STRONG - PCC+GCC, paper coating pigments, sells TiO2 replacement
--   Artemyn            TOP    - 17 carbonate plants, Chris Nutbeem at the Par Moor P&B lab
--   Zantat             STRONG - names its own partnership inbox
--
-- TEN OPENED. SIX WORTH CONTACTING. Filler parties with a contact went from 4 to
-- 6 today, and both additions are inboxes the companies published themselves.
--
-- Still to sweep - Q-min (TH, listed), Gulshan Polyols (IN), Takehara Chemical,
-- and the rest.
