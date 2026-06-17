-- ============================================================
-- 20260616160000_investor_contacts_notes_batchD.sql
-- Batch D enrichment (Texas/angel + nearby fit funds), verified
-- 2026-06-16 from official/firm sources only. No guessed addresses.
--
-- Part 1: insert VERIFIED public pitch-email contacts (so these
--         parties gain an email and enter the High mailing pool):
--           - Ecliptic Capital   inquiries@eclipticcapital.com  (strong fit)
--           - Scout Ventures     ir@scout.vc                    (weak fit)
--
-- Part 2: record cold-email status in app.parties.notes for firms
--         that do NOT accept cold email (form / warm-intro / cycle
--         portal only), plus a record note for the two above.
--
-- Idempotent: contacts use NOT EXISTS; notes append only if the
-- exact note text is not already present. Safe to re-run.
--
-- HOW TO APPLY (live): run in the Supabase SQL Editor.
-- ============================================================

begin;

-- ---------- Part 1: verified pitch-email contacts ----------
with picks(party_name, email, label) as (
  values
    ('Ecliptic Capital', 'inquiries@eclipticcapital.com', 'Pitch Inbox'),
    ('Scout Ventures',   'ir@scout.vc',                   'Pitch Inbox')
)
insert into app.contacts
  (party_id, organization_id, contact_type_id, full_name, email, is_primary, is_active, source)
select
  p.id,
  p.organization_id,
  coalesce(
    (select id from app.contact_types
       where code in ('general','other','company','main','primary')
       order by sort_order limit 1),
    (select min(id) from app.contact_types)
  ),
  k.label,
  k.email,
  true,
  true,
  'contact_enrich_2026Q2'
from picks k
join app.parties p
  on p.party_name = k.party_name
 and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
 and p.deleted_at is null
join app.party_types pt
  on pt.id = p.party_type_id and pt.code = 'investor'
where not exists (
  select 1 from app.contacts c
  where c.party_id = p.id
    and lower(c.email) = lower(k.email)
    and c.deleted_at is null
);

-- ---------- Part 2: cold-email status into parties.notes ----------
with notes(party_name, note) as (
  values
    ('Ecliptic Capital',
     '[pitch-email 2026-06-16] Verified pitch email inquiries@eclipticcapital.com added. Fit: STRONG - material science / cleantech / consumer goods; Austin local. Website ecliptic.capital.'),
    ('Scout Ventures',
     '[pitch-email 2026-06-16] Verified pitch email ir@scout.vc added. Fit: WEAK - defense / dual-use focus (likely mis-tagged High).'),
    ('True Wealth Ventures',
     '[no-cold-email 2026-06-16] No email channel; accepts direct pitch via truewealthvc.com form (warm intro NOT required). Fit: STRONG - women-led consumer / sustainable health (Marine Gift / femcare).'),
    ('Suzano Ventures',
     '[no-cold-email 2026-06-16] No public cold email. Inbound via suzano.com.br Contact Us / accelerator programs. Fit: pulp/paper bioeconomy (CVC of the largest global pulp producer).'),
    ('Closed Loop Partners',
     '[no-cold-email 2026-06-16] No public cold email. Apply via closedlooppartners.com Apply-for-Funding (Closed Loop Ventures Group). Fit: circular economy / packaging.'),
    ('Central Texas Angel Network (CTAN)',
     '[no-cold-email 2026-06-16] Does not review off-cycle/cold deals; apply via ctan.com funding-cycle portal (admin fee). Member contacts confidential. General inquiries: Director@ctan.com. Note: website is ctan.com.'),
    ('ATX Venture Partners',
     '[no-cold-email 2026-06-16] No public email; submit via atxventurepartners.com/contact form; warm intro preferred. Fit: WEAK - B2B software / AI focus (likely mis-tagged High).'),
    ('Valhalla Ventures',
     '[no-cold-email 2026-06-16] No public email; pitch via valhalla.ventures form. Fit: WEAK - deeptech + gaming.'),
    ('Emergent Technologies',
     '[no-cold-email 2026-06-16] IP-commercialization / partner model (emergenttechnologies.com), not a standard round investor; no cold-pitch email. Low priority as a cold target.')
)
update app.parties p
set notes = case
              when coalesce(p.notes, '') = '' then n.note
              else p.notes || E'\n' || n.note
            end
from notes n
where p.party_name = n.party_name
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.deleted_at is null
  and exists (
    select 1 from app.party_types pt
    where pt.id = p.party_type_id and pt.code = 'investor'
  )
  and (p.notes is null or position(n.note in p.notes) = 0);

commit;

-- Verify:
-- select party_name, notes from app.parties
-- where party_name in ('Ecliptic Capital','Scout Ventures','True Wealth Ventures',
--   'Suzano Ventures','Closed Loop Partners','Central Texas Angel Network (CTAN)',
--   'ATX Venture Partners','Valhalla Ventures','Emergent Technologies')
-- order by party_name;
