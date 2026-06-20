-- ============================================================
-- 20260620050000_app_filler_profile_groupB2_marketrole_cleanup.sql
-- (Group 2) Final market_role cleanup. 13 rows whose market_role held genuine
-- operational descriptions (plant lists, capacities, HQ/sales detail). The long
-- text is MOVED to notes (preserved verbatim) and market_role is set to a short,
-- accurate role value per row.
--
-- >>> RUN IN THE SUPABASE SQL EDITOR. <<<
-- Idempotent : re-run is a no-op (guard: still-long market_role and value differs).
-- Reversible : original market_role text preserved in notes.
-- ============================================================

update app.filler_supplier_profile fp
set
  notes = case
            when coalesce(fp.notes, '') = '' then fp.market_role
            else fp.notes || E'\n[ex-market_role]: ' || fp.market_role
          end,
  market_role = m.new_role,
  updated_at  = now()
from (values
    ('fac3df6e-875a-4cc3-97d4-fbb0ca10dd7f', 'Domestic merchant (Yeongwol GCC)'),
    ('85249ecd-c58c-499c-b7df-3cd505c742e4', 'Domestic merchant (GCC micronizer)'),
    ('3bccf3f8-8b1e-43af-9fdd-049b62af066b', 'Merchant + onsite/satellite (NA)'),
    ('8f10519d-75ac-49f2-b4ce-587b47accdf6', 'Merchant (Mielnik plant)'),
    ('33d5aa0b-2cf8-4b73-842f-873f2a85312d', 'Merchant (lime/limestone)'),
    ('fce58997-4089-4a47-8b3e-348f1e97e1fe', 'Merchant (Saudi minerals)'),
    ('fa423be1-6482-4147-beae-179d118f48d9', 'Regional HQ (SMI Americas)'),
    ('939c9bcc-9f01-4394-b66e-886def63bde9', 'Cross-border merchant (from US mills)'),
    ('7868456a-bd64-4de2-9930-74cd21db8dea', 'Merchant (kaolin/mineral solutions)'),
    ('988b7f5c-40fb-487d-ac4e-1d432007f8e9', 'Merchant (AU processing network)'),
    ('55b9c376-49fd-4179-9277-1d4e1c7df03b', 'Merchant (lime, Poland)'),
    ('39aeaeff-6c76-41c6-8ccd-d004bc9d5102', 'Merchant (carbonate + kaolin coating)'),
    ('fbca4410-7bb9-4ec4-8d17-5adb39e1c38d', 'Merchant (Shah Alam base)')
) as m(party_id, new_role)
where fp.party_id = m.party_id::uuid
  and fp.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and fp.deleted_at is null
  and fp.market_role is not null
  and length(fp.market_role) > 55
  and fp.market_role <> m.new_role;

-- verification: expect 13 rows with short market_role + notes carrying the old text.
select p.party_name, fp.market_role, left(fp.notes, 50) as notes_head
from app.filler_supplier_profile fp
join app.parties p on p.id = fp.party_id
where fp.party_id in (
  'fac3df6e-875a-4cc3-97d4-fbb0ca10dd7f',  '85249ecd-c58c-499c-b7df-3cd505c742e4',  '3bccf3f8-8b1e-43af-9fdd-049b62af066b',  '8f10519d-75ac-49f2-b4ce-587b47accdf6',  '33d5aa0b-2cf8-4b73-842f-873f2a85312d',  'fce58997-4089-4a47-8b3e-348f1e97e1fe',  'fa423be1-6482-4147-beae-179d118f48d9',  '939c9bcc-9f01-4394-b66e-886def63bde9',  '7868456a-bd64-4de2-9930-74cd21db8dea',  '988b7f5c-40fb-487d-ac4e-1d432007f8e9',  '55b9c376-49fd-4179-9277-1d4e1c7df03b',  '39aeaeff-6c76-41c6-8ccd-d004bc9d5102',  'fbca4410-7bb9-4ec4-8d17-5adb39e1c38d'
)
order by p.party_name;
