-- sequence_reports.sql
-- Monitoring + open-rate reporting for email sequences.
-- Paste into the Supabase SQL Editor. Every query here is read-only (SELECT).
--
-- Schema verified against MarineGift/mbg-project @ branch marinebiogroup:
--   app.email_sequence_sends(status, sent_at, step_order, enrollment_id, communication_id)
--   app.email_sequence_enrollments(id, sequence_id, status, party_id, contact_id)
--   app.communications(id, error_message, ...)
--   app.email_tracking(communication_id, sent_at, first_opened_at, open_count, click_count, sent_to, open_token)
--   app.parties(id, party_name)   app.contacts(id, email)   app.email_sequences(id, name, from_account_id)
--   app.inbound_mailboxes(id, address, is_default, is_active, smtp_host, smtp_port, smtp_use_tls)
--
-- Open join chain (verified in code):
--   advance_enrollment records email_sequence_sends.communication_id on a successful send;
--   sendOutboundEmail creates one email_tracking row per send with the same communication_id;
--   so opens link via email_tracking.communication_id = email_sequence_sends.communication_id.
--
-- Live investor cold-outreach sequence id used in the examples below:
--   151d5454-8efc-4ecb-90a6-ff4f0d18520d
--   (replace it to report on a different sequence)


-- =====================================================================
-- [A] Send-status summary for one sequence (all time)
-- =====================================================================
select snd.status, count(*) as n
from app.email_sequence_sends snd
join app.email_sequence_enrollments e on e.id = snd.enrollment_id
where e.sequence_id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'::uuid
group by snd.status
order by n desc;


-- =====================================================================
-- [B] Per-step send + open breakdown for one sequence
--     step_order 0 = Day 0, 1 = Day 3, 2 = Day 7
-- =====================================================================
select
  snd.step_order,
  count(*)                                              as sent,
  count(t.id)                                           as tracked,
  count(t.id) filter (where t.open_count > 0)           as opened,
  round(100.0 * count(t.id) filter (where t.open_count > 0)
        / nullif(count(t.id), 0), 1)                    as open_rate_pct,
  sum(coalesce(t.open_count, 0))                        as total_opens,
  sum(coalesce(t.click_count, 0))                       as total_clicks
from app.email_sequence_sends snd
join app.email_sequence_enrollments e on e.id = snd.enrollment_id
left join app.email_tracking t on t.communication_id = snd.communication_id
where e.sequence_id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'::uuid
  and snd.status = 'sent'
group by snd.step_order
order by snd.step_order;


-- =====================================================================
-- [C] Overall open rate for one sequence (sent rows only)
-- =====================================================================
select
  count(*)                                            as sent,
  count(t.id) filter (where t.open_count > 0)         as opened,
  round(100.0 * count(t.id) filter (where t.open_count > 0)
        / nullif(count(*), 0), 1)                     as open_rate_pct,
  sum(coalesce(t.open_count, 0))                       as total_opens
from app.email_sequence_sends snd
join app.email_sequence_enrollments e on e.id = snd.enrollment_id
left join app.email_tracking t on t.communication_id = snd.communication_id
where e.sequence_id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'::uuid
  and snd.status = 'sent';


-- =====================================================================
-- [D] Per-recipient detail: who opened, how many times, first open
-- =====================================================================
select
  p.party_name,
  coalesce(c.email, t.sent_to)        as email,
  snd.step_order,
  snd.sent_at,
  coalesce(t.open_count, 0)           as opens,
  t.first_opened_at,
  coalesce(t.click_count, 0)          as clicks
from app.email_sequence_sends snd
join app.email_sequence_enrollments e on e.id = snd.enrollment_id
join app.parties p on p.id = e.party_id
left join app.contacts c on c.id = e.contact_id
left join app.email_tracking t on t.communication_id = snd.communication_id
where e.sequence_id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'::uuid
  and snd.status = 'sent'
order by opens desc, snd.sent_at desc;


-- =====================================================================
-- [E] Failure detail (re-check after each drip)
-- =====================================================================
select p.party_name, c.email, cm.error_message, snd.sent_at
from app.email_sequence_sends snd
join app.email_sequence_enrollments e on e.id = snd.enrollment_id
join app.parties p on p.id = e.party_id
left join app.contacts c on c.id = e.contact_id
left join app.communications cm on cm.id = snd.communication_id
where e.sequence_id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'::uuid
  and snd.status = 'failed'
order by snd.sent_at desc;


-- =====================================================================
-- [F] Recent drip monitor (last 24h) -- confirms the worker is sending
--     Day 3 / Day 7 follow-ups automatically (resume point #1).
-- =====================================================================
select
  snd.step_order,
  snd.status,
  count(*) as n,
  max(snd.sent_at) as latest
from app.email_sequence_sends snd
join app.email_sequence_enrollments e on e.id = snd.enrollment_id
where e.sequence_id = '151d5454-8efc-4ecb-90a6-ff4f0d18520d'::uuid
  and snd.sent_at >= now() - interval '24 hours'
group by snd.step_order, snd.status
order by snd.step_order, snd.status;


-- =====================================================================
-- [G] Org-wide open rate by day (all tracked sends: sequences + blasts)
--     Adjust the interval as needed.
-- =====================================================================
select
  date_trunc('day', t.sent_at)::date                  as send_day,
  count(*)                                            as tracked,
  count(*) filter (where t.open_count > 0)            as opened,
  round(100.0 * count(*) filter (where t.open_count > 0)
        / nullif(count(*), 0), 1)                     as open_rate_pct
from app.email_tracking t
where t.sent_at >= now() - interval '30 days'
group by 1
order by 1 desc;


-- =====================================================================
-- [H] Duplicate-bug audit
--     Sequences with NULL from_account_id used to "float" to whatever the
--     default account was at send time. The duplicateSequence fix now pins
--     the resolved default onto copies at duplicate time. Confirm the org
--     default sender is the working account (yunyoung.heo, smtp-ready).
-- =====================================================================
select id, name, from_account_id
from app.email_sequences
where from_account_id is null
order by created_at desc;

select id, address, is_default, is_active, smtp_host, smtp_port, smtp_use_tls
from app.inbound_mailboxes
where is_default = true;
