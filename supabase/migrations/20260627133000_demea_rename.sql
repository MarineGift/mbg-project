-- ============================================================
-- 20260627133000_demea_rename.sql
-- Rename the 'Demeter' party to its current name after rebrand.
-- Demeter Investment Managers -> Demea Sustainable Investment (part of Demea Invest,
-- after merger with Cerea Partners). Active domain: demea-si.com (demeter-im.com redirects there).
-- Updates party_name + website + notes only. investor_profile / contacts (party_id FK) unaffected.
-- Idempotent: after rename the WHERE no longer matches, so re-runs are a safe no-op.
-- Run as one txn in Supabase SQL Editor (clear the tab first, then paste).
-- ============================================================

begin;

update app.parties
set party_name = 'Demea Sustainable Investment',
    website    = 'https://www.demea-si.com',
    notes      = 'Demea Sustainable Investment (ex Demeter Investment Managers), part of Demea Invest after merger with Cerea Partners. About EUR 3B AUM across agriculture, agrifood, energy and ecological transition. Advanced-materials and circular-economy exposure via the Circular Innovation Fund (co-managed with Cycle Capital).'
where party_name = 'Demeter'
  and source = 'global_am_investors_2026Q3'
  and deleted_at is null;

commit;

-- ===================== VERIFY =====================
-- expect 1 row, now named 'Demea Sustainable Investment', website demea-si.com:
select party_name, country_code, city, website, source
from app.parties
where source = 'global_am_investors_2026Q3'
  and party_name in ('Demea Sustainable Investment','Demeter');

-- linked email contact still attached (expect contact@demea-si.com):
select p.party_name, c.email
from app.contacts c join app.parties p on p.id = c.party_id
where c.source = 'global_am_investors_2026Q3_email'
  and p.party_name = 'Demea Sustainable Investment';
