-- ==========================================================================
-- repair_20260927_revert_activate_name_domain.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--
-- The 2026-09-27 rule G backfill tagged one Activate Houston cohort broadcast
-- (houston@activate.org) as Investors and linked it to the Activate party.
-- It is a program broadcast, not an investor conversation. Same false
-- positive as the 2026-09-21 rule F incident. This reverts it.
-- Code guard: activate.org is added to PLATFORM_HOSTS in investor-intro.ts.
-- Idempotent.
-- ==========================================================================

update app.communications c
set party_id = null,
    contact_id = null,
    external_data = (coalesce(c.external_data, '{}'::jsonb) - 'inferred_party_type') - 'investor_intro'
where c.direction = 'inbound'
  and c.deleted_at is null
  and lower(coalesce(c.from_address, '')) ~ '@([a-z0-9-]+\.)*activate\.org$'
  and c.external_data->'investor_intro'->>'reason' in ('name_domain', 'intro_participant')
  and coalesce((c.external_data->'investor_intro'->>'backfilled')::boolean, false);

-- verification: expect zero rows
select c.occurred_at::date as day, c.from_address, left(c.subject, 80) as subject_text,
       c.external_data->'investor_intro'->>'reason' as reason
from app.communications c
where c.deleted_at is null
  and lower(coalesce(c.from_address, '')) ~ '@([a-z0-9-]+\.)*activate\.org$'
  and c.external_data->>'inferred_party_type' = 'investor';
