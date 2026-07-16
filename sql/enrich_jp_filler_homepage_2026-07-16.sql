-- ============================================================
-- enrich_jp_filler_homepage_2026-07-16.sql
-- Japan filler suppliers - HOMEPAGE-VERIFIED ENRICHMENT.
--
-- AUDIT FIRST (lesson from the Omya Korea dupe): Japan is NOT a gap. The DB
-- already holds 9 domestic JP makers plus 2 SMI JP rows plus Shiraishi Malaysia.
-- 4 of the 9 were enriched in batch12/13 (Nitto Funka, Fimatec, Nittetsu Mining,
-- Toyo Denka). The other 5 only ever got a website in batch1 and were never
-- enriched - and they are the most paper-relevant names in Japan. This file
-- fills exactly that hole. NOTHING IS INSERTED. Every statement targets a known
-- uuid, so a duplicate is structurally impossible.
--
-- Sources read 2026-07-16: okutama.co.jp, shiraishi.co.jp, maruo-cal.co.jp,
-- bihokufunka.co.jp (+ ja.wikipedia for corporate history).
--
-- TWO CORRECTIONS RAISED (flagged, not force-written):
--   A. Shiraishi roles look swapped - Shiraishi Kogyo is the MAKER, Shiraishi
--      Calcium is the SALES arm. The stored "PCC pioneer" note sits on the
--      sales entity.
--   B. Shiraishi does not lead with paper. Its four headline fields are
--      automotive, industrial, living, food-agri/healthcare. Okutama is the
--      paper PCC player, not Shiraishi.
--
-- IDEMPOTENT. No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- intro_en is ASCII-only per project convention.
-- ============================================================

-- ---------- 1) PARTY location backfill (coalesce - never overwrites) ----------
update app.parties p
set country_code = coalesce(p.country_code, d.cc),
    region       = coalesce(p.region, d.region),
    city         = coalesce(p.city, d.city),
    updated_at   = now()
from (values
  ('8395314e-f6a8-4191-9795-5c26f5cb54f7'::uuid,'JP','東京都','立川市'),      -- Okutama Kogyo
  ('6cb04800-9a18-4ec1-b7ba-bb7882e6581b'::uuid,'JP','大阪府','大阪市'),      -- Shiraishi Kogyo
  ('e00f4fd0-1c82-42d7-b535-965b2ed2c998'::uuid,'JP','大阪府','大阪市'),      -- Shiraishi Calcium
  ('1be485ad-2edd-494d-9f4d-c5caa2a333b1'::uuid,'JP','兵庫県','明石市'),      -- Maruo Calcium
  ('844b4120-2db9-4f39-a191-0700c67b48e6'::uuid,'JP','岡山県','新見市')       -- Bihoku Funka Kogyo
) as d(id, cc, region, city)
where p.id = d.id and p.party_type_id = 3 and p.deleted_at is null;

