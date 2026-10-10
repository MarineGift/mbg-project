-- ============================================================
-- enrich_20261010_mill_emails_b07.sql   (already run 2026-10-10 - kept for history)
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Muda Paper Mills - two mill inboxes listed under Muda Paper Mills on the
-- muda.com.my contact page (checked by YunYoung in the browser 2026-10-10).
-- The other 13 addresses on that page belong to Muda's corrugating,
-- packaging, trading and JV subsidiaries or IR - not used.
-- Idempotent. Last statement is a verification select.
-- ============================================================
insert into app.contacts
  (organization_id, party_id, contact_type_id, email, title_text,
   is_primary, is_decision_maker, source, notes)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid,
       '18ecb713-8f25-4201-a594-bf54b97307c4'::uuid, 2, v.email, v.title_text,
       v.is_primary, false, 'homepage',
       'Listed under Muda Paper Mills on muda.com.my contact page (checked 2026-10-10)'
from (values
  ('info.mpmt@muda.com', 'Mill inbox (Muda Paper Mills, Tasek)', true),
  ('admin@mpmkj.com',    'Mill inbox (Muda Paper Mills, Kajang)', false)
) as v(email, title_text, is_primary)
where not exists (
  select 1 from app.contacts c
  where c.party_id = '18ecb713-8f25-4201-a594-bf54b97307c4'::uuid
    and lower(c.email) = lower(v.email) and c.deleted_at is null
);

select c.email, c.title_text, c.is_primary
from app.contacts c
where c.party_id = '18ecb713-8f25-4201-a594-bf54b97307c4'::uuid
  and c.deleted_at is null and c.email is not null;
