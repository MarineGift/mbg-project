-- 20260620260000_paper_mill_website_corrections_m5.sql
-- Corrections to paper_mill (party_type_id = 2) websites set in m3/m4, after spot-check.
-- These rows already hold an http URL, so the usual "fill only if missing" guard would skip
-- them; here we match on the OLD (wrong) value and overwrite, which is idempotent (re-running
-- after the fix is a no-op). UTF-8. RUN IN SUPABASE SQL EDITOR. Org+type scoped.

-- Seshasayee Paper & Boards: spbltd.com (was seshapaper.com)
update app.parties
set website = 'https://www.spbltd.com', updated_at = now()
where id = 'a7721ae3-e761-4b31-a6aa-d7b7610df205'
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and party_type_id = 2
  and website = 'https://www.seshapaper.com';

-- Bashundhara: bashundharapapermills.com (was bashundharagroup.com)
update app.parties
set website = 'https://www.bashundharapapermills.com', updated_at = now()
where id = 'cd2af0b1-a9ff-4251-aafd-4395ae3228b4'
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and party_type_id = 2
  and website = 'https://www.bashundharagroup.com';

-- Celulosa Argentina: celulosaargentina.com.ar (was celulosaargentina.com)
update app.parties
set website = 'https://www.celulosaargentina.com.ar', updated_at = now()
where id = '4ba39dee-769b-41d8-a494-f35e4f467ffd'
  and organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and party_type_id = 2
  and website = 'https://www.celulosaargentina.com';

-- verify (expect the 3 corrected domains)
select party_name, website
from app.parties
where id in (
  'a7721ae3-e761-4b31-a6aa-d7b7610df205',
  'cd2af0b1-a9ff-4251-aafd-4395ae3228b4',
  '4ba39dee-769b-41d8-a494-f35e4f467ffd'
)
order by party_name;
