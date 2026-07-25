-- ============================================================
-- enrich_houston_sweep_round2.sql
-- Houston sweep round 2 (web research 2026-07-25)
-- Follows seed_houston_investor_sweep.sql - run that FIRST.
--
-- WHAT THIS DOES
--   A) Verified outreach channels and refreshed notes for the T1 funds
--   B) Re-ranks T1 - New Climate Ventures moves ahead of Fathom Fund
--   C) Climate Impact Capital stays T3 after research, but a HAN link
--      is recorded that matters for the September pitch
--   D) Adds 6 Houston funds missed in round 1
--
-- KEY FINDINGS
--   New Climate Ventures states a price parity with traditional
--   alternatives thesis and targets hard-to-decarbonize sectors. Its
--   portfolio already holds biobased materials companies (Rheom
--   Materials, BUCHA BIO). Paper is a hard-to-decarbonize sector and
--   FCC is a cost parity argument, so this is a triple match. It also
--   follows into Series A - portfolio company Ecolectro raised a 10.5M
--   USD Series A co-led by Toyota Ventures.
--
--   Fathom Fund states a preference for the pre-commercialization or
--   early commercialization phase where technical and scale-up risk
--   REMAINS. Incumbent OEM licensing may read as past that window -
--   the same reason First Bight passed on stage grounds. Real risk,
--   so it drops below NCV. Address is 4201 Main Street, the Ion
--   building, alongside Ara Partners.
--
--   Climate Impact Capital targets the energy, food and water nexus.
--   Industrial materials is NOT in that mandate, so it does NOT get
--   promoted to T1. But founder Alex Rozenfeld is recorded as energy
--   co-chair of the Houston Angel Network and a Rice Alliance advisory
--   board member. The HAN application targets the Energy committee, so
--   he may sit on the other side of that review. Verify the role is
--   current - the bio sources date to 2020 and 2023.
--
-- EMAILS are still not seeded. Only official-page URLs and forms are
-- recorded. Reported intake addresses sit in notes marked CONFIRM.
--
-- Idempotent. Supabase SQL Editor safe. Save as UTF-8 WITHOUT BOM.
-- ============================================================


-- ------------------------------------------------------------
-- A1) New Climate Ventures - now the top T1 target
-- ------------------------------------------------------------
update app.parties p
set notes = 'HOU-T1 RANK1 | Established 2021. Founding Managing Partner Eric Rubenstein, investor Taylor Chapman covers seed stage bioplastics, carbon management and grid analytics. Stated thesis targets hard-to-decarbonize sectors and technologies reaching price parity with traditional alternatives - both describe FCC exactly. Portfolio already holds biobased materials companies Rheom Materials and BUCHA BIO, plus Solidec and Transition Metal Solutions. Follows on at Series A, as with the Ecolectro 10.5M USD round co-led by Toyota Ventures. Reported intake address Info@NewClimateVentures.com - CONFIRM on the official site before sending.',
    preferred_contact_method = 'email',
    updated_at = now()
where p.party_name = 'New Climate Ventures'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;


-- ------------------------------------------------------------
-- A2) Fathom Fund - verified site and submission path
-- ------------------------------------------------------------
update app.parties p
set website = 'https://ff.vc',
    contact_form_url = 'https://ff.vc',
    preferred_contact_method = 'web_form',
    notes = 'HOU-T1 RANK2 | Established 2023, fund size about 100M USD. Sectors are advanced computing, energy transition, materials and manufacturing, aerospace and defense. Submissions go through the website. Warm introductions preferred but not required. Office at 4201 Main Street, the Ion building, same address as Ara Partners. CAUTION - the firm states a preference for the pre-commercialization or early commercialization phase in which technical and scale-up risk remains. Incumbent OEM licensing may read as past that window, which is exactly why First Bight passed. Lead with remaining scale-up risk rather than with commercial traction.',
    updated_at = now()
where p.party_name = 'Fathom Fund'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;


