-- repair_20260921_revert_sender_domain.sql
-- !!! Ctrl+A (SELECT ALL) then Run !!!  Single statement.
-- Reverts the sender-domain backfill for platform mail (LinkedIn, Microsoft, Samsung, Activate):
-- keeps only apventures.com, helioscv.com, energytransitionvc.com. Those rows were unlinked before.
with bad as (
  select c.id,
         c.external_data->'investor_intro'->>'reason' as reason,
         c.external_data->'investor_intro'->>'matched_domain' as dom
  from app.communications c
  where c.external_data->'investor_intro' ? 'matched_domain'
    and c.external_data->'investor_intro'->>'matched_domain'
        not in ('apventures.com', 'helioscv.com', 'energytransitionvc.com')
),
fixed as (
  update app.communications c
  set party_id = null,
      contact_id = null,
      external_data = case
        when bad.reason = 'sender_domain'
          then c.external_data - 'inferred_party_type' - 'investor_intro'
        else jsonb_set(c.external_data - 'investor_intro', '{investor_intro}',
               (c.external_data->'investor_intro') - 'matched_domain'
                 || jsonb_build_object('relinked', false))
      end
  from bad
  where c.id = bad.id
  returning bad.dom
)
select dom, count(*) as reverted
from fixed
group by dom
order by count(*) desc;
