-- ============================================================
-- 20260620000000_app_filler_profile_marketrole_cleanup_D.sql
-- (D) Filler-supplier profile cleanup.
--
-- Moves mis-placed NOTE text out of app.filler_supplier_profile.market_role
-- into notes, for 15 "Specialty Minerals (Country)" placeholder variants whose
-- market_role held boilerplate note text:
--   "HQ NY USA. NO direct presence in this market - only USA+China+...(17 countries)."
--   "HQ NY USA. EU operations: Lifford UK + Lappeenranta Finland + Hermalle Belgium"
--   "HQ NY USA (622 3rd Avenue). 34 operating countries ... Korea = NOT in list"
--
-- After: market_role = 'No direct presence'  (clean short value)
--        original text preserved verbatim in notes.
--
-- >>> RUN IN THE SUPABASE SQL EDITOR. <<<
-- Idempotent  : re-running is a no-op (guarded by market_role value + length).
-- Reversible  : the original market_role text is kept verbatim in notes.
-- Scope       : exactly the 15 party_ids listed below (Group 1 from diagnostic _7).
-- NOT touched : Group 2 (13 rows with genuine operational descriptions, e.g.
--               Omya (Korea) Yeongwol plant) - handled separately by judgment.
-- ============================================================

update app.filler_supplier_profile fp
set
  notes = case
            when coalesce(fp.notes, '') = '' then fp.market_role
            else fp.notes || E'\n[ex-market_role]: ' || fp.market_role
          end,
  market_role = 'No direct presence',
  updated_at  = now()
where fp.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and fp.deleted_at is null
  and fp.market_role is distinct from 'No direct presence'
  and length(fp.market_role) > 50
  and fp.party_id in (
    'e741435e-a148-4c97-b854-a734de4597a2',  -- Specialty Minerals (Austria)
    'eda52ae8-24f1-4182-b46b-09a52941be77',  -- Specialty Minerals (Bangladesh)
    '975fe6f1-c4e0-4000-80b0-7b375687ebe9',  -- Specialty Minerals (Global - PCC)
    '3b6015f7-1818-4f3c-a92b-25aca4e91395',  -- Specialty Minerals (Italy)
    'b083dc90-3569-4242-83bc-95c382c61039',  -- Specialty Minerals (Norway)
    '30ad1876-d91a-4269-b683-8d7f97bcd2a8',  -- Specialty Minerals (Pakistan)
    '64523bd1-fb8b-49f6-a610-948943eafbe4',  -- Specialty Minerals (Philippines)
    '067bd518-bbbf-4562-96d5-210ccbfb99b8',  -- Specialty Minerals (Russia)
    '7c88240a-501f-4363-ae34-a5c90855ef4d',  -- Specialty Minerals (Slovakia)
    '034f1462-2b04-47d5-bbe7-7ae903d98f59',  -- Specialty Minerals (Spain)
    '793ac93f-dadd-46e3-8248-718680332e88',  -- Specialty Minerals (Sri Lanka)
    '2724757b-7565-41f4-a048-e3da33805fdf',  -- Specialty Minerals (UK)
    '4986266c-fe4b-4c45-98f6-6ebf07f58c6c',  -- Specialty Minerals (Korea)
    'f644544d-bced-4938-818d-f1d8026dce61',  -- Specialty Minerals (Poland)
    'da2b4748-187f-4201-942b-cec65243388a'   -- Specialty Minerals (Turkey)
  );

-- verification: expect 15 rows, market_role='No direct presence', notes populated.
select p.party_name,
       fp.market_role,
       left(fp.notes, 60) as notes_head
from app.filler_supplier_profile fp
join app.parties p on p.id = fp.party_id
where fp.party_id in (
  'e741435e-a148-4c97-b854-a734de4597a2','eda52ae8-24f1-4182-b46b-09a52941be77',
  '975fe6f1-c4e0-4000-80b0-7b375687ebe9','3b6015f7-1818-4f3c-a92b-25aca4e91395',
  'b083dc90-3569-4242-83bc-95c382c61039','30ad1876-d91a-4269-b683-8d7f97bcd2a8',
  '64523bd1-fb8b-49f6-a610-948943eafbe4','067bd518-bbbf-4562-96d5-210ccbfb99b8',
  '7c88240a-501f-4363-ae34-a5c90855ef4d','034f1462-2b04-47d5-bbe7-7ae903d98f59',
  '793ac93f-dadd-46e3-8248-718680332e88','2724757b-7565-41f4-a048-e3da33805fdf',
  '4986266c-fe4b-4c45-98f6-6ebf07f58c6c','f644544d-bced-4938-818d-f1d8026dce61',
  'da2b4748-187f-4201-942b-cec65243388a'
)
order by p.party_name;
