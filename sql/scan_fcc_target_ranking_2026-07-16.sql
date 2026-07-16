-- ============================================================
-- scan_fcc_target_ranking_2026-07-16.sql
--
-- THE COVERAGE INVERSION, from block 4.
--
--   151 live deals = Omya 40 country shells
--                  + Specialty Minerals 43 country shells
--                  + Specialty Minerals 65 PLANTS
--                  + 3 reachable rows
--
--   90 companies with NO deal at all, including:
--     * the ENTIRE Imerys family - 8 rows covering Korea, HQ, China with 11
--       processing plants, India, USA, Brazil, Canada, Mexico. Imerys is the
--       number 3 global player.
--     * EVERY satellite PCC operator except SMI - Taekyung BK (KR, the Hansol
--       Janghang on-site plant), Double A Specialty Minerals (TH), Fimatec (JP)
--     * the entire Japanese roster of 9 - Okutama, whose own site claims over
--       90 percent of Japanese paper PCC, plus Shiraishi Kogyo, Maruo, Nittetsu,
--       Bihoku, Toyo Denka, Nitto Funka
--     * India 10, China 9, Korea 7, Poland 6, Turkey 5
--     * Mississippi Lime - the ONLY filler party with real contact depth
--
-- The campaign went deep where depth is useless - 65 individual plants that can
-- never sign a licence - and reached zero on the number 3 global player and on
-- three of the four satellite operators in the database.
--
-- WHY SATELLITE OPERATORS ARE THE POINT. FCC replaces or upgrades PCC in paper.
-- A company already running an on-site satellite PCC plant has the process, the
-- mill relationship, and the capex model FCC slots into. They are the most
-- natural licensees in the whole roster. There are four in this DB. The campaign
-- has one.
--
-- This scan builds the list the campaign should have been. It writes nothing.
--
-- READ-ONLY. Run each block SEPARATELY.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) THE RANKED TARGET LIST ----------
select
  case
    when coalesce(f.market_role,'') || ' ' || coalesce(f.supply_model,'') ~* 'satellite|on-?site'
      then '1_SATELLITE OPERATOR - runs the model FCC enters'
    when coalesce(f.evidence_level,'') in ('A','B')
         and coalesce(f.mineral_class,'') ~* 'pcc|gcc|caco3|both'
      then '2_PCC/GCC PRODUCER - evidence A or B'
    when coalesce(f.evidence_level,'') in ('A','B')
      then '3_EVIDENCE A/B - mineral class unclear'
    else '4_LONG TAIL'
  end as tier,
  p.party_name, p.country_code,
  f.evidence_level, f.mineral_class, f.supply_model,
  (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts,
  (select count(*) from app.deals d where d.party_id = p.id and d.deleted_at is null) as live_deals
from app.parties p
join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  -- exclusions, each for a reason established today
  and p.party_name !~ ' - '                                      -- plants cannot sign
  and p.party_name !~* '\(Global'                                -- abstractions
  and coalesce(f.extra_data #>> '{fcc_fit,verdict}','') <> 'no'  -- Thiele - kaolin, no CaCO3 line
  and coalesce(f.market_role,'') || ' ' || coalesce(f.supply_model,'')
        !~* 'no direct presence|theoretical|no .{0,12}commercial entity'
  and coalesce(f.market_role,'') !~* 'holding company|not the licensing counterparty'
  and coalesce(f.market_role,'') !~* 'not an independent supplier'  -- Calrock = Zantat group
order by 1, f.evidence_level nulls last, p.party_name;


-- ---------- 2) TIER 1 ALONE - the four that matter most ----------
select p.id, p.party_name, p.country_code, f.evidence_level,
       f.supply_model, f.market_role,
       (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts,
       (select count(*) from app.deals d where d.party_id = p.id and d.deleted_at is null) as live_deals,
       (select count(*) from app.party_supply_links s where s.filler_party_id = p.id) as known_mill_links
from app.parties p
join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null
  and p.party_name !~ ' - '
  and coalesce(f.market_role,'') || ' ' || coalesce(f.supply_model,'') ~* 'satellite|on-?site'
order by (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) desc,
         f.evidence_level, p.party_name;
-- Expect Specialty Minerals (HQ) with 3 contacts and a deal, then Taekyung BK,
-- Double A Specialty Minerals and Fimatec with zero of both. Omya (Korea) and
-- Omya (USA) should surface too - their supply_model mentions onsite/satellite.


-- ---------- 3) THE IMERYS HOLE ----------
select p.party_name, p.country_code, f.evidence_level, f.mineral_class,
       f.supply_model, f.market_role,
       (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts,
       (select count(*) from app.deals d where d.party_id = p.id and d.deleted_at is null) as live_deals
from app.parties p
left join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* 'imerys'
order by f.evidence_level nulls last, p.party_name;
-- Eight rows, zero contacts, zero deals, on the number 3 global producer.
-- Imerys China alone is recorded as 11 processing plants plus a tech centre.
-- Imerys Korea is evidence A and was never researched - it is NOT a KFTC 2019-109
-- respondent, so its Korean paper GCC role is unconfirmed and the A may be
-- generous.


-- ---------- 4) CONTACT COVERAGE - the real constraint ----------
select coalesce(f.evidence_level,'?') as evidence,
       count(*) as companies,
       count(*) filter (where exists (select 1 from app.contacts c
                                      where c.party_id = p.id and c.deleted_at is null)) as with_a_contact,
       round(100.0 * count(*) filter (where exists (select 1 from app.contacts c
                                      where c.party_id = p.id and c.deleted_at is null)) / count(*), 1) as pct
from app.parties p
join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
where p.party_type_id = 3 and p.deleted_at is null and p.party_name !~ ' - '
group by 1
order by 1;
-- Four filler parties have a contact. Everything else is a name and a note.
-- No amount of further enrichment changes that number. Contact acquisition is
-- the binding constraint, and today was spent proving it rather than fixing it.
