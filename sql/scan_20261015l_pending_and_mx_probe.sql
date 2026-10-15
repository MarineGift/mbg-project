-- ============================================================
-- scan_20261015l_pending_and_mx_probe.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Read-only probe, one result set (export as CSV):
--  1_k   migration 20261015k: AI link columns + check constraint + filled links
--  2_il  Israel / Jordan / Lebanon seed rows (parties, profiles, links, market rows)
--  3_lb  Lebanese Calcium Carbonate duplicate check
--  4_mx  existing Mexico mills, fillers, supply links, market row
--        (needed before the Mexico seed - many MX rows already exist)
-- No writes.
-- ============================================================

select '1_k' as section, c.column_name::text as name, 'column ok' as info, c.data_type::text as extra
from information_schema.columns c
where c.table_schema = 'app' and c.table_name = 'country_markets'
  and c.column_name in ('chatgpt_url', 'claude_url', 'gemini_url')
union all
select '1_k', 'country_markets_ai_url_check',
       case when exists (select 1 from pg_constraint k where k.conname = 'country_markets_ai_url_check') then 'constraint ok' else 'constraint MISSING' end, '-'
union all
select '1_k', 'rows with links', count(*)::text || ' rows',
       'chatgpt ' || count(cm.chatgpt_url)::text || ' / claude ' || count(cm.claude_url)::text || ' / gemini ' || count(cm.gemini_url)::text
from app.country_markets cm
where cm.deleted_at is null
union all
select '2_il', p.source || ' type ' || p.party_type_id::text, count(*)::text || ' rows',
       'mill profile ' || count(mp.party_id)::text || ' / plant ' || count(mp.extra_data -> 'plant')::text || ' / filler profile ' || count(fp.party_id)::text
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
left join app.filler_supplier_profile fp on fp.party_id = p.id
where p.deleted_at is null and p.source in ('israel_update_20261014', 'jordan_update_20261014', 'lebanon_update_20261014')
group by p.source, p.party_type_id
union all
select '2_il', 'plant blocks ' || p.country_code, count(*)::text || ' mills with plant', string_agg(p.party_name, ' | ' order by p.party_name)
from app.parties p
join app.paper_mill_profile mp on mp.party_id = p.id
where p.deleted_at is null and p.party_type_id = 2 and p.country_code in ('IL', 'JO', 'LB')
  and mp.extra_data ? 'plant'
group by p.country_code
union all
select '2_il', 'links ' || (l.extra_data ->> 'batch'), count(*)::text || ' links', string_agg(l.link_type, ', ')
from app.party_supply_links l
where l.deleted_at is null and l.extra_data ->> 'batch' in ('israel_update_20261014', 'jordan_update_20261014', 'lebanon_update_20261014')
group by l.extra_data ->> 'batch'
union all
select '2_il', 'market ' || cm.country_code, coalesce(cm.priority, '-'), coalesce(cm.headline, '-')
from app.country_markets cm
where cm.deleted_at is null and cm.country_code in ('IL', 'JO', 'LB')
union all
select '3_lb', p.party_name, coalesce(p.source, '-') || ' / ' || coalesce(p.country_code, '-'),
       p.id::text || ' / ' || to_char(p.created_at, 'YYYY-MM-DD HH24:MI') || case when p.deleted_at is null then ' / live' else ' / removed' end
from app.parties p
where p.party_type_id = 3
  and (p.party_name ilike '%Lebanese Calcium%' or p.party_name ilike '%Carbonate de Calcium Libanais%'
       or (p.country_code = 'LB' and p.party_name ilike '%carbonat%'))
union all
select '4_mx mill', p.party_name,
       coalesce(p.city, '-') || ' / ' || coalesce(p.region, '-') || ' / ' || coalesce(p.source, '-'),
       case when mp.party_id is null then 'no profile' else 'profile' end
       || ' / plant ' || coalesce(mp.extra_data #>> '{plant,priority}', case when mp.extra_data ? 'plant' then 'yes' else 'no' end)
       || ' / ' || case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro' else 'no intro' end
       || ' / ' || coalesce(p.website, 'no web') || ' / ' || p.id::text
from app.parties p
left join app.paper_mill_profile mp on mp.party_id = p.id
where p.deleted_at is null and p.party_type_id = 2 and p.country_code = 'MX'
union all
select '4_mx filler', p.party_name,
       coalesce(p.country_code, '-') || ' / ' || coalesce(p.city, '-') || ' / ' || coalesce(p.region, '-') || ' / ' || coalesce(p.source, '-'),
       case when fp.party_id is null then 'no profile' else 'profile ' || coalesce(fp.mineral_class, '-') end
       || ' / ' || case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro' else 'no intro' end
       || ' / ' || coalesce(p.website, 'no web') || ' / ' || p.id::text
from app.parties p
left join app.filler_supplier_profile fp on fp.party_id = p.id
where p.deleted_at is null and p.party_type_id = 3
  and (p.country_code = 'MX' or p.party_name ilike '%Mexic%' or p.party_name ilike '%México%'
       or p.party_name ilike '%Terrazo%' or p.party_name ilike '%Reverte%' or p.party_name ilike '%Reverté%'
       or p.party_name ilike '%ONIC%' or p.party_name ilike '%Calidra%' or p.party_name ilike '%ATSA%'
       or p.party_name ilike '%Carbonato%' or p.party_name ilike '%Anahuac%' or p.party_name ilike '%Anáhuac%')
union all
select '4_mx link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'),
       coalesce(l.extra_data ->> 'batch', '-')
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id
join app.parties m on m.id = l.mill_party_id
where l.deleted_at is null and m.country_code = 'MX'
union all
select '4_mx market', cm.country_code, coalesce(cm.priority, '-'), coalesce(cm.headline, '-')
from app.country_markets cm
where cm.country_code = 'MX'
order by 1, 2;
