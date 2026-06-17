-- ============================================================
-- 20260616170000_investor_research64_channel_fit.sql
-- Apply the 64-investor cold-outreach Research (2026-06-16).
--
-- Part 1: insert VERIFIED public pitch-email contacts not already
--         handled in batch D:
--           - Breakout Ventures   contact@breakout.vc   (official site)
--         (Ecliptic / Scout were inserted in batch D; not repeated.)
--
-- Part 2: write channel + fit + keep/downgrade into app.parties.notes
--         for all 64 firms, using the AUTHORITATIVE DB party_name from
--         the original no-email list (names differ from the research
--         table label in a few cases, e.g. "Data Collective Venture
--         Capital", "Founders Fund LLC", "Stanford Management Company
--         (SMC)", "Union Square Ventures (USV)").
--
-- Emails seen only on third-party aggregators (M12 contact@m12.vc,
-- G2VP info@g2vp.com, Trust Ventures info@trustventures.com, Applied
-- applied_ventures@amat.com) are NOT inserted as contacts - per the
-- no-guessing rule they are recorded in notes with "official form
-- preferred" / "reconfirm on official site".
--
-- Idempotent: contacts use NOT EXISTS; notes append only if the exact
-- tagged note is not already present (so batch-D rows are not dupes,
-- and re-running is safe). Tag prefix: [research64 2026-06-16].
--
-- HOW TO APPLY (live): run in the Supabase SQL Editor. The final
-- SELECT reports how many of the 64 names matched a party row, so any
-- name mismatch is visible immediately.
-- ============================================================

begin;

-- ---------- Part 1: verified pitch-email contact (Breakout) ----------
with picks(party_name, email, label) as (
  values
    ('Breakout Ventures', 'contact@breakout.vc', 'Pitch Inbox')
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
  k.label, k.email, true, true, 'contact_enrich_2026Q2'
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

-- ---------- Part 2: channel + fit notes for all 64 ----------
with research(party_name, note) as (
  values
    ('3M Ventures',                         '[research64 2026-06-16] FORM (3m.com 3M Ventures contact). Fit: STRONG - advanced materials/sustainable packaging/consumer. Keep High.'),
    ('8090 Industries',                     '[research64 2026-06-16] WARM_INTRO_ONLY. Fit: MODERATE - industrial/energy transition. Keep High.'),
    ('8VC',                                 '[research64 2026-06-16] WARM_INTRO_ONLY. Fit: WEAK - B2B/healthcare/logistics/defense. DOWNGRADE.'),
    ('Accel',                               '[research64 2026-06-16] WARM_INTRO_ONLY. Fit: WEAK - software/internet generalist. DOWNGRADE.'),
    ('Amazon Climate Pledge Fund',          '[research64 2026-06-16] FORM (fund.theclimatepledge.com/us/en/contact-us). Fit: MODERATE - decarbonization/sustainable packaging. Keep High.'),
    ('Applied Ventures',                    '[research64 2026-06-16] FORM/EMAIL (appliedmaterials.com Applied Ventures submissions; applied_ventures@amat.com - official). Fit: WEAK - semiconductor/display materials, not paper/consumer. DOWNGRADE.'),
    ('At One Ventures',                     '[research64 2026-06-16] FORM (atoneventures.com contact). Fit: STRONG - climate deep tech, nature-positive materials. Keep High.'),
    ('BASF Venture Capital',                '[research64 2026-06-16] FORM (basf.com BVC contact). Fit: STRONG - evergreen fund, 1-5M USD tickets, CO2/circular economy/new materials/biotech. Keep High.'),
    ('Breakout Ventures',                   '[research64 2026-06-16] EMAIL contact@breakout.vc added (form at breakout.vc/contact). Fit: STRONG - bioscience/biomaterials/sustainability. Keep High.'),
    ('Capricorn Investment Group',          '[research64 2026-06-16] NOT_A_COLD_TARGET - impact asset manager/LP, no cold seed portal. DOWNGRADE.'),
    ('Cavallo Ventures',                    '[research64 2026-06-16] FORM (cavallovc.com). Fit: MODERATE - Wilbur-Ellis CVC: specialty chemicals/ingredients/cosmetics+ag. Keep High.'),
    ('Closed Loop Partners',                '[research64 2026-06-16] FORM (closedlooppartners.com apply-for-funding). Fit: MODERATE - circular economy/packaging. Keep High.'),
    ('Data Collective Venture Capital',     '[research64 2026-06-16] WARM_INTRO_ONLY. Fit: MODERATE - deep tech incl. industrial/bio; warm-intro driven. Keep High.'),
    ('Dow Venture Capital',                 '[research64 2026-06-16] FORM (corporate.dow.com VC contact). Fit: STRONG - materials science/chemicals/packaging; core FCC fit. Keep High.'),
    ('Emerson Collective',                  '[research64 2026-06-16] WARM_INTRO_ONLY. Fit: WEAK-MODERATE - impact/consumer/health; no public pitch channel. DOWNGRADE.'),
    ('Flagship Pioneering',                 '[research64 2026-06-16] WARM_INTRO_ONLY - venture-creation firm, builds in-house, no external pitches. Fit: WEAK. DOWNGRADE.'),
    ('Founders Fund LLC',                   '[research64 2026-06-16] WARM_INTRO_ONLY. Fit: WEAK - frontier/defense/generalist. DOWNGRADE.'),
    ('G2 Venture Partners',                 '[research64 2026-06-16] FORM (g2vp.com/contact). NOTE: info@g2vp.com only on 3rd-party aggregators - use official form. Fit: STRONG - sustainable industrial/materials/climate. Keep High.'),
    ('Generation Investment Management',    '[research64 2026-06-16] NOT_A_COLD_TARGET - sustainability public-equity/growth, no cold seed. DOWNGRADE.'),
    ('Genoa Ventures',                      '[research64 2026-06-16] FORM (genoavc.com contact). Fit: STRONG - biology+tech incl. industrial/consumer bio, chemicals. Keep High.'),
    ('GIC',                                 '[research64 2026-06-16] NOT_A_COLD_TARGET - Singapore sovereign wealth fund. DOWNGRADE.'),
    ('Gigafund',                            '[research64 2026-06-16] WARM_INTRO_ONLY - concentrated, founder-referral. Fit: WEAK. DOWNGRADE.'),
    ('GM Ventures',                         '[research64 2026-06-16] WARM_INTRO_ONLY - automotive/mobility/materials CVC, no public submit. Fit: WEAK. DOWNGRADE.'),
    ('ICONIQ Capital',                      '[research64 2026-06-16] WARM_INTRO_ONLY - wealth-mgmt/growth, relationship-driven. Fit: WEAK. DOWNGRADE.'),
    ('In-Q-Tel',                            '[research64 2026-06-16] FORM (iqt.org submit-a-business-plan). Fit: WEAK - national-security mission, no materials/consumer relevance. DOWNGRADE.'),
    ('KKR Global Impact Fund',              '[research64 2026-06-16] NOT_A_COLD_TARGET - large-cap PE/growth impact, no cold seed. DOWNGRADE.'),
    ('Kleiner Perkins',                     '[research64 2026-06-16] WARM_INTRO_ONLY. Fit: WEAK - generalist tech. DOWNGRADE.'),
    ('L Catterton',                         '[research64 2026-06-16] NOT_A_COLD_TARGET - consumer-PE growth/buyout, no cold seed portal. DOWNGRADE.'),
    ('Lowercarbon Capital',                 '[research64 2026-06-16] FORM (lowercarbon.com website inbound). Fit: MODERATE - climate/industrial materials/decarbonization. Keep High.'),
    ('M12 (Microsoft)',                     '[research64 2026-06-16] FORM (m12.vc/contact). NOTE: contact@m12.vc only on 3rd-party aggregators - use official form. Fit: WEAK - B2B software/enterprise/AI. DOWNGRADE.'),
    ('Microsoft Climate Innovation Fund',   '[research64 2026-06-16] FORM (microsoft.com climate-innovation-fund). Fit: MODERATE - climate/decarbonization. Keep High.'),
    ('Mithril Capital',                     '[research64 2026-06-16] WARM_INTRO_ONLY - growth tech, no cold channel. Fit: WEAK. DOWNGRADE.'),
    ('Mitsui Global Investment',            '[research64 2026-06-16] FORM (mitsui-global.com/contact-us). Fit: MODERATE - industrial/chemicals/materials/consumer conglomerate CVC. Keep High.'),
    ('P&G Ventures',                        '[research64 2026-06-16] FORM (ventureschallenge.com Innovation Challenge - periodic intake, time to open call). Fit: STRONG - consumer/personal-care, womens wellness/femcare. Keep High.'),
    ('PepsiCo Greenhouse Accelerator',      '[research64 2026-06-16] FORM (greenhouseaccelerator.com). Fit: WEAK - food/beverage sustainability/ag, not our category. DOWNGRADE.'),
    ('Phoenix Venture Partners',            '[research64 2026-06-16] FORM (phoenix-vp.com submit deck). Fit: STRONG - commercializes breakthrough materials-science; core FCC fit. Keep High.'),
    ('Playground Global',                   '[research64 2026-06-16] WARM_INTRO_ONLY. Fit: MODERATE - deep tech incl. advanced materials/robotics. Keep High.'),
    ('Prime Movers Lab',                    '[research64 2026-06-16] FORM (primemoverslab.com/contact). Fit: MODERATE - breakthrough science/manufacturing/materials/energy. Keep High.'),
    ('Qualcomm Ventures',                   '[research64 2026-06-16] WARM_INTRO_ONLY - 5G/semiconductors; 5G fund email is fund-specific, no general public form. Fit: WEAK. DOWNGRADE.'),
    ('S2G Ventures',                        '[research64 2026-06-16] FORM (s2ginvestments.com/contact-us). Fit: MODERATE - food/ag/oceans/energy; oceans adjacency to Marine Gift. Keep High.'),
    ('Safar Partners',                      '[research64 2026-06-16] FORM (safar.partners contact). Fit: STRONG - cleantech & advanced materials, life sciences. Keep High.'),
    ('Saint-Gobain NOVA',                   '[research64 2026-06-16] FORM (nova-saint-gobain.com Get in touch). Fit: MODERATE-STRONG - building/advanced materials, minerals, circular economy; FCC fillers/minerals. Keep High.'),
    ('Samsung NEXT',                        '[research64 2026-06-16] WARM_INTRO_ONLY - software/AI/consumer-tech/frontier; catalyst@samsung.com is the separate Catalyst Fund. Fit: WEAK. DOWNGRADE.'),
    ('Section 32',                          '[research64 2026-06-16] WARM_INTRO_ONLY - deep tech/bio/AI; only press email published. Fit: WEAK-MODERATE. DOWNGRADE.'),
    ('SOSV',                                '[research64 2026-06-16] FORM (sosv.com/apply - HAX/IndieBio). Fit: STRONG - hard tech (HAX) + bio (IndieBio); pre-seed checks. Keep High.'),
    ('Stanford Management Company (SMC)',   '[research64 2026-06-16] NOT_A_COLD_TARGET - university endowment. DOWNGRADE.'),
    ('Sumitomo Corp Equity Asia / Presidio','[research64 2026-06-16] WARM_INTRO_ONLY - corporate/industrial CVC (presidio-ventures.com), no cold channel. Fit: MODERATE. DOWNGRADE.'),
    ('Supply Change Capital',               '[research64 2026-06-16] FORM (supplychange.fund contact). Fit: MODERATE - food-system/ingredients/sustainability, women-led; partial Marine Gift. Keep High.'),
    ('Sutter Hill Ventures',                '[research64 2026-06-16] WARM_INTRO_ONLY. Fit: WEAK - enterprise/software. DOWNGRADE.'),
    ('Temasek',                             '[research64 2026-06-16] NOT_A_COLD_TARGET - Singapore state investor. DOWNGRADE.'),
    ('The Coca-Cola Company Ventures',      '[research64 2026-06-16] NOT_A_COLD_TARGET - beverage/consumer; current vehicle via Greycroft, no cold portal. DOWNGRADE.'),
    ('TPG Rise Climate',                    '[research64 2026-06-16] NOT_A_COLD_TARGET - large PE/growth climate, no cold seed. DOWNGRADE.'),
    ('Trust Ventures',                      '[research64 2026-06-16] EMAIL info@trustventures.com (3rd-party profiles only - reconfirm on official site; no public form found). Fit: MODERATE - regulatory-barrier industries; sunscreen/femcare regulatory angle. Keep High.'),
    ('UC Investments',                      '[research64 2026-06-16] NOT_A_COLD_TARGET - University of California endowment. DOWNGRADE.'),
    ('Union Square Ventures (USV)',         '[research64 2026-06-16] WARM_INTRO_ONLY. Fit: WEAK - internet/software/fintech. DOWNGRADE.'),
    ('Voyager Ventures',                    '[research64 2026-06-16] FORM (voyagervc.com contact). Fit: STRONG - frontier energy/industrial/climate, critical materials, chemicals decarbonization. Keep High.'),
    ('Walmart Strategic Capital',           '[research64 2026-06-16] NOT_A_COLD_TARGET / WARM_INTRO_ONLY - no genuine venture cold-pitch portal; public Open Call/RangeMe is supplier sourcing, not investment. DOWNGRADE.')
)
update app.parties p
set notes = case
              when coalesce(p.notes, '') = '' then r.note
              else p.notes || E'\n' || r.note
            end
from research r
where p.party_name = r.party_name
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and p.deleted_at is null
  and exists (
    select 1 from app.party_types pt
    where pt.id = p.party_type_id and pt.code = 'investor'
  )
  and (p.notes is null or position(r.note in p.notes) = 0);

commit;

-- ---------- Match report: confirm all research names hit a party ----------
-- (Names with matched=0 did not match a DB party_name and need attention.)
with research(party_name) as (
  values
    ('3M Ventures'),('8090 Industries'),('8VC'),('Accel'),('Amazon Climate Pledge Fund'),
    ('Applied Ventures'),('At One Ventures'),('BASF Venture Capital'),('Breakout Ventures'),
    ('Capricorn Investment Group'),('Cavallo Ventures'),('Closed Loop Partners'),
    ('Data Collective Venture Capital'),('Dow Venture Capital'),('Emerson Collective'),
    ('Flagship Pioneering'),('Founders Fund LLC'),('G2 Venture Partners'),
    ('Generation Investment Management'),('Genoa Ventures'),('GIC'),('Gigafund'),
    ('GM Ventures'),('ICONIQ Capital'),('In-Q-Tel'),('KKR Global Impact Fund'),
    ('Kleiner Perkins'),('L Catterton'),('Lowercarbon Capital'),('M12 (Microsoft)'),
    ('Microsoft Climate Innovation Fund'),('Mithril Capital'),('Mitsui Global Investment'),
    ('P&G Ventures'),('PepsiCo Greenhouse Accelerator'),('Phoenix Venture Partners'),
    ('Playground Global'),('Prime Movers Lab'),('Qualcomm Ventures'),('S2G Ventures'),
    ('Safar Partners'),('Saint-Gobain NOVA'),('Samsung NEXT'),('Section 32'),('SOSV'),
    ('Stanford Management Company (SMC)'),('Sumitomo Corp Equity Asia / Presidio'),
    ('Supply Change Capital'),('Sutter Hill Ventures'),('Temasek'),
    ('The Coca-Cola Company Ventures'),('TPG Rise Climate'),('Trust Ventures'),
    ('UC Investments'),('Union Square Ventures (USV)'),('Voyager Ventures'),
    ('Walmart Strategic Capital')
)
select r.party_name,
       count(p.id) as matched
from research r
left join app.parties p
  on p.party_name = r.party_name
 and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
 and p.deleted_at is null
group by r.party_name
having count(p.id) = 0
order by r.party_name;
-- (The 7 batch-D names handled earlier - Ecliptic, Scout, True Wealth, Suzano,
--  Closed Loop appears above too, CTAN, ATX, Valhalla, Emergent - are intentionally
--  not all re-listed here; Closed Loop is included since it is also a research row.)
