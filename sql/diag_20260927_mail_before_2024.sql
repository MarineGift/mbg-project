-- ==========================================================================
-- diag_20260927_mail_before_2024.sql
--
--   !!! Ctrl+A (SELECT ALL) then Run !!!
--   (the editor runs only highlighted text when something is selected)
--
-- Purpose
--   Read-only preview before deleting email older than 2024-01-01 (UTC).
--   Target = app.communications rows with channel email and
--   occurred_at before 2024-01-01, active and soft-deleted alike.
--   Changes nothing. One statement so the editor shows one grid.
--
-- Sections
--   1 target      count by direction and active or soft_deleted
--   2 range       oldest and newest target timestamp (epoch days in n)
--   3 keep        email rows that stay (2024 and later)
--   4 attach      attachment rows linked to target mail, and total bytes
--   5 child       target rows referenced by known child tables
--   6 fk          every live foreign key that points at app.communications
-- ==========================================================================

with t as (
  select c.id, c.direction::text as dir, c.deleted_at, c.occurred_at
    from app.communications c
   where c.channel = 'email'
     and c.occurred_at < timestamptz '2024-01-01 00:00:00+00'
)
select '1_target' as section,
       dir || ' / ' || case when deleted_at is null then 'active' else 'soft_deleted' end as item,
       count(*)::bigint as n
  from t
 group by 1, 2
union all
select '2_range', 'oldest ' || coalesce(min(occurred_at)::text, 'none'), count(*)::bigint from t
union all
select '2_range', 'newest ' || coalesce(max(occurred_at)::text, 'none'), count(*)::bigint from t
union all
select '3_keep', 'email rows 2024 and later', count(*)::bigint
  from app.communications c
 where c.channel = 'email'
   and c.occurred_at >= timestamptz '2024-01-01 00:00:00+00'
union all
select '4_attach', 'attachment rows', count(*)::bigint
  from app.attachments a
 where a.entity_type = 'communication'
   and a.entity_id in (select id from t)
union all
select '4_attach', 'attachment bytes', coalesce(sum(a.file_size_bytes), 0)::bigint
  from app.attachments a
 where a.entity_type = 'communication'
   and a.entity_id in (select id from t)
union all
select '5_child', 'email_sequence_sends.communication_id', count(*)::bigint
  from app.email_sequence_sends s where s.communication_id in (select id from t)
union all
select '5_child', 'consultations.source_communication_id', count(*)::bigint
  from app.consultations x where x.source_communication_id in (select id from t)
union all
select '5_child', 'engagement_email_details.source_communication_id', count(*)::bigint
  from app.engagement_email_details e where e.source_communication_id in (select id from t)
union all
select '5_child', 'email_tracking.communication_id', count(*)::bigint
  from app.email_tracking k where k.communication_id in (select id from t)
union all
select '6_fk',
       k.conrelid::regclass::text || '.' || att.attname
         || '  on_delete=' || k.confdeltype::text
         || '  nullable=' || case when att.attnotnull then 'no' else 'yes' end,
       null::bigint
  from pg_constraint k
  join pg_attribute att
    on att.attrelid = k.conrelid
   and att.attnum = any (k.conkey)
 where k.contype = 'f'
   and k.confrelid = 'app.communications'::regclass
 order by 1, 2
