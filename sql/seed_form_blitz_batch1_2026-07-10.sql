-- ============================================================
-- seed_form_blitz_batch1_2026-07-10.sql
-- Registers the 8 Series A web-form targets as not_started
-- application_forms rows (form blitz queue order preserved
-- in the notes prefix P1..P8).
--
-- Targets: Azolla, Clean Energy Ventures, Breakout, Toyota,
--          Anzu, Good Growth, Emerald, Capital Factory
--
-- Supabase SQL Editor safe:
--   * no do-blocks, no temp tables, single self-contained INSERT
--   * no semicolons or SQL keywords inside string literals
-- SaaS rules:
--   * application_forms is an ENTITY table -> created_by required,
--     copied off an existing row (auth.uid() is null in SQL editor)
--   * party matched by ilike pattern, shortest name wins
--   * guard: skip when same party + form_url already registered
-- ============================================================

insert into app.application_forms
  (organization_id, party_id, form_url, form_type, cycle_label,
   status, submission_method, login_required, notes, created_by)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  m.party_id,
  v.form_url,
  'application',
  'Series A 2026-07',
  'not_started',
  'web_form',
  false,
  v.note,
  (select f0.created_by
     from app.application_forms f0
    where f0.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    order by f0.created_at
    limit 1)
from (values
  ('%azolla%',
   'https://azollaventures.com/contact-us/',
   'P1 form blitz - gigaton CO2e decarbonization thesis fit'),
  ('%clean energy ventures%',
   'https://cleanenergyventures.com/investment-application/',
   'P2 form blitz - guarantees review of every application'),
  ('%breakout%',
   'https://breakout.vc/contact',
   'P3 form blitz - biomaterials portfolio overlaps directly'),
  ('%toyota%',
   'https://toyota.ventures/submit-pitch.html',
   'P4 form blitz - Frontier and Climate dual track possible'),
  ('%anzu%',
   'https://anzupartners.com/company-questionnaire/',
   'P5 form blitz - company questionnaire route'),
  ('%good growth%',
   'https://goodgrowthvc.com/contact',
   'P6 form blitz - Advanced Materials named explicitly'),
  ('%emerald technology%',
   'https://emerald.vc/entrepreneurs',
   'P7 form blitz - corporate LP base of 50 plus potential customers'),
  ('%capital factory%',
   'https://info.capitalfactory.com/ventures-application',
   'P8 form blitz - resident member internal channel in parallel')
) as v(pat, form_url, note)
join lateral (
  select pt.id as party_id
  from app.parties pt
  where pt.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and pt.party_name ilike v.pat
  order by char_length(pt.party_name)
  limit 1
) m on true
where not exists (
  select 1
  from app.application_forms f
  where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and f.party_id = m.party_id
    and f.form_url = v.form_url
);


-- ------------------------------------------------------------
-- VERIFY 1: pattern -> party resolution
-- any row with party_name NULL means the party is MISSING and
-- must be created first, then rerun the insert above
-- ------------------------------------------------------------
select v.pat, m.party_name, m.id as party_id
from (values
  ('%azolla%'),
  ('%clean energy ventures%'),
  ('%breakout%'),
  ('%toyota%'),
  ('%anzu%'),
  ('%good growth%'),
  ('%emerald technology%'),
  ('%capital factory%')
) as v(pat)
left join lateral (
  select pt.id, pt.party_name
  from app.parties pt
  where pt.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and pt.party_name ilike v.pat
  order by char_length(pt.party_name)
  limit 1
) m on true;


-- ------------------------------------------------------------
-- VERIFY 2: today's blitz queue as registered
-- ------------------------------------------------------------
select pt.party_name, f.status, f.form_url, f.notes
from app.application_forms f
join app.parties pt on pt.id = f.party_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and f.cycle_label = 'Series A 2026-07'
order by f.notes;
