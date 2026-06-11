-- ============================================================
-- 20260610130000_track_receipt_to_communications.sql
--
-- Goal: when a recipient OPENS (or clicks) a sent email, the receipt
-- info must land on the activity tables, not only app.email_tracking.
--
-- Today record_email_open / record_email_click update only
-- app.email_tracking(open_count, first_opened_at, click_count).
-- This patch makes them ALSO:
--   - stamp app.communications.opened_at / clicked_at (and delivered_at,
--     since an open proves delivery) on the linked communication
--     (email_tracking.communication_id), first-touch wins.
--   - stamp the linked engagement's extra_data with opened_at/clicked_at
--     so the Deal Activity timeline reflects "recipient read this".
--
-- Pure additive replacement of two SECURITY DEFINER RPCs. No schema
-- changes (communications.opened_at / clicked_at / delivered_at and
-- engagements.extra_data already exist). Safe + idempotent.
-- Requires: 20260610120000 (engagement auto-log) already applied so
-- communications.engagement_id is populated for sent mail.
-- ============================================================

-- ---- record_email_open ----
create or replace function public.record_email_open(
  p_token text,
  p_ip    text default null,
  p_ua    text default null
)
returns void
language plpgsql security definer
set search_path = public, app
as $$
declare
  v_id    uuid;       -- email_tracking.id
  v_comm  uuid;       -- communications.id
  v_now   timestamptz := now();
begin
  select id, communication_id
    into v_id, v_comm
    from app.email_tracking
   where open_token = p_token;
  if v_id is null then return; end if;

  -- raw event + tracking counters (unchanged behaviour)
  insert into app.email_tracking_events(tracking_id, event_type, ip, user_agent)
  values (v_id, 'open', p_ip, p_ua);

  update app.email_tracking
     set open_count      = open_count + 1,
         first_opened_at = coalesce(first_opened_at, v_now)
   where id = v_id;

  -- NEW: write receipt info onto the communication (first-touch wins).
  -- An open also proves delivery, so backfill delivered_at if empty.
  if v_comm is not null then
    update app.communications
       set opened_at    = coalesce(opened_at, v_now),
           delivered_at = coalesce(delivered_at, v_now)
     where id = v_comm;

    -- NEW: reflect on the linked engagement timeline row.
    update app.engagements e
       set extra_data = coalesce(e.extra_data, '{}'::jsonb)
                        || jsonb_build_object(
                             'opened_at', coalesce(e.extra_data->>'opened_at', v_now::text),
                             'open_count', coalesce((e.extra_data->>'open_count')::int, 0) + 1
                           ),
           updated_at = v_now
      from app.communications c
     where c.id = v_comm
       and e.id = c.engagement_id;
  end if;
end;
$$;

-- ---- record_email_click ----
create or replace function public.record_email_click(
  p_token text,
  p_ip    text default null,
  p_ua    text default null
)
returns text
language plpgsql security definer
set search_path = public, app
as $$
declare
  v_link_id     uuid;
  v_tracking_id uuid;
  v_url         text;
  v_comm        uuid;
  v_now         timestamptz := now();
begin
  select id, tracking_id, original_url
    into v_link_id, v_tracking_id, v_url
    from app.email_tracking_links
   where token = p_token;
  if v_link_id is null then return null; end if;

  insert into app.email_tracking_events(tracking_id, link_id, event_type, url, ip, user_agent)
  values (v_tracking_id, v_link_id, 'click', v_url, p_ip, p_ua);

  update app.email_tracking_links set click_count = click_count + 1 where id = v_link_id;
  update app.email_tracking       set click_count = click_count + 1 where id = v_tracking_id;

  -- a click implies an open too: backfill first_opened_at
  update app.email_tracking
     set first_opened_at = coalesce(first_opened_at, v_now)
   where id = v_tracking_id;

  select communication_id into v_comm from app.email_tracking where id = v_tracking_id;

  -- NEW: receipt info onto the communication (clicked implies opened+delivered)
  if v_comm is not null then
    update app.communications
       set clicked_at   = coalesce(clicked_at, v_now),
           opened_at    = coalesce(opened_at, v_now),
           delivered_at = coalesce(delivered_at, v_now)
     where id = v_comm;

    update app.engagements e
       set extra_data = coalesce(e.extra_data, '{}'::jsonb)
                        || jsonb_build_object(
                             'clicked_at', coalesce(e.extra_data->>'clicked_at', v_now::text),
                             'opened_at',  coalesce(e.extra_data->>'opened_at', v_now::text),
                             'click_count', coalesce((e.extra_data->>'click_count')::int, 0) + 1
                           ),
           updated_at = v_now
      from app.communications c
     where c.id = v_comm
       and e.id = c.engagement_id;
  end if;

  return v_url;
end;
$$;

-- ============================================================
-- Verification (after a tracked open in the wild):
--   select id, opened_at, delivered_at, clicked_at
--     from app.communications
--    where direction = 'outbound' and opened_at is not null
--    order by opened_at desc limit 5;
--
--   select id, title, extra_data->>'opened_at' as opened
--     from app.engagements
--    where extra_data ? 'opened_at' order by updated_at desc limit 5;
-- ============================================================
