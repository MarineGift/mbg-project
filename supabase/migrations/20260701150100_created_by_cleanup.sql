-- created_by_cleanup.sql
-- Removes created_by from tables that should NOT have it (SaaS standard: only
-- genuine user-created ENTITIES carry created_by). The earlier audit was
-- deliberately broad; this trims it back to the correct set.
--
-- Dropped from: reference/lookup, pure join/link, 1:1 detail, log/derived/
-- worker-state, and backup tables. Ownership on those is inherited from a parent
-- or is meaningless (system/derived data).
--
-- Safe + instant (drop column is metadata-only) + idempotent + reported.

create temp table if not exists _cb_drop(sch text, tbl text, action text);
truncate _cb_drop;

do $$
declare
  item text;
  sch  text;
  tbl  text;
  drops text[] := array[
    -- reference / lookup
    'app.countries','app.sectors','app.industry_tags','app.investment_stages',
    'app.meeting_modes','app.todo_status_options','app.deal_close_reasons',
    'app.partner_seniority_meta','app.permissions','app.engagement_type_registry',
    -- pure join / link
    'app.investor_sector_focus','app.investor_stage_focus','app.engagement_attendees',
    'app.meeting_attendees','app.team_members','app.role_permissions',
    'app.mail_run_recipients','app.todo_dependencies','app.user_roles',
    -- 1:1 detail extensions of a parent
    'app.engagement_email_details','app.engagement_meeting_details',
    -- log / derived / worker-state
    'app.calendar_sync_log','app.reminder_log','app.mailcarrier_state',
    'app.account_scores','app.lead_scores','app.email_tracking','app.email_tracking_events',
    'app.email_sequence_sends',
    -- backup
    'app._bak_pmpt_20260606'
  ];
begin
  foreach item in array drops loop
    sch := split_part(item,'.',1);
    tbl := split_part(item,'.',2);
    if exists (select 1 from information_schema.columns
               where table_schema=sch and table_name=tbl and column_name='created_by') then
      execute format('alter table %I.%I drop column created_by', sch, tbl);
      insert into _cb_drop values (sch, tbl, 'dropped');
    else
      insert into _cb_drop values (sch, tbl, 'skip (already absent)');
    end if;
  end loop;
end $$;

select action, sch, tbl from _cb_drop order by action, tbl;
