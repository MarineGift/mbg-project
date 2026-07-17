-- ============================================================
-- fix_artemyn_contact_form_2026-07-17.sql
--
-- THE FIRST contact_inquiry FORM IN THIS DATABASE. Migration 027 built this
-- machinery for "any party that communicates via a web form (mills included)"
-- and nothing has ever used it - form_type contact_inquiry has zero rows.
--
-- CONFIRMED FROM artemyn.com DIRECTLY:
--   contact form   https://www.artemyn.com/en/pages/contact
--   global offices New York City (USA) and Paris (France) - both marked "Global
--                  Office", which is why country_code was ambiguous
--   parent         "Part of - Flacks Group" in the site footer
--   footprint      sites in 16 countries, and the site publishes the MINERAL AT
--                  EACH SITE. Calcium carbonate industrial facilities:
--                    Somerset ME (US), Bennettsville SC (US), Ledesma (AR),
--                    Capitan Bermudez (AR), Limeira (BR), Pirai (BR),
--                    Tunadal (SE), Husum (SE), Yueyang (CN), Amritsar (IN),
--                    Balasore (IN), Bhadrachalam (IN), Bhigwan (IN),
--                    Silvassa (IN), Miyagi (JP), Niigata (JP), Kaohsiung (TW)
--                  plus Rauma (FI) warehousing kaolin and calcium carbonate.
--                  SEVENTEEN calcium carbonate plants.
--   R&D            Par Moor, United Kingdom - listed as "P&B Lab", a paper and
--                  board laboratory. That is the FCC counterpart.
--
-- READ THE PLANT LOCATIONS. Somerset ME, Bennettsville SC, Husum SE,
-- Bhadrachalam IN, Niigata JP - these are paper mill towns. Carbonate plants
-- placed at paper mills are on-site satellite plants. ARTEMYN IS A SATELLITE
-- OPERATOR, which puts it in Tier 1 of scan_fcc_target_ranking. I said there
-- were four - Specialty Minerals, Taekyung BK, Double A Specialty Minerals and
-- Fimatec. There are five, and the fifth is the largest one outside SMI. It has
-- been sitting in the database as a kaolin merchant with a null country.
--
-- THE SITE INVITES THIS EXACT APPROACH, in its own words:
--   "We believe great change happens through collaboration. Whether you are an
--    investor, PARTNER, or industry peer, our leadership team is ready to talk."
--
-- WHAT I COULD NOT GET, and did not invent.
-- The contact page returns an empty shell - the form is a HubSpot embed rendered
-- client-side (the newsletter and brochure both post to 2e6ohs.share-eu1
-- .hsforms.com, so portal 2e6ohs on HubSpot EU1). A server fetch sees no fields.
-- SO NO application_form_fields ARE CREATED HERE. Field labels, types, max_length
-- and the Subject dropdown options need a human or a browser on that page.
-- Guessing them would defeat the entire point of the variant system, which picks
-- a body against a REAL max_length.
--
-- The one thing already known about the form: a Subject dropdown exists. Artemyn
-- 's whistleblower page says "please return to the Contact Us page and select the
-- Subject that corresponds to your specific matter". Whether that dropdown
-- carries a partnership or technology option is THE question - if it only offers
-- sales, the form routes to a sales queue and is the wrong door.
--
-- created_by is set explicitly. application_forms declares
-- created_by uuid NOT NULL DEFAULT auth.uid(), and auth.uid() is null in the SQL
-- Editor - that is what threw 23502 on the answer seed an hour ago.
--
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) The party: form URL, contact method, offices ----------
update app.parties p
set contact_form_url        = 'https://www.artemyn.com/en/pages/contact',
    preferred_contact_method = 'web_form',
    city         = coalesce(p.city, 'Paris'),
    country_code = coalesce(p.country_code, 'FR'),
    updated_at = now()
where p.id = '7868456a-bd64-4de2-9930-74cd21db8dea'::uuid
  and p.deleted_at is null;


