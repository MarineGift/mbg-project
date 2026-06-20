-- 20260620210000_paper_mill_website_intro_batch15.sql
-- paper_mill (party_type_id = 2) website + company intro - BATCH 15.
-- Scope: supply-link-connected mills with no website. This batch = Korea +
-- major EU/NA paper groups (corporate domains; mill sites map to the parent site).
-- UTF-8. RUN IN SUPABASE SQL EDITOR to apply. Idempotent guards (website fill only
-- where missing/non-URL; intro overwrite ok as these were empty). Org+type scoped.

-- 1) website (only where currently missing or non-URL)
update app.parties p
set website = d.url, updated_at = now()
from (values
  -- Korea (verified)
  ('0ff1fdfa-b549-4c25-af27-c9aec46900df'::uuid, 'https://www.hansolpaper.com'),
  ('890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid, 'https://www.hansolpaper.com'),
  ('715e8a6c-9bc4-4e41-afdb-a1827dd887ee'::uuid, 'http://www.moorimpnp.co.kr'),
  ('86c35de3-a0cd-4456-9054-70c9c3642722'::uuid, 'http://www.moorimpaper.co.kr'),
  ('028f9b56-3780-4bb2-91f4-ca3514025484'::uuid, 'https://www.hankukpaper.com'),
  -- Domtar (US/CA)
  ('f26708ad-70bf-47f9-82b3-9f40459e15c5'::uuid, 'https://www.domtar.com'),
  ('42107ee3-2894-49c9-8af4-98eb4ddbd865'::uuid, 'https://www.domtar.com'),
  ('ea842041-1311-4d41-b76f-a0c7a212f30e'::uuid, 'https://www.domtar.com'),
  ('eae2d488-9375-441b-bc07-3a4d09ca99c2'::uuid, 'https://www.domtar.com'),
  -- Mondi
  ('34d5265e-1666-4bb8-ad15-ef23a9525a81'::uuid, 'https://www.mondigroup.com'),
  ('7e5f0af4-ca4b-4a79-8b8b-4d3b22d9d414'::uuid, 'https://www.mondigroup.com'),
  ('7b86ee8e-c3a7-4d2b-ab86-3665e81737cc'::uuid, 'https://www.mondigroup.com'),
  ('737d8310-0515-4c02-8db0-497d70be79e2'::uuid, 'https://www.mondigroup.com'),
  ('9ea85952-07fc-4a70-a106-4f2d4dfc9560'::uuid, 'https://www.mondigroup.com'),
  ('e8874d4d-12e7-414e-ba8b-05e20e9db4db'::uuid, 'https://www.mondigroup.com'),
  ('27423257-e837-4103-9b55-0fef0fbb2c4d'::uuid, 'https://www.mondigroup.com'),
  ('bdaa7165-7117-4660-b7ee-b6e0b8b046ad'::uuid, 'https://www.mondigroup.com'),
  ('9652ee9d-b1e9-4d87-96d2-3596e9fe151c'::uuid, 'https://www.mondigroup.com'),
  -- Billerud
  ('2ed3ac31-de06-4608-9427-fa4789cc80ed'::uuid, 'https://www.billerud.com'),
  ('32c4c745-dd70-4312-85d2-a80fda4cd857'::uuid, 'https://www.billerud.com'),
  ('396a3eec-ea55-48a7-bfde-1703a940a99a'::uuid, 'https://www.billerud.com'),
  -- Holmen
  ('d3e5e182-cb96-4fec-bb05-815b1fad0be7'::uuid, 'https://www.holmen.com'),
  ('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid, 'https://www.holmen.com'),
  -- Navigator (PT)
  ('69219439-2553-4015-ac97-abeea25c1c4d'::uuid, 'https://www.thenavigatorcompany.com'),
  ('a336b16b-27d4-4153-ba11-c1bd8c594d81'::uuid, 'https://www.thenavigatorcompany.com'),
  ('590025b8-d703-4c70-82bc-a0df8c700392'::uuid, 'https://www.thenavigatorcompany.com')
) as d(party_id, url)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and (p.website is null or p.website not ilike 'http%');

-- 2) company intro (ko/en)
update app.parties p
set intro_ko = d.intro_ko, intro_en = d.intro_en, updated_at = now()
from (values
  ('0ff1fdfa-b549-4c25-af27-c9aec46900df'::uuid,
   '한솔그룹 계열의 종합 제지사(1965년 창업, 옛 삼성 계열). 인쇄용지·백판지·특수지를 생산하는 한국 대표 제지기업.',
   'A comprehensive Korean paper maker in the Hansol Group (founded 1965; ex-Samsung), producing printing, board and specialty papers.'),
  ('890ae7ee-12ae-4889-be24-c1f2155dbad0'::uuid,
   '한솔제지의 장항공장(충남 서천). 인쇄·특수지를 생산하며 현장 PCC(태경비케이) 공급 관계가 있는 핵심 생산거점.',
   'Hansol Paper''s Janghang mill (Seocheon, Korea), a key printing/specialty-paper site with an on-site PCC supply relationship (Taekyung BK).'),
  ('715e8a6c-9bc4-4e41-afdb-a1827dd887ee'::uuid,
   '무림그룹 계열의 국내 유일 표백화학펄프 제조사(유가증권시장 상장). 울산 온산에서 2011년 펄프-제지 일관화공장을 완공해 인쇄용지를 생산.',
   'Korea''s only bleached chemical pulp maker, a listed Moorim Group company; completed an integrated pulp-and-paper mill in Ulsan (Onsan) in 2011, producing printing papers.'),
  ('86c35de3-a0cd-4456-9054-70c9c3642722'::uuid,
   '무림그룹의 제지 핵심사(상장). 경남 진주 공장에서 아트지·백상지 등 인쇄용지를 생산하며 무림P&P·무림SP와 함께 그룹 제지사업을 영위.',
   'A core paper company of the Moorim Group (listed), producing printing papers (art/woodfree) at its Jinju, Korea plant alongside Moorim P&P and Moorim SP.'),
  ('028f9b56-3780-4bb2-91f4-ca3514025484'::uuid,
   '해성그룹 계열의 종합 제지기업(1958년 창업). 인쇄용지·정보용지(복사지 miilk)·특수지·패키지를 생산하며 국내 중성지 시대를 연 기업.',
   'A comprehensive Korean paper maker in the Haesung Group (founded 1958), producing printing papers, copy paper (miilk), specialty papers and packaging; a pioneer of neutral-sized paper in Korea.'),
  ('f26708ad-70bf-47f9-82b3-9f40459e15c5'::uuid,
   '북미 최대급 비코팅 인쇄용지·종이 제조사(미국). 인쇄용지·펄프·포장재를 생산하며 다수의 제지공장을 운영.',
   'A leading North-American maker of uncoated freesheet and paper (USA), producing printing papers, pulp and packaging across multiple mills.'),
  ('42107ee3-2894-49c9-8af4-98eb4ddbd865'::uuid,
   'Domtar의 미국 위스콘신주 Nekoosa 제지공장. 인쇄용지를 생산하며 현장 PCC 도입 사례로 알려진 생산거점.',
   'Domtar''s Nekoosa mill in Wisconsin, USA, producing printing papers; noted for an on-site PCC arrangement.'),
  ('ea842041-1311-4d41-b76f-a0c7a212f30e'::uuid,
   'Domtar의 미국 위스콘신주 Rothschild 제지공장. 인쇄용지를 생산하는 생산거점.',
   'Domtar''s Rothschild mill in Wisconsin, USA, a printing-paper production site.'),
  ('eae2d488-9375-441b-bc07-3a4d09ca99c2'::uuid,
   'Domtar의 캐나다 온타리오 Cornwall 거점. 종이·포장 관련 생산/물류 거점.',
   'Domtar''s Cornwall site in Ontario, Canada, a paper/packaging production and logistics location.'),
  ('34d5265e-1666-4bb8-ad15-ef23a9525a81'::uuid,
   '글로벌 포장·종이 그룹 Mondi의 생산거점(Frantschach 계열). 크라프트지·포장재 등을 생산.',
   'A production site of the global packaging-and-paper group Mondi (Frantschach lineage), making kraft paper and packaging.'),
  ('7e5f0af4-ca4b-4a79-8b8b-4d3b22d9d414'::uuid,
   '글로벌 포장·종이 그룹 Mondi의 오스트리아 Grünburg 거점.',
   'Mondi''s Grünburg site in Austria, part of the global packaging-and-paper group.'),
  ('7b86ee8e-c3a7-4d2b-ab86-3665e81737cc'::uuid,
   '글로벌 포장·종이 그룹 Mondi의 남아공 Merebank(더반) 제지공장. 사무용지·포장재를 생산.',
   'Mondi''s Merebank mill (Durban, South Africa), producing office papers and packaging within the global Mondi group.'),
  ('737d8310-0515-4c02-8db0-497d70be79e2'::uuid,
   '글로벌 포장·종이 그룹 Mondi의 남아공 다수 거점(멀티밀). 펄프·포장·사무용지를 생산.',
   'Multiple South-African sites of the global packaging-and-paper group Mondi, producing pulp, packaging and office paper.'),
  ('9ea85952-07fc-4a70-a106-4f2d4dfc9560'::uuid,
   'Mondi의 오스트리아 Neusiedler 계열 3개 제지공장. 사무·인쇄용지를 생산.',
   'Mondi''s three Neusiedler-lineage mills in Austria, producing office and printing papers.'),
  ('e8874d4d-12e7-414e-ba8b-05e20e9db4db'::uuid,
   'Mondi 및 Smurfit Westrock·DS Smith 등이 연관된 슬로바키아 포장·종이 거점군.',
   'A Slovak packaging-and-paper cluster associated with Mondi and Smurfit Westrock / DS Smith.'),
  ('27423257-e837-4103-9b55-0fef0fbb2c4d'::uuid,
   'Mondi의 슬로바키아 Ružomberok 통합 펄프-제지공장(Mondi SCP). 사무용지·펄프를 대규모 생산.',
   'Mondi''s integrated pulp-and-paper mill at Ružomberok, Slovakia (Mondi SCP), a large producer of office paper and pulp.'),
  ('bdaa7165-7117-4660-b7ee-b6e0b8b046ad'::uuid,
   'Mondi SCP(Ružomberok)의 PM19 신규 초지기 및 바이오매스 발전 설비를 포함한 확장 거점.',
   'Mondi SCP (Ružomberok) expansion including the PM19 paper machine and biomass power.'),
  ('9652ee9d-b1e9-4d87-96d2-3596e9fe151c'::uuid,
   'Mondi의 폴란드 Świecie 제지공장. 크라프트라이너·포장재를 생산하는 대형 거점.',
   'Mondi''s Świecie mill in Poland, a large producer of kraftliner and packaging.'),
  ('2ed3ac31-de06-4608-9427-fa4789cc80ed'::uuid,
   '스웨덴 Billerud의 미국 Escanaba(미시간) 공장. 2022년 Billerud가 Verso를 인수해 편입한 거점으로 그래픽·특수지를 생산.',
   'Billerud''s Escanaba mill (Michigan, USA), acquired via Billerud''s 2022 purchase of Verso, producing graphic and specialty papers.'),
  ('32c4c745-dd70-4312-85d2-a80fda4cd857'::uuid,
   '스웨덴 Billerud의 핀란드 Jakobstad(Pietarsaari) 제지·보드 공장.',
   'Billerud''s Jakobstad (Pietarsaari) paper-and-board mill in Finland.'),
  ('396a3eec-ea55-48a7-bfde-1703a940a99a'::uuid,
   '스웨덴 기반 글로벌 포장·종이 기업 Billerud의 다수 생산거점(멀티밀). 크라프트지·보드·포장재를 생산.',
   'Multiple mills of Billerud, the Sweden-based global packaging-and-paper company, producing kraft paper, board and packaging.'),
  ('d3e5e182-cb96-4fec-bb05-815b1fad0be7'::uuid,
   '스웨덴 Holmen의 Hallsta 제지공장. 인쇄·출판용지를 생산.',
   'Holmen''s Hallsta paper mill in Sweden, producing printing and publication papers.'),
  ('d98f9ba1-b305-405e-a52a-1bba727d9521'::uuid,
   '스웨덴 Holmen의 Iggesund 거점(Iggesund Paperboard). 고급 판지(SBB/FBB)를 생산.',
   'Holmen''s Iggesund site (Iggesund Paperboard) in Sweden, producing premium paperboard (SBB/FBB).'),
  ('69219439-2553-4015-ac97-abeea25c1c4d'::uuid,
   '포르투갈 The Navigator Company의 4개 거점 및 Altri 연관 펄프·제지 거점군. 유칼립투스 펄프·인쇄용지를 생산하는 유럽 최대급 UWF 메이커.',
   'The Navigator Company''s four Portuguese sites (with Altri-related pulp/paper), a top European uncoated woodfree maker producing eucalyptus pulp and printing papers.'),
  ('a336b16b-27d4-4153-ba11-c1bd8c594d81'::uuid,
   'The Navigator Company의 포르투갈 Figueira da Foz 통합 펄프-제지공장. 인쇄용지·펄프를 대규모 생산.',
   'The Navigator Company''s integrated pulp-and-paper mill at Figueira da Foz, Portugal, a large producer of printing papers and pulp.'),
  ('590025b8-d703-4c70-82bc-a0df8c700392'::uuid,
   'The Navigator Company의 포르투갈 Setúbal 통합 펄프-제지공장. 인쇄용지·펄프를 생산.',
   'The Navigator Company''s integrated pulp-and-paper mill at Setúbal, Portugal, producing printing papers and pulp.')
) as d(party_id, intro_ko, intro_en)
where p.id = d.party_id
  and p.organization_id = 'b25de8f2-1020-482f-9012-183f63883169';

-- 3) verify
select count(*) filter (where website ilike 'http%') as with_url,
       count(*) filter (where intro_ko is not null) as with_intro,
       count(*) as total
