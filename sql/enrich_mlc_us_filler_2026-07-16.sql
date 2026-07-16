-- ============================================================
-- enrich_mlc_us_filler_2026-07-16.sql
-- Mississippi Lime Company (MLC) - party id cbde4480-031d-4836-b7bb-a9b5a335b7cb
-- Source: mlc.com homepage read, 2026-07-16 (contact page modified 2026-03-27).
--
-- TWO MATERIAL CORRECTIONS TO THE EXISTING RECORD:
--   1. DOMAIN MOVED. The record has www.mississippilime.com. The live site is
--      www.mlc.com - the company now trades as MLC (d/b/a).
--   2. MLC HAS EXITED PCC. The current sample-request and compliance-request
--      forms both state plainly that PCC products are no longer sold by MLC.
--      The existing profile note calls MLC the No.2 US PCC player after MTI.
--      That is now stale. The paper market page still mentions merchant PCC at
--      Ste. Genevieve, but that page is older than the forms.
--      -> This file FLAGS the conflict rather than overwriting market_role,
--         so the call stays with a human.
--
-- Adds 13 named sales contacts published on the MLC contact page.
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) PARTY: domain, location, phone ----------
update app.parties p
set website    = 'https://www.mlc.com',
    country_code = 'US',
    region     = coalesce(p.region, 'Missouri'),
    city       = coalesce(p.city, 'St. Louis'),
    phone_e164 = coalesce(p.phone_e164, '+13145436300'),
    linkedin_url = coalesce(p.linkedin_url, 'https://www.linkedin.com/company/mississippi-lime-company/'),
    updated_at = now()
where p.id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid
  and p.party_type_id = 3
  and p.deleted_at is null;

-- ---------- 2) PARTY: bilingual intro ----------
update app.parties p
set intro_ko = '1907년 설립된 미국 최대 석회 기업(비상장, 지주사 HBM Holdings, 매출 약 3.8억 달러, 직원 약 750명). 미주리주 세인트루이스 본사, Ste. Genevieve(미주리)에 아메리카 대륙 최대 석회 설비를 두고 Calera(AL)·Verona(KY)·Vicksburg(MS)·Weirton(WV)·Chester(SC)·Mobile(AL)·Prairie du Rocher(IL)·Bridgeville(PA) 등 12개 이상 공장/터미널을 운영한다. 영국 Singleton Birch를 보유하고 2026년 1월 Burnett을 인수했다. 중요: 현재 자사 웹폼에 "PCC 제품은 더 이상 판매하지 않는다"고 명시되어 있어 PCC 사업에서 철수한 것으로 보인다. GCC는 CalCarb 브랜드로 유지하나 제지용 필러 등급이 아니라 아스팔트·농업·광산 분진·유리용이 중심이다.',
    intro_en = 'Founded 1907, the largest US lime producer (private, held by HBM Holdings, about 376 million dollars revenue, roughly 750 employees). HQ in St. Louis, Missouri, with the largest lime facility in the Americas at Ste. Genevieve, Missouri, plus twelve or more plants and terminals including Calera AL, Verona KY, Vicksburg MS, Weirton WV, Chester SC, Mobile AL, Prairie du Rocher IL and Bridgeville PA. Owns Singleton Birch in the UK and acquired Burnett in January 2026. Important - the current MLC web forms state that PCC products are no longer sold, so the company appears to have left the PCC business. GCC continues under the CalCarb brand, but the listed grades are asphalt, agriculture, mine rock dust and glass rather than paper filler.',
    updated_at = now()
where p.id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid
  and p.party_type_id = 3
  and p.deleted_at is null
  and p.intro_ko is null;

-- ---------- 3) PROFILE: flag the PCC exit (append only, no overwrite) ----------
update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[mlc-homepage 2026-07-16] CONFLICT FLAG - the stored positioning (No.2 US PCC player after MTI) looks stale. The live mlc.com sample-request and compliance-request forms both state that PCC products are no longer sold by MLC. The markets/paper page still mentions merchant PCC at Ste. Genevieve plus satellite PCC at paper mills, but that page predates the forms. Current CalCarb GCC grades listed are R1, R2, mineral filler, coal mine rock dust, athletic field marker, ag stone, AC3, poultry grit, FGD and feed grade - no paper-filler grade. Domain moved from mississippilime.com to mlc.com. Legacy paper products Magnum Fill 70 percent slurry and Magnum Gloss PCC appear discontinued. ACTION - confirm PCC exit with Dan Menniti or Bill Wleklinski before treating MLC as an FCC licensing target, and re-rank if confirmed.',
    updated_at = now()
where f.party_id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[mlc-homepage 2026-07-16]%';

