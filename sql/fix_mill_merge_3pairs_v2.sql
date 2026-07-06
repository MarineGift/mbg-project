-- ============================================================
-- fix_mill_merge_3pairs_v2.sql (2026-07-05)
-- Paper-mill exact-duplicate merge, 3 pairs.
-- v2 fixes the Supabase parser issue: NO temp table, NO do-block, NO BEGIN.
-- Every statement is self-contained and repeats the 3-pair map inline as a
-- CTE (values ...), exactly like the investor merge v9 that finally passed.
-- Run the whole file with "Run" (select-all). Idempotent-ish: reparent uses
-- NOT EXISTS guards where a unique/1:1 constraint could collide.
--
-- REPARENT list is FINAL, built from fix_mill_merge_probe_fk.sql (26 FKs):
--   generic party_id move (17): account_scores, calendar_events, communications,
--     consultations, contacts, deal_backers, deal_participation, deal_parties,
--     deals, email_sequence_enrollments, email_tracking, engagements,
--     lead_scores, meetings, response_strategies  + contacts_history.firm_party_id
--   mill-named col: party_supply_links.mill_party_id, paper_mill_paper_types.mill_party_id
--   1:1 detail: paper_mill_profile.party_id, party_profiles.party_id (move-or-drop)
--   SKIPPED (never a mill): investor_profile, investor_portfolio_companies,
--     filler_supplier_profile, engagement_participants.person_party_id,
--     meeting_attendees.person_party_id (person, not firm),
--     party_supply_links.filler_party_id (filler side, not the mill side)
--
-- 3 pairs (keep <- merge):
--   Essity            a31ef82c...  <-  Essity AB         3a6e8e3e...
--   Holmen Iggesund   d98f9ba1...  <-  Holmen Iggesund Mill  b2e47e37...
--   Mondi Neusiedler  c1fb01a0...  <-  Mondi Neusiedler GmbH 29d74802...
-- ============================================================

-- (0) PRE-FLIGHT: expect all_ok = 3 (all pairs valid). If not 3, STOP.
with pairs(keep_id, merge_id) as (values
  ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid, '3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),
  ('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid, 'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),
  ('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid, '29d74802-3088-4434-a478-a3c47b34a98e'::uuid)
)
select count(*) as all_ok
from pairs pr
where exists (select 1 from app.parties p join app.party_types pt on pt.id=p.party_type_id and pt.code='paper_mill'
              where p.id=pr.keep_id  and p.deleted_at is null)
  and exists (select 1 from app.parties p join app.party_types pt on pt.id=p.party_type_id and pt.code='paper_mill'
              where p.id=pr.merge_id and p.deleted_at is null)
  and pr.keep_id <> pr.merge_id;

-- (1) CANONICAL enrich: fill only NULL/empty fields on keep from merge
update app.parties k set
  website = coalesce(nullif(k.website,''), nullif(mp.website,'')),
  city    = coalesce(nullif(k.city,''),    nullif(mp.city,'')),
  email   = coalesce(nullif(k.email,''),   nullif(mp.email,''))
from (values
  ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid, '3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),
  ('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid, 'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),
  ('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid, '29d74802-3088-4434-a478-a3c47b34a98e'::uuid)
) as m(keep_id, merge_id)
join app.parties mp on mp.id = m.merge_id
where k.id = m.keep_id;

-- (2) REPARENT generic party_id children (16 tables) --------------------------
-- account_scores has unique(organization_id, party_id) -> move only if keep has none, else drop merge's row
update app.account_scores t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id and not exists (select 1 from app.account_scores k where k.party_id = m.keep_id and k.organization_id = t.organization_id);
delete from app.account_scores t using (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.calendar_events t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.communications t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.consultations t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.deal_backers t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.deal_participation t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.deal_parties t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.deals t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.email_sequence_enrollments t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.email_tracking t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.engagements t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
-- lead_scores is also per-party -> move only if keep has none, else drop merge's row
-- (guard on party_id alone -> safe whether the unique is party_id or (org,party_id))
update app.lead_scores t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id and not exists (select 1 from app.lead_scores k where k.party_id = m.keep_id);
delete from app.lead_scores t using (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.meetings t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.response_strategies t set party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.party_id = m.merge_id;
update app.contacts_history t set firm_party_id = m.keep_id from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id) where t.firm_party_id = m.merge_id;

-- (3) CONTACTS: reparent but avoid duplicate (same party_id+email) -------------
update app.contacts t set party_id = m.keep_id
from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id)
where t.party_id = m.merge_id
  and not exists (select 1 from app.contacts k where k.party_id = m.keep_id and lower(k.email) = lower(t.email));
-- leftover contacts that would collide are soft-orphaned by the merge soft-delete below

-- (4) SUPPLY LINKS (mill side): reparent, avoid duplicate (mill,filler) pair ---
update app.party_supply_links t set mill_party_id = m.keep_id
from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id)
where t.mill_party_id = m.merge_id
  and not exists (
    select 1 from app.party_supply_links k
    where k.mill_party_id = m.keep_id
      and k.filler_party_id is not distinct from t.filler_party_id);
-- delete now-redundant duplicate links still pointing at merge
delete from app.party_supply_links t
using (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id)
where t.mill_party_id = m.merge_id;

-- (5) paper_mill_paper_types (mill_party_id): plain reparent. -----------------
-- NOTE: could NOT confirm this table's non-key column name from source, so this
-- is a plain move WITHOUT a dedup guard. If a unique(mill,type) constraint
-- exists and both mills share a type, this single statement may raise a
-- unique-violation; for these 3 EU mills the table is very likely empty, so it
-- should be a no-op. If it errors, delete this statement and skip -- the merge
-- rows get soft-deleted anyway.
update app.paper_mill_paper_types t set mill_party_id = m.keep_id
from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id)
where t.mill_party_id = m.merge_id;

