-- ============================================================
-- scan_20261010_licensee_host_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- READ-ONLY. One statement - export the result as CSV.
-- Paper mills supplied by MBG's licensees (Omya, Specialty Minerals / MTI),
-- through app.party_supply_links. This is the list to bring to the Omya and
-- SMI headquarters talks: "propose FCC to your host mills".
--   licensee      Omya or SMI (by supplier party name)
--   supplier_row  the licensee plant / country row the link points at
--   link_type     active / potential, confidence as stored
--   mill_has_email  whether URM already holds an e-mail for the mill
-- Archived and deleted mills are left out.
-- ============================================================
select case when f.party_name ilike '%omya%' then 'Omya'
            else 'SMI' end                         as licensee,
       f.party_name                                as supplier_row,
       l.link_type,
       l.confidence,
       m.party_name                                as mill_name,
       m.country_code                              as mill_country,
       m.city                                      as mill_city,
       m.website                                   as mill_website,
       exists (select 1 from app.contacts c
               where c.party_id = m.id and c.deleted_at is null
                 and nullif(btrim(c.email), '') is not null) as mill_has_email,
       m.id                                        as mill_party_id
from app.party_supply_links l
join app.parties f on f.id = l.filler_party_id and f.deleted_at is null
join app.parties m on m.id = l.mill_party_id   and m.deleted_at is null
join app.party_types t on t.id = m.party_type_id and t.code = 'paper_mill'
where (f.party_name ilike '%omya%'
       or f.party_name ilike '%specialty minerals%'
       or f.party_name ilike 'minerals technologies%')
  and coalesce(m.status, 'active') <> 'archived'
order by licensee, l.link_type, m.country_code, m.party_name;
