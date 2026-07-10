-- ============================================================
-- fix_cev_answer_bindings_2026-07-10.sql
-- P2 seed VERIFY showed 4 empty bindings - competitors, uvp,
-- team_management, already_raised. The seed joined the library
-- at variant medium only, but these keys evidently live under a
-- different variant (or medium has no body_en). This patch
-- rebinds them variant-agnostically: prefer medium, then long,
-- then short, requiring body_en to be present.
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons inside string literals
-- ============================================================

-- ------------------------------------------------------------
-- DIAG: what actually exists for the 4 keys (drives library
-- hygiene decisions - a key living only as long is fine, a
-- medium row with null body_en needs a backfill)
-- ------------------------------------------------------------
select answer_key, variant,
       length(body_en) as en_chars,
       length(body_ko) as ko_chars,
       updated_at
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key in ('competitors','uvp','team_management','already_raised')
order by answer_key, variant;


-- ------------------------------------------------------------
-- PATCH: rebind the 4 empty answers on the CEVG form
-- ------------------------------------------------------------
update app.application_field_answers fa
set answer_id  = pick.id,
    final_text = pick.body_en,
    updated_at = now()
from app.application_form_fields ff
join app.application_forms f on f.id = ff.form_id
join app.parties pt          on pt.id = f.party_id
join (values
  ('Unique innovations vs competitors and sustainable advantage', 'competitors'),
  ('Value propositions and unit economics',                       'uvp'),
  ('Team capabilities',                                           'team_management'),
  ('Financing to date',                                           'already_raised')
) as v(label, lib_key)
  on v.label = ff.label
join lateral (
  select al.id, al.body_en
  from app.answer_library al
  where al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and al.answer_key = v.lib_key
    and al.body_en is not null
  order by case al.variant when 'medium' then 1 when 'long' then 2 else 3 end
  limit 1
) pick on true
where ff.id = fa.field_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%clean energy ventures%'
  and f.form_url = 'https://cevg.com/members/node/add/company?field_application_source=CEVF'
  and fa.final_text is null;


-- ------------------------------------------------------------
-- VERIFY: the 4 rows now carry text and a key (expect nonzero
-- char counts on all four)
-- ------------------------------------------------------------
select ff.seq, ff.label, fa.char_count,
       left(fa.final_text, 35) as text_head,
       al.answer_key, al.variant
from app.application_form_fields ff
join app.application_forms f on f.id = ff.form_id
join app.parties pt          on pt.id = f.party_id
left join app.application_field_answers fa on fa.field_id = ff.id
left join app.answer_library al            on al.id = fa.answer_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%clean energy ventures%'
  and ff.seq in (230, 240, 270, 350)
order by ff.seq;
