-- diag_basf_mail.sql (READ ONLY) - is the BASF reply stored, where is the mailbox cursor
select k, v
  from (
    select 'a_basf_comm' as k, to_jsonb(x) as v, x.occurred_at as sort_at
      from (select id, direction, occurred_at, received_at, subject, from_address, party_id, deleted_at
              from app.communications
             where (from_address ilike '%@basf.com' or from_address ilike '%basf-vc.com')
               and occurred_at >= now() - interval '5 days') x
    union all
    select 'b_cursor', to_jsonb(s) - 'organization_id', null
      from app.mailcarrier_state s
     where s.username = 'yunyoung.heo@marinebiogroup.com'
    union all
    select 'c_whitelist', jsonb_build_object('pattern', w.pattern, 'kind', w.kind, 'is_active', w.is_active), null
      from app.email_whitelist w
     where w.pattern ilike '%basf%'
    union all
    select 'd_latest_inbound',
           jsonb_build_object('max_received_at', max(received_at),
                              'stored_last_3h', count(*) filter (where received_at > now() - interval '3 hours')),
           null
      from app.communications
     where direction = 'inbound'
  ) t
 order by k, sort_at;