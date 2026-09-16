-- ===========================================================================
--  update_20260915e_party_websites_round2.sql
--  URM - the second research pass: 12 more investor websites
-- ---------------------------------------------------------------------------
--  !! SUPABASE SQL EDITOR: press Ctrl+A (SELECT ALL) BEFORE pressing Run. !!
-- ---------------------------------------------------------------------------
--  Three values are marked CHECK below. They are plausible but each could
--  belong to a different company with a similar name, and every domain here
--  becomes a mail whitelist rule once migration_20260915k runs - a wrong one
--  opens the gate to whoever really owns it. Empty the quotes on any line you
--  are unsure about; that line is then skipped.
--
--  The 14 rows still blank after this pass are family offices with no public
--  site, individuals, or internal records. They stay empty on purpose.
--
--  NEXT: sql/migration_20260915l_normalize_websites.sql (one format + the
--  duplicate report), then re-run migration_20260915k_whitelist_directory.sql.
--
--  IDEMPOTENT: safe to re-run.
-- ===========================================================================

update app.parties p
   set website = v.website,
       updated_at = now()
  from (values
    ('cascadeassetmanagement.com', 'ad5e0008-6ca2-4c0b-b558-1579d2a048ca'::uuid),  -- [US] Cascade Investment  << CHECK
    ('deepspacevc.com', 'c6a32f22-e8de-441b-8989-54da84f52c85'::uuid),  -- [US] Deep Space Ventures
    ('humbaventures.com', '53219170-f6c8-40de-8434-3171491aaf7e'::uuid),  -- [US] Humba Ventures
    ('integr8dcapital.com', '5db46a86-a45a-412d-b7c5-c98c0657f6fe'::uuid),  -- [US] Integr8d Capital
    ('jones.com', '4f5158be-54c8-46c6-a0a8-07df1d49fc47'::uuid),  -- [US] Jones Capital  << CHECK
    ('perot.com', 'af2a872d-a1a9-4849-aa75-2e1987e98317'::uuid),  -- [US] Petrus Group (Perot Family Office)  << CHECK
    ('poscoinvestment.com', '1aebebda-2a09-4b74-aaab-8b9483daa084'::uuid),  -- [KR] POSCO Venture Capital
    ('quake.vc', 'f0c2b8aa-2562-4377-bdac-d8f74bb6bc89'::uuid),  -- [US] Quake Capital
    ('seabirdventures.fund', '47cb0fe4-66ea-4e35-9b2f-69cd1380a15f'::uuid),  -- [US] Seabird Ventures
    ('valhalla-investment.com', '29107c16-2a13-444f-8a8b-584f610822a9'::uuid),  -- [US] Valhalla Investment Group
    ('veritecventures.com', '8851ac5c-5a12-442a-b013-8b12c7d58016'::uuid),  -- [US] Veritec Ventures
    ('wildbasininv.com', '37b6063b-77a1-469b-8f40-857978b213bf'::uuid)   -- [US] Wild Basin Investments
  ) as v(website, party_id)
 where p.id = v.party_id
   and p.deleted_at is null
   and nullif(trim(v.website), '') is not null;

-- ---------------------------------------------------------------------------
-- VERIFY - how many investors / partners are still without a website
-- ---------------------------------------------------------------------------
select t.code as party_type,
       count(*) filter (where coalesce(nullif(trim(p.website), ''), null) is null) as no_website,
       count(*) as total
from app.parties p
join app.party_types t on t.id = p.party_type_id
where p.deleted_at is null
  and t.code in ('investor', 'partner')
group by t.code
order by no_website desc;
