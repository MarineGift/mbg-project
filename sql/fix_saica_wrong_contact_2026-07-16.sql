-- ============================================================
-- fix_saica_wrong_contact_2026-07-16.sql
--
-- A LIVE MIS-SENDING BUG, found in block 6 of scan_bare_contacts.
--
--   Saica Paper El Burgo de Ebro Zaragoza  ->  info@burgogroup.com
--
-- Saica is Sociedad Anonima Industrias Celulosa Aragonesa - Spanish, founded in
-- Zaragoza, saica.com, four divisions, over 10,000 staff.
-- Burgo Group is Italian - burgogroup.com. A DIFFERENT COMPANY.
-- El Burgo de Ebro is a municipality in Zaragoza province with about 2,432
-- residents. It is a PLACE NAME.
--
-- Some string match saw "Burgo" in the mill name and attached an Italian
-- competitor's inbox to a Spanish mill. If a sequence had enrolled this row, the
-- Saica approach would have been mailed to Burgo. That is worse than no contact.
--
-- WHAT THIS FILE DOES NOT DO: it does not guess a replacement address. Swapping
-- one wrong email for a plausible-looking guess would hide the problem instead
-- of fixing it. The bad contact is SOFT-DELETED and the reason recorded. Find
-- the real address at saica.com and add it deliberately.
--
-- Also enriches the Saica party record, since saica.com was read to confirm the
-- above and the mill turns out to matter - 1,310,000 t/yr across three machines.
--
-- Targeted by exact party_name plus exact email. IDEMPOTENT.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 0) PRE-FLIGHT (run first, separately) ----------
-- select c.id, c.email, c.full_name, c.source, p.party_name, p.website
-- from app.contacts c join app.parties p on p.id = c.party_id
-- where p.party_name = 'Saica Paper El Burgo de Ebro Zaragoza'
--   and c.deleted_at is null;
-- EXPECT 1 row with email info@burgogroup.com. If the email differs, stop.


-- ---------- 1) SOFT-DELETE the contaminated contact ----------
update app.contacts c
set deleted_at = now(),
    notes = coalesce(c.notes, '') || E'\n[saica-contamination 2026-07-16] REMOVED - wrong company. This row carried info@burgogroup.com, the inbox of Burgo Group, an ITALIAN paper producer. Saica is Spanish (Sociedad Anonima Industrias Celulosa Aragonesa, Zaragoza, saica.com). The address was almost certainly attached by a string match on "Burgo" in the mill name - El Burgo de Ebro is a municipality in Zaragoza province, not a company. Mailing this address would have sent a Saica approach to a competitor. NO replacement guessed - find the real contact at saica.com and add it deliberately. Reversible - clear deleted_at to restore.',
    updated_at = now()
from app.parties p
where c.party_id = p.id
  and p.party_name = 'Saica Paper El Burgo de Ebro Zaragoza'
  and c.email = 'info@burgogroup.com'
  and c.deleted_at is null;


-- ---------- 2) FIX the party website if it caught the same contamination ----------
update app.parties p
set website = 'https://www.saica.com',
    updated_at = now()
where p.party_name = 'Saica Paper El Burgo de Ebro Zaragoza'
  and p.party_type_id = 2 and p.deleted_at is null
  and (p.website is null or p.website like '%burgogroup%');


-- ---------- 3) ENRICH - the mill is worth having right ----------
update app.parties p
set country_code = coalesce(p.country_code, 'ES'),
    region       = coalesce(p.region, 'Aragon'),
    city         = coalesce(p.city, 'El Burgo de Ebro'),
    intro_ko = '스페인 사라고사에 본사를 둔 Saica 그룹(Sociedad Anonima Industrias Celulosa Aragonesa, 1943년경 창업)의 최대 제지 거점으로, 사라고사주 엘 부르고 데 에브로에 있다. 초지기 3대(PM8 360,000 t/년, PM9 430,000 t/년, PM10 520,000 t/년)로 합산 연산 131만 톤. 골판지 원지용 재생지를 생산한다. 그룹은 Saica Paper·Saica Natur·Saica Pack·Saica Flex 4개 사업부에 직원 1만 명 이상, 스페인·프랑스·이탈리아·포르투갈·영국·아일랜드·터키·룩셈부르크·네덜란드·미국·폴란드에 거점을 둔다. 2023년 창립 80주년에 맞춰 이 공장에 4,000제곱미터 규모의 그룹 R&D&I 센터를 열었다. ★FCC 관점: Saica는 저평량(grammage reduction)을 회사의 정체성으로 내세우며, 자사 설명에 따르면 MP9는 75 g/m2까지 생산 가능한 세계 최초의 기계다. 평량 저감은 FCC의 펄프 저감 서사와 정확히 같은 축이라 기술 대화의 출발점이 이미 공유돼 있다. 그룹 R&D 센터가 이 부지에 있다는 점도 파일럿 논의에 유리하다. 주소는 Poligono El Espartal, Carretera Castellon Km 21, 50730 El Burgo de Ebro (Zaragoza), 전화 +34 976 103 102.',
    intro_en = 'The largest paper site of Spain''s Saica Group (Sociedad Anonima Industrias Celulosa Aragonesa, founded in Zaragoza around 1943), located at El Burgo de Ebro in Zaragoza province. Three machines - PM8 at 360,000 t/yr, PM9 at 430,000 t/yr and PM10 at 520,000 t/yr - give a combined 1,310,000 t/yr of recycled paper for corrugated board. The group runs four divisions, Saica Paper, Saica Natur, Saica Pack and Saica Flex, with more than 10,000 employees and operations across Spain, France, Italy, Portugal, the UK, Ireland, Turkey, Luxembourg, the Netherlands, the United States and Poland. A 4,000 square metre group R&D&I centre opened on this site for the company 80th anniversary in 2023. FCC ANGLE - Saica makes grammage reduction a core part of its identity and states that its MP9 was the world first machine able to produce grammages down to 75 g/m2. Lightweighting sits on exactly the same axis as the FCC pulp-reduction story, so the technical conversation starts on shared ground, and having the group R&D centre on this site helps any pilot discussion. Address - Poligono El Espartal, Carretera Castellon Km 21, 50730 El Burgo de Ebro (Zaragoza). Phone +34 976 103 102.',
    updated_at = now()
where p.party_name = 'Saica Paper El Burgo de Ebro Zaragoza'
  and p.party_type_id = 2 and p.deleted_at is null;


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.website, p.city, p.country_code,
--        (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as live_contacts,
--        left(p.intro_ko, 40) as ko_head
-- from app.parties p
-- where p.party_name = 'Saica Paper El Burgo de Ebro Zaragoza';
-- expect website saica.com, live_contacts 0, ko_head starting with the Spanish HQ line
