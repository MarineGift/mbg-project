-- ============================================================
-- fix_houston_sweep_tier_backfill.sql
-- Repair the four Houston sweep parties that already existed
-- under source manual:tx_investor_seed (2026-07-25)
--
-- WHAT HAPPENED
--   seed_houston_investor_sweep.sql guards party inserts with
--   NOT EXISTS on party_name. Four names were already in the DB, so
--   no duplicate was created - correct behaviour. But their source
--   stayed manual:tx_investor_seed, and the investor_profile INSERT
--   in that seed filtered on source = houston_sweep_2026-07-25, so
--   those four were skipped there too. The sector focus and priority
--   statements join through investor_profile, so if the profile row
--   was absent they silently did nothing.
--
--   Affected:
--     New Climate Ventures      notes already fixed by the enrich file
--     Quantum Energy Partners   notes null
--     The Artemis Fund          notes null
--     Golden Section            notes null
--
-- DESIGN CORRECTION
--   source is NOT overwritten - provenance of the original seed is
--   worth keeping. The tier prefix in notes is the canonical roster
--   key from here on. Count the roster with
--     notes like 'HOU-%'
--   NOT with a source filter. The final query in this file is the
--   corrected roster query - use it for future sweeps.
--
-- Existing intro_ko / intro_en are preserved. They are only written
-- when currently null, so curated text is never clobbered.
--
-- Idempotent. Supabase SQL Editor safe. Save as UTF-8 WITHOUT BOM.
-- ============================================================


-- ------------------------------------------------------------
-- 1) Tier notes for the three parties still carrying null notes
-- ------------------------------------------------------------
update app.parties p
set notes = 'HOU-T3 | Houston energy investor appearing regularly on local cap tables alongside Chevron Technology Ventures. Large scale energy focus - fit depends entirely on the industrial decarbonization framing. Pre-existing party, tier assigned by the Houston sweep 2026-07-25.',
    updated_at = now()
where p.party_name = 'Quantum Energy Partners'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null
  and (p.notes is null or p.notes not like 'HOU-%');

update app.parties p
set notes = 'HOU-T4 | Houston and New York. Fund II closed at 36M USD, leading seed rounds for diverse founders across fintech, commerce and care. WARM PATH - co-founder Stephanie Campbell served as HAN Managing Director since 2016, Leslie Goldman sat on the HAN board and Diana Murakhovskaya was a HAN investor member, so a successful HAN track opens a route here. HARD GATE - female founder requirement, and the thesis leans tech-enabled rather than physical CPG. Not the same organization as Artemis Energy Partners. Pre-existing party, tier assigned by the Houston sweep 2026-07-25.',
    updated_at = now()
where p.party_name = 'The Artemis Fund'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null
  and (p.notes is null or p.notes not like 'HOU-%');

update app.parties p
set notes = 'HOU-LOW | Houston early stage investor focused on B2B SaaS, contact historically Dougal Cameron. Poor thesis fit for a materials company. Pre-existing party, tier assigned by the Houston sweep 2026-07-25.',
    updated_at = now()
where p.party_name = 'Golden Section'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null
  and (p.notes is null or p.notes not like 'HOU-%');


-- ------------------------------------------------------------
-- 2) Bilingual intros, written only when currently null
-- ------------------------------------------------------------
update app.parties p
set intro_ko = coalesce(p.intro_ko, $ko$휴스턴 에너지 투자사로 Chevron Technology Ventures 와 함께 로컬 캡테이블에 정기적으로 등장한다. 대형 에너지 중심이라 산업 탈탄소 프레이밍이 통해야만 접점이 열린다.$ko$),
    intro_en = coalesce(p.intro_en, $en$A Houston energy investor that appears regularly on local cap tables alongside Chevron Technology Ventures. Its large scale energy focus means fit depends entirely on the industrial decarbonization framing.$en$),
    updated_at = now()
where p.party_name = 'Quantum Energy Partners'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;

update app.parties p
set intro_ko = coalesce(p.intro_ko, $ko$2호 펀드 3,600만 달러 규모로 핀테크·커머스·케어 이코노미에서 다양성 창업자 대상 시드를 리드한다. 공동창업자 Stephanie Campbell 이 2016년부터 HAN Managing Director 를 지냈고 Leslie Goldman 은 HAN 이사, Diana Murakhovskaya 는 HAN 투자 회원이었다. HAN 트랙이 잘 풀리면 자연스러운 다리가 생긴다. 다만 여성 창업 요건이 하드 게이트이고 테제가 물리적 CPG 보다 tech-enabled 쪽에 가깝다.$ko$),
    intro_en = coalesce(p.intro_en, $en$Fund II closed at 36M USD and the firm leads seed rounds for diverse founders across fintech, commerce and care. Co-founder Stephanie Campbell served as HAN Managing Director since 2016, Leslie Goldman sat on the HAN board and Diana Murakhovskaya was a HAN investor member, so a successful HAN track opens a natural warm path. The female founder requirement is a hard gate and the thesis leans tech-enabled rather than physical CPG.$en$),
    updated_at = now()