from app.parties
where organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  and id in (
   '0ff1fdfa-b549-4c25-af27-c9aec46900df','890ae7ee-12ae-4889-be24-c1f2155dbad0','715e8a6c-9bc4-4e41-afdb-a1827dd887ee',
   '86c35de3-a0cd-4456-9054-70c9c3642722','028f9b56-3780-4bb2-91f4-ca3514025484','f26708ad-70bf-47f9-82b3-9f40459e15c5',
   '42107ee3-2894-49c9-8af4-98eb4ddbd865','ea842041-1311-4d41-b76f-a0c7a212f30e','eae2d488-9375-441b-bc07-3a4d09ca99c2',
   '34d5265e-1666-4bb8-ad15-ef23a9525a81','7e5f0af4-ca4b-4a79-8b8b-4d3b22d9d414','7b86ee8e-c3a7-4d2b-ab86-3665e81737cc',
   '737d8310-0515-4c02-8db0-497d70be79e2','9ea85952-07fc-4a70-a106-4f2d4dfc9560','e8874d4d-12e7-414e-ba8b-05e20e9db4db',
   '27423257-e837-4103-9b55-0fef0fbb2c4d','bdaa7165-7117-4660-b7ee-b6e0b8b046ad','9652ee9d-b1e9-4d87-96d2-3596e9fe151c',
   '2ed3ac31-de06-4608-9427-fa4789cc80ed','32c4c745-dd70-4312-85d2-a80fda4cd857','396a3eec-ea55-48a7-bfde-1703a940a99a',
   'd3e5e182-cb96-4fec-bb05-815b1fad0be7','d98f9ba1-b305-405e-a52a-1bba727d9521','69219439-2553-4015-ac97-abeea25c1c4d',
   'a336b16b-27d4-4153-ba11-c1bd8c594d81','590025b8-d703-4c70-82bc-a0df8c700392'
  );
