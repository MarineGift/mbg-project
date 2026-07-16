-- ============================================================
-- scan_entity_enrollment_2026-07-16.sql
--
-- THE REAL QUESTION THE SMI DEALS RAISED.
--
-- On 2026-07-02 a person opened one deal on Specialty Minerals (HQ) by hand at
-- 19:56. Between 20:04 and 20:12, source = entity_enrollment stamped a deal onto
-- three more party rows that are the same company. The automation has no idea
-- those rows are duplicates - it enrolled every party that matched its criteria.
--
-- So this is not a story about four deals. It is a story about a process that
-- CONVERTS DUPLICATE ROWS INTO PIPELINE NUMBERS. Every duplicate found today -
-- Omya Korea, Taekyung BK, Taekyung Industrial, Specialty Minerals Inc. - was a
-- candidate for the same treatment, and the campaign
-- e0000000-0000-4000-8000-00000000000e may be inflated well beyond SMI.
--
-- It got lucky in one respect: MTI, SMI Inc. and Regional HQ all have zero
-- contacts, so no email could physically send. Omya (Korea) is NOT so lucky -
-- it has jaehoon.cho@omya.com. And the Saica row carried a COMPETITOR's inbox
-- until this afternoon.
--
-- READ-ONLY. Run each block SEPARATELY.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) HOW BIG IS THE FCC LICENSING CAMPAIGN, AND WHO BUILT IT ----------
select coalesce(d.source, '(null)') as deal_source,
       count(*) as deals,
       count(*) filter (where d.deleted_at is null) as live,
       min(d.created_at)::date as first_created,
       max(d.created_at)::date as last_created,
       count(*) filter (where d.last_activity_at = d.created_at) as never_touched_since_creation
from app.deals d
where d.campaign_id = 'e0000000-0000-4000-8000-00000000000e'::uuid
group by 1
order by count(*) desc;


-- ---------- 2) PHANTOM DEALS - the general shape ----------
-- A deal on a party with no contacts and no communications, created by
-- automation, never touched since. That is the SMI phantom pattern expressed as
-- a query. If this returns a long list, the pipeline count is fiction.
select p.party_name, p.party_type_id, p.source as party_source,
       d.deal_name, d.source as deal_source, d.status,
       d.created_at::date, (d.last_activity_at = d.created_at) as never_touched
from app.deals d
join app.parties p on p.id = d.party_id
where d.deleted_at is null and p.deleted_at is null
  and not exists (select 1 from app.contacts c where c.party_id = p.id and c.deleted_at is null)
  and not exists (select 1 from app.communications m where m.party_id = p.id)
order by d.source, p.party_name;


-- ---------- 3) DID THE SAME AUTOMATION ENROL EMAIL SEQUENCES ----------
-- Deals are harmless without contacts. Sequences are not. If entity_enrollment
-- also created sequence enrollments, then duplicate parties WITH contacts -
-- Omya (Korea) has one - could have been mailed twice, and Saica would have been
-- mailed at a competitor's inbox.
select e.*
from app.email_sequence_enrollments e
where e.party_id in ('5ba57cb3-a5bb-4fd1-8750-342eb2cc25f1'::uuid,
                     'cd3dbf9e-bb61-4fda-81aa-9d914a5a5658'::uuid,
                     '9f161ff5-c369-4ca2-8a22-46a1ec40fd0d'::uuid,
                     'fa423be1-6482-4147-beae-179d118f48d9'::uuid,
                     'fac3df6e-875a-4cc3-97d4-fbb0ca10dd7f'::uuid);
-- If app.email_sequence_enrollments has no party_id column this errors. Tell me
-- the shape and I will redo it - blocks 1 and 2 will already have run.


-- ---------- 4) ANY REMAINING DUPLICATE PAIR THAT BOTH CARRY A LIVE DEAL ----------
-- Two parties, same website host, same country, both with an open deal. That is
-- double-counting still in the pipeline right now.
select lower(regexp_replace(regexp_replace(coalesce(p.website,''), '^https?://', ''), '/.*$', '')) as host,
       coalesce(p.country_code,'??') as cc,
       count(distinct p.id) as parties_with_live_deals,
       string_agg(distinct p.party_name || ' <' || coalesce(p.source,'null') || '>', E'\n   ') as parties
from app.parties p
join app.deals d on d.party_id = p.id and d.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null and coalesce(p.website,'') <> ''
group by 1, 2
having count(distinct p.id) > 1
order by count(distinct p.id) desc;


-- ---------- 5) THE HONEST PIPELINE NUMBER ----------
-- Deals on filler targets, split by whether anyone has ever spoken to them.
-- Given that only FOUR filler parties have any contact at all - MLC 13, SMI HQ 3,
-- Omya HQ 1, Omya Korea 1 - the second bucket is probably almost everything.
select case when exists (select 1 from app.contacts c where c.party_id = p.id and c.deleted_at is null)
            then '1_has a contact'
            else '2_NOBODY TO CALL' end as reachability,
       count(*) as live_deals,
       string_agg(p.party_name, ' | ' order by p.party_name) as parties
from app.deals d
join app.parties p on p.id = d.party_id
where d.deleted_at is null and p.deleted_at is null and p.party_type_id = 3
group by 1
order by 1;
