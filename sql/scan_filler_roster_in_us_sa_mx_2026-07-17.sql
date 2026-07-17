-- ============================================================
-- scan_filler_roster_in_us_sa_mx_2026-07-17.sql
--
-- READ-ONLY. Returns the India, USA, Saudi and Mexico filler rows in the order
-- you asked for, so the sweep can continue.
--
-- WHY THIS FILE EXISTS INSTEAD OF THE NEXT BATCH: I do not know these companies'
-- names. From India I know 20 Microns and Gulshan Polyols, and both are done. The
-- other eight are strangers to me.
--
-- Writing a batch against guessed names would produce files whose `~*` patterns
-- match zero rows. They would run. They would say Success. Nothing would change,
-- and nobody would know - which is precisely the failure this session has been
-- chasing all day: two states drifting apart with no error raised.
--
-- ONE result set, four countries, sweep order IN then US then SA then MX. One run,
-- one Export, and the sweep continues.
--
-- ALREADY EXCLUDED:
--   Omya, Specialty Minerals / MTI - partners, per partner_names
--   Taekyung - adverse party in a live dispute
--   anything flagged do_not_contact (migration 028)
--   anything already swept today (the homepage-check marker in notes)
--
-- No BEGIN / no DO blocks / no writes.
-- ============================================================

select
  case p.country_code
    when 'IN' then 1 when 'US' then 2 when 'SA' then 3 when 'MX' then 4
  end                                                          as sweep_order,
  p.country_code,
  p.party_name,
  p.website,
  f.evidence_level,
  left(coalesce(f.market_role, ''), 60)                        as market_role,
  left(coalesce(f.mineral_class, ''), 40)                      as mineral_class,
  left(coalesce(f.supply_model, ''), 40)                       as supply_model,
  p.contact_form_url,
  p.preferred_contact_method,
  (select count(*) from app.contacts c
    where c.party_id = p.id and c.deleted_at is null)          as contacts,
  (select count(*) from app.application_forms af
    where af.party_id = p.id)                                  as forms,
  f.extra_data #>> '{fcc_fit,verdict}'                         as fcc_fit_now,
  p.id                                                         as party_id
from app.parties p
left join app.filler_supplier_profile f
       on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3
  and p.deleted_at is null
  and p.country_code in ('IN', 'US', 'SA', 'MX')
  and coalesce(p.do_not_contact, false) = false
  and p.party_name !~* 'omya|specialty minerals|minerals technolog|\bmti\b|taekyung|태경'
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%'
order by sweep_order, f.evidence_level nulls last, p.party_name;


-- ---------- WHAT I NEED BACK ----------
-- The whole result, or just party_name + country_code + website + evidence_level.
-- Websites matter most - a row with a website is one search. A row without one is
-- two or three, and half the time the company turns out to be a trading name.
--
-- Expected shape based on the earlier country counts: India 10 minus 20 Microns
-- and Gulshan leaves about 8. USA 4, Saudi 4, Mexico 4. Roughly 20 rows.
-- If the counts come back very different, that itself is worth knowing - it would
-- mean the country tally I have been working from is stale.
--
-- ---------- WHAT TO EXPECT FROM THE SWEEP ----------
-- Sixteen opened so far, seven worth contacting. If that rate holds, about half
-- of these twenty are companies that should never receive a message. The US four
-- are worth particular attention: the American filler market is where Specialty
-- Minerals and Artemyn already operate, so expect partners, competitors and
-- entanglement rather than clean targets.
--
-- Saudi is the one I have no prior on at all. Four rows, and I do not know
-- whether they are producers, traders or cement companies with a limestone line.
