-- 20260620120000_app_parties_website_backfill_batch6.sql
-- filler_supplier (party_type_id = 3) website backfill - BATCH 6 (policy decisions)
--
-- RUN IN SUPABASE SQL EDITOR to apply data. Pushing this file only
-- version-controls it; it does NOT apply the UPDATE.
--
-- Two decisions applied here:
--   (A) Guangdong Qiangda -> gdcaco3.com  (verified own corporate site; LinkedIn-listed)
--   (B) Imerys policy change: apply imerys.com to ALL Imerys country units
--       (overrides the earlier Tier-C "intentional NULL" stance for Imerys only).
-- Guards : idempotent (website IS NULL), party_type_id = 3, org-scoped.

-- (A) Guangdong Qiangda New Materials Technology
update app.parties set website = 'https://www.gdcaco3.com', updated_at = now()
where id = '6e2eddb4-511a-454f-8f6b-d2e2533f933a'::uuid
  and website is null
  and party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- (B) Imerys blanket: every Imerys country unit that is still NULL -> imerys.com
update app.parties set website = 'https://www.imerys.com', updated_at = now()
where party_name ilike 'Imerys%'
  and website is null
  and party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- verify (Qiangda + every Imerys filler row, with resulting website)
select id, party_name, website
from app.parties
where party_type_id = 3
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and ( id = '6e2eddb4-511a-454f-8f6b-d2e2533f933a'::uuid
        or party_name ilike 'Imerys%' )
order by party_name;