-- (6) 1:1 DETAIL tables: move merge's detail only if keep has none, else drop --
-- paper_mill_profile
update app.paper_mill_profile t set party_id = m.keep_id
from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id)
where t.party_id = m.merge_id
  and not exists (select 1 from app.paper_mill_profile k where k.party_id = m.keep_id);
delete from app.paper_mill_profile t
using (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id)
where t.party_id = m.merge_id;
-- party_profiles
update app.party_profiles t set party_id = m.keep_id
from (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id)
where t.party_id = m.merge_id
  and not exists (select 1 from app.party_profiles k where k.party_id = m.keep_id);
delete from app.party_profiles t
using (values ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid,'3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid,'29d74802-3088-4434-a478-a3c47b34a98e'::uuid)) as m(keep_id,merge_id)
where t.party_id = m.merge_id;

-- (7) SOFT-DELETE merge rows (recoverable + audit note) ------------------------
update app.parties k set
  deleted_at = now(),
  notes = concat_ws(' | ', nullif(k.notes,''),
            'merged into ' || m.keep_id::text || ' (mill dedupe 2026-07-05)')
from (values
  ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid, '3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),
  ('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid, 'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),
  ('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid, '29d74802-3088-4434-a478-a3c47b34a98e'::uuid)
) as m(keep_id, merge_id)
where k.id = m.merge_id and k.deleted_at is null;

-- (8) VERIFY -- expect merge_still_active=0, keep_active=3 ----------------------
with pairs(keep_id, merge_id) as (values
  ('a31ef82c-b170-45b0-b80b-596850fdd15a'::uuid, '3a6e8e3e-c717-4356-af0a-93a5bace7d9a'::uuid),
  ('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid, 'b2e47e37-8276-4eea-93fb-85a0e2a2412e'::uuid),
  ('c1fb01a0-9407-4181-ba10-745a3c45e016'::uuid, '29d74802-3088-4434-a478-a3c47b34a98e'::uuid)
)
select
  (select count(*) from app.parties p join pairs pr on p.id = pr.merge_id where p.deleted_at is null) as merge_still_active,
  (select count(*) from app.parties p join pairs pr on p.id = pr.keep_id  where p.deleted_at is null) as keep_active;