-- ------------------------------------------------------------
-- A3) GOOSE Capital - verified screening form
-- ------------------------------------------------------------
update app.parties p
set website = 'https://www.goose.capital',
    contact_form_url = 'https://www.goose.capital/goose-capital-screening',
    preferred_contact_method = 'web_form',
    notes = 'HOU-T1 RANK3 | Established 2005. Investment group of roughly 20 operators and Fortune 500 executives, more than 55M USD deployed and about 10M USD per year, 60 investments and 15 exits. Stated screen is breakthrough defendable technology. Formal route is the investment screening form on the site. Contacts named on the official contact page are Alexa Stahowiak and Alex Krantz. Address 6100 Main, Houston TX 77005. Co-invested with Artemis Energy Partners, Tupper Lake Partners and Veritec Ventures on the P6 Technologies seed round.',
    updated_at = now()
where p.party_name = 'GOOSE Capital'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;


-- ------------------------------------------------------------
-- A4) Texas HALO Fund - no verified public channel yet
-- ------------------------------------------------------------
update app.parties p
set notes = 'HOU-T1 RANK4 | Seed and Series A fund that grew out of HAN, run as annual cohort based rolling seed vehicles. Portfolio overlaps heavily with HAN and the two co-invest often, so approach it together with the September 2026 HAN pitch track rather than separately. No verified public submission channel found as of 2026-07-25 - the practical route is a referral through the HAN process. Partners historically Kyra Doolan, David Steakley, Kevin King, Bob Tucci - verify.',
    updated_at = now()
where p.party_name = 'Texas HALO Fund'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;


-- ------------------------------------------------------------
-- A5) Climate Impact Capital - stays T3, HAN link recorded
-- ------------------------------------------------------------
update app.parties p
set website = 'https://climateimpactcapital.com',
    notes = 'HOU-T3 | Established 2016 by Alex Rozenfeld, MIT Sloan MBA and founding member and President of Shell Technology Ventures. Team of 1 to 10, venture partner Paul Watson. Mandate is the energy, food and water nexus for climate mitigation and adaptation, early stage and technology driven. RESEARCHED 2026-07-25 - industrial materials is NOT in that mandate, so this does not move up to T1 despite the name. HIGH VALUE FOR A DIFFERENT REASON - Rozenfeld is recorded as energy co-chair of the Houston Angel Network and a Rice Alliance advisory board member. The HAN application targets the Energy committee, so he may sit on the review side. Bio sources date to 2020 and 2023 - verify the role is current before relying on it.',
    updated_at = now()
where p.party_name = 'Climate Impact Capital'
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.deleted_at is null;