-- ---------- 2) BILINGUAL INTROS ----------
update app.parties p
set intro_ko = d.ko, intro_en = d.en, updated_at = now()
from (values
  ('8395314e-f6a8-4191-9795-5c26f5cb54f7'::uuid,
   '도쿄 다치카와시 본사. 도쿄 오쿠타마에 자체 석회석 광산을 보유하고 채굴-화공-판매 일관체제를 갖춘 석회 기업이다. 1975년 자사 합성기술로 입경·입도를 제어한 경질탄산칼슘 「タマパール(TAMAPEARL)」 제조판매를 시작했고, 광택도·백색도·불투명도가 뛰어나 제지용 내전재·도공안료로 자리잡았다. 회사 홈페이지는 タマパール이 홋카이도부터 가고시마까지 전국에 공급되며 제지용에서 9할 초과의 압도적 점유율을 갖는다고 밝히고 있다. 2002년 자회사 (주)니가타PCC를 설립했다. 그 외 タマカルク(1995년~, 배가스 처리제), タマブラン(폐수 중화, 가성소다 대체), マスターズ 라인을 보유한다. 일본 제지용 PCC의 실질적 지배 사업자로, JP 시장 FCC 라이선싱 1순위 타깃이다.',
   'Headquartered in Tachikawa, Tokyo, with its own limestone mine at Okutama, Tokyo, and an integrated mine-to-chemical-to-sales chain. In 1975 it launched TAMAPEARL, a precipitated calcium carbonate whose particle shape and size are controlled by its own synthesis technology. Strong gloss, brightness and opacity made it a standard paper filler and coating pigment. The company website states that TAMAPEARL ships nationwide from Hokkaido to Kagoshima and holds an overwhelming share of more than 90 percent in papermaking use. It set up a subsidiary, Niigata PCC, in 2002. Other lines are TAMACALC from 1995 for flue-gas treatment, TAMABRAN for wastewater neutralisation as a caustic soda substitute, and MASTERS. The de facto leader of paper PCC in Japan and the top FCC licensing target in this market.'),

  ('6cb04800-9a18-4ec1-b7ba-bb7882e6581b'::uuid,
   '1910년대에 뿌리를 둔 백석(白石)그룹의 제조 중핵사. 그룹은 22개사, 국내외 44거점 규모다. 군마의 白艶華공장(1932년 조업)과 碓氷第一공장, 시즈오카의 不二공장·富士川공장, 고치의 土佐공장, 효고 아마가사키의 開発공장 등 6개 공장을 운영한다. 2022년 7월 太陽化学工業을 흡수합병했다. 제품은 극미세 탄산칼슘(UFPCC)·경질탄산칼슘(PCC)·중질탄산칼슘(GCC)이며, 2024년 3월 「신규 탄산염화 기술 및 부생성물을 활용한 경질탄산칼슘 제조기술 개발」이 NEDO 과제설정형 조성사업에 채택됐다. 주의: 홈페이지가 내세우는 4대 분야는 자동차자재·산업자재·생활자재·식품아그리/헬스케어로, 제지는 헤드라인에 없다. 즉 고무·수지·식품 중심이며 제지 비중은 상대적으로 낮아 보인다. 다만 NEDO 탄산염화 과제는 FCC와 기술 접점이 있어 대화 훅으로 쓸 수 있다.',
   'The manufacturing core of the Shiraishi Group, whose roots go back to the 1910s. The group spans 22 companies and 44 sites in Japan and abroad. It runs six plants - Hakuenka in Gunma, operating since 1932, plus Usui No.1 in Gunma, Fuji and Fujikawa in Shizuoka, Tosa in Kochi, and a development plant in Amagasaki, Hyogo. It absorbed Taiyo Kagaku Kogyo in July 2022. Products span ultrafine calcium carbonate (UFPCC), PCC and GCC. In March 2024 its project on new carbonation technology and by-product-based PCC manufacture was selected for a NEDO grant programme. Note - the four headline fields on its site are automotive, industrial, living, and food-agri/healthcare. Paper is not among them, so the mix looks weighted to rubber, resin and food rather than paper. The NEDO carbonation work is still a useful technical hook for an FCC conversation.'),

  ('e00f4fd0-1c82-42d7-b535-965b2ed2c998'::uuid,
   '백석(白石)그룹의 판매·네트워크 담당 법인이다. 제조는 백석공업(白石工業), 연구개발은 백석중앙연구소가 맡고, 백석칼슘은 그룹 탄산칼슘 제품의 판매 거점 역할을 한다. 주의: 기존 DB 노트의 「Japanese PCC pioneer」는 실제로는 제조사인 백석공업에 해당하는 설명으로, 두 법인의 역할이 뒤바뀌어 기록된 것으로 보인다. 상업 접촉 창구로는 유효하나, 기술·라이선싱 논의의 상대는 백석공업이다.',
   'The sales and distribution arm of the Shiraishi Group. Manufacturing sits with Shiraishi Kogyo and R and D with the Shiraishi Central Research Laboratory, while Shiraishi Calcium acts as the group sales network for its calcium carbonate products. Note - the stored description calling this entity the Japanese PCC pioneer actually fits Shiraishi Kogyo, the maker, so the two roles look swapped in the record. This entity is a valid commercial door, but technical and licensing talks belong with Shiraishi Kogyo.'),

  ('1be485ad-2edd-494d-9f4d-c5caa2a333b1'::uuid,
   '효고현 아카시시 본사(우오즈미초 니시오카 1455)의 탄산칼슘 종합 메이커로, 1926년 丸尾製粉合資会社로 창업해 도료용 백악(白亜) 제조에서 출발했다. 1931년 본사공장에 경질탄산칼슘 공장, 1957년 土山공장, 1966년 土浦공장에 중질탄산칼슘 공장을 신설했고 1979년 九州カルシウム(후쿠오카현 미야코마치, 현 연결자회사)에서 각종 중질·표면처리 중질탄산칼슘을 만든다. 아카시에 중앙연구소를 두고 2003년 丸尾(上海)貿易을 설립했다. PCC와 GCC를 모두 갖춘 종합 사업자이며 용도에 제지가 명시되어 있다. 탄산칼슘 종합메이커 중 유일한 상장사이고 한국·중국·동남아·북미·남미·EU에 수출한다. 연구개발을 사업의 근간으로 내세우는 회사라 신기술 라이선싱 대화의 수용도가 높을 수 있다.',
   'A full-range calcium carbonate maker headquartered in Akashi, Hyogo, founded in 1926 as Maruo Seifun and starting from chalk for the paint industry. It added a PCC plant at the head office works in 1931, the Tsuchiyama works in 1957 and a GCC plant at the Tsuchiura works in 1966, and since 1979 has made ground and surface-treated GCC through Kyushu Calcium in Miyako, Fukuoka, now a consolidated subsidiary. It runs a central research laboratory in Akashi and set up Maruo Shanghai Trading in 2003. It covers both PCC and GCC, and paper is named among its applications. It is the only listed company among the full-range calcium carbonate makers, and exports to Korea, China, Southeast Asia, North and South America and the EU. The company positions R and D as the root of its business, which may make it receptive to a new-technology licensing conversation.'),

  ('844b4120-2db9-4f39-a191-0700c67b48e6'::uuid,
   '오카야마현 니이미시 기반의 중질탄산칼슘(GCC) 전업 메이커다. 홈페이지에 「당사는 중질탄산칼슘을 취급한다」고 명시되어 있어 PCC는 하지 않는 것으로 보인다. 자체 광산 2곳을 보유한다 - 니이미시 테츠타초의 唐櫃(가라비츠)광산은 갱내가 지하 100m에 달하고 열변성으로 결정화된 양질 광석을 채굴하며 매장량이 약 1억 톤으로 알려져 있고, 후쿠시마현 다무라시의 大滝根(오타키네)광산이 동일본을 커버한다. 용도로 플라스틱·접착제·건재·식품·제지·도료·고무·의약품을 명시한다. FCC 관점에서는 PCC 설비가 없다는 점이 제약이지만, 고순도 결정질 원석과 1억 톤 매장량은 GCC 계열 응용의 원료 기반으로 강점이다.',
   'A ground calcium carbonate specialist based in Niimi, Okayama. Its site states plainly that the company handles ground calcium carbonate, so it appears not to make PCC. It owns two mines - the Karabitsu mine in Tetta, Niimi, whose workings reach 100 metres underground and yield thermally metamorphosed crystalline high-grade ore with reserves put at about 100 million tons, and the Otakine mine in Tamura, Fukushima, covering eastern Japan. Listed applications include plastics, adhesives, building materials, food, paper, coatings, rubber and pharmaceuticals. For FCC the absence of PCC capacity is a constraint, but the high-purity crystalline ore and the 100 million ton reserve are a strong raw-material base for GCC-route applications.')
) as d(id, ko, en)
where p.id = d.id and p.party_type_id = 3 and p.deleted_at is null and p.intro_ko is null;

