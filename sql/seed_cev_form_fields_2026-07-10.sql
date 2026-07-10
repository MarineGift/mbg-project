-- ============================================================
-- seed_cev_form_fields_2026-07-10.sql
-- P2 form blitz: Clean Energy Ventures / CEVG shared pipeline
-- Real entry: cevg.com Drupal form (captured remotely, full
-- question set, no login needed to view).
--
-- Not seeded on purpose:
--   * Demographics and Equity block - voluntary, personal,
--     answer live at submission
--   * Climate Impact CO2e numerics - need a validated per-ton
--     FCC pulp-displacement figure, guessing hurts review
--   * Date founded, phone, trailing-12M revenue, closing date -
--     values unknown, confirm before submitting
--
-- Supabase SQL Editor safe: no do-blocks, no temp tables,
-- no semicolons or SQL keywords inside string literals
-- ============================================================

-- ------------------------------------------------------------
-- 1. Correct the entry URL on the P2 row (blitz registered the
--    marketing page, the actual application lives on cevg.com)
-- ------------------------------------------------------------
update app.application_forms f
set form_url   = 'https://cevg.com/members/node/add/company?field_application_source=CEVF',
    notes      = 'P2 form blitz - CEV and CEVG share one pipeline, 100 pct of submissions screened, 20 plus reviewers, response target 3 weeks',
    updated_at = now()
from app.parties pt
where pt.id = f.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%clean energy ventures%'
  and f.form_url = 'https://cleanenergyventures.com/investment-application/';


-- ------------------------------------------------------------
-- 2. Field rows (guarded per label)
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
  (10,  'Company Name', 'text', null::int, true, null, null),
  (20,  'One Sentence Company Description', 'textarea', null::int, true,
        null, 'company_one_liner'),
  (30,  'Industry Subsector', 'dropdown', null::int, true,
        'exact option Advanced Materials exists in the list', null),
  (40,  'Industry Subsector - Additional', 'dropdown', null::int, false,
        'no clean second fit - leave as None', null),
  (50,  'Seeking - Mentoring or Investment', 'dropdown', null::int, true,
        'checkbox group - pick Investment', null),
  (60,  'Number of Employees', 'number', null::int, false, null, null),
  (70,  'Monthly Burn Rate USD', 'number', null::int, false,
        'digits only', null),
  (80,  'Total Revenues Last 12 Months USD', 'number', null::int, false,
        'confirm royalty recognition first - do not guess', null),
  (90,  'Date Founded', 'date', null::int, true,
        'month and year dropdowns - confirm the actual founding date', null),
  (100, 'Company Website', 'url', null::int, false,
        'use the live corporate site if one exists', null),
  (110, 'Country', 'dropdown', null::int, true, null, null),
  (120, 'City', 'text', null::int, true, null, null),
  (130, 'State', 'dropdown', null::int, true, null, null),
  (140, 'How did you hear about us', 'dropdown', null::int, false, null, null),
  (150, 'Applied to CEV or CEVG in the past', 'dropdown', null::int, false,
        'checkbox - leave unchecked for No', null),
  (160, 'Contact First Name', 'text', null::int, true, null, null),
  (170, 'Contact Last Name', 'text', null::int, true, null, null),
  (180, 'Contact Title', 'text', null::int, true, null, null),
  (190, 'Email', 'text', null::int, true, null, null),
  (200, 'Phone Number', 'text', null::int, true,
        'required - fill live at submission', null),
  (210, 'LinkedIn Profile', 'url', null::int, false, null, null),
  (220, 'Product service customers and sales channel', 'textarea', null::int, true,
        'asks target markets, business model, unit economics and channel partners - append market_customers and go_to_market blocks in the editor', 'business_model'),
  (230, 'Unique innovations vs competitors and sustainable advantage', 'textarea', null::int, true,
        'append uvp advantage lines after the competitor comparison', 'competitors'),
  (240, 'Value propositions and unit economics', 'textarea', null::int, true,
        'value at lower cost than alternatives - unit economics welcome', 'uvp'),
  (250, 'Development stage and next milestones', 'textarea', null::int, true,
        'manual - TRL optional, describe production scale-up milestones', null),
  (260, 'Customer traction evidence and top customers', 'textarea', null::int, true,
        'specify commitment level - append market_customers names', 'traction'),
  (270, 'Team capabilities', 'textarea', null::int, true,
        'ends with three observer words on team performance', 'team_management'),
  (280, 'Anything else - regulations and key risks', 'textarea', null::int, true,
        'manual - extra value props, regulation neutrality, risk mitigation', null),
  (290, 'kWh reduced per unit per year', 'number', null::int, false,
        'leave blank - impact is not grid electricity', null),
  (300, 'CO2 tons abated per unit per year', 'number', null::int, false,
        'unit = 1 ton FCC displacing pulp - needs a validated CO2e figure, do not guess', null),
  (310, 'Years of impact per unit', 'number', null::int, false,
        'consumable material - one year per unit', null),
  (320, 'Units per year at max adoption', 'number', null::int, false,
        'ton volume at max adoption - derive off the royalty model', null),
  (330, 'Years to max adoption', 'number', null::int, false, null, null),
  (340, 'Unit definition and methodology', 'textarea', null::int, false,
        'manual - define 1 ton FCC and the CO2e method, or explain why unavailable', null),
  (350, 'Financing to date', 'textarea', null::int, false,
        null, 'already_raised'),
  (360, 'Largest Previous Investors', 'text', null::int, false, null, null),
  (370, 'Total Capital Required to Break-even or Exit USD', 'number', null::int, true,
        'verify - royalty offset may cap the total need at this round', null),
  (380, 'Capital Raise Target Current Round USD', 'number', null::int, true, null, null),
  (390, 'Pre-Money Valuation USD', 'number', null::int, true,
        'their reference median seed is 5M - our 30M pre must lean on the validated royalty track', null),
  (400, 'Anticipated Closing Date', 'date', null::int, false, null, null),
  (410, 'Investment Terms', 'dropdown', null::int, true,
        'checkbox group - pick Equity', null),
  (420, 'Pitch deck shareable link', 'url', null::int, true,
        'must open for anyone without an account - single pdf strongly preferred over pptx, verify Drive sharing set to anyone with the link', null)
) as v(seq, label, field_type, max_length, is_required, help_text, canonical_key)
  on true
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%clean energy ventures%'
  and f.form_url = 'https://cevg.com/members/node/add/company?field_application_source=CEVF'
  and not exists (
    select 1 from app.application_form_fields ff
    where ff.form_id = f.id and ff.label = v.label
  );