-- ---------- 2) The footprint, from Artemyn's own site ----------
update app.filler_supplier_profile f
set supply_model = 'Merchant + on-site satellite carbonate plants at paper mills',
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"footprint": {"source": "artemyn.com/en global presence map", "source_type": "marketing", "checked_at": "2026-07-17", "sites_countries": 16, "global_offices": ["New York City, USA", "Paris, France"], "calcium_carbonate_plants": ["Somerset, ME, US", "Bennettsville, SC, US", "Ledesma, AR", "Capitan Bermudez, AR", "Limeira, BR", "Pirai, BR", "Tunadal, SE", "Husum, SE", "Yueyang, CN", "Amritsar, IN", "Balasore, IN", "Bhadrachalam, IN", "Bhigwan, IN", "Silvassa, IN", "Miyagi, JP", "Niigata, JP", "Kaohsiung, TW"], "carbonate_plant_count": 17, "kaolin": ["Capim / PPSA mine, BR - stated as the world largest kaolin reserve, 25000 acres, 2 mines", "Barcarena port, BR", "Sunila, FI", "Gavle, SE", "Halla / Inkoo / Rauma warehouses, FI"], "talc": ["Suzuka, JP", "Tomakomai, JP"], "rnd": "Par Moor, United Kingdom - listed as P&B Lab, a paper and board laboratory", "brands": ["Capim", "BarriKote", "Carbiloop", "EcoBright", "ArteMax"]}, "satellite_read": {"claim": "Artemyn is a satellite PCC operator, not only a merchant", "basis": "Its own site places carbonate plants at Somerset ME, Bennettsville SC, Husum SE, Bhadrachalam IN and Niigata JP - all paper mill locations. A carbonate plant sited at a paper mill is an on-site satellite. Artemyn is therefore a FIFTH satellite operator in this database alongside Specialty Minerals, Taekyung BK, Double A Specialty Minerals and Fimatec, and the largest of those outside SMI.", "confidence": "medium - inferred from plant siting, not from a statement that these are satellites. Confirm per site before relying on it.", "checked_at": "2026-07-17"}, "open_door": {"quote": "Whether you are an investor, partner, or industry peer, our leadership team is ready to talk.", "where": "artemyn.com/en homepage", "note": "The company publicly invites partner approaches. Also exhibited at TAPPICon 2026 and holds an EcoVadis silver rating."}}'::jsonb,
    updated_at = now()
where f.party_id = '7868456a-bd64-4de2-9930-74cd21db8dea'::uuid
  and f.deleted_at is null
  and not (coalesce(f.extra_data, '{}'::jsonb) ? 'footprint');


-- ---------- 3) THE FORM ROW ----------
insert into app.application_forms
  (organization_id, party_id, form_url, form_type, submission_method,
   login_required, status, notes, created_by)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       '7868456a-bd64-4de2-9930-74cd21db8dea'::uuid,
       'https://www.artemyn.com/en/pages/contact',
       'contact_inquiry',
       'web_form',
       false,
       'not_started',
       'First contact_inquiry form in this database. Target number 1 on the filler list - Artemyn is the former Imerys paper business, 17 calcium carbonate plants, roughly 370m EUR of 2023 sales, independent since July 2024 under a Flacks Group affiliate. FIELDS ARE NOT RECORDED YET and must not be guessed. The page renders its form as a HubSpot embed client-side (portal 2e6ohs on hsforms EU1), so a server fetch returns an empty shell. Someone needs to open the page and capture - field labels, field_type, max_length on the message box, and above all THE SUBJECT DROPDOWN OPTIONS. If Subject offers only sales categories the form routes to a sales queue and is the wrong door - in that case try the Par Moor P&B Lab or the leadership page instead. If it offers partnership, technology or R&D, this is the right door and the answer variant is picked against the message field''s real max_length.',
       coalesce(auth.uid(), (select p.created_by from app.parties p where p.created_by is not null limit 1))
where not exists (
  select 1 from app.application_forms af
  where af.party_id = '7868456a-bd64-4de2-9930-74cd21db8dea'::uuid
    and af.form_type = 'contact_inquiry');


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.country_code, p.preferred_contact_method, p.contact_form_url,
--        af.form_type, af.submission_method, af.status,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit,
--        f.extra_data #>> '{footprint,carbonate_plant_count}' as caco3_plants
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- left join app.application_forms af on af.party_id = p.id
-- where p.id = '7868456a-bd64-4de2-9930-74cd21db8dea'::uuid;
-- EXPECT one contact_inquiry form, web_form, not_started, 17 carbonate plants.


-- ---------- 5) NEXT, IN ORDER ----------
-- (a) Open artemyn.com/en/pages/contact and send me the field list - labels,
--     types, max_length, and the Subject options. Then I write the fields with
--     canonical_key and bind the filler_safe answers by variant. That completes
--     the first form end to end, and the other 77 targets copy the pattern.
-- (b) artemyn.com/en/pages/leadership names people. Par Moor is the P&B Lab. A
--     named technical contact beats a Subject dropdown every time.
-- (c) Consider whether the form is the right door at all here. Artemyn publicly
--     says its leadership will talk to partners, it exhibited at TAPPICon 2026,
--     and it is PE-owned and newly independent - which is exactly the owner
--     profile that wants a differentiation story on a 370m EUR asset. The form
--     may be the slow path.
