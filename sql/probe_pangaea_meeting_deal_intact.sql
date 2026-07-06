-- ============================================================
-- probe_pangaea_meeting_deal_intact.sql (2026-07-06) -- READ ONLY
-- Confirms the 7/8 Pangaea meeting + the Pangaea deal both survived the
-- dup-campaign deletion and are still correctly linked. Nothing is modified.
-- NOTE: app.meetings links to party_id / engagement_id (NOT deal_id).
-- ============================================================

-- (1) The Pangaea meeting(s): party link + engagement link + status
select m.id as meeting_id, m.title, m.status,
       m.party_id, p.party_name,
       m.engagement_id,
       (p.id is null or p.deleted_at is not null) as party_missing
from app.meetings m
left join app.parties p on p.id = m.party_id
where m.title ilike '%pangaea%'
   or p.party_name ilike '%pangaea%'
order by m.title;

-- (2) All Pangaea deals now: alive? on which campaign? which stage?
select d.id as deal_id, d.deal_name, d.deleted_at,
       d.campaign_id, c.name as campaign_name,
       p.party_name, s.name as stage
from app.deals d
join app.parties p on p.id = d.party_id
left join app.campaigns c on c.id = d.campaign_id
left join app.stages s on s.id = d.current_stage_id
where p.party_name ilike '%pangaea%'
order by d.deleted_at nulls first, d.deal_name;

-- (3) The Pangaea party itself + its engagements (meetings hang off these)
select p.id as party_id, p.party_name, p.deleted_at,
       e.id as engagement_id, e.status as engagement_status
from app.parties p
left join app.engagements e on e.party_id = p.id
where p.party_name ilike '%pangaea%'
order by p.party_name;

-- (4) Confirm the deleted dup campaign id is truly gone (expect 0 rows)
select id, name from app.campaigns
where id = 'd0000000-0000-4000-8000-0000000000fe'::uuid;
