-- ============================================================
-- seed_azolla_form_fields_2026-07-10.sql
-- P1 form blitz: Azolla Ventures Company Interest Form
-- (typeform zgHBtjoX, captured off screenshots 2026-07-10)
--
-- Fields seeded: 7 contact basics + description(300) + sector +
-- subsector. The optional demographic block is intentionally
-- NOT seeded - it is voluntary and personal, answer it live.
--
-- Prefills: contact basics as direct final_text, description
-- bound to answer_library company_one_liner (medium, 196 chars,
-- fits the 300 char limit).
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons inside string literals.
-- application_form_fields / application_field_answers are
-- child-detail and link tables - no created_by per SaaS rules.
-- ============================================================

-- ------------------------------------------------------------
-- 1. Field rows (guarded per label)
-- ------------------------------------------------------------
insert into app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, canonical_key)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  f.id,
  v.seq, v.label, v.field_type, v.max_length, v.is_required,
  v.help_text, v.canonical_key
from app.application_forms f
join app.parties pt on pt.id = f.party_id
join (values
  (10, 'Your first name',   'text',     null::int, true,
   null, null),
  (20, 'Your last name',    'text',     null::int, true,
   null, null),
  (30, 'Email address',     'text',     null::int, true,
   null, null),
  (40, 'Company or project name', 'text', null::int, true,
   null, null),
  (50, 'Company or project website or personal LinkedIn', 'url', null::int, false,
   'leave blank if none - LinkedIn profile used', null),
  (60, 'Are you the company CEO', 'dropdown', null::int, true,
   'options Yes or No', null),
  (70, 'Referred by',       'text',     null::int, false,
   'First Last format or leave blank - fill if the CF community manager warm intro lands first', null),
  (80, 'Company description', 'textarea', 300, true,
   '300 characters max - company_one_liner fits at 196', 'company_one_liner'),
  (90, 'Sector',            'dropdown', null::int, true,
   'typeform dropdown - pick the closest option, likely Advanced Materials or Industrials or Climate', null),
  (100,'Subsector',         'dropdown', null::int, false,
   'typeform dropdown - pick the closest option to bio-based materials', null)
) as v(seq, label, field_type, max_length, is_required, help_text, canonical_key)
  on true
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%azolla%'
  and f.form_url = 'https://azollaventures.typeform.com/to/zgHBtjoX'
  and not exists (
    select 1 from app.application_form_fields ff
    where ff.form_id = f.id and ff.label = v.label
  );


-- ------------------------------------------------------------
-- 2. Prefilled answers (ON CONFLICT on the field_id uniqueness
--    keeps this rerunnable). Description binds the library row,
--    the rest are direct final_text.
-- ------------------------------------------------------------
insert into app.application_field_answers
  (organization_id, field_id, answer_id, final_text, is_copied)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  ff.id,
  al.id,
  coalesce(al.body_en, v.final_text),
  false
from app.application_form_fields ff
join app.application_forms f on f.id = ff.form_id
join app.parties pt          on pt.id = f.party_id
join (values
  ('Your first name',   'Yun Young',                null),
  ('Your last name',    'Heo',                      null),
  ('Email address',     'ceo@marinebiogroup.com',   null),
  ('Company or project name', 'Marinebio Group Inc', null),
  ('Company or project website or personal LinkedIn',
     'https://www.linkedin.com/in/yunyoung-heo-a2640a195/', null),
  ('Are you the company CEO', 'Yes',                null),
  ('Company description', null,                     'company_one_liner'),
  ('Sector',            'Advanced Materials',       null),
  ('Subsector',         'Bio-based materials',      null)
) as v(label, final_text, lib_key)
  on v.label = ff.label
left join app.answer_library al
  on al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
 and al.answer_key = v.lib_key
 and al.variant = 'medium'
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%azolla%'
  and f.form_url = 'https://azollaventures.typeform.com/to/zgHBtjoX'
on conflict (field_id) do nothing;


-- ------------------------------------------------------------
-- 3. Form status -> drafting
-- ------------------------------------------------------------
update app.application_forms f
set status = 'drafting', updated_at = now()
from app.parties pt
where pt.id = f.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%azolla%'
  and f.form_url = 'https://azollaventures.typeform.com/to/zgHBtjoX'
  and f.status = 'not_started';


-- ------------------------------------------------------------
-- VERIFY: field list with prefills and char counts - the
-- description row must show 196 chars and state ok
-- ------------------------------------------------------------
select ff.seq, ff.label, ff.field_type, ff.max_length,
       fa.char_count,
       left(fa.final_text, 40) as text_head,
       al.answer_key
from app.application_form_fields ff
join app.application_forms f on f.id = ff.form_id
join app.parties pt          on pt.id = f.party_id
left join app.application_field_answers fa on fa.field_id = ff.id
left join app.answer_library al            on al.id = fa.answer_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%azolla%'
order by ff.seq;
