-- ============================================================
-- enrich_thiele_kaolin_2026-07-16.sql
-- Thiele Kaolin Company - 45d93ac1-41a4-4207-acc1-896c1300a3b2
-- Source: thielekaolin.com read 2026-07-16, plus TAPPI Buyers Guide listing.
--
-- A DIFFERENT FAILURE MODE FROM MLC / ZANTAT / SHIRAISHI.
-- Those three had paper claims that had gone STALE. Thiele's paper claim is
-- TRUE and always has been - it has supplied the coated paper market for 75
-- years and calls itself an industry leader for paper and packaging.
-- The problem is RELEVANCE, not accuracy:
--
--   Thiele is KAOLIN. FCC is Flexible Calcium Carbonate.
--   Thiele has no PCC and no GCC line anywhere in its portfolio.
--
-- So Thiele cannot license FCC - there is no carbonate process to put it in.
-- It is a SUBSTITUTE-MINERAL COMPETITOR to the CaCO3 fillers mbg is targeting,
-- not a licensee candidate. evidence_level A is correct for "does it serve
-- paper" and wrong as a signal of FCC target quality, because the two questions
-- were never separated.
--
-- Also: market_role was literally 'Sandersville, GA'. That is an address, not a
-- role. Replaced.
--
-- uuid-targeted UPDATE only. NOTHING IS INSERTED. No intro_ko null guard.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

-- ---------- 1) PARTY ----------
update app.parties p
set website    = coalesce(p.website, 'https://www.thielekaolin.com'),
    region     = coalesce(p.region, 'Georgia'),
    city       = coalesce(p.city, 'Sandersville'),
    phone_e164 = coalesce(p.phone_e164, '+14785523951'),
    founded_year = coalesce(p.founded_year, 1946),
    updated_at = now()
where p.id = '45d93ac1-41a4-4207-acc1-896c1300a3b2'::uuid
  and p.party_type_id = 3 and p.deleted_at is null;

update app.parties p
set intro_ko = '1946년 설립된 비상장 카올린 기업으로 조지아주 샌더스빌에 본사와 전용 제지 코팅 연구소를 둔다. 1947년 1월 조업을 시작해 75년 이상 미국 도공지 시장에 공급해 왔고 1966년경부터 수출한다. 샌더스빌·렌즈(조지아)에 가공설비, 위스콘신 래피즈(위스콘신)와 스웨덴 예블레에 슬러리 설비, 그 외 리디크릭 설비를 운영한다. 북미 최대 확정 카올린 매장량을 보유하며, 안료 문제만 전담하는 세계 최대급 연구개발센터를 갖고 있다. 소성·수화·박리·블렌드 등급의 카올린을 제지·포장용으로 공급하고 도료에서는 TiO2 익스텐더로 쓰인다. 최근에는 실리카 제품도 취급한다. ★FCC 관점의 핵심: Thiele은 카올린 회사다. PCC도 GCC도 없다. 제지 적합성은 사실이지만 FCC(Flexible Calcium Carbonate)를 적용할 탄산칼슘 공정 자체가 없으므로 라이선싱 대상이 될 수 없다. mbg가 노리는 CaCO3 필러의 대체광물 경쟁자로 보는 것이 정확하다. 다만 자사 카올린을 TiO2 대체재로 포지셔닝한다는 점은 mbg의 TiO2 부분대체 서사와 같은 논리라 경쟁 참고점으로서 가치가 있다. 담당자는 홈페이지에 공개되지 않으며 문의 폼과 대표번호만 제공한다.',
    intro_en = 'A privately held kaolin producer founded in 1946, headquartered in Sandersville, Georgia, where it also runs a dedicated paper coating laboratory. Operations began on 1 January 1947 and it has served the US coated paper market for more than 75 years, exporting since around 1966. It has processing plants at Sandersville and Wrens in Georgia, slurry plants at Wisconsin Rapids in Wisconsin and Gavle in Sweden, plus a Reedy Creek facility. It holds the largest proven kaolin reserves in North America and runs one of the largest research centres in the world devoted solely to pigments. It supplies calcined, hydrous, delaminated and blended kaolin grades for paper and packaging, and its products serve as a TiO2 extender in coatings. It has recently added silica products. KEY POINT FOR FCC - Thiele is a kaolin company. It has no PCC and no GCC. Its paper credentials are real, but there is no calcium carbonate process for FCC to sit inside, so it cannot be a licensee. It is better understood as a substitute-mineral competitor to the CaCO3 fillers mbg targets. That said, it positions its kaolin as a TiO2 extender, which is the same displacement logic as mbg partial TiO2 replacement story, so it is a useful competitive reference. No named contacts are published - the site offers enquiry forms and switchboard numbers only.',
    updated_at = now()
