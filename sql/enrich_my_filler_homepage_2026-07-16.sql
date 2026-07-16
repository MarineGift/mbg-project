-- ============================================================
-- enrich_my_filler_homepage_2026-07-16.sql
-- Malaysia filler suppliers - VERIFICATION PASS.
--
-- The MY rows carried several open "needs verification" flags. This file closes
-- the two biggest ones. NOTHING IS INSERTED - uuid-targeted UPDATE only.
-- intro is written WITHOUT a null guard, because the "intro_ko is null" guard
-- is exactly what silently swallowed the MLC update.
--
-- Sources read 2026-07-16: zantat.com.my (production-plants), Bursa/ACE listing
-- records, Zantat Holdings Berhad public company descriptions.
--
-- RESOLVED:
--   1. Calrock Sdn Bhd is NOT a standalone unknown - zantat.com.my names it as
--      Zantat's SISTER COMPANY, running one of the three Ipoh plants.
--   2. Zantat is no longer a private family firm - Zantat Holdings Berhad
--      listed on the Bursa ACE Market in March 2024 (code 0301 / ZANTAT).
--      That means public financials and prospectus-level disclosure.
--   3. Capacity figure in circulation (60,000 t/yr) is STALE. Zantat's own
--      plant page gives 320,000 MT combined after the 2014 and 2017 phases.
--
-- RAISED (not force-written):
--   4. Paper may be a shrinking segment. Zantat's own plant page names paper,
--      but every current investor-facing description of the listed entity lists
--      end markets as plastics, paints and coatings, gloves, rubber, adhesives -
--      with PAPER ABSENT. Same stale-marketing-vs-current-reality pattern as MLC.
--
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) PARTY: location + website ----------
update app.parties p
set country_code = coalesce(p.country_code, 'MY'),
    region       = coalesce(p.region, 'Perak'),
    city         = coalesce(p.city, 'Kampung Kepayang'),
    website      = coalesce(p.website, 'http://www.zantat.com.my'),
    updated_at   = now()
where p.id = 'ea39bb0c-639e-44be-a84c-a586f88e3cb5'::uuid
  and p.party_type_id = 3 and p.deleted_at is null;

update app.parties p
set country_code = coalesce(p.country_code, 'MY'),
    region       = coalesce(p.region, 'Perak'),
    city         = coalesce(p.city, 'Ipoh'),
    website      = coalesce(p.website, 'http://www.zantat.com.my'),
    updated_at   = now()
where p.id = 'ff8b1fb0-6983-43c9-8dd8-1cd0599bdc0b'::uuid
  and p.party_type_id = 3 and p.deleted_at is null;

-- ---------- 2) INTROS - forced overwrite (no null guard) ----------
update app.parties p
set intro_ko = d.ko, intro_en = d.en, updated_at = now()
from (values
  ('ea39bb0c-639e-44be-a84c-a586f88e3cb5'::uuid,
   '1985년 설립된 말레이시아 대표 탄산칼슘 사업자로, 지주사 Zantat Holdings Berhad가 2024년 3월 부르사 ACE 마켓에 상장했다(코드 0301 / ZANTAT, 공모가 RM0.25, 조달 약 RM1,820만). 본사는 페락주 Kampung Kepayang. 공장 4곳 중 3곳이 이포(페락)에 있고 그중 하나는 자매회사 Calrock Sdn Bhd가 운영하며, 나머지 1곳은 쿠알라룸푸르 케퐁에 있다. 2011년 신공장은 플라스틱·도료·제지용 탄산칼슘 분말에 특화했고 2014년·2017년 2·3차 증설로 합산 능력 32만 MT에 이른다(널리 인용되는 6만 t은 옛 수치다). 자체 석회석 광구 2곳을 보유하며 채굴권 만료는 2068년·2070년, 면적 25에이커, 추정 매장량 약 2,200만 톤이다. GCC와 탄산칼슘 디스퍼전이 주력이고 카올린 디스퍼전, 초미립 PCC 분말 가공, 바이오플라스틱 컴파운드도 한다. 2002년 라텍스 장갑용 탄산칼슘 디스퍼전을 국내 최초로 도입했다. 2024년 매출 약 RM1억190만(전년 대비 -17.0%), 직원 약 216명, 말레이시아 탄산칼슘 Top 3. ⚠️ 주의: 자사 공장 페이지는 제지를 명시하지만 상장 법인 기준의 현행 사업 설명은 전방시장을 플라스틱·도료·장갑·고무·접착제로 열거하고 제지가 빠져 있다. 제지 비중이 축소 중일 가능성이 있어 확인이 필요하다.',
   'Malaysia flagship calcium carbonate producer founded in 1985. Its holding company, Zantat Holdings Berhad, listed on the Bursa ACE Market in March 2024 (code 0301 / ZANTAT) at RM0.25, raising about RM18.2 million. HQ in Kampung Kepayang, Perak. Of its four plants, three sit in Ipoh, Perak - one of them run by sister company Calrock Sdn Bhd - and the fourth is in Kepong, Kuala Lumpur. The 2011 plant specialises in calcium carbonate powder for plastics, paints and paper, and phase two in 2014 and phase three in 2017 lifted combined capacity to 320,000 MT (the widely quoted 60,000 t/yr figure is stale). It holds two limestone reserves with mining leases running to 2068 and 2070, covering 25 acres with an estimated 22 million tonnes. Core output is GCC and calcium carbonate dispersions, plus kaolin dispersion, ultrafine PCC powder processing and bioplastic compounds. In 2002 it was first in Malaysia to bring calcium carbonate dispersion to latex glove production. FY2024 revenue was about RM101.9 million, down 17.0 percent year on year, with roughly 216 staff. A top-three Malaysian calcium carbonate player. CAUTION - its own plant page names paper, but every current description of the listed entity lists end markets as plastics, paints and coatings, gloves, rubber and adhesives, with paper absent. Paper may be a shrinking segment and needs checking.'),

  ('ff8b1fb0-6983-43c9-8dd8-1cd0599bdc0b'::uuid,
   'Zantat Sdn Bhd의 자매회사로, 독립 사업자가 아니다. zantat.com.my 공장 소개에 이포(페락) 3개 공장 중 하나를 Calrock이 운영한다고 명시되어 있으며 건축면적은 약 48,305 sq ft이다. 즉 Zantat 그룹 생산능력의 일부를 구성한다. 기존 「단순 로컬 후보, 제지 적합성 미확인」 평가는 관계 파악이 안 된 상태의 기록이었다. 상업 접촉은 Calrock 단독이 아니라 Zantat 그룹(상장사 Zantat Holdings Berhad) 창구로 진행하는 것이 맞다.',
   'A sister company of Zantat Sdn Bhd, not a standalone operator. The zantat.com.my plant page states that Calrock runs one of the three Ipoh plants in Perak, with a built-up area of about 48,305 sq ft, so it forms part of the Zantat group production base. The earlier read of Calrock as a bare local candidate with unverified paper fit reflects a record made before the relationship was known. Commercial contact should route through the Zantat group, whose listed parent is Zantat Holdings Berhad, rather than approaching Calrock alone.')
) as d(id, ko, en)
where p.id = d.id and p.party_type_id = 3 and p.deleted_at is null;