-- ---------- 4) CONTACTS (13, published on mlc.com/contact-us) ----------
-- contact_type_id = 2. Specialty Products team = the FCC-relevant entry point.
-- Regional Sales Managers carry lime/limestone territories - kept for coverage,
-- flagged non-decision-maker for this use case.
insert into app.contacts
  (organization_id, party_id, contact_type_id, email,
   given_name, family_name, full_name, title_text, department,
   phone_e164, is_primary, is_decision_maker, source, notes)
select v.organization_id, v.party_id, v.contact_type_id, v.email,
       v.given_name, v.family_name, v.full_name, v.title_text, v.department,
       v.phone_e164, v.is_primary, v.is_decision_maker, v.source, v.notes
from (values
  -- Specialty Products / leadership - PRIMARY TARGETS
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'dtmenniti@mlc.com','Dan','Menniti','Dan Menniti','Global Business and Sales Manager - Specialty Products','Specialty Products',
   '+14129798030',true,true,'homepage','Global owner of specialty products - the right first call for an FCC licensing conversation and for confirming the PCC exit.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'wjwleklinski@mlc.com','Bill','Wleklinski','Bill Wleklinski','Sales & Business Development Manager - Specialty Products','Specialty Products',
   '+16149676221',false,true,'homepage','Business development on specialty products - the natural second contact for new technology and licensing.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'tpfrey@mlc.com','Ted','Frey','Ted Frey','Director Sales & Customer Support','Sales',
   '+15024323296',false,true,'homepage','Sales director - useful if the specialty route stalls.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'econway@mlc.com','Eustace','Conway','Eustace Conway','Director - Southern Sales & Logistics','Sales',
   '+16019944418',false,true,'homepage','Southern sales and logistics director.'),

  -- Senior Regional Sales Managers
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'woneal@mlc.com','Will','O''Neal','Will O''Neal','Senior Regional Sales Manager - West Region','Sales',
   '+17312416609',false,false,'homepage','West region.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'pmpine@mlc.com','Paul','Pine','Paul Pine','Senior Regional Sales Manager - East Region','Sales',
   '+17046572154',false,false,'homepage','East region.'),

  -- Regional Sales Managers (territory in notes)
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'jjhuff@mlc.com','Jennifer','Huff','Jennifer Huff','Regional Sales Manager','Sales',
   '+14026075624',false,false,'homepage','Territory - W.IA, WY, NM, CO, SD, NE, KS, OK, W.MO, TX, AZ.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'djokenfuss@mlc.com','Dan','Okenfuss','Dan Okenfuss','Regional Sales Manager','Sales',
   '+13142888928',false,false,'homepage','Territory - N.AR, E.MO, S.MO, N.TN.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'dwcox@mlc.com','David','Cox','David Cox','Regional Sales Manager','Sales',
   '+13149480616',false,false,'homepage','Territory - S.IL, IN, W.KY.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'drevans@mlc.com','David','Evans','David Evans','Regional Sales Manager','Sales',
   '+13145014451',false,false,'homepage','Territory - E.IA, IL, N.MO, MN, ND, WI.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'awbergman@mlc.com','Andy','Bergman','Andy Bergman','Regional Sales Manager','Sales',
   '+14406661138',false,false,'homepage','Territory - OH, PA, WV, MI, MD, DE, NJ, CT, RI, NY, ME, VT, NH, MA and Canada. Covers the northeast paper belt.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'kwmehl@mlc.com','Kyle','Mehl','Kyle Mehl','Regional Sales Manager','Sales',
   '+17048284669',false,false,'homepage','Territory - NC, SC, VA, E.GA, NE.FL.'),
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid,'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid,2,
   'aasmith@mlc.com','Al','Smith','Al Smith','Regional Sales Manager','Sales',
   '+16784289279',false,false,'homepage','Territory - AL, GA, FL, S.TN, E.MS.')
) as v(organization_id, party_id, contact_type_id, email,
       given_name, family_name, full_name, title_text, department,
       phone_e164, is_primary, is_decision_maker, source, notes)
where not exists (
  select 1 from app.contacts c
  where c.party_id = v.party_id and lower(c.email) = lower(v.email) and c.deleted_at is null
);

-- ---------- 5) VERIFY (run separately) ----------
-- select full_name, title_text, email, phone_e164, is_decision_maker
-- from app.contacts
-- where party_id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid and deleted_at is null
-- order by is_decision_maker desc, full_name;
-- expect 13 rows, 4 decision-makers

-- select party_name, website, city, region, phone_e164 from app.parties
-- where id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid;
-- expect website = https://www.mlc.com

-- ---------- 6) ROLLBACK ----------
-- delete from app.contacts
-- where party_id = 'cbde4480-031d-4836-b7bb-a9b5a335b7cb'::uuid and source = 'homepage';
