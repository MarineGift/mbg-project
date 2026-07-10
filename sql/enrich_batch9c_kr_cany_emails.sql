-- ============================================================
-- enrich_batch9c_kr_cany_emails.sql (2026-07-05)
-- Batch 9c-1: verified contact emails for wave-6 (KR) + wave-8 (CA/NY)
-- investors -> app.contacts + app.email_whitelist.
-- Same pattern as enrich_batch9a_emails.sql. Idempotent (NOT EXISTS).
-- No begin/commit, no do-blocks, no ';' or bare SQL keywords in strings
-- (Supabase editor parser quirks).
--
-- APPLIED (8) - verified on the firm's OWN site / official channel:
--   Kolon Investment      yjkim721@kolon.com        (official inquiry page - send business plan here)
--   Primer Sazze          info@primersazze.com      (own contact page)
--   Strong Ventures       info@strongvc.com         (Crunchbase + pitch guide, deck submission stated)
--   Samsung Ventures      sv.a@samsung.com          (official LinkedIn - global startup inbound)
--   645 Ventures          ideas@645ventures.com     (Crunchbase + pitch guide)
--   Contour Venture Ptrs  matt@contourventures.com  (own contact page - Matt Gorin MP)
--   Great Oaks VC         info@greatoaksvc.com      (Crunchbase)
--   LifeSci Venture Ptrs  info@lifesciventure.com   (own site general inquiries)
-- REVIEW (10) - single/aggregator source, commented out below:
--   Bluepoint magellan@bluepoint.ac (program inbox 2023) / Big Basin ideas@bigbasincapital.com
--   Aju IB info@ajuib.com (US entity) / Goodwater info@goodwatercap.com
--   SBVA b_plan@softbank.co.kr (pre-rebrand domain, validity uncertain)
--   Base10 purpose@base10.vc / LifeX contact@lifex.vc / Point72 ideas@p72.vc
--   True connect@trueventures.com (official channel is the Pitch Us web form)
--   Primary sam@primary.vc (personal addr, single source - verify first)
-- FORM-ONLY (6) - no public pitch email, nothing fabricated:
--   FuturePlay (futureplay.co/contact form) / LG Technology Ventures
--   Altos Ventures (warm-intro house) / SR One (media@ only)
--   Sands Capital Ventures (web form, iratcliffe@ is IR/LP relations)
--   Novo Holdings (info@novoholdings.dk is corporate general - low pitch value)
-- ============================================================

-- (1a) contacts - KR wave 6 (pattern match, names may carry suffixes)
insert into app.contacts (organization_id, party_id, contact_type_id, email, full_name, source)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       p.id, v.contact_type_id, v.email, v.full_name, 'investor_email_batch9c'
from app.parties p
join (values
  ('Kolon Investment%',          'yjkim721@kolon.com',    'Kolon Investment (business plan inbox)',  1::smallint),
  ('Primer Sazze%',              'info@primersazze.com',  'Primer Sazze (general)',                  1::smallint),
  ('Strong Ventures%',           'info@strongvc.com',     'Strong Ventures (deck submission inbox)', 1::smallint),
  ('Samsung Venture Investment%','sv.a@samsung.com',      'Samsung Ventures (global inbound)',       1::smallint)
) as v(match_pat, email, full_name, contact_type_id) on p.party_name ilike v.match_pat
where p.deleted_at is null
  and p.source = 'web_research_2026Q3_kr'
  and not exists (
    select 1 from app.contacts c
    where c.party_id = p.id and lower(c.email) = lower(v.email));

