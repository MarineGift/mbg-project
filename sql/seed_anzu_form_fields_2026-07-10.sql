-- ============================================================
-- seed_anzu_form_fields_2026-07-10.sql
-- P5 form blitz: Anzu Partners company questionnaire
-- (real field structure provided 2026-07-10). The legacy
-- 15-field Anzu form (ce64cf37) had generic labels that do not
-- match the actual questionnaire, so this REPLACES its fields
-- with the true structure and rebinds answers.
--
-- Confirmed answers: patents = 1 Granted, Materials sub =
-- Nanomaterials.
--
-- Prefill join is variant-agnostic (medium -> long -> short,
-- body_en required) - locking in the convention after two forms
-- hit the medium-only trap today.
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons or SQL keywords inside string literals
-- ============================================================

-- ------------------------------------------------------------
-- 1. Clear legacy fields on the surviving Anzu form so the real
--    structure can be seeded clean (answers cascade off fields)
-- ------------------------------------------------------------
delete from app.application_form_fields ff
using app.application_forms f, app.parties pt
where ff.form_id = f.id
  and f.id = 'ce64cf37-9a02-498c-8b90-84bbddf5edba'::uuid
  and pt.id = f.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid;


-- ------------------------------------------------------------
-- 2. Seed the real questionnaire fields
-- ------------------------------------------------------------
insert into app.application_form_fields
  (organization_id, form_id, seq, label, field_type, max_length,
   is_required, help_text, canonical_key)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'ce64cf37-9a02-498c-8b90-84bbddf5edba'::uuid,
  v.seq, v.label, v.field_type, v.max_length, v.is_required,
  v.help_text, v.canonical_key
from (values
  (10,  'Company name', 'text', null::int, true, null, null),
  (20,  'First Name', 'text', null::int, true, null, null),
  (30,  'Last name', 'text', null::int, true, null, null),
  (40,  'Job Title', 'text', null::int, false, null, null),
  (50,  'Email', 'text', null::int, true, null, null),
  (60,  'City', 'text', null::int, true, null, null),
  (70,  'Region State', 'dropdown', null::int, true, 'Texas', null),
  (80,  'Country', 'dropdown', null::int, true, 'United States', null),
  (90,  'Website URL', 'url', null::int, false, null, null),
  (100, 'What does the company do', 'textarea', null::int, true,
        'brief description', 'company_one_liner'),
  (110, 'Pitch deck', 'file', null::int, true,
        'attach the deck pdf - required upload, not a link', null),
  (120, 'Area of focus category', 'dropdown', null::int, true,
        'pick Materials and Chemicals', null),
  (130, 'Materials and Chemicals subcategory', 'dropdown', null::int, true,
        'confirmed Nanomaterials', null),
  (140, 'Category other detail', 'text', null::int, false,
        'leave blank - Nanomaterials chosen', null),
  (150, 'Patents on the technology', 'dropdown', null::int, true,
        'confirmed 1 Granted including exclusive university license', null),
  (160, 'Notable tech accomplishments', 'textarea', null::int, false,
        'thinnest fastest lightest style - draw the in-situ nano CaCO3 growth angle from uvp', 'uvp'),
  (170, 'Notable customers', 'textarea', null::int, false,
        'the industrial filler maker partner stays anonymous in writing', 'market_customers'),
  (180, 'Raise amount USD', 'text', null::int, true,
        'format with commas', null),
  (190, 'What will the funds be used for', 'textarea', null::int, false,
        null, 'use_of_funds'),
  (200, 'Prior capital raised USD', 'text', null::int, false, null, null),
  (210, 'Previous investors', 'text', null::int, false, null, null),
  (220, 'Pre-money valuation USD', 'text', null::int, false,
        'format with commas', null)
) as v(seq, label, field_type, max_length, is_required, help_text, canonical_key);


-- ------------------------------------------------------------
-- 3. Prefilled answers (variant-agnostic library pick)
-- ------------------------------------------------------------
insert into app.application_field_answers
  (organization_id, field_id, answer_id, final_text, is_copied)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  ff.id,
  pick.id,
  coalesce(pick.body_en, v.final_text),
  false
from app.application_form_fields ff
join (values
  ('Company name',                   'Marinebio Group Inc', null),
  ('First Name',                     'Yun Young', null),
  ('Last name',                      'Heo', null),
  ('Job Title',                      'CEO', null),
  ('Email',                          'ceo@marinebiogroup.com', null),
  ('City',                           'Austin', null),
  ('Region State',                   'Texas', null),
  ('Country',                        'United States', null),
  ('Website URL',                    'https://www.linkedin.com/in/yunyoung-heo-a2640a195/', null),
  ('What does the company do',       null, 'company_one_liner'),
  ('Area of focus category',         'Materials & Chemicals', null),
  ('Materials and Chemicals subcategory', 'Nanomaterials', null),
  ('Patents on the technology',      '1 - Yes: Granted (including exclusive license from university)', null),
  ('Notable tech accomplishments',   null, 'uvp'),
  ('Notable customers',              null, 'market_customers'),
  ('Raise amount USD',               '$5,000,000', null),
  ('What will the funds be used for', null, 'use_of_funds'),
  ('Prior capital raised USD',       '$0', null),
  ('Previous investors',             'None - bootstrapped', null),
  ('Pre-money valuation USD',        '$30,000,000', null)
) as v(label, final_text, lib_key)
  on v.label = ff.label
left join lateral (
  select al.id, al.body_en
  from app.answer_library al
  where al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and al.answer_key = v.lib_key
    and al.body_en is not null
  order by case al.variant when 'medium' then 1 when 'long' then 2 else 3 end
  limit 1
) pick on true
where ff.form_id = 'ce64cf37-9a02-498c-8b90-84bbddf5edba'::uuid
on conflict (field_id) do nothing;


-- ------------------------------------------------------------
-- VERIFY: 22 fields, prefills visible, the file and manual rows
-- (deck upload, prior capital) are the only expected blanks
-- ------------------------------------------------------------
select ff.seq, ff.label, ff.field_type, ff.is_required,
       fa.char_count,
       left(fa.final_text, 35) as text_head,
       al.answer_key, al.variant
from app.application_form_fields ff
left join app.application_field_answers fa on fa.field_id = ff.id
left join app.answer_library al            on al.id = fa.answer_id
where ff.form_id = 'ce64cf37-9a02-498c-8b90-84bbddf5edba'::uuid
order by ff.seq;
