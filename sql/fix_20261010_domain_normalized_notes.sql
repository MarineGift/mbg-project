-- ============================================================
-- fix_20261010_domain_normalized_notes.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Problem (seen in scan_20261010_filler_email_worklist, 51 filler rows, plus
-- paper mill rows with 'b' and the literal text 'null'):
--   app.parties.domain_normalized holds analyst remarks instead of a domain.
--   The domain auto-whitelist trigger (migration_20260918g) reads this column,
--   so mail from those companies is not matched to them.
-- Fix, for paper_mill and filler_supplier rows whose value is not a domain:
--   1) a remark longer than 3 characters (not the text null) is appended to
--      notes, so it is kept, not lost
--   2) domain_normalized is rebuilt from website, or set null if no website
-- Rows that already hold a real domain are not touched. Re-running is a no-op.
-- Last statement is a verification select.
-- ============================================================
update app.parties p
set notes = case
              when length(btrim(p.domain_normalized)) > 3
                 and lower(btrim(p.domain_normalized)) <> 'null'
                then coalesce(nullif(btrim(p.notes), '') || ' | ', '')
                     || 'Analyst remark (was in domain field): ' || btrim(p.domain_normalized)
              else p.notes
            end,
    domain_normalized = nullif(regexp_replace(lower(btrim(coalesce(p.website, ''))),
                          '^(https?://)?(www\.)?([^/:?#]+).*$', '\3'), ''),
    updated_at = now()
where p.deleted_at is null
  and p.domain_normalized is not null
  and lower(btrim(p.domain_normalized)) !~ '^[a-z0-9-]+(\.[a-z0-9-]+)+$'
  and p.party_type_id in (select t.id from app.party_types t
                          where t.code in ('paper_mill', 'filler_supplier'));

select t.code as party_type,
       count(*) filter (where p.domain_normalized is not null
                          and lower(btrim(p.domain_normalized)) !~ '^[a-z0-9-]+(\.[a-z0-9-]+)+$') as still_not_a_domain,
       count(*) filter (where p.notes like '%Analyst remark (was in domain field)%') as remarks_kept_in_notes
from app.parties p
join app.party_types t on t.id = p.party_type_id
where p.deleted_at is null
  and t.code in ('paper_mill', 'filler_supplier')
group by t.code
order by t.code;
