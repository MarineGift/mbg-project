-- ============================================================
-- enrich_batch9c2_us_emails.sql (2026-07-06)
-- Batch 9c-2: US residual firms (_us2 5 + _us 9 = 14 researched).
-- APPLIED (3) - own-site / multi-source verified:
--   Obvious Ventures          info@obvious.com   (PEI + Crunchbase + pitch guide - "pitch via form or this email")
--   Overture VC               info@overture.vc   (Crunchbase contact email, climate/industrial fund)
--   Osage University Partners info@oup.vc        (official contact page oup.vc/contact - top grade)
-- REVIEW (2) - commented out:
--   Compound (compound.vc)  info@compound.vc  - own about-page lists an email but masks it, local part assumed - verify
--   Humba Ventures - GP Leo Polovets states his pitch email is public on his LinkedIn profile - grab it there
-- FORM-ONLY (9) - no public inbox, nothing fabricated:
--   Fine Structure (F-Prime), Innovation Endeavors, Third Sphere (deck form),
--   1955 Capital (sust. manufacturing fit - form worth doing), ADM Ventures,
--   Overlay Capital (2026 waste+materials fund), Ponderosa (oceans/forestry - TOP fit, 15-day decision form),
--   Refactor (form goes straight to solo GP inbox), Seabird Ventures (SOA ocean fund)
-- NAME-COLLISION WARNINGS - never use these:
--   marco@adm-ventures.com   = Swiss advisory firm, NOT the ADM CVC
--   seabirdventures@gmail.com = Alaska boat-tour company, NOT the ocean fund
-- Matching: name pattern + investor_profile existence (wave source strings vary).
-- ============================================================

-- (1) contacts
insert into app.contacts (organization_id, party_id, contact_type_id, email, full_name, source)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       p.id, v.contact_type_id, v.email, v.full_name, 'investor_email_batch9c2'
from app.parties p
join (values
  ('Obvious Ventures%', 'info@obvious.com', 'Obvious Ventures (general)',           1::smallint),
  ('Overture%',         'info@overture.vc', 'Overture VC (general)',                1::smallint),
  ('Osage U%',          'info@oup.vc',      'Osage University Partners (general)',  1::smallint)
) as v(match_pat, email, full_name, contact_type_id) on p.party_name ilike v.match_pat
where p.deleted_at is null
  and exists (select 1 from app.investor_profile ip where ip.party_id = p.id)
  and not exists (
    select 1 from app.contacts c
    where c.party_id = p.id and lower(c.email) = lower(v.email));

-- REVIEW tier (uncomment after verification):
-- ('Compound%',       'info@compound.vc',       'Compound (local part assumed - verify on site)', 1::smallint),
-- ('Humba Ventures%', '<from-LinkedIn>',        'Leo Polovets (GP - email on his LinkedIn)',      5::smallint),

-- (2) email_whitelist
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.pattern, v.kind, v.notes, true
from (values
  ('obvious.com', 'domain', 'Obvious Ventures (batch9c2)'),
  ('overture.vc', 'domain', 'Overture VC (batch9c2)'),
  ('oup.vc',      'domain', 'Osage University Partners (batch9c2)')
) as v(pattern, kind, notes)
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and lower(w.pattern) = lower(v.pattern));

-- (3) VERIFY: expect 3 contact + 3 whitelist = 6 rows
select 'contact' as kind, p.party_name as name, c.email as detail
from app.contacts c
join app.parties p on p.id = c.party_id
where c.source = 'investor_email_batch9c2'
union all
select 'whitelist', w.pattern, w.kind
from app.email_whitelist w
where w.notes like '%batch9c2%'
order by 1, 2;
