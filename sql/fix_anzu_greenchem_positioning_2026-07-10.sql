-- ============================================================
-- fix_anzu_greenchem_positioning_2026-07-10.sql
-- Category repositioning: Nanomaterials -> Greenchem on the
-- Anzu form, plus a reusable green-chemistry positioning line
-- seeded into answer_library for Good Growth / Emerald reuse.
--
-- Rationale: Greenchem signals climate + regulatory-tailwind
-- impact to deep-tech VCs, where Nanomaterials reads as a
-- technology-push descriptor. The positioning sentence was
-- corrected from the draft - FCC is the product that displaces
-- pulp and SAPs, not a nanofiber that replaces fillers.
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons or SQL keywords inside string literals.
-- created_by copied from an existing library row (auth.uid() is
-- null in the editor).
-- ============================================================

-- ------------------------------------------------------------
-- 1. Seed the reusable positioning line (new key). Guarded so a
--    rerun updates in place rather than duplicating.
-- ------------------------------------------------------------
insert into app.answer_library
  (organization_id, answer_key, title, body_en, body_ko,
   disclosure_level, variant, tags, created_by)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  'category_positioning',
  'Green-chemistry one-line positioning',
  'A green-chemistry platform that grows functional calcium carbonate (FCC) in-situ to displace wood pulp in paper and to replace superabsorbent polymers (SAPs), cutting cost and carbon.',
  '기능성 탄산칼슘(FCC)을 섬유 위에 in-situ로 성장시켜 제지의 목재 펄프를 대체하고 고흡수성수지(SAP)를 대체하는 그린케미스트리 플랫폼으로, 원가와 탄소를 동시에 절감합니다.',
  'public',
  'medium',
  array['positioning','category','greenchem'],
  (select created_by from app.answer_library
    where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    order by created_at limit 1)
where not exists (
  select 1 from app.answer_library
  where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    and answer_key = 'category_positioning'
    and variant = 'medium'
);

update app.answer_library
set body_en    = 'A green-chemistry platform that grows functional calcium carbonate (FCC) in-situ to displace wood pulp in paper and to replace superabsorbent polymers (SAPs), cutting cost and carbon.',
    body_ko    = '기능성 탄산칼슘(FCC)을 섬유 위에 in-situ로 성장시켜 제지의 목재 펄프를 대체하고 고흡수성수지(SAP)를 대체하는 그린케미스트리 플랫폼으로, 원가와 탄소를 동시에 절감합니다.',
    updated_at = now()
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key = 'category_positioning'
  and variant = 'medium';


-- ------------------------------------------------------------
-- 2. Anzu subcategory field -> Greenchem, and put the
--    positioning line in the "other detail" field so it reads
--    on the form
-- ------------------------------------------------------------
update app.application_field_answers fa
set final_text = 'Greenchem',
    updated_at = now()
from app.application_form_fields ff
where ff.id = fa.field_id
  and ff.form_id = 'ce64cf37-9a02-498c-8b90-84bbddf5edba'::uuid
  and ff.label = 'Materials and Chemicals subcategory';

-- help_text on the subcategory field updated to match the new pick
update app.application_form_fields ff
set help_text = 'repositioned to Greenchem for the climate and regulatory-tailwind frame',
    updated_at = now()
where ff.form_id = 'ce64cf37-9a02-498c-8b90-84bbddf5edba'::uuid
  and ff.label = 'Materials and Chemicals subcategory';

-- category other detail field carries the positioning sentence
insert into app.application_field_answers
  (organization_id, field_id, answer_id, final_text, is_copied)
select
  'b25de8f2-1020-482f-9012-183f63883169'::uuid,
  ff.id,
  al.id,
  al.body_en,
  false
from app.application_form_fields ff
join app.answer_library al
  on al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
 and al.answer_key = 'category_positioning'
 and al.variant = 'medium'
where ff.form_id = 'ce64cf37-9a02-498c-8b90-84bbddf5edba'::uuid
  and ff.label = 'Category other detail'
on conflict (field_id) do update
  set answer_id  = excluded.answer_id,
      final_text = excluded.final_text,
      updated_at = now();


-- ------------------------------------------------------------
-- VERIFY 1: new positioning key present, both languages
-- ------------------------------------------------------------
select answer_key, variant,
       left(body_en, 55) as en_head,
       left(body_ko, 35) as ko_head
from app.answer_library
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and answer_key = 'category_positioning';


-- ------------------------------------------------------------
-- VERIFY 2: Anzu category rows now read Greenchem + positioning
-- ------------------------------------------------------------
select ff.seq, ff.label, fa.char_count,
       left(fa.final_text, 55) as text_head
from app.application_form_fields ff
left join app.application_field_answers fa on fa.field_id = ff.id
where ff.form_id = 'ce64cf37-9a02-498c-8b90-84bbddf5edba'::uuid
  and ff.seq in (120, 130, 140)
order by ff.seq;