-- ---------- 3) PROFILE: verification notes ----------
update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[my-verify 2026-07-16] ' || d.note, updated_at = now()
from (values
  ('ea39bb0c-639e-44be-a84c-a586f88e3cb5'::uuid,
   'VERIFIED and UPGRADED. Zantat Holdings Berhad listed on Bursa ACE Market March 2024 (0301 / ZANTAT, RM0.25, raised about RM18.2m) - public financials now available, which makes diligence far easier than the earlier private-family-firm read. Capacity correction - 320,000 MT combined after the 2014 and 2017 phases, NOT the 60,000 t/yr figure still circulating in directories. Reserves - 2 limestone leases to 2068 and 2070, 25 acres, about 22 million tonnes. 4 plants - 3 in Ipoh Perak (one operated by sister company Calrock) and 1 in Kepong KL. Products - GCC, CaCO3 dispersion, kaolin dispersion, ultrafine PCC powder processing, bioplastic compound. FY2024 revenue about RM101.9m, down 17.0 percent, roughly 216 staff. PAPER-FIT CAUTION - the company plant page names paper, but current listed-entity descriptions list end markets as plastics, paints and coatings, gloves, rubber and adhesives with paper absent. Same stale-page pattern as MLC. VERIFY the paper share before ranking as a top FCC target.'),
  ('ff8b1fb0-6983-43c9-8dd8-1cd0599bdc0b'::uuid,
   'RELATIONSHIP RESOLVED - closes the open "role needs verification" flag. Calrock Sdn Bhd is Zantat Sdn Bhd''s SISTER COMPANY per zantat.com.my, running one of the three Ipoh (Perak) plants, built-up area about 48,305 sq ft. It is not an independent supplier and should not be scored as one. Treat it as part of the Zantat group under listed parent Zantat Holdings Berhad (Bursa ACE 0301). ACTION - decide whether to keep this row as a plant-level entity linked to Zantat (ea39bb0c-639e-44be-a84c-a586f88e3cb5) or merge it away, and route all commercial contact through Zantat.')
) as d(pid, note)
where f.party_id = d.pid and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[my-verify 2026-07-16]%';

-- ---------- 4) PROFILE: mineral_class + market_role ----------
update app.filler_supplier_profile f
set mineral_class = coalesce(f.mineral_class, 'gcc'),
    market_role   = 'MY top-3 CaCO3 producer (Bursa ACE listed) - GCC + dispersions',
    supplier_type = coalesce(f.supplier_type, 'GCC and dispersion producer'),
    updated_at = now()
where f.party_id = 'ea39bb0c-639e-44be-a84c-a586f88e3cb5'::uuid and f.deleted_at is null;

update app.filler_supplier_profile f
set mineral_class = coalesce(f.mineral_class, 'gcc'),
    market_role   = 'Zantat group plant (sister company) - not an independent supplier',
    updated_at = now()
where f.party_id = 'ff8b1fb0-6983-43c9-8dd8-1cd0599bdc0b'::uuid and f.deleted_at is null;

-- ---------- 5) VERIFY ----------
-- select p.party_name, p.city, p.website, fp.mineral_class, fp.market_role,
--        left(p.intro_ko, 50) as ko_head
-- from app.parties p left join app.filler_supplier_profile fp on fp.party_id = p.id
-- where p.id in ('ea39bb0c-639e-44be-a84c-a586f88e3cb5'::uuid,
--                'ff8b1fb0-6983-43c9-8dd8-1cd0599bdc0b'::uuid);
-- expect 2 rows, both intro filled

-- FULL MY PICTURE - run this and send it back for the next batch:
-- select p.id, p.party_name, p.country_code, p.city, p.website,
--        fp.mineral_class, fp.supply_model, fp.evidence_level, fp.market_role,
--        (p.intro_ko is not null) as has_ko,
--        (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts
-- from app.parties p
-- left join app.filler_supplier_profile fp on fp.party_id = p.id
-- where p.party_type_id = 3 and p.deleted_at is null
--   and (p.country_code = 'MY' or p.party_name ilike '%Malaysia%' or p.party_name ilike '%Sdn Bhd%')
-- order by p.party_name;
