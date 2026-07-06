-- ============================================================
-- enrich_batch9a_emails.sql (2026-07-05)
-- Batch 9a: verified contact emails for wave-2 (global) + wave-4
-- (philanthropic) investors -> app.contacts + app.email_whitelist.
-- Research date 2026-07-05. Same pattern as
-- 20260627130000_global_am_investor_emails.sql. Idempotent (NOT EXISTS).
-- No begin/commit and no do-blocks (Supabase editor parser quirks).
--
-- APPLIED (9) - verified on the firm's OWN site / official release:
--   Voima Ventures      inka.mero@voimaventures.com     (MP, compliance page)
--   Metsa Spring        niklas.vonweymarn@metsagroup.com (CEO, Metsa press rel.)
--   UB FIGG             sakari.saarela@unitedbankers.com (Partner, UB press rel.)
--   SWEN Blue Ocean     blueocean@swen-cp.fr            (own site proposal inbox)
--   Evonik Venture Cap. pitch@evonik.com                (official LinkedIn pitch inbox)
--   Schmidt Marine      info@schmidtmarine.org          (own contact page)
--   Grantham Foundation info@granthamfoundation.org     (own contact page)
--   Icos Capital        info@icoscapital.com            (PEI + Mergr corroborated)
--   Prime Coalition     info@primecoalition.org         (PEI - deal flow runs via
--                                                        Azolla Ventures, already in DB)
-- REVIEW (3) - single aggregator source, commented out below:
--   Katapult Ocean hello@katapult.vc / Propeller VC hello@propellervc.com
--   Rhapsody VP contact@rhapsodyvp.com
-- OMITTED (5) - no public pitch email, documented, nothing fabricated:
--   Collateral Good (contact form only - Packaging Innovation Fund is the fit)
--   Pivotal Ventures (states it does not review unsolicited requests - media@ only)
--   Bezos Earth Fund (own site: no unsolicited proposals - grant source only)
--   Gates Foundation Strategic Investment Fund (form/referral only)
--   Autodesk Foundation (no public inbox - portfolio sourced via network)
-- ============================================================

-- (1) contacts (join by exact party_name + wave source)
insert into app.contacts (organization_id, party_id, contact_type_id, email, full_name, source)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       p.id, v.contact_type_id, v.email, v.full_name, 'investor_email_batch9a'
from app.parties p
join (values
  ('Voima Ventures',                       'inka.mero@voimaventures.com',      'Inka Mero (Managing Partner)',        5::smallint),
  ('Metsa Spring',                         'niklas.vonweymarn@metsagroup.com', 'Niklas von Weymarn (CEO)',            5::smallint),
  ('UB Forest Industry Green Growth Fund', 'sakari.saarela@unitedbankers.com', 'Sakari Saarela (Partner)',            5::smallint),
  ('SWEN Blue Ocean',                      'blueocean@swen-cp.fr',             'SWEN Blue Ocean (proposal inbox)',    1::smallint),
  ('Evonik Venture Capital',               'pitch@evonik.com',                 'Evonik Venture Capital (pitch inbox)',1::smallint),
  ('Schmidt Marine Technology Partners',   'info@schmidtmarine.org',           'Schmidt Marine (general)',            1::smallint),
  ('Grantham Foundation',                  'info@granthamfoundation.org',      'Grantham Foundation (general)',       1::smallint),
  ('Icos Capital',                         'info@icoscapital.com',             'Icos Capital (general)',              1::smallint),
  ('Prime Coalition',                      'info@primecoalition.org',          'Prime Coalition (general)',           1::smallint)
) as v(party_name, email, full_name, contact_type_id) on v.party_name = p.party_name
where p.deleted_at is null
  and p.source in ('web_research_2026Q3', 'web_research_2026Q3_phil')
  and not exists (
    select 1 from app.contacts c
    where c.party_id = p.id and lower(c.email) = lower(v.email));

-- REVIEW tier: uncomment after a second source confirms.
-- ('Katapult Ocean', 'hello@katapult.vc', 'Katapult Ocean (general)', 1::smallint),
-- ('Propeller VC', 'hello@propellervc.com', 'Propeller (general - warm intro preferred)', 1::smallint),
-- ('Rhapsody Venture Partners', 'contact@rhapsodyvp.com', 'Rhapsody VP (general)', 1::smallint),

-- (2) email_whitelist (domains for independents, addresses where corp domain too broad)
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.pattern, v.kind, v.notes, true
from (values
  ('voimaventures.com',                'domain',  'Voima Ventures (Nordic deep tech, batch9a)'),
  ('swen-cp.fr',                       'domain',  'SWEN Blue Ocean (batch9a)'),
  ('schmidtmarine.org',                'domain',  'Schmidt Marine Technology Partners (batch9a)'),
  ('granthamfoundation.org',           'domain',  'Grantham Foundation (batch9a)'),
  ('icoscapital.com',                  'domain',  'Icos Capital (batch9a)'),
  ('primecoalition.org',               'domain',  'Prime Coalition (batch9a)'),
  ('niklas.vonweymarn@metsagroup.com', 'address', 'Metsa Spring CEO (metsagroup.com too broad)'),
  ('sakari.saarela@unitedbankers.com', 'address', 'UB FIGG Partner (unitedbankers.com too broad)'),
  ('pitch@evonik.com',                 'address', 'Evonik VC pitch inbox (evonik.com too broad)')
) as v(pattern, kind, notes)
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and lower(w.pattern) = lower(v.pattern));

-- (3) VERIFY: single combined result (expect 9 contact rows + 9 whitelist rows)
select 'contact' as kind, p.party_name as name, c.email as detail
from app.contacts c
join app.parties p on p.id = c.party_id
where c.source = 'investor_email_batch9a'
union all
select 'whitelist', w.pattern, w.kind
from app.email_whitelist w
where w.pattern in ('voimaventures.com','swen-cp.fr','schmidtmarine.org',
                    'granthamfoundation.org','icoscapital.com','primecoalition.org',
                    'niklas.vonweymarn@metsagroup.com','sakari.saarela@unitedbankers.com',
                    'pitch@evonik.com')
order by 1, 2;
