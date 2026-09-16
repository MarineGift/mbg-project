-- diag_ai_drafts_today_by_mail_age.sql (READ ONLY)
-- drafts created in the last 24h, grouped by how old the source mail was and by draft status
select case
         when c.occurred_at >= now() - interval '2 days'  then 'a_mail_last_2_days'
         when c.occurred_at >= now() - interval '14 days' then 'b_mail_2_to_14_days'
         when c.occurred_at >= now() - interval '90 days' then 'c_mail_14_to_90_days'
         else 'd_mail_older_or_unknown'
       end as mail_age,
       d.status,
       count(*) as drafts
  from ai.drafts d
  left join app.communications c on c.id = d.inbound_communication_id
 where d.created_at >= now() - interval '24 hours'
 group by 1, 2
 order by 1, 2;