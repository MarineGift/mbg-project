-- =====================================================================
-- mbg-project : 0003 - landing page content (marinebiogroup home)
-- Run AFTER 0002. ASCII-only. Idempotent (NOT EXISTS guards).
-- Real content sourced from marinebiogroup.com.
-- =====================================================================

-- helper: main site id and home page id are referenced repeatedly
-- (inlined as subselects below for portability in the SQL editor)

-- ---------------------------------------------------------------------
-- COLLECTIONS : products showcase, patents, journals
-- ---------------------------------------------------------------------
insert into web.collections (site_id, key, name)
select s.id, v.key, v.name
from web.sites s
cross join (values
  ('products_showcase', 'Products Showcase'),
  ('patents', 'Patents'),
  ('journals', 'SCI Journals')
) as v(key, name)
where s.slug = 'marinebiogroup'
  and not exists (select 1 from web.collections c where c.site_id = s.id and c.key = v.key);

-- products showcase items (content cards, not the shop)
insert into web.items (collection_id, kind, title, data, sort_order)
select c.id, 'product', v.title,
  jsonb_build_object('image', v.img, 'category', v.cat, 'description', v.descr,
                     'tags', v.tags::jsonb),
  v.ord
from web.collections c
join web.sites s on s.id = c.site_id and s.slug = 'marinebiogroup'
cross join (values
  ('Natural Soap', 'Cosmetics',
   'Premium natural soap enriched with marine nanofibers for gentle cleansing and superior moisturizing.',
   '["Natural Ingredients","Deep Cleansing","Moisturizing"]',
   'https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/15eac05385e1d4b27684af717747e642.jpeg', 0),
  ('Face Mask', 'Cosmetics',
   'Revitalizing face mask with marine collagen and nanofiber technology for deep hydration and anti-aging.',
   '["Deep Hydration","Anti-Aging","Skin Brightening"]',
   'https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/96f5a33690dc1d43dc4bf8612039bd07.jpeg', 1),
  ('Sun Screen', 'Cosmetics',
   'Advanced sun protection with marine nanofiber technology offering broad-spectrum UV defense.',
   '["Broad Spectrum","Water Resistant","Non-Greasy"]',
   'https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/2512458350bcd76c09ab3d2828086115.jpeg', 2),
  ('Tone Up', 'Cosmetics',
   'Brightening tone-up cream with marine nanofibers for instant skin illumination and long-lasting radiance.',
   '["Instant Brightening","Natural Glow","Long-Lasting"]',
   'https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/2a87d3ae034f8ec6d4c3174af6225cd7.jpeg', 3),
  ('High-Performance Diapers', 'Bio-SAP',
   'Diapers made with nanofiber technology offering superior absorption and breathability.',
   '["Ultra-High Absorption","Breathability","Skin-Friendly"]',
   'https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/7a649bcc17f0b84791334de5ef7e8b99.jpeg', 4),
  ('Advanced Sanitary Pads', 'Bio-SAP',
   'Revolutionary sanitary pads with marine nanofiber technology for superior comfort and protection.',
   '["Ultra-Thin","Maximum Absorption","Odor Control"]',
   'https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/0555cc65db223230da04aec830267327.jpeg', 5),
  ('Cost Saving Paper Filler', 'Paper',
   'An eco-friendly paper additive that reduces pulp usage through microfiber processing technology.',
   '["Pulp Reduction","Cost Effective","Eco-Friendly"]',
   'https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/716e4de89aa85deee92f835203edc8cd.png', 6)
) as v(title, cat, descr, tags, img, ord)
where c.key = 'products_showcase'
  and not exists (select 1 from web.items i where i.collection_id = c.id and i.sort_order = v.ord);

-- patents (cells: No, Patent Details, Category)
insert into web.items (collection_id, kind, data, sort_order)
select c.id, 'patent',
  jsonb_build_object('cells', jsonb_build_array(v.no, v.detail, v.cat)), v.ord
from web.collections c
join web.sites s on s.id = c.site_id and s.slug = 'marinebiogroup'
cross join (values
  ('1','Manufacturing Method of Pulp Using Red Algae','pulp',0),
  ('2','A method of manufacturing pulp with low internal gel extract content from red algae','pulp',1),
  ('3','Manufacturing Method of Pulp Using Thick Red Algae','pulp',2),
  ('4','Manufacturing Method of Pulp Using Thin-skinned Red Algae','pulp',3),
  ('5','A method of manufacturing pulp with high internal gel extract content from algae','pulp',4),
  ('6','Pulps manufactured from red algae and their manufacturing methods','pulp',5),
  ('7','Electronic component case using bio-composite material with seaweeds fiber reinforcement','bio-composite',6),
  ('8','Bio-complex materials with red algae fibers as reinforcing materials','bio-composite',7),
  ('9','Korean paper containing red algae fibers','traditional paper',8),
  ('10','Manufacturing Method of Paper Surface Size Agent Using Raincoat from Red Algae','papermaking',9),
  ('11','Manufacturing method of opaque low-volume paper and opaque low-volume paper','papermaking',10),
  ('12','Transparent red algae food wrapper and its manufacturing method','food packaging',11),
  ('13','Bio with low concentrations of toxic substances from red algae - alcohol raw materials and bio-alcohol','bio-ethanol',12),
  ('14','Method for production of methane gas using red algae extract','methane generation',13),
  ('15','An opaque food wrapper using red algae and its manufacturing method','food packaging',14),
  ('16','Pretendable food film using red algae and its manufacturing method','edible film',15),
  ('17','Sheet for mask pack containing seaweeds fiber and its manufacturing method','cosmetics',16),
  ('18','Transparent high density from algae - raw material pulp and transparent high density paper','papermaking',17),
  ('19','The manufacturing method of RA-PLA and the RA-PLA manufactured thereunder','bio-plastic',18),
  ('20','Dehydrate Red algae low molecular extract and dehydrate drying method','food additive',19),
  ('21','Oil control paper containing marine algae for removing skin oil','cosmetics',20),
  ('22','Paper yarn comprising red algae fiber and method for manufacturing thereof','fabrics',21),
  ('23','(PCT) Manufacturing method of pulp using algae pulsed with alkali aqueous solution','pulping method',22),
  ('24','(Registered) Manufacturing method of sheet for mask packs containing seaweeds fibers','cosmetic',23)
) as v(no, detail, cat, ord)
where c.key = 'patents'
  and not exists (select 1 from web.items i where i.collection_id = c.id and i.sort_order = v.ord);

-- SCI journals (cells: No, Description)
insert into web.items (collection_id, kind, data, sort_order)
select c.id, 'generic',
  jsonb_build_object('cells', jsonb_build_array(v.no, v.descr)), v.ord
from web.collections c
join web.sites s on s.id = c.site_id and s.slug = 'marinebiogroup'
cross join (values
  ('1','Seo, Y.B. et al., Gelidium and their use in papermaking, BIORESOURCE TECHNOLOGY 101(7):2549-2553 (2010)',0),
  ('2','CELL 79 Algae fiber and its biocomposites, ABSTRACTS OF PAPERS OF THE ACS 233:790 (2007)',1),
  ('3','Ku, K.J. et al., Application of edible Gelidium paper for shelf life extension, FOOD SCI BIOTECH 17(2):421-424 (2008)',2),
  ('4','Lee, M.W. et al., Gelidium fibre/PBS biocomposites, COMPOSITES SCIENCE AND TECHNOLOGY 68(6):1266-1272 (2008)',3),
  ('5','Boo, S.M. et al., Diversity and phylogeny of pulp-producing alga gelidiales, J BIOTECHNOLOGY 136:S523 (2008)',4),
  ('6','Sim, K.J. et al., Gelidium Fiber Reinforced PLA Biocomposites, MACROMOLECULAR RESEARCH 18(5):489-495 (2010)',5),
  ('7','Seo, Y.B. et al., Optical Properties of Gelidium Fibers, IND ENG CHEM RES 49(20):9830-9833 (2010)',6),
  ('8','Jang, S.A. et al., Plasticizers and Nanoclays on Gelidium Film, J FOOD SCIENCE 76(3):N30-N34 (2011)',7),
  ('9','Seo, Y.B. and Lee, M.W., Non-wood fibres and paper opacity, APPITA JOURNAL 64(5):445-449 (2011)',8),
  ('10','Shin, Y.J. et al., Gelidium Film with Grapefruit Seed Extract for packaging, FOOD SCI BIOTECH 21(1):225-231 (2012)',9),
  ('11','Yoon, M.H. et al., Bio-ethanol and bleached pulp from Gelidium, BIORESOURCE TECHNOLOGY 126:198-201 (2012)',10),
  ('12','Bondable and Biodegradable Cellulosic Opacifiers, IND ENG CHEM RES 52(29):9812-9815 (2013)',11),
  ('13','Le Van Hai, Seo Y.B., Nanocrystalline cellulose from wood, cotton, cattail, Gelidium, CELLULOSE 22(3):1789-1798 (2015)',12),
  ('14','Le Van Hai, Seo Y.B., CNC from electron beam treated cellulose fiber, NORDIC PULP PAPER RES J 32(2):170-178 (2017)',13),
  ('15','Seo Y.B. et al., Upgrading waste paper by in-situ calcium carbonate formation, J CLEANER PRODUCTION 155(1):212-217 (2017)',14)
) as v(no, descr, ord)
where c.key = 'journals'
  and not exists (select 1 from web.items i where i.collection_id = c.id and i.sort_order = v.ord);

-- ---------------------------------------------------------------------
-- SECTIONS : insert landing blocks between hero (0) and contact (90)
-- A reusable insert pattern guarded by (page, type, sort_order).
-- ---------------------------------------------------------------------

-- Core Technology (feature_steps)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'feature_steps', 10, '{
  "title":"Core Technology",
  "subtitle":"From biomass to nanofibers, our 3rd generation technology revolutionizes quality, functionality, and cost simultaneously.",
  "steps":[
    {"title":"Bio Mass","body":"1st Gen: Sugar-containing biomass\n2nd Gen: Starch materials\n3rd Gen: Lignocellulosic biomass","images":["https://public.readdy.ai/ai/img_res/0430cc9095a71adad792a995ed61683a.jpg"]},
    {"title":"Nanoization","body":"Innovative nanoization process transforms marine bio materials into nanofibers."},
    {"title":"Quality Applications","body":"High-quality products across cosmetics, diapers, paper, and more."}
  ],
  "cards":[
    {"title":"Quality Innovation","body":"Achieving high-quality properties impossible with terrestrial plant materials."},
    {"title":"Enhanced Functionality","body":"Maximizing product functionality through nanofiber technology."},
    {"title":"Cost Efficiency","body":"Optimizing production costs through innovative processes."}
  ]
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 10);

-- Products showcase (card_grid with tabs)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'card_grid', 20, '{
  "title":"Innovative Products",
  "subtitle":"Discover high-quality products across various industries powered by marine nanofiber technology.",
  "collection_key":"products_showcase",
  "tabs":true,
  "columns":4
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 20);

-- Custom solution CTA
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'cta_banner', 25, '{
  "title":"Need a Custom Solution?",
  "body":"We provide optimized marine nanofiber technology solutions tailored to your business needs.",
  "cta":{"label":"Request Consultation","href":"#contact"}
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 25);

-- Research intro (story with features + image)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'story', 30, '{
  "id":"research",
  "title":"World-Class Research Excellence",
  "body":"MarinebioGroup is a pioneer in marine biomass research, continuously investing in R&D to develop innovative technologies. Our research team collaborates with experts worldwide to lead next-generation nanofiber technology.",
  "image":"https://public.readdy.ai/ai/img_res/8a4df81f3111beac0513d9eec745e069.jpg",
  "image_side":"right",
  "features":[
    {"title":"Advanced Research Facilities","body":"Precise analysis and experiments with state-of-the-art equipment."},
    {"title":"Expert Research Team","body":"Top specialists in marine biology, nanotechnology, and materials engineering."},
    {"title":"Global Collaboration","body":"Joint research with leading universities and institutions worldwide."}
  ]
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 30);