-- ---------- 3) PROFILE: mineral_class (coalesce) ----------
update app.filler_supplier_profile f
set mineral_class = coalesce(f.mineral_class, d.mc), updated_at = now()
from (values
  ('8395314e-f6a8-4191-9795-5c26f5cb54f7'::uuid,'pcc'),
  ('6cb04800-9a18-4ec1-b7ba-bb7882e6581b'::uuid,'pcc'),
  ('e00f4fd0-1c82-42d7-b535-965b2ed2c998'::uuid,'pcc'),
  ('1be485ad-2edd-494d-9f4d-c5caa2a333b1'::uuid,'pcc/gcc'),
  ('844b4120-2db9-4f39-a191-0700c67b48e6'::uuid,'gcc')
) as d(pid, mc)
where f.party_id = d.pid and f.deleted_at is null;

-- ---------- 4) PROFILE: evidence notes (append only, tag-guarded) ----------
update app.filler_supplier_profile f
set notes = coalesce(f.notes, '') || E'\n[jp-homepage 2026-07-16] ' || d.note, updated_at = now()
from (values
  ('8395314e-f6a8-4191-9795-5c26f5cb54f7'::uuid,
   'Paper-grade: YES, and dominant. TAMAPEARL PCC since 1975. Company site claims over 90 percent share in papermaking use, shipped nationwide. Own Okutama limestone mine, integrated mine-to-product chain. SATELLITE SIGNAL - subsidiary Niigata PCC established 2002, which points at an on-site or mill-adjacent PCC model, most likely serving a Niigata paper mill. VERIFY the Niigata PCC customer and whether it is a true on-site satellite before setting supply_model. If confirmed, this is the strongest FCC licensing fit in Japan and supply_model should move to satellite with evidence_level B.'),
  ('6cb04800-9a18-4ec1-b7ba-bb7882e6581b'::uuid,
   'Paper-grade: WEAK. Shiraishi Kogyo is the MAKER of the Shiraishi Group - 6 plants (Hakuenka and Usui No.1 in Gunma, Fuji and Fujikawa in Shizuoka, Tosa in Kochi, development plant in Amagasaki). Absorbed Taiyo Kagaku Kogyo 2022-07. Makes UFPCC, PCC and GCC. CAUTION - the four headline fields on the site are automotive, industrial, living and food-agri/healthcare. Paper is NOT a headline field, so the earlier read of Shiraishi as a paper PCC player looks overstated. HOOK - March 2024 NEDO award for new carbonation technology and by-product-based PCC manufacture, which overlaps the FCC technical story.'),
  ('e00f4fd0-1c82-42d7-b535-965b2ed2c998'::uuid,
   'ROLE CORRECTION FLAG. Shiraishi Calcium is the SALES and network arm of the Shiraishi Group, not a manufacturer. Manufacturing sits with Shiraishi Kogyo (6cb04800-9a18-4ec1-b7ba-bb7882e6581b), R and D with the Shiraishi Central Research Laboratory. The stored note calling this row the Japanese PCC pioneer describes Shiraishi Kogyo, so the two rows look swapped. ACTION - decide whether to keep both rows with corrected roles or merge, and route technical/licensing contact to Shiraishi Kogyo.'),
  ('1be485ad-2edd-494d-9f4d-c5caa2a333b1'::uuid,
   'Paper-grade: YES, named among applications. Full-range PCC plus GCC maker, founded 1926, HQ Akashi Hyogo. PCC plant since 1931, GCC at Tsuchiura since 1966, GCC and surface-treated GCC via consolidated subsidiary Kyushu Calcium (Miyako, Fukuoka). Central research laboratory in Akashi. Maruo Shanghai Trading since 2003. Described as the only listed company among full-range calcium carbonate makers. Exports to Korea, China, SE Asia, Americas and EU. R and D is stated as the root of the business - a receptive audience for licensing. Strong JP target number 2 after Okutama.'),
  ('844b4120-2db9-4f39-a191-0700c67b48e6'::uuid,
   'Paper-grade: YES, paper named among applications - but GCC ONLY. Site states the company handles ground calcium carbonate, so no PCC line is evident. Two owned mines - Karabitsu (Tetta, Niimi, Okayama), workings to 100m depth, thermally metamorphosed crystalline high-grade ore, reserves about 100 million tons - and Otakine (Tamura, Fukushima) covering eastern Japan. FCC constraint - no PCC capacity. FCC opportunity - excellent high-purity crystalline feedstock at very large reserve scale.')
) as d(pid, note)
where f.party_id = d.pid and f.deleted_at is null
  and coalesce(f.notes, '') not like '%[jp-homepage 2026-07-16]%';

