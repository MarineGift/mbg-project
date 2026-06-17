-- ============================================================
-- 20260616180000_investor_priority_downgrade_offthesis.sql
-- Apply the 64-investor Research keep/downgrade recommendations:
-- move every DOWNGRADE firm (off-thesis VCs + cold-not-target
-- LP/sovereign/endowment/large-PE) from priority 'high' to 'medium',
-- leaving the High pool to the on-thesis, cold-pitchable targets.
--
-- 35 downgrade names (authoritative DB party_name from the original
-- no-email list). Matching is exact; STEP 1 lets you eyeball the set
-- and any name that does not match before STEP 2 changes anything.
--
-- HOW TO APPLY (live): run in the Supabase SQL Editor.
--   1) Run STEP 1 alone first - review current priority + matched count.
--   2) If it looks right, run STEP 2 to perform the UPDATE.
-- (Running the whole file executes both; STEP 2 only touches rows that
--  are currently 'high', so it is safe and idempotent.)
-- ============================================================

-- ---------- shared list ----------
-- (kept inline in each step so each can be run independently)

-- ====================== STEP 1: PREVIEW ======================
-- Shows each downgrade target: current priority + whether it matched.
-- matched=0  => name not found as an investor party (tell me; needs fix)
-- priority    => what it is now (only 'high' rows will change in STEP 2)
with dg(party_name) as (
  values
    ('8VC'),('Accel'),('Applied Ventures'),('ATX Venture Partners'),
    ('Capricorn Investment Group'),('Emergent Technologies'),('Emerson Collective'),
    ('Flagship Pioneering'),('Founders Fund LLC'),('Generation Investment Management'),
    ('GIC'),('Gigafund'),('GM Ventures'),('ICONIQ Capital'),('In-Q-Tel'),
    ('KKR Global Impact Fund'),('Kleiner Perkins'),('L Catterton'),('M12 (Microsoft)'),
    ('Mithril Capital'),('PepsiCo Greenhouse Accelerator'),('Qualcomm Ventures'),
    ('Samsung NEXT'),('Scout Ventures'),('Section 32'),('Stanford Management Company (SMC)'),
    ('Sumitomo Corp Equity Asia / Presidio'),('Sutter Hill Ventures'),('Temasek'),
    ('The Coca-Cola Company Ventures'),('TPG Rise Climate'),('UC Investments'),
    ('Union Square Ventures (USV)'),('Valhalla Ventures'),('Walmart Strategic Capital')
)
select
  d.party_name,
  count(p.id)                                   as matched,
  coalesce(max(ip.priority), '(no investor_profile)') as current_priority
from dg d
left join app.parties p
  on p.party_name = d.party_name
 and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
 and p.deleted_at is null
left join app.party_types pt
  on pt.id = p.party_type_id and pt.code = 'investor'
left join app.investor_profile ip
  on ip.party_id = p.id
group by d.party_name
order by current_priority desc, d.party_name;

-- ====================== STEP 2: UPDATE ======================
-- Downgrade only the rows currently at 'high'. Re-runnable (rows already
-- 'medium' are skipped by the priority = 'high' guard).
with dg(party_name) as (
  values
    ('8VC'),('Accel'),('Applied Ventures'),('ATX Venture Partners'),
    ('Capricorn Investment Group'),('Emergent Technologies'),('Emerson Collective'),
    ('Flagship Pioneering'),('Founders Fund LLC'),('Generation Investment Management'),
    ('GIC'),('Gigafund'),('GM Ventures'),('ICONIQ Capital'),('In-Q-Tel'),
    ('KKR Global Impact Fund'),('Kleiner Perkins'),('L Catterton'),('M12 (Microsoft)'),
    ('Mithril Capital'),('PepsiCo Greenhouse Accelerator'),('Qualcomm Ventures'),
    ('Samsung NEXT'),('Scout Ventures'),('Section 32'),('Stanford Management Company (SMC)'),
    ('Sumitomo Corp Equity Asia / Presidio'),('Sutter Hill Ventures'),('Temasek'),
    ('The Coca-Cola Company Ventures'),('TPG Rise Climate'),('UC Investments'),
    ('Union Square Ventures (USV)'),('Valhalla Ventures'),('Walmart Strategic Capital')
)
update app.investor_profile ip
set priority = 'medium'
from app.parties p
join dg d on d.party_name = p.party_name
join app.party_types pt on pt.id = p.party_type_id and pt.code = 'investor'
where ip.party_id = p.id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.deleted_at is null
  and ip.priority = 'high';

-- ---------- after-state check ----------
select coalesce(priority, '(none)') as priority, count(*)
from app.investor_profile
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
group by 1 order by 1;