-- Achievements (stat_grid)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'stat_grid', 35, '{
  "title":"Research Achievements",
  "subtitle":"Outstanding results from continuous research and development.",
  "stats":[
    {"value":"15+","label":"Research Patents","sub":"Core patents in marine nanofiber technology"},
    {"value":"50+","label":"Research Papers","sub":"Publications in international journals"},
    {"value":"10+","label":"Research Partners","sub":"Collaborations with global institutions"},
    {"value":"3rd Gen","label":"Technology Innovation","sub":"Next-generation biomass technology"}
  ]
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 35);

-- NET certification (cert_block)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'cert_block', 40, '{
  "title":"Government-Certified Innovation Technology",
  "body":"Officially recognized as a New Excellent Technology (NET) by the Ministry of Oceans and Fisheries, Republic of Korea.",
  "image":"https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/0b1e747313b51c08e640e2dca9dfec43.jpeg",
  "cards":[
    {"title":"NET Certification","body":"Certified under Article 17(1) of the Act on Support of Science and Technology for Oceans and Fisheries. Certificate No. 2023-0010."},
    {"title":"Certified Technology","body":"Manufacturing technology for a natural superabsorbent polymer using a chitin-derived nanomesh - a world-first innovation."},
    {"title":"Validity Period","body":"Issued October 13, 2023. Valid through July 9, 2028."},
    {"title":"Issuing Authority","body":"Minister of Oceans and Fisheries, Republic of Korea."}
  ]
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 40);

-- Patents table (data_table from collection)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'data_table', 45, '{
  "title":"Registration and Application Patents",
  "subtitle":"Red Algae Technology Patents - Prof. Seo Yung-Bum / Director Lee Yoon-woo",
  "columns":["No","Patent Details","Category"],
  "collection_key":"patents",
  "note":"Total 24 patents registered and applied."
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 45);

-- Journals table (data_table from collection)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'data_table', 50, '{
  "title":"SCI-grade Journals",
  "subtitle":"Related to use of red algae and nanocellulose.",
  "columns":["No","Description"],
  "collection_key":"journals",
  "note":"15 SCI international journal papers published."
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 50);

-- About / Our Vision (story with image + CTAs)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'story', 60, '{
  "id":"about",
  "title":"Our Vision",
  "body":"MarinebioGroup believes in the infinite potential of marine biomass materials and aims to enrich human life through this technology. We do not just create products; we provide solutions for a sustainable future. Based on our world-unique marine nanofiber technology, we develop innovative products across various fields, from cosmetics to industrial materials.",
  "image":"https://public.readdy.ai/ai/img_res/ce7723a782dce6dbceff7c07c9a544f8.jpg",
  "image_side":"left",
  "ctas":[
    {"label":"Download Company Brochure","href":"#contact"},
    {"label":"View Investment Information","href":"#contact"}
  ]
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 60);

-- Core Values (story, features-only)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'story', 65, '{
  "title":"Core Values",
  "body":"Values and philosophy that MarinebioGroup pursues.",
  "features":[
    {"title":"Innovation","body":"Creating new possibilities through continuous research and development."},
    {"title":"Sustainability","body":"Preparing for the future with eco-friendly technology."},
    {"title":"Quality","body":"Providing the highest quality products and services."},
    {"title":"Global","body":"Leading the world market with advanced technology."}
  ]
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 65);

-- Company History (timeline)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'timeline', 70, '{
  "title":"Company History",
  "events":[
    {"year":"2026","title":"Company Establishment - Global Headquarter","body":"Marinebio Group Inc. established in Austin, Texas. FCC global patent submissions - USA, EU, Japan, China, India, Indonesia."},
    {"year":"2025","title":"Global Expansion","body":"Acquired patents for marine nanofiber extraction and processing technology."},
    {"year":"2024","title":"Technology Innovation","body":"Launched first commercial product in the cosmetics sector."},
    {"year":"2022","title":"First Product Launch","body":"Entered international markets and established global partnerships."},
    {"year":"2014","title":"Core Technology Development","body":"Completed 3rd generation biomass technology and multi-field applications."}
  ]
}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.sort_order = 70);

-- =====================================================================
-- done : marinebiogroup home now renders a complete corporate site
-- =====================================================================