-- ---------- 5) VERIFY (run separately) ----------
-- select p.party_name, p.city, fp.mineral_class, fp.supply_model, fp.evidence_level,
--        (p.intro_ko is not null) as has_ko, (p.intro_en is not null) as has_en
-- from app.parties p
-- left join app.filler_supplier_profile fp on fp.party_id = p.id
-- where p.id in ('8395314e-f6a8-4191-9795-5c26f5cb54f7'::uuid,
--                '6cb04800-9a18-4ec1-b7ba-bb7882e6581b'::uuid,
--                'e00f4fd0-1c82-42d7-b535-965b2ed2c998'::uuid,
--                '1be485ad-2edd-494d-9f4d-c5caa2a333b1'::uuid,
--                '844b4120-2db9-4f39-a191-0700c67b48e6'::uuid)
-- order by p.party_name;
-- expect 5 rows, all has_ko = true, all city filled

-- FULL JP PICTURE - run this and send it back for the next batch:
-- select p.id, p.party_name, p.country_code, p.city, p.website,
--        fp.mineral_class, fp.supply_model, fp.evidence_level, fp.market_role,
--        (p.intro_ko is not null) as has_ko,
--        (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts
-- from app.parties p
-- left join app.filler_supplier_profile fp on fp.party_id = p.id
-- where p.party_type_id = 3 and p.deleted_at is null
--   and (p.country_code = 'JP' or p.website ilike '%.jp%' or p.party_name ilike '%japan%')
-- order by p.party_name;