where p.id = '45d93ac1-41a4-4207-acc1-896c1300a3b2'::uuid
  and p.party_type_id = 3 and p.deleted_at is null;

-- ---------- 2) PROFILE ----------
update app.filler_supplier_profile f
set mineral_class = 'kaolin',
    supplier_type = 'Kaolin and silica producer',
    market_role   = 'US paper kaolin leader - COMPETITOR/substitute, not an FCC licensee (no CaCO3 line)',
    notes = coalesce(f.notes, '') || E'\n[us-tier1 2026-07-16] RELEVANCE CORRECTION, not a staleness correction. The paper-grade claim is TRUE - 75+ years supplying US coated paper, self-described industry leader for paper and packaging, dedicated paper coating lab in Sandersville, largest proven kaolin reserves in North America. But Thiele has NO PCC and NO GCC. FCC is a calcium carbonate technology, so there is no process for it to enter. Thiele is a substitute-mineral COMPETITOR to the CaCO3 fillers mbg targets, not a licensing target. evidence_level A answers "does it serve paper" - it was never answering "is it a good FCC target", and the two questions have been collapsed across this whole table. market_role was literally the string Sandersville, GA - an address, not a role - now replaced. Sites - Sandersville and Wrens GA (processing), Wisconsin Rapids WI and Gavle Sweden (slurry), Reedy Creek. Founded 1946, private, ISO 9001. Positions kaolin as a TiO2 extender, the same displacement logic as the mbg TiO2-replacement story, so keep as a competitive reference. CONTACTS - none published, forms plus switchboard +1 478-552-3951 and 877-544-3322 only, so it will not yield a named-contact batch the way MLC did.',
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"paper_grade": {"claim": "yes", "source_url": "https://www.thielekaolin.com/kaolin-products", "source_type": "marketing", "checked_at": "2026-07-16"}, "fcc_fit": {"verdict": "no", "reason": "kaolin only - no PCC or GCC process for FCC to enter", "checked_at": "2026-07-16"}}'::jsonb,
    updated_at = now()
where f.party_id = '45d93ac1-41a4-4207-acc1-896c1300a3b2'::uuid
  and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[us-tier1 2026-07-16]%';

-- ---------- 3) VERIFY ----------
-- select p.party_name, p.website, p.city, f.mineral_class, f.market_role,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit
-- from app.parties p join app.filler_supplier_profile f on f.party_id = p.id
-- where p.id = '45d93ac1-41a4-4207-acc1-896c1300a3b2'::uuid;
-- expect mineral_class = kaolin, fcc_fit = no

-- ---------- 4) THE SAME QUESTION FOR THE OTHER KAOLIN ROWS ----------
-- Imerys USA (39aeaeff-6c76-41c6-8ccd-d004bc9d5102) is also in Sandersville GA
-- and stored as "Merchant (carbonate + kaolin coating)" - carbonate IS named, so
-- it is NOT the same case and stays a live FCC target.
-- Huber Engineered Materials (ce77920a-b7f2-45d9-bf6c-82a99a8112e7) is stored as
-- "Specialty minerals (kaolin, PCC)" - PCC IS named, so it also stays.
-- Kaolin (Malaysia) Sdn Bhd (dae6be28-25cd-453b-98a5-86d239b0766c) is kaolin-only
-- and likely takes the same fcc_fit = no verdict. Worth confirming next batch.