-- (1b) contacts - CA/NY wave 8 (exact names per seed file)
insert into app.contacts (organization_id, party_id, contact_type_id, email, full_name, source)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       p.id, v.contact_type_id, v.email, v.full_name, 'investor_email_batch9c'
from app.parties p
join (values
  ('645 Ventures',               'ideas@645ventures.com',    '645 Ventures (ideas inbox)',       1::smallint),
  ('Contour Venture Partners',   'matt@contourventures.com', 'Matt Gorin (Managing Partner)',    5::smallint),
  ('Great Oaks Venture Capital', 'info@greatoaksvc.com',     'Great Oaks VC (general)',          1::smallint),
  ('LifeSci Venture Partners',   'info@lifesciventure.com',  'LifeSci Venture Ptrs (general)',   1::smallint)
) as v(party_name, email, full_name, contact_type_id) on v.party_name = p.party_name
where p.deleted_at is null
  and p.source = 'web_research_2026Q3_ca_ny'
  and not exists (
    select 1 from app.contacts c
    where c.party_id = p.id and lower(c.email) = lower(v.email));

-- REVIEW tier: uncomment individual lines after a second source confirms.
-- KR (add to 1a values):
-- ('Bluepoint Partners%',  'magellan@bluepoint.ac',      'Bluepoint (program inbox 2023 - verify)',   1::smallint),
-- ('Big Basin Capital%',   'ideas@bigbasincapital.com',  'Big Basin (ideas inbox - verify)',          1::smallint),
-- ('Aju IB%',              'info@ajuib.com',             'Aju IB / Solasta US entity (verify)',       1::smallint),
-- ('Goodwater Capital%',   'info@goodwatercap.com',      'Goodwater (general - verify)',              1::smallint),
-- ('SBVA%',                'b_plan@softbank.co.kr',      'SBVA legacy inbox (domain may be stale)',   1::smallint),
-- CA/NY (add to 1b values):
-- ('Base10 Partners',          'purpose@base10.vc',        'Base10 (purpose inbox - verify)',       1::smallint),
-- ('LifeX Ventures',           'contact@lifex.vc',         'LifeX (general - verify)',              1::smallint),
-- ('Point72 Ventures',         'ideas@p72.vc',             'Point72 Ventures (ideas - verify)',     1::smallint),
-- ('True Ventures',            'connect@trueventures.com', 'True (form is official channel)',       1::smallint),
-- ('Primary Venture Partners', 'sam@primary.vc',           'Primary (personal addr - verify)',      1::smallint),

-- (2) email_whitelist (domains for independents, addresses where corp domain too broad)
insert into app.email_whitelist (organization_id, pattern, kind, notes, is_active)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.pattern, v.kind, v.notes, true
from (values
  ('primersazze.com',     'domain',  'Primer Sazze (KR cross-border, batch9c)'),
  ('strongvc.com',        'domain',  'Strong Ventures (KR cross-border, batch9c)'),
  ('645ventures.com',     'domain',  '645 Ventures (batch9c)'),
  ('contourventures.com', 'domain',  'Contour Venture Partners (batch9c)'),
  ('greatoaksvc.com',     'domain',  'Great Oaks VC (batch9c)'),
  ('lifesciventure.com',  'domain',  'LifeSci Venture Partners email domain (site is lifescivp.com)'),
  ('yjkim721@kolon.com',  'address', 'Kolon Investment inquiry inbox (kolon.com too broad)'),
  ('sv.a@samsung.com',    'address', 'Samsung Ventures inbound (samsung.com too broad)')
) as v(pattern, kind, notes)
where not exists (
  select 1 from app.email_whitelist w
  where w.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and lower(w.pattern) = lower(v.pattern));

-- (3) VERIFY: expect 8 contact rows + 8 whitelist rows (16 total)
select 'contact' as kind, p.party_name as name, c.email as detail
from app.contacts c
join app.parties p on p.id = c.party_id
where c.source = 'investor_email_batch9c'
union all
select 'whitelist', w.pattern, w.kind
from app.email_whitelist w
where w.notes like '%batch9c%' or w.pattern in ('yjkim721@kolon.com','sv.a@samsung.com','lifesciventure.com')
order by 1, 2;