-- ------------------------------------------------------------
-- B) Six Houston funds missed in round 1
--    Source is a Houston VC census listing 11 funds headquartered in
--    the city. That census is dated, so every entry carries a verify
--    flag rather than a confident thesis read.
-- ------------------------------------------------------------
with ids as (
  select 'b25de8f2-1020-482f-9012-183f63883169'::uuid as org,
         coalesce((select id from app.party_types where code = 'investor'), 1) as investor_type_id
),
firms(party_name, entity_code, city, notes, intro_ko, intro_en) as (
  values
  ('Montrose Lane', 'fund', 'Houston',
   'HOU-T3 | Houston headquartered venture fund, formerly named Cottonwood Venture Partners. Energy technology heritage. Current thesis and check size UNVERIFIED - research before tiering.',
   $ko$Cottonwood Venture Partners 에서 이름을 바꾼 휴스턴 본사 벤처 펀드. 에너지 기술 투자 이력이 있다. 현재 테제와 체크 사이즈가 미검증 상태라 티어링 전 조사가 필요하다.$ko$,
   $en$A Houston headquartered venture fund previously named Cottonwood Venture Partners, with a history in energy technology. Its current thesis and check size are unverified and need research before proper tiering.$en$),

  ('Texas Medical Center Venture Fund', 'fund', 'Houston',
   'HOU-T4 | Venture arm connected to the Texas Medical Center. Life science and health focus. Relevant to the marine biomaterial line only if the sanitary pad is positioned as a health product rather than a consumer brand. Distinct entity to TMCx, which is already in the DB.',
   $ko$Texas Medical Center 와 연결된 벤처 투자 부문으로 라이프사이언스·헬스 중심이다. 생리대를 소비재 브랜드가 아니라 헬스 제품으로 포지셔닝할 경우에만 해양 바이오소재 라인과 접점이 생긴다. 이미 DB 에 있는 TMCx 와는 별개 조직.$ko$,
   $en$The venture arm connected to the Texas Medical Center, focused on life science and health. It becomes relevant to the marine biomaterial line only if the sanitary pad is positioned as a health product rather than a consumer brand. It is a separate entity to TMCx, which is already recorded.$en$),

  ('Knightsgate Ventures', 'fund', 'Houston',
   'HOU-LOW | Houston headquartered venture fund. Thesis, stage and check size UNVERIFIED. Recorded to prevent repeat research.',
   $ko$휴스턴 본사 벤처 펀드. 테제·단계·체크 사이즈 모두 미검증. 중복 조사 방지 목적으로 기록한다.$ko$,
   $en$A Houston headquartered venture fund with thesis, stage and check size all unverified. Recorded to prevent repeat research.$en$),

  ('Amplo Ventures', 'fund', 'Houston',
   'HOU-LOW | Houston headquartered venture fund. Thesis, stage and check size UNVERIFIED. Recorded to prevent repeat research.',
   $ko$휴스턴 본사 벤처 펀드. 테제·단계·체크 사이즈 모두 미검증. 중복 조사 방지 목적으로 기록한다.$ko$,
   $en$A Houston headquartered venture fund with thesis, stage and check size all unverified. Recorded to prevent repeat research.$en$),

  ('Decarbonization Partners', 'fund', 'Houston',
   'HOU-T5 | Decarbonization focused fund with partner level presence in Houston, headquartered elsewhere. Programming partner at Houston Energy and Climate Startup Week. Thesis aligns strongly but the vehicle targets later stage and larger checks, so track for a future round.',
   $ko$휴스턴에 파트너급 인력을 두고 있으나 본사는 다른 지역인 탈탄소 전문 펀드. Houston Energy and Climate Startup Week 프로그램 파트너다. 테제 정합성은 매우 높지만 후기 단계·대형 체크를 겨냥해 현재 라운드에는 맞지 않는다. 다음 라운드용으로 기록.$ko$,
   $en$A decarbonization focused fund with partner level presence in Houston though headquartered elsewhere, and a programming partner at Houston Energy and Climate Startup Week. The thesis aligns strongly but the vehicle targets later stage and larger checks, so it is tracked for a future round.$en$),

  ('Energy Innovation Capital', 'fund', 'Houston',
   'HOU-T3 | Energy technology venture fund with partner level presence in Houston, headquartered elsewhere. Fit depends entirely on the industrial decarbonization framing. Stage and check size UNVERIFIED.',
   $ko$휴스턴에 파트너급 인력을 둔 에너지 기술 벤처 펀드로 본사는 다른 지역이다. 산업 탈탄소 프레이밍이 통해야만 접점이 생긴다. 단계·체크 사이즈 미검증.$ko$,
   $en$An energy technology venture fund with partner level presence in Houston though headquartered elsewhere. Fit depends entirely on the industrial decarbonization framing, and its stage and check size are unverified.$en$)
)
insert into app.parties
  (organization_id, party_name, party_type_id, entity_type_id, country_code, region, city, source, notes, intro_ko, intro_en)
select i.org, f.party_name, i.investor_type_id,
       coalesce((select id from app.entity_types et where et.code = f.entity_code),
                (select id from app.entity_types et where et.code = 'company')),
       'US', 'Texas', f.city, 'houston_sweep_2026-07-25_r2', f.notes, f.intro_ko, f.intro_en
