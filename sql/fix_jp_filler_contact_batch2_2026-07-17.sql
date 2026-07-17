-- ============================================================
-- fix_jp_filler_contact_batch2_2026-07-17.sql
--
-- Japanese filler sweep, batch 2. One of the strongest targets found all week,
-- and one that must not be approached until you decide - because it runs on your
-- own partner's technology.
--
-- ------------------------------------------------------------
-- OKUTAMA KOGYO - STRONG. Over 90 percent of Japanese paper PCC.
--   okutama.co.jp/project/papermaking/ states it plainly: Tamapearl, their PCC,
--   sells nationwide from Hokkaido to Kagoshima and holds an overwhelming share
--   of OVER 90 PERCENT for papermaking use. Filler and coating both.
--   Their own synthesis technology, controlled particle size, in production
--   since 1975. A Taiheiyo Cement group company. They set up Niigata PCC Co.,
--   Ltd. in 2002 - a satellite operation.
--
--   AND THEIR CONTACT PAGE ANSWERS THE QUESTION I HAVE BEEN ASKING ALL DAY.
--   I kept saying the Subject dropdown decides whether a form is the right door.
--   Okutama does not use a dropdown. It NAMES THE DEPARTMENT for each subject:
--     paper filler and coating agents  -> Tamapearl Sales Section  042-540-5571
--     technical enquiries              -> Technical Research Inst.  042-557-3111
--     aggregate and soil business      -> Crushed Stone Sales Dept
--     recruitment, results, other      -> HQ General Affairs
--   plus an email form at okutama.co.jp/contact/ with a confirmation step.
--   No guessing which door. Both doors are labelled, and one of them is a
--   research institute.
--
--   WHY A 90 PERCENT INCUMBENT IS THE RIGHT SHAPE OF LICENSEE, not the wrong
--   one: they already own the mill relationships, they already have the plants,
--   and a dominant share is a thing to DEFEND. FCC is defensive for them and
--   offensive for anyone else. That argument does not need a single number from
--   the nda_only set.
--
-- ------------------------------------------------------------
-- FIMATEC - DO NOT APPROACH YET. It is entangled with Specialty Minerals.
--   fmt.co.jp/quality/factory.html, their own words: the on-site PCC operation
--   was established in 1997 as a JOINT VENTURE WITH MINTEQ JAPAN, built by
--   INTRODUCING THE TECHNOLOGY OF SPECIALTY MINERALS OF THE USA, and today
--   produces PCC INSIDE NIPPON PAPER'S SHIRAOI MILL.
--
--   Specialty Minerals is your partner - partner_names, nda_only, names Omya for
--   the paper filler track and Specialty Minerals for the tissue track. So
--   Fimatec's satellite PCC business stands on your own partner's licensed
--   technology.
--
--   This is not adversity like Taekyung. It is ENTANGLEMENT, and it is a
--   different failure mode that the database also has no field for. Nothing in
--   evidence_level, market_role, supply_model or fcc_fit can say "approaching
--   this company touches a relationship you already have". Taekyung taught that
--   every field measures fit and none measures conflict. Fimatec shows the same
--   gap from the other side - a target that is commercially perfect and
--   politically expensive.
--
--   I am not deciding this. It is your partner relationship. Recorded so nobody
--   walks past it.
--
--   Fimatec's OWN business, distinct from the SMI-licensed satellite, is
--   wet-ground GCC coating pigment (the FMT brand) made at four domestic plants
--   plus Thailand. Their paper page says talc and PCC go to filler while GCC and
--   kaolin go to coating - so their filler offering IS the SMI-derived PCC.
--   FCC is a filler. The overlap is exact.
--
--   BONUS IDENTIFICATION: the database row "F.M.T. (Thailand) Co., Ltd." at
--   evidence B with a null website is Fimatec's Thai subsidiary - GCC at
--   Singburi, 150km north of Bangkok, serving paper, white board and rubber
--   gloves. Same entanglement applies.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted, nothing deleted.
-- preferred_contact_method is only set where a real contact_form_url is set with
-- it - migration 027's parties_contact_form_url_chk requires the pair to be
-- coherent, and it caught me writing web_form with a null URL an hour ago.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) OKUTAMA - the form URL and the method, together ----------
update app.parties p
set website                  = coalesce(p.website, 'https://www.okutama.co.jp'),
    country_code             = coalesce(p.country_code, 'JP'),
    city                     = coalesce(p.city, 'Tachikawa'),
    region                   = coalesce(p.region, 'Tokyo'),
    phone_e164               = coalesce(p.phone_e164, '+81425405571'),
    contact_form_url         = 'https://www.okutama.co.jp/contact/',
    preferred_contact_method = 'web_form',
    updated_at = now()