-- ------------------------------------------------------------
-- 3. Prefilled answers (rerunnable via the field_id uniqueness)
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
  ('Company Name',                        'Marinebio Group Inc', null),
  ('One Sentence Company Description',    null, 'company_one_liner'),
  ('Industry Subsector',                  'Advanced Materials', null),
  ('Seeking - Mentoring or Investment',   'Investment', null),
  ('Number of Employees',                 '3', null),
  ('Monthly Burn Rate USD',               '5000', null),
  ('Country',                             'United States', null),
  ('City',                                'Austin', null),
  ('State',                               'Texas', null),
  ('How did you hear about us',           'Online research', null),
  ('Applied to CEV or CEVG in the past',  'No', null),
  ('Contact First Name',                  'Yun Young', null),
  ('Contact Last Name',                   'Heo', null),
  ('Contact Title',                       'CEO', null),
  ('Email',                               'ceo@marinebiogroup.com', null),
  ('LinkedIn Profile',                    'https://www.linkedin.com/in/yunyoung-heo-a2640a195/', null),
  ('Product service customers and sales channel', null, 'business_model'),
  ('Unique innovations vs competitors and sustainable advantage', null, 'competitors'),
  ('Value propositions and unit economics', null, 'uvp'),
  ('Customer traction evidence and top customers', null, 'traction'),
  ('Team capabilities',                   null, 'team_management'),
  ('Years of impact per unit',            '1', null),
  ('Financing to date',                   null, 'already_raised'),
  ('Largest Previous Investors',          'None - bootstrapped', null),
  ('Total Capital Required to Break-even or Exit USD', '5000000', null),
  ('Capital Raise Target Current Round USD', '5000000', null),
  ('Pre-Money Valuation USD',             '30000000', null),
  ('Investment Terms',                    'Equity', null),
  ('Pitch deck shareable link',           'https://drive.google.com/file/d/1alGPNW-LafjgszrRkj0ATkQ86bFy7GNN/view?usp=drive_link', null)
) as v(label, final_text, lib_key)
  on v.label = ff.label
left join app.answer_library al
  on al.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
 and al.answer_key = v.lib_key
 and al.variant = 'medium'
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%clean energy ventures%'
  and f.form_url = 'https://cevg.com/members/node/add/company?field_application_source=CEVF'
on conflict (field_id) do nothing;


-- ------------------------------------------------------------
-- 4. Form status -> drafting
-- ------------------------------------------------------------
update app.application_forms f
set status = 'drafting', updated_at = now()
from app.parties pt
where pt.id = f.party_id
  and f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%clean energy ventures%'
  and f.form_url = 'https://cevg.com/members/node/add/company?field_application_source=CEVF'
  and f.status = 'not_started';


-- ------------------------------------------------------------
-- VERIFY: 43 fields, 29 answered, bindings visible - the rows
-- with null text_head are the confirm-before-submit set
-- ------------------------------------------------------------
select ff.seq, ff.label, ff.is_required,
       fa.char_count,
       left(fa.final_text, 35) as text_head,
       al.answer_key
from app.application_form_fields ff
join app.application_forms f on f.id = ff.form_id
join app.parties pt          on pt.id = f.party_id
left join app.application_field_answers fa on fa.field_id = ff.id
left join app.answer_library al            on al.id = fa.answer_id
where f.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and pt.party_name ilike '%clean energy ventures%'
order by ff.seq;
