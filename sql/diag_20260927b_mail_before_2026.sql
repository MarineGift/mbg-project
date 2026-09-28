-- ==========================================================================
-- diag_20260927b_mail_before_2026.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--   (the editor runs only highlighted text when something is selected)
--
-- Purpose
--   Read-only preview before deleting ALL email older than 2026-01-01 UTC
--   (years 2024 and 2025 - pre-2024 mail is already gone).
--   Changes nothing. One statement so the editor shows one grid.
--
-- Sections
--   1 year        target count per year, direction, active or soft_deleted
--   2 keep        email rows that stay (2026 and later)
--   3 attach      attachment rows and bytes of target mail
--   4 child       target rows referenced by child tables incl. ai.drafts
-- ==========================================================================

with t as (
  select c.id, c.direction::text as dir, c.deleted_at, c.occurred_at
    from app.communications c
   where c.channel = 'email'
     and c.occurred_at < timestamptz '2026-01-01 00:00:00+00'
)
select '1_year' as section,
       extract(year from occurred_at)::int::text || ' ' || dir || ' / '
         || case when deleted_at is null then 'active' else 'soft_deleted' end as item,
       count(*)::bigint as n
  from t
 group by 1, 2
union all
select '2_keep', 'email rows 2026 and later', count(*)::bigint
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at >= timestamptz '2026-01-01 00:00:00+00'
union all
select '3_attach', 'attachment rows', count(*)::bigint
  from app.attachments a
 where a.entity_type = 'communication' and a.entity_id in (select id from t)
union all
select '3_attach', 'attachment bytes', coalesce(sum(a.file_size_bytes), 0)::bigint
  from app.attachments a
 where a.entity_type = 'communication' and a.entity_id in (select id from t)
union all
select '4_child', 'ai.drafts.inbound_communication_id', count(*)::bigint
  from ai.drafts d where d.inbound_communication_id in (select id from t)
union all
select '4_child', 'ai.drafts.sent_communication_id', count(*)::bigint
  from ai.drafts d where d.sent_communication_id in (select id from t)
union all
select '4_child', 'email_sequence_sends.communication_id', count(*)::bigint
  from app.email_sequence_sends s where s.communication_id in (select id from t)
union all
select '4_child', 'consultations.source_communication_id', count(*)::bigint
  from app.consultations x where x.source_communication_id in (select id from t)
union all
select '4_child', 'engagement_email_details.source_communication_id', count(*)::bigint
  from app.engagement_email_details e where e.source_communication_id in (select id from t)
union all
select '4_child', 'email_tracking.communication_id', count(*)::bigint
  from app.email_tracking k where k.communication_id in (select id from t)
 order by 1, 2