where p.party_name ~* 'okutama|奥多摩' and p.party_type_id = 3 and p.deleted_at is null;


-- ---------- 2) OKUTAMA profile ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "strong", "reason": "Okutama states on its own papermaking page that Tamapearl, its PCC, holds an overwhelming share of OVER 90 PERCENT of Japanese papermaking use, sold nationwide from Hokkaido to Kagoshima, as both filler and coating pigment. Own synthesis technology with controlled particle size, in production since 1975. A dominant incumbent is the right shape of licensee, not the wrong one - they already hold the mill relationships and the plants, and a 90 percent share is a thing to defend. FCC is defensive for them and offensive for everyone else.", "checked_at": "2026-07-17", "source": "okutama.co.jp/project/papermaking/", "source_type": "marketing"}, "contactability": {"form_url": "https://www.okutama.co.jp/contact/", "form_note": "Email form with a confirmation step. Reply comes by mail or phone.", "departments_named": {"paper_filler_and_coating": "Tamapearl Sales Section, TEL 042-540-5571", "technical": "Technical Research Institute, TEL 042-557-3111", "aggregate_and_soil": "Crushed Stone Sales Department, TEL 0428-74-4501", "hq_admin_and_results": "HQ General Affairs and Accounting, TEL 042-540-5670"}, "why_this_matters": "No Subject dropdown to guess at. The contact page labels each door by department, and one of them is a research institute. This is the clearest contact structure found in the whole filler sweep.", "checked_at": "2026-07-17"}, "corporate": {"parent": "Taiheiyo Cement group company", "hq": "Akebono-cho, Tachikawa, Tokyo", "brands": ["Tamapearl - PCC", "Tamacalc - high specific surface area calcium hydroxide, since 1995", "Tamablanc", "Masters"], "satellite": "Niigata PCC Co., Ltd. established March 2002", "mine": "Okutama district limestone deposit, western Tokyo"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] STRONG FCC TARGET, arguably the best in Japan. Over 90 percent share of Japanese paper PCC by their own statement. Contact page names the department for each subject rather than using a dropdown - Tamapearl Sales Section for paper filler, Technical Research Institute for technical. Form at okutama.co.jp/contact/. Taiheiyo Cement group, so a large decision may travel to the parent - worth knowing before pitching.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'okutama|奥多摩'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 3) FIMATEC - hold. Entangled with your own partner. ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "hold - decision required", "reason": "COMMERCIALLY A FIT, POLITICALLY EXPENSIVE. Fimatec own words at fmt.co.jp/quality/factory.html - the on-site PCC operation was established in 1997 as a joint venture with MINTEQ JAPAN, built by INTRODUCING THE TECHNOLOGY OF SPECIALTY MINERALS OF THE USA, and today produces PCC inside NIPPON PAPER SHIRAOI MILL. Specialty Minerals is our tissue-track partner. Their filler business runs on our partner licensed technology, and FCC is a filler. Not adverse like Taekyung - ENTANGLED. Requires a human decision, not a ranking.", "checked_at": "2026-07-17", "source": "fmt.co.jp/quality/factory.html", "source_type": "disclosure"}, "entanglement": {"with": "Specialty Minerals / Minteq Japan", "how": "1997 JV with Minteq Japan, on-site PCC plant built on Specialty Minerals US technology, operating inside Nippon Paper Shiraoi mill", "why_it_matters": "SMI is named in partner_names (nda_only) as the tissue-track partner. Approaching Fimatec about licensing a filler technology touches a relationship we already hold.", "structural_note": "The database has no field for this. evidence_level, market_role, supply_model and fcc_fit all measure fit. Taekyung showed nothing measures CONFLICT. Fimatec shows nothing measures ENTANGLEMENT either - a target that is commercially perfect and politically costly looks identical to a clean one in every column.", "raised_at": "2026-07-17"}, "own_business": {"note": "Distinct from the SMI-licensed satellite. Fimatec is primarily a specialised trading house for calcium carbonate. Its own product is wet-ground GCC coating pigment, the FMT brand, made at four domestic plants plus Thailand, including an ultrafine grade marketed as a kaolin replacement.", "paper_split_per_their_site": "talc and PCC go to filler, GCC and kaolin go to coating - so their FILLER offering is the SMI-derived PCC, and FCC is a filler. The overlap is exact.", "hq": "Ochanomizu Center Building 5F, 2-23-1 Kanda Awajicho, Chiyoda-ku, Tokyo 101-0063, TEL 03-5295-8061", "other_jv": "2017 JV with Top Glove, GCC for rubber gloves produced inside Top Glove premises, plant completed March 2018"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] HOLD - do not approach until you decide. Fimatec on-site PCC is a Minteq Japan JV running Specialty Minerals technology inside Nippon Paper Shiraoi. SMI is our tissue-track partner. Commercially this is a fit and politically it is not mine to call. Their own GCC coating business (FMT brand, 4 JP plants + Thailand) is separate, but their FILLER offering is the SMI-derived PCC and FCC is a filler.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'fimatec|ファイマテック'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 4) F.M.T. (Thailand) - identified ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"identified": {"what": "Fimatec Thai subsidiary, not an independent company. GCC produced at Singburi, about 150km north of Bangkok, serving paper, white board and rubber glove customers.", "source": "fmt.co.jp/quality/factory.html", "checked_at": "2026-07-17", "consequence": "The Fimatec / Specialty Minerals entanglement applies here too. Hold."}, "fcc_fit": {"verdict": "hold - decision required", "reason": "Subsidiary of Fimatec, which runs its on-site PCC on Specialty Minerals technology via a Minteq Japan JV. SMI is our tissue-track partner. See the parent row.", "checked_at": "2026-07-17"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] IDENTIFIED as Fimatec Thailand - the row had a null website and evidence B. GCC at Singburi for paper, white board and rubber gloves. Inherits the Fimatec hold - the group PCC business runs on Specialty Minerals technology and SMI is our partner.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'F\.M\.T|FMT.*Thailand'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- 5) VERIFY ----------
-- select p.party_name, p.country_code, p.contact_form_url, p.preferred_contact_method,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'okutama|奥多摩|fimatec|ファイマテック|F\.M\.T' and p.deleted_at is null
-- order by p.party_name;
-- EXPECT - Okutama 'strong' with a form URL, Fimatec and FMT Thailand both
-- 'hold - decision required'.


-- ---------- 6) RUNNING TALLY OF THE SWEEP ----------
--   Maruo Calcium      no    - paper is not in its applications list
--   Bihoku Funka       strong - paper-grade CaCO3, neutral papermaking, cost-down
--   Shiraishi Group    strong - paper listed, UFPCC+PCC+GCC, open testing lab
--   Okutama Kogyo      strong - 90%+ of Japanese paper PCC, departments named
--   Fimatec            HOLD   - runs on Specialty Minerals technology
--   F.M.T. (Thailand)  HOLD   - Fimatec subsidiary
--
-- Six opened, two disqualified or held, three strong, and one of the three has
-- the clearest contact structure of any company in the list.
--
-- Still to sweep in Japan - Nittetsu Mining, Takehara Chemical, and the rest of
-- the JP nine. Then Zantat (MY, Bursa-listed), Q-min (TH, listed), Gulshan
-- Polyols (IN).
--
-- The pattern holds every time: nothing in this database could distinguish Maruo
-- from Okutama, or a clean target from one standing on our own partner's
-- licence. Only the companies' own websites could.