from firms f cross join ids i
where not exists (
  select 1 from app.parties p
  where p.party_name = f.party_name
    and p.organization_id = i.org
    and p.deleted_at is null
);


-- investor_profile for the six new parties
insert into app.investor_profile (organization_id, party_id)
select p.organization_id, p.id
from app.parties p
where p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'::uuid
  and p.source = 'houston_sweep_2026-07-25_r2'
  and p.deleted_at is null
  and not exists (select 1 from app.investor_profile ip where ip.party_id = p.id);


-- sector tags for the six new parties
insert into app.investor_sector_focus (investor_profile_id, sector_id, organization_id)
select ip.id, s.id, ip.organization_id
from (values
  ('Montrose Lane','energy'),
  ('Texas Medical Center Venture Fund','life_science'),
  ('Texas Medical Center Venture Fund','healthcare'),
  ('Decarbonization Partners','climate'),
  ('Decarbonization Partners','industrial'),
  ('Energy Innovation Capital','energy'),
  ('Energy Innovation Capital','climate')
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
-- C) Deal descriptions reflect the verified route and the rank
-- ------------------------------------------------------------
update app.deals d
set description = 'RANK 1 of the Houston T1 set. Price parity plus hard-to-decarbonize thesis matches FCC directly, and the portfolio already holds biobased materials companies. Route is email to the intake address - confirm it on the official site first. Lead with cost parity against incumbent filler, not with the marine biomaterial story.',
    updated_at = now()
where d.deal_name = 'New Climate Ventures - Series A Houston'
  and d.deleted_at is null;

update app.deals d
set description = 'RANK 2 of the Houston T1 set. Submit through ff.vc. Materials and manufacturing is a named sector, but the firm prefers remaining technical and scale-up risk, so frame the ask around scale-up rather than around incumbent OEM traction.',
    updated_at = now()
where d.deal_name = 'Fathom Fund - Series A Houston'
  and d.deleted_at is null;

update app.deals d
set description = 'RANK 3 of the Houston T1 set. Formal route is the investment screening form on goose.capital. The stated screen of breakthrough defendable technology is the closest language match to a patent defended licensing model anywhere in this sweep.',
    updated_at = now()
where d.deal_name = 'GOOSE Capital - Series A Houston'
  and d.deleted_at is null;

update app.deals d
set description = 'RANK 4 of the Houston T1 set. No verified public submission channel. Practical route is a referral out of the September 2026 HAN pitch cycle, so hold this until the HAN outcome is known.',
    updated_at = now()
where d.deal_name = 'Texas HALO Fund - Series A Houston'
  and d.deleted_at is null;


-- ============================================================
-- VERIFY (read-only)
-- ============================================================

-- V1: T1 ranking, verified channels
select p.party_name, p.preferred_contact_method, p.website, p.contact_form_url,
       left(p.notes, 18) as tier_rank
from app.parties p
where p.party_name in ('New Climate Ventures','Fathom Fund','GOOSE Capital','Texas HALO Fund','Climate Impact Capital')
  and p.deleted_at is null
order by left(p.notes, 18);

-- V2: round 2 additions (expect 6)
select p.party_name, left(p.notes, 7) as tier, p.city
from app.parties p
where p.source = 'houston_sweep_2026-07-25_r2' and p.deleted_at is null
order by p.party_name;

-- V3: whole Houston sweep by tier (expect 38 across both rounds)
select left(p.notes, 7) as tier, count(*) as parties
from app.parties p
where p.source like 'houston_sweep_2026-07-25%' and p.deleted_at is null
group by left(p.notes, 7)
order by tier;

-- V4: SAFETY. Any swept party that already declined. Expect zero rows.
select p.party_name, o.outcome, o.reason
from app.parties p
join app.email_send_outcomes o on o.party_id = p.id
where p.source like 'houston_sweep_2026-07-25%'
  and o.outcome like 'rejected%'
  and p.deleted_at is null;