where p.party_name = 'The Artemis Fund'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;

update app.parties p
set intro_ko = coalesce(p.intro_ko, $ko$B2B SaaS 중심의 휴스턴 초기 단계 투자사(담당 Dougal Cameron 로 기록됨). 소재 기업과는 테제가 맞지 않아 재조사 방지 목적으로만 기록한다.$ko$),
    intro_en = coalesce(p.intro_en, $en$A Houston early stage investor focused on B2B SaaS with Dougal Cameron recorded as the contact. Poor thesis fit for a materials company, recorded only to prevent repeat research.$en$),
    updated_at = now()
where p.party_name = 'Golden Section'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;


-- ------------------------------------------------------------
-- 3) investor_profile rows for any HOU tier party still lacking one.
--    Keyed on the notes prefix, so this also catches future sweeps.
-- ------------------------------------------------------------
insert into app.investor_profile (organization_id, party_id)
select p.organization_id, p.id
from app.parties p
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.notes like 'HOU-%'
  and p.party_type_id = coalesce((select id from app.party_types where code = 'investor'), 1)
  and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);


-- ------------------------------------------------------------
-- 4) Sector tags for the four repaired parties.
--    Re-running is harmless - the NOT EXISTS guard covers it.
-- ------------------------------------------------------------
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, s.id, ip.organization_id
from (values
  ('New Climate Ventures','climate'),
  ('New Climate Ventures','advanced_materials'),
  ('New Climate Ventures','industrial'),
  ('Quantum Energy Partners','energy'),
  ('The Artemis Fund','consumer'),
  ('Golden Section','software')
) as m(party_name, sector_code)
join app.parties p on p.party_name = m.party_name
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null
join app.investor_profile ip on ip.party_id = p.id
join app.sectors s on s.code = m.sector_code
where not exists (
  select 1 from app.investor_sector_focus f
  where f.investor_profile_id = ip.id and f.sector_id = s.id
);


-- ------------------------------------------------------------
-- 5) Priority. Re-applied because the original statement may have
--    hit zero rows while the New Climate Ventures profile was absent.
-- ------------------------------------------------------------
update app.investor_profile ip
set priority = 'high', updated_at = now()
from app.parties p
where p.id = ip.party_id
  and p.deleted_at is null
  and p.party_name in ('Fathom Fund','New Climate Ventures','GOOSE Capital','Texas HALO Fund')
  and ip.priority is distinct from 'high';


-- ============================================================
-- VERIFY (read-only)
-- ============================================================

-- V1: CORRECTED ROSTER QUERY. Use this one from now on, not the
--     source filter. Expect 38 rows total across the six tiers.
select left(p.notes, 7) as tier, count(*) as parties
from app.parties p
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.notes like 'HOU-%'
  and p.deleted_at is null
group by left(p.notes, 7)
order by tier;

-- V2: the four repaired parties
select p.party_name, left(p.notes, 12) as notes_head, p.source,
       (ip.id is not null) as has_profile, ip.priority,
       array_agg(s.code order by s.code) filter (where s.code is not null) as sectors
from app.parties p
left join app.investor_profile ip on ip.party_id = p.id
left join app.investor_sector_focus isf on isf.investor_profile_id = ip.id
left join app.sectors s on s.id = isf.sector_id
where p.party_name in ('New Climate Ventures','Quantum Energy Partners','The Artemis Fund','Golden Section')
  and p.deleted_at is null
group by p.party_name, p.notes, p.source, ip.id, ip.priority
order by p.party_name;

-- V3: the four T1 funds must all read priority high
select p.party_name, ip.priority, left(p.notes, 12) as rank
from app.parties p
join app.investor_profile ip on ip.party_id = p.id
where p.party_name in ('Fathom Fund','New Climate Ventures','GOOSE Capital','Texas HALO Fund')
  and p.deleted_at is null
order by left(p.notes, 12);

-- V4: T1 deals exist and carry the ranked descriptions
select d.deal_name, st.code as stage, left(d.description, 22) as rank_head
from app.deals d
join app.stages st on st.id = d.current_stage_id
where d.campaign_id = 'd0000000-0000-4000-8000-0000000000fa'::uuid
  and d.deleted_at is null
order by d.deal_name;
