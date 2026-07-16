-- ============================================================
-- fix_burgo_domain_verified_2026-07-16.sql
--
-- FALSE POSITIVE, closed. Block 5 of scan_contact_email_domain_mismatch flagged
-- 4 Burgo rows because website = burgo.com while email = info@burgogroup.com.
-- Both are real and both are Burgo's. The contacts page at burgo.com/en/contacts
-- lists the HQ as Via Piave 1, Altavilla Vicentina (VI), tel +39 0444 227811,
-- info@burgogroup.com. The company simply uses one domain for the web and
-- another for mail. Personal addresses use burgo.com in a lastname.firstname
-- form. Nothing to fix - recording the check so nobody re-flags it.
--
-- THIS MAKES THE SAICA BUG WORSE, NOT BETTER. info@burgogroup.com is not a dead
-- address that would have bounced harmlessly. It is Burgo's live, monitored
-- inbox. Had the Saica row been enrolled, a competitor would have READ the
-- approach.
--
-- Enriching Burgo Group S.p.A. while here, since burgo.com had to be read anyway.
--
-- uuid-free, targeted by exact party_name. NOTHING IS INSERTED. IDEMPOTENT.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) Record the verification on all 4 Burgo contacts ----------
update app.contacts c
set notes = coalesce(c.notes, '') || E'\n[domain-check 2026-07-16] VERIFIED CORRECT - not a mismatch. Burgo Group uses burgo.com for the web and burgogroup.com for mail. info@burgogroup.com is listed as the HQ inbox on burgo.com/en/contacts alongside Via Piave 1, Altavilla Vicentina (VI) and tel +39 0444 227811. Do not "fix" this to info@burgo.com. Personal addresses at Burgo follow lastname.firstname@burgo.com.',
    updated_at = now()
from app.parties p
where c.party_id = p.id
  and c.email = 'info@burgogroup.com'
  and c.deleted_at is null and p.deleted_at is null
  and coalesce(c.notes, '') not like '%[domain-check 2026-07-16]%';


-- ---------- 2) Enrich the group parent ----------
update app.parties p
set country_code = coalesce(p.country_code, 'IT'),
    region       = coalesce(p.region, 'Veneto'),
    city         = coalesce(p.city, 'Altavilla Vicentina'),
    phone_e164   = coalesce(p.phone_e164, '+390444227811'),
    founded_year = coalesce(p.founded_year, 1905),
    intro_ko = '1905년 창업한 이탈리아 최대급 제지그룹. 본사는 베네토주 알타빌라 비첸티나(Via Piave 1), 전화 +39 0444 227811. 이탈리아에 제지공장 11곳, 벨기에 비르통에 일관공장 1곳(Burgo Ardennes)을 두고 초지 라인 16개를 운영하며 연산 약 300만 톤 규모다. 그래픽용지·컨테이너보드·특수지(식품포장용지 포함)가 주력이고 섬유 원료와 에너지 생산·판매도 한다. 그룹사로 Mosaico S.p.A.(특수지), Burgo Distribuzione(유통), Burgo Energia(에너지), Burgo North America(코네티컷 스탬퍼드)가 있다. 2004년 경쟁사 Marchi 그룹과 합병했다. ★도메인 주의: 웹사이트는 burgo.com이고 메일은 burgogroup.com이다. 둘 다 정상이며 오류가 아니다. 개인 주소는 lastname.firstname@burgo.com 형식이 지배적이다. ★현황: 최근 컨테이너보드 시장 진입을 확대 중이라고 밝히고 있어 필러 대화의 접점이 있다. 다만 DB에는 Burgo 관련 행이 4개뿐인데 실제 공장은 12곳이라 로스터가 불완전하다.',
    intro_en = 'One of Italy''s largest paper groups, founded in 1905. HQ at Via Piave 1, Altavilla Vicentina in Veneto, tel +39 0444 227811. It runs 11 paper mills in Italy plus one integrated mill at Virton in Belgium (Burgo Ardennes), with 16 production lines and output of roughly 3 million tonnes a year. Core products are graphic papers, containerboard and specialty papers including food packaging grades, and the group also produces and sells fibrous raw materials and energy. Group companies include Mosaico S.p.A. for specialty papers, Burgo Distribuzione, Burgo Energia and Burgo North America in Stamford, Connecticut. It merged with the rival Marchi Group in 2004. DOMAIN NOTE - the website is burgo.com while mail runs on burgogroup.com. Both are correct and this is not an error. Personal addresses predominantly follow lastname.firstname@burgo.com. STATUS - the group states it is widening its containerboard presence, which gives a filler conversation an opening. Note that the database holds only 4 Burgo rows against 12 actual mills, so the roster is incomplete.',
    updated_at = now()
where p.party_name = 'Burgo Group S.p.A.'
  and p.party_type_id = 2 and p.deleted_at is null;


-- ---------- 3) Record the provenance of the domain check ----------
update app.parties p
set notes = coalesce(p.notes, '') || E'\n[domain-check 2026-07-16] burgo.com read directly. Website and mail domains differ by design - verified, not a data error.',
    updated_at = now()
where p.party_name in ('Burgo Group S.p.A.', 'Burgo Ardennes (Belgium)', 'Burgo Tolmezzo', 'Burgo Verzuolo')
  and p.party_type_id = 2 and p.deleted_at is null
  and coalesce(p.notes, '') not like '%[domain-check 2026-07-16]%';


-- ---------- 4) VERIFY ----------
-- select p.party_name, p.city, p.website, p.founded_year,
--        (p.intro_ko is not null) as has_ko
-- from app.parties p
-- where p.party_name like 'Burgo%' and p.deleted_at is null
-- order by p.party_name;


-- ---------- 5) NOT DONE - named Burgo people exist but I will not invent emails
-- Third-party directories list Burgo leadership, and one is directly relevant:
--   Stefano Carraro      - R&D Director
--   Massimo Sobrero      - Corporate Containerboard Sales Director
--   Andrea Bettin        - Corporate Procurement Director
--   Marco Tagliapietra   - Group CFO, Legal and IT Director
--   Johan Blyaert        - Managing Director Benelux and Nordic
--   Paolo Pastore        - Managing Director Burgo France
-- Carraro (R&D) plus Sobrero (containerboard sales) is the natural pair for an
-- FCC approach. BUT these come from a third-party directory, and the directory
-- gives an email FORMAT, not addresses. Deriving carraro.stefano@burgo.com from
-- a stated 82 percent pattern is a GUESS, and guessed addresses to real people
-- at a real company are how a sending domain gets burned. This project already
-- has DKIM absent, DMARC at p=none and a PTR mismatch.
-- Confirm these people and their addresses from a primary source before adding.
