-- ============================================================
-- scan_20261010_mill_email_worklist.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- READ-ONLY. Writes nothing. ONE statement, so the editor shows the whole
-- worklist as one result set - export it as CSV and upload it to the chat.
--
-- Rows: every live paper_mill party that has NO contact with an email.
-- Do-not-contact parties are left out.
-- Sorted so that rows sharing one corporate domain sit together - one
-- website lookup then covers every site row of that company.
--
-- Columns used for research:
--   company_key   domain (or website host) - the unit of research
--   rows_in_key   how many mill rows share that domain
--   has_form      a form marker contact already exists (source = form)
--   suppliers     filler suppliers linked through party_supply_links
-- ============================================================
with mill as (
  select p.id, p.party_name, p.country_code, p.city, p.website,
         p.domain_normalized, p.linkedin_url, p.email as party_email,
         coalesce(
           nullif(btrim(lower(p.domain_normalized)), ''),
           nullif(regexp_replace(lower(coalesce(p.website, '')),
                  '^(https?://)?(www\.)?([^/:?#]+).*$', '\3'), '')
         ) as company_key
  from app.parties p
  join app.party_types t on t.id = p.party_type_id
  where t.code = 'paper_mill'
    and p.deleted_at is null
    and coalesce(p.do_not_contact, false) = false
    and not exists (
      select 1 from app.contacts c
      where c.party_id = p.id
        and c.deleted_at is null
        and nullif(btrim(c.email), '') is not null
    )
),
ct as (
  select c.party_id,
         count(*) as contact_rows,
         bool_or(c.source = 'form') as has_form,
         string_agg(distinct nullif(btrim(c.linkedin_url), ''), ' | ') as contact_linkedin
  from app.contacts c
  where c.deleted_at is null
    and c.party_id in (select id from mill)
  group by c.party_id
),
sup as (
  select l.mill_party_id,
         string_agg(distinct f.party_name, ' | ') as suppliers
  from app.party_supply_links l
  join app.parties f on f.id = l.filler_party_id
  where l.mill_party_id in (select id from mill)
  group by l.mill_party_id
)
select m.company_key,
       count(*) over (partition by m.company_key) as rows_in_key,
       m.id as party_id,
       m.party_name,
       m.country_code,
       m.city,
       m.website,
       m.linkedin_url,
       m.party_email,
       coalesce(ct.contact_rows, 0) as contact_rows,
       coalesce(ct.has_form, false) as has_form,
       ct.contact_linkedin,
       sup.suppliers
from mill m
left join ct  on ct.party_id = m.id
left join sup on sup.mill_party_id = m.id
order by (m.company_key is null), m.company_key, m.country_code, m.party_name;
