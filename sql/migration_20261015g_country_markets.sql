-- ============================================================
-- migration_20261015g_country_markets.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Country market overviews.
-- 1) New table app.country_markets - one row per country (organization +
--    country_code unique). Linked to paper mills and filler suppliers through
--    app.parties.country_code (same ISO 2-letter code).
--    Columns: country_name, priority (high / medium / low / on_hold / none),
--    headline, summary, sections jsonb (fillers, mills, strategy, risks,
--    next_steps[], key_numbers[{label,value}], files[]), checked_at.
-- 2) Seed 34 countries researched 2026-10-14 / 15 (summaries of the
--    country reports). Re-running updates the text (upsert).
-- 3) Verify: each country with its mill and filler counts in URM.
--
-- The party page (paper_mill / filler_supplier) shows a "Country market"
-- button that opens this overview.
-- ============================================================

create table if not exists app.country_markets (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null default app.current_organization_id(),
  country_code     text not null,
  country_name     text not null,
  priority         text not null default 'low',
  headline         text,
  summary          text,
  sections         jsonb not null default '{}'::jsonb,
  checked_at       date,
  created_at       timestamptz not null default now(),
  created_by       uuid default auth.uid(),
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz,
  constraint country_markets_priority_check
    check (priority in ('high', 'medium', 'low', 'on_hold', 'none')),
  constraint country_markets_code_check
    check (country_code ~ '^[A-Z]{2}$')
);

create unique index if not exists country_markets_org_code_uidx
  on app.country_markets (organization_id, country_code);

drop trigger if exists trg_country_markets_updated_at on app.country_markets;
create trigger trg_country_markets_updated_at
  before update on app.country_markets
  for each row execute function app.set_updated_at();

alter table app.country_markets enable row level security;

grant select, insert, update, delete on app.country_markets to authenticated;

drop policy if exists pol_country_markets_select on app.country_markets;
create policy pol_country_markets_select on app.country_markets
  for select
  using (organization_id = (select app.current_organization_id()));

drop policy if exists pol_country_markets_insert on app.country_markets;
create policy pol_country_markets_insert on app.country_markets
  for insert
  with check (organization_id = (select app.current_organization_id()));

drop policy if exists pol_country_markets_update on app.country_markets;
create policy pol_country_markets_update on app.country_markets
  for update
  using (organization_id = (select app.current_organization_id()))
  with check (organization_id = (select app.current_organization_id()));

drop policy if exists pol_country_markets_delete on app.country_markets;
create policy pol_country_markets_delete on app.country_markets
  for delete
  using (organization_id = (select app.current_organization_id()));

insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections, checked_at)
select 'b25de8f2-1020-482f-9012-183f63883169'::uuid, v.country_code, v.country_name, v.priority, v.headline, v.summary, v.sections, '2026-10-15'::date
from (values
  ('US', $cm$United States$cm$, 'high', $cm$Large printing-paper base with SMI satellite PCC and Omya on-site plants$cm$, $cm$The US has the deepest network of satellite PCC plants run by SMI (MTI) next to paper mills, plus Omya on-site PCC and GCC plants. Printing and writing capacity is shrinking but the remaining fine-paper mills are large and filler-intensive.$cm$,
   $cm${"fillers": "SMI satellite PCC at Ashdown, Quinnesec, Cloquet, International Falls, Eastover, Longview and others. Omya PCC at Hawesville and Johnsonburg, Omya GCC at Florence VT, Sylacauga, Lucerne Valley, Superior. Columbia River Carbonates and GLC Minerals regional GCC.", "mills": "Sylvamo, Domtar (Paper Excellence), Sappi, Billerud, PCA. Domtar Nekoosa is the reference case (Omya on-site PCC 2024).", "strategy": "Work through the licensees - SMI and Omya already operate on-site plants, so FCC can run on existing satellite lines. Priority mills carry FCC scenarios on their cards.", "risks": "Mill closures and conversions to packaging. SMI and Omya plant-level volumes are not public.", "next_steps": ["Confirm per-mill PCC volumes with SMI and Omya", "Pick one satellite site for an FCC line trial"], "key_numbers": [{"label": "SMI satellite plants recorded", "value": "8+"}, {"label": "Omya US PCC sites", "value": "Hawesville, Johnsonburg (Kingsport historical)"}, {"label": "Top targets", "value": "Sylvamo Eastover, Ticonderoga, Sappi Cloquet, Domtar Hawesville, Johnsonburg"}], "files": ["seed_20261014_us_filler_mill_links", "seed_20261014b_omya_us_plants", "fix_20261014c_us_mill_plant_profiles"]}$cm$::jsonb),
  ('JP', $cm$Japan$cm$, 'high', $cm$Mature fine-paper market with in-house PCC at the large integrated mills$cm$, $cm$Japanese majors (Nippon Paper, Oji, Daio, Hokuetsu, Mitsubishi) run large integrated mills, several with in-house PCC. Capacity is being cut and lines converted, so targets must be checked machine by machine.$cm$,
   $cm${"fillers": "In-house PCC at the majors, SMI FMT on-site PCC at Nippon Paper Shiraoi (historical PM8).", "mills": "Priority: Hokuetsu Niigata, Nippon Paper Ishinomaki, Oji Kasugai, Oji Yonago, Daio Mishima, Mitsubishi Hachinohe, Nippon Paper Shiraoi.", "strategy": "Approach groups at technical HQ level - mills with in-house PCC can host FCC directly.", "risks": "Ongoing capacity cuts and line closures.", "next_steps": ["Confirm in-house PCC volumes at Hokuetsu Niigata and Ishinomaki"], "key_numbers": [{"label": "Mills profiled", "value": "16"}, {"label": "Recent shutdowns", "value": "Shiraoi PM8 2025-09, Tomakomai PM9 2025-03, Yatsushiro N2 2025-06"}], "files": ["fix_20261014d_jp_mill_plant_profiles", "fix_20261014e_jp_missing_mills"]}$cm$::jsonb),
  ('IN', $cm$India$cm$, 'high', $cm$Growing printing-paper market with SMI, Gulshan and Fimakem supply links$cm$, $cm$India has rising printing and writing demand, several SMI satellite PCC plants and strong local PCC (Gulshan) and wet GCC (Fimakem) suppliers.$cm$,
   $cm${"fillers": "SMI satellites (JK Rayagada, BILT Sewa, Century Lalkuan, Satia, Andhra), Gulshan Polyols PCC (Orient, ITC Tribeni, Silvertone, Trident planned 22 kt FY2027-28), Fimakem wet GCC (ITC Bhadrachalam, JK Rayagada), Omya India.", "mills": "JK Paper, ITC PSPD, Satia, Andhra Paper, Trident, West Coast, TNPL, Silvertone. Century Lalkuan moved to ITC 2026-08-01.", "strategy": "Use SMI and Omya at mills they already serve, Gulshan and Fimakem as local partners.", "risks": "Price-sensitive buyers, fragmented mid-size mills.", "next_steps": ["Approach ITC PSPD for Bhadrachalam and Lalkuan together"], "key_numbers": [{"label": "Mills profiled", "value": "8 priority mills"}, {"label": "Key links", "value": "SMI, Gulshan, Fimakem at named mills"}], "files": ["seed_20261014f_india_mills_fillers"]}$cm$::jsonb),
  ('CN', $cm$China$cm$, 'high', $cm$Largest market - SMI satellites and in-house PCC, Omya expanding$cm$, $cm$China has the largest printing and packaging paper base. SMI runs satellites at several majors, groups like APP China make in-house PCC and GCC, and Omya announced six new plants in 2023.$cm$,
   $cm${"fillers": "SMI satellites, Omya China (6 plants planned 2023), Guangxi Huarui, Guangxi Guigang Huitong, in-house PCC at Gold East.", "mills": "Sun Paper Yanzhou (FulFill competitor), Gold East, Asia Symbol Shandong, Nine Dragons Beihai, Gold Huasheng, Bohui, Wuzhou Special Paper, Lee and Man (tissue).", "strategy": "Group-level deals (Sun Paper, APP, Nine Dragons) - one win covers many mills.", "risks": "SMI FulFill is a direct competitor at Sun Paper. Chenming in heavy losses.", "next_steps": ["Map Omya China plant sites against priority mills"], "key_numbers": [{"label": "Mills profiled", "value": "10"}, {"label": "SMI links", "value": "Gold East, Gold Huasheng, Nine Dragons Beihai, Zhefeng, Asia Symbol Rugao, Sun Paper Yanzhou"}], "files": ["seed_20261014g_china_mills_fillers", "fix_20261014h_cn_wuzhou_mill"]}$cm$::jsonb),
  ('ID', $cm$Indonesia$cm$, 'high', $cm$APP and APRIL dominate - SMI JV PCC at Indah Kiat$cm$, $cm$Indonesia is concentrated in APP (Sinar Mas) and APRIL. SMI runs a JV PCC plant at Indah Kiat Perawang, and Omya announced an on-site GCC plant in Sumatra in 2023.$cm$,
   $cm${"fillers": "SMI JV (Sinar Mas) at Indah Kiat Perawang, Omya Indonesia, Dwi Selo Giri Mas, Aneka Sumberbumi Jaya (120 kt GCC), Supersonic Chemical.", "mills": "Indah Kiat Perawang, APRIL Kerinci, Pindo Deli, Tjiwi Kimia, Pura Barutama.", "strategy": "Two groups decide most volume - approach APP and APRIL technical HQs. Indonesian mills also supply Timor-Leste and PNG.", "risks": "Concentrated buyers with strong in-house capability.", "next_steps": ["Confirm SMI JV volumes at Perawang"], "key_numbers": [{"label": "Mills profiled", "value": "9"}, {"label": "Big lines", "value": "APRIL Kerinci PaperOne 1.15 Mt, BoardOne 1.2 Mt"}], "files": ["seed_20261014i_indonesia_mills_fillers", "fix_20261014j_id_missing_mills"]}$cm$::jsonb),
  ('MY', $cm$Malaysia$cm$, 'medium', $cm$Tissue and board market - local GCC, Schaefer Kalk PCC$cm$, $cm$Malaysia is mainly tissue, board and packaging. Local wet-grinding GCC (MRC) and a Schaefer Kalk PCC plant exist. Sabah Forest Industries is closed.$cm$,
   $cm${"fillers": "MRC Industries (Perak wet grinding), Schaefer Kalk Malaysia (PCC), Omya Malaysia, Imerys, RCI Lime, Zantat (GCC, imports PCC).", "mills": "NTPM (21 machines, tissue), Kimberly-Clark Kluang, GS Paperboard, Muda, Lee and Man, Nine Dragons Malaysia.", "strategy": "Tissue track first (NTPM direct comparison with MBG 15 gsm trial).", "risks": "Recycled-fibre packaging dominates volume.", "next_steps": ["Tissue trial proposal to NTPM"], "key_numbers": [{"label": "Mills profiled", "value": "6 priority"}, {"label": "Closed", "value": "SFI Sipitang, Pascorp 2025-08"}], "files": ["seed_20261014k_malaysia_mills_fillers", "fix_20261014l_my_muda_plant"]}$cm$::jsonb),
  ('VN', $cm$Vietnam$cm$, 'medium', $cm$Growing GCC exporter with mid-size printing and tissue mills$cm$, $cm$Vietnam has many GCC grinders (VMPC, YBM, EAMC) exporting across the region and mid-size printing and tissue mills. Packaging capacity is large and foreign-owned.$cm$,
   $cm${"fillers": "VMPC, YBM, EAMC, Tan Ky, ACBM, Mien Trung, Nimex, Phu Thanh Dat (PCC).", "mills": "An Hoa (140 kt copy and printing), Bai Bang VINAPACO, Saigon Paper, New Toyo Pulppy. Packaging: Vina Kraft, Cheng Loong, Lee and Man, Nine Dragons.", "strategy": "An Hoa is the scenario mill. Vietnamese GCC makers also supply Bangladesh and PNG.", "risks": "Packaging-heavy capacity.", "next_steps": ["Contact VMPC as a regional GCC partner"], "key_numbers": [{"label": "GCC makers", "value": "VMPC 300 kt, YBM about 1 Mt, EAMC 200 kt+"}, {"label": "Mills profiled", "value": "4 priority"}], "files": ["seed_20261014m_vietnam_mills_fillers"]}$cm$::jsonb),
  ('KR', $cm$Korea$cm$, 'high', $cm$Active account - 9,000 t/yr FCC commercial program at Moorim with Omya$cm$, $cm$Korea is MBG's home market and the first commercial FCC program: 9,000 t/yr at Moorim Paper with Omya as producer, under a three-party NDA.$cm$,
   $cm${"fillers": "Omya Korea (5 plants), Omya Hankook Chemical (Onsan PCC JV with Hankuk Paper), Taekyung Industrial, Taekyung BK (on-site PCC at Hansol Janghang), GMC.", "mills": "Moorim Jinju and Ulsan (active), Hansol Janghang, Hankuk Onsan, Hansol Cheonan, Shintanjin, Moorim SP, Kleannara, Samjung Pulp.", "strategy": "Execute the Moorim program, then Hansol and Hankuk. Check Omya NDA limits before involving Taekyung BK.", "risks": "Omya exclusivity terms. Second filler maker at Janghang.", "next_steps": ["Finish the three-party NDA with Moorim"], "key_numbers": [{"label": "Commercial program", "value": "9,000 t/yr FCC (target)"}, {"label": "Taekyung BK to Hansol Janghang", "value": "52,210 t in 2025"}], "files": ["seed_20261014n_korea_mills_fillers", "fix_20261014o_kr_notes_hansol"]}$cm$::jsonb),
  ('TW', $cm$Taiwan$cm$, 'medium', $cm$Local PCC and GCC makers, Chung Hwa Pulp is the printing-paper target$cm$, $cm$Taiwan has local PCC and GCC makers and a compact paper industry led by YFY (Chung Hwa Pulp), Cheng Loong and Longchen. Yuncheng Chemical stopped PCC output on 2026-07-31.$cm$,
   $cm${"fillers": "Lih Hsiang (PCC and GCC), Diamond Quantum DIACAL (paper PCC), An Jung, Chu Shin APEX (dry GCC), Tai Yang (oyster-shell PCC R and D).", "mills": "Chung Hwa Pulp Chiutang, Hualien, Taitung, Cheng Loong Chupei, YFY Qingshui tissue, Jih Sun, Kuan Yuan, Longchen Erlin.", "strategy": "Lead with Chung Hwa Pulp copy and uncoated lines, with Lih Hsiang or Diamond Quantum as local producer.", "risks": "No public mill-filler supply pairs.", "next_steps": ["Ask CHP for its current PCC and GCC supplier"], "key_numbers": [{"label": "Mills profiled", "value": "8"}, {"label": "Yuncheng exit", "value": "2026-07-31, customers passed to Diamond Quantum"}], "files": ["seed_20261014p_taiwan_mills_fillers"]}$cm$::jsonb),
  ('SA', $cm$Saudi Arabia$cm$, 'medium', $cm$Tissue and duplex board - no paper PCC plant$cm$, $cm$Saudi Arabia's paper industry is tissue (Saudi Paper, Juthor, Al-Faris), duplex board (Obeikan) and containerboard (MEPCO). Local GCC exists, no paper PCC plant.$cm$,
   $cm${"fillers": "Saudi Carbonate (Riyadh, about 200 kt GCC and PCC, Omya partner), Saudi Marble (Jeddah), Arabian Carbonate (to verify).", "mills": "Saudi Paper, Juthor (13.5-15.5 gsm virgin facial), Al-Faris, Obeikan, MEPCO, WARAQ.", "strategy": "Tissue first - Juthor is the closest match to the MBG 15 gsm trial. Regional hub for Kuwait and Yemen supply.", "risks": "Packaging dominates volume.", "next_steps": ["Tissue trial proposal to Juthor and Saudi Paper"], "key_numbers": [{"label": "Saudi Paper tissue", "value": "190 kt"}, {"label": "MEPCO", "value": "500 kt + PM5 450 kt in 2027"}], "files": ["seed_20261014q_saudi_mills_fillers"]}$cm$::jsonb),
  ('AE', $cm$United Arab Emirates$cm$, 'high', $cm$Ittihad Paper Mill with Omya on-site PCC - Gulf proof point$cm$, $cm$The UAE has the region's only large uncoated woodfree mill (Ittihad, 325 kt) with an Omya-technology on-site PCC plant, plus several tissue mills.$cm$,
   $cm${"fillers": "Omya (UAE) on-site PCC at Ittihad, GMI (Ajman PCC 15 kt), ECCF, Gulf Lime, Apex Chemical (Fujairah 200 kt GCC), Wasit.", "mills": "Ittihad, Crown, ADNPM, Star Paper, Al Nakheel (Fine), Queenex, Star KEZAD, Union Paper, Gulf Paper Dubai, Arabian Kraft.", "strategy": "Confirm Omya's role at the Ittihad PCC plant - it decides the licence counterparty. Then tissue in the same group (Crown).", "risks": "PCC plant owner and capacity not public.", "next_steps": ["Ask Omya HQ who owns and runs the Ittihad PCC plant"], "key_numbers": [{"label": "Ittihad", "value": "325 kt copy and printing"}, {"label": "Tissue mills", "value": "Crown 100 kt, ADNPM 90 kt+, Star 40 kt, Al Nakheel 60 kt"}], "files": ["seed_20261014r_uae_mills_fillers"]}$cm$::jsonb),
  ('MM', $cm$Myanmar$cm$, 'low', $cm$Second-tier market - recycled packaging and small tissue mills$cm$, $cm$Myanmar has 100+ registered mostly small recycled-fibre mills and no confirmed paper PCC maker. Power, foreign exchange and logistics are hard.$cm$,
   $cm${"fillers": "Crown Calcium Carbonate (running status to confirm).", "mills": "New Century, YDE (new 50 t line), Star Flower, KKN Tissue, Yeni, Nilar (R and D), Thabaung (only if restarted).", "strategy": "Low effort - use MPPIA to get a list of running mills.", "risks": "Operating environment, payment and power risk.", "next_steps": ["Ask MPPIA for running mills and filler suppliers"], "key_numbers": [{"label": "Registered mills", "value": "100+ (not all running)"}, {"label": "New Century", "value": "5,000 t/month packaging"}], "files": ["seed_20261014s_myanmar_mills_fillers"]}$cm$::jsonb),
  ('BD', $cm$Bangladesh$cm$, 'medium', $cm$Bashundhara makes its own PCC and wet GCC - imported-pulp mills want savings$cm$, $cm$Bangladesh has fine-paper mills running on imported pulp (Bashundhara, Meghna) and local PCC makers, but the industry is in a downturn with 70-80 mills reported stopped.$cm$,
   $cm${"fillers": "SMI (Bashundhara Meghnaghat satellite, 2007 agreement), BBCL (PCC), Crescent Chemical, ASM Chemical (paper GCC spec), Unirex (PCC plant 2027).", "mills": "Bashundhara Multi-Paper (own PCC and WGCC), Meghna, Partex Tissue, Lipy, Pearl, Sonali, Akij, Partex Paper.", "strategy": "Bashundhara first - production and use in one group. Use existing PCC and GCC plants, not a new FCC plant.", "risks": "Industry downturn and foreign-exchange shortage.", "next_steps": ["Confirm whether the SMI Meghnaghat satellite still runs"], "key_numbers": [{"label": "Meghna", "value": "printing 300 t/day, tissue 100 t/day"}, {"label": "Stopped mills", "value": "70-80 (industry claim 2025-26)"}], "files": ["seed_20261014t_bangladesh_mills_fillers"]}$cm$::jsonb),
  ('PK', $cm$Pakistan$cm$, 'medium', $cm$OmyaPack JV next to Bulleh Shah - IP boundary with Omya needed$cm$, $cm$Pakistan's key fact is OmyaPack, a 50:50 Omya-Packages JV in Kasur in the same group as Bulleh Shah, the largest wood-pulp copy-paper maker. Local PCC (Asian Chemicals) and GCC (Shaheen) exist.$cm$,
   $cm${"fillers": "OmyaPack, Asian Chemicals (PCC since 1981), Shaheen Grinding Mills (170 kt, liquid GCC), Shaheen Carbonates (supplies Empire and Fazal), Asian Polymer, Omar Group, Salamat.", "mills": "Bulleh Shah, Premier (25 kt), Century (280 kt board), Flying Board, Rose Petal tissue.", "strategy": "Go through Packages Group aligned with Omya HQ. Premier as a small first proof.", "risks": "Price-sensitive market. Omya is both licensee and JV owner - set the FCC IP boundary first.", "next_steps": ["Agree with Omya HQ how OmyaPack fits the licence"], "key_numbers": [{"label": "Bulleh Shah", "value": "360 kt installed, 266 kt in 2025"}, {"label": "OmyaPack 2025 revenue", "value": "about PKR 2.6bn"}], "files": ["seed_20261014u_pakistan_mills_fillers"]}$cm$::jsonb),
  ('AF', $cm$Afghanistan$cm$, 'low', $cm$Long-term only - one real paper mill, no paper filler maker$cm$, $cm$Afghanistan has marble powder but no paper-grade PCC or GCC, and one mill with its own machine (Baheer). Several A4 brands only sheet imported rolls.$cm$,
   $cm${"fillers": "Afghan Morvarid (marble powder, paper grade unconfirmed).", "mills": "Baheer Group, Paktia Paper, Rahim Gardizi (likely converters), Wazirson (imports PaperOne rolls).", "strategy": "Monitor only.", "risks": "Operating environment.", "next_steps": [], "key_numbers": [{"label": "Baheer", "value": "55 kt announced 2022"}], "files": ["seed_20261014v_afghanistan_mills_fillers"]}$cm$::jsonb),
  ('IR', $cm$Iran$cm$, 'on_hold', $cm$ON HOLD - US sanctions. Record only.$cm$, $cm$Iran has local PCC and GCC makers, a printing-paper base (Mazandaran) and large tissue mills, but US sanctions (OFAC) apply. MBG is a US company - no contact, NDA, samples, licence or royalty until a sanctions lawyer clears it.$cm$,
   $cm${"fillers": "Chemie Ma-Dani Hamadan, Pars Hasti Asia, Arman Powder, Arosha, MAD KOOHZAD, Farayand, Arya Powder Pars.", "mills": "Mazandaran, Pars Paper, Dibaye Shushtar, Zarrin Barg, Pars Hayat, Latif, Harir, Golpoune, Aryan Cellulose.", "strategy": "None until cleared.", "risks": "US sanctions. Iranian mills must stay out of marketing campaigns.", "next_steps": ["Add a sanctioned-country block to the marketing segment"], "key_numbers": [{"label": "Mazandaran", "value": "175-185 kt"}, {"label": "Zarrin Barg tissue", "value": "120 kt"}], "files": ["seed_20261014w_iran_mills_fillers"]}$cm$::jsonb),
  ('LB', $cm$Lebanon$cm$, 'low', $cm$Tissue and recycled board - INDEVCO is the regional entry$cm$, $cm$Lebanon makes tissue (Unipak, MIMOSA) and recycled board (SICOMO, Solicar, SIPCO). No paper PCC plant.$cm$,
   $cm${"fillers": "Lebanese Calcium Carbonate (Amchit), Microfillers (Al Koura).", "mills": "Unipak Tissue Mill (INDEVCO), MIMOSA, SICOMO, Solicar, SIPCO.", "strategy": "Approach INDEVCO Paper Making centrally - Lebanon, Egypt and Greece.", "risks": "Small volumes.", "next_steps": ["Contact INDEVCO Paper Making"], "key_numbers": [{"label": "Unipak PM1", "value": "22 kt"}, {"label": "MIMOSA", "value": "15 kt"}], "files": ["seed_20261014x_lebanon_mills_fillers"]}$cm$::jsonb),
  ('IL', $cm$Israel$cm$, 'low', $cm$PCC history ended with Hadera's printing paper - tissue and containerboard now$cm$, $cm$SMI (1996-2006) and then Omya Shefaya (2005-2020) supplied PCC to Hadera Paper, which left white printing paper in 2019. Today the market is tissue and recycled containerboard.$cm$,
   $cm${"fillers": "Omya Shefaya, Specialty Minerals Israel (closed 2006), Negev Industrial Minerals.", "mills": "Shaniv, Panda (Sano), Kimberly-Clark Israel, Infinya, Snir.", "strategy": "Tissue first. Kimberly-Clark Israel links to Arbex and the Kluang mill.", "risks": "No white-paper filler demand left.", "next_steps": [], "key_numbers": [{"label": "Infinya", "value": "320 kt containerboard"}, {"label": "Shaniv", "value": "35 kt+ tissue"}], "files": ["seed_20261014y_israel_mills_fillers"]}$cm$::jsonb),
  ('JO', $cm$Jordan$cm$, 'medium', $cm$GCC export base - tissue mills Sanabel and Fine$cm$, $cm$Jordan is a GCC producer and exporter (Manaseer, GCCI, Jordan Minerals) with tissue mills (Sanabel, Fine's Al Snobar and Al Keena).$cm$,
   $cm${"fillers": "Manaseer, GCCI (250 kt), Jordan Minerals (paper superfine grades), Jordan Carbonate (Omya JV 2006), Petra, ILCCMCo (PCC to verify).", "mills": "Sanabel Al Ataa, Al Snobar, Al Keena.", "strategy": "Jordan GCC makers as a regional FCC base for Saudi Arabia, UAE and Iraq. Approach Fine at group level with Al Nakheel (UAE).", "risks": "Check Jordan Carbonate's existing Omya terms.", "next_steps": [], "key_numbers": [{"label": "Manaseer", "value": "350 kt+ GCC"}, {"label": "Tissue", "value": "Sanabel 47 kt, Al Snobar 54 kt, Al Keena 30 kt"}], "files": ["seed_20261014z_jordan_mills_fillers"]}$cm$::jsonb),
  ('IQ', $cm$Iraq$cm$, 'low', $cm$New lines and state mill rebuilds - small today$cm$, $cm$Iraq has a new tissue mill (Al Sindyan), a planned 500 t/day packaging project (Al Shumookh) and state mills listed for rebuilding.$cm$,
   $cm${"fillers": "White Shield (GCC, PCC claimed), Noor Al Shams, Al Azm, Basmat Al-Haram.", "mills": "Al Sindyan, Al Shumookh, Basra and Maysan state mills.", "strategy": "Tissue trial at Al Sindyan. Screen parties against sanctions lists as normal.", "risks": "Single mid-size tissue mill gives a small royalty.", "next_steps": [], "key_numbers": [{"label": "Al Sindyan", "value": "65 t/day tissue"}, {"label": "Al Shumookh", "value": "500 t/day planned"}], "files": ["seed_20261014aa_iraq_mills_fillers"]}$cm$::jsonb),
  ('KW', $cm$Kuwait$cm$, 'low', $cm$One real mill - Gulf Paper$cm$, $cm$Kuwait has one sizeable paper mill (Gulf Paper, 50 kt packaging + 15 kt tissue) and no paper PCC maker.$cm$,
   $cm${"fillers": "KDF (drilling-grade GCC), NICBM lime.", "mills": "Gulf Paper Manufacturing, United Paper Industries (pulp - machine to confirm).", "strategy": "Serve as part of a Gulf region supplied by Saudi or UAE filler bases.", "risks": "Small market.", "next_steps": [], "key_numbers": [{"label": "Gulf Paper", "value": "65-70 kt"}], "files": ["seed_20261014ab_kuwait_mills_fillers"]}$cm$::jsonb),
  ('YE', $cm$Yemen$cm$, 'on_hold', $cm$Record only - screen against OFAC before any contact$cm$, $cm$No paper filler maker and no confirmed paper machine. The Houthis (Ansar Allah), who control Sana'a and parts of Taiz, are US-designated.$cm$,
   $cm${"fillers": "None.", "mills": "NCSPI (HSA), Al-Ganad (likely converters).", "strategy": "None until screened.", "risks": "Sanctions and conflict.", "next_steps": ["Consider adding to the sanctioned-country marketing block"], "key_numbers": [{"label": "CaCO3 imports 2023", "value": "13,425 t (69 pct Jordan)"}], "files": ["seed_20261014ac_yemen_mills"]}$cm$::jsonb),
  ('OM', $cm$Oman$cm$, 'low', $cm$Recycled containerboard plus GCC export base$cm$, $cm$Oman's paper is recycled containerboard (Keryas 180 kt) and its strength is GCC (IMC Sohar 120 kt).$cm$,
   $cm${"fillers": "IMC (Northern Minerals), GMMC, SAC, ALTAIF (planned), Al Jood.", "mills": "Keryas, Oman Royal Paper.", "strategy": "Pair IMC with Keryas in Sohar. Oman GCC as an export base for UAE and Saudi Arabia.", "risks": "Packaging grades need strength data.", "next_steps": [], "key_numbers": [{"label": "Keryas", "value": "180 kt nameplate, about 100 kt in 2022"}], "files": ["seed_20261014ad_oman_mills_fillers"]}$cm$::jsonb),
  ('LK', $cm$Sri Lanka$cm$, 'low', $cm$Proof market for printing paper and tissue$cm$, $cm$Sri Lanka has small mills (National Paper, Nalaka tissue) and an ultrafine GCC maker (LANMIC). Volumes are small - value is technical proof.$cm$,
   $cm${"fillers": "LANMIC (ultrafine GCC), Quality Chemicals (PCC claimed), Unitum, Promark, Lanka Phosphate PCC proposal.", "mills": "National Paper Valaichchenai, Nalaka Tissue, Nithya, KSPA Embilipitiya.", "strategy": "Printing and tissue trials with LANMIC as filler partner.", "risks": "Tiny royalty.", "next_steps": [], "key_numbers": [{"label": "4 mills combined", "value": "about 1,850 t FCC even at full adoption"}], "files": ["seed_20261014ae_srilanka_mills_fillers"]}$cm$::jsonb),
  ('BT', $cm$Bhutan$cm$, 'low', $cm$Limestone source only$cm$, $cm$No paper filler maker and one recycled kraft mill short of waste paper. At most a raw-material source for northeast India.$cm$,
   $cm${"fillers": "Nortak, RSA Limestone, Jigme Flux.", "mills": "Eco-Tech Bhutan.", "strategy": "No business-development effort now.", "risks": "Very small market.", "next_steps": [], "key_numbers": [], "files": ["seed_20261014af_bhutan_mills_fillers"]}$cm$::jsonb),
  ('NP', $cm$Nepal$cm$, 'low', $cm$Small printing-paper mills replacing imports - NPPI has its own PCC plant$cm$, $cm$Nepal imports about 50 kt/yr of writing and printing paper and new mills are replacing it. Nepal Pulp and Paper (IME) has a PCC plant inside the mill.$cm$,
   $cm${"fillers": "Shakti Minerals (feed-grade limestone).", "mills": "Nepal Pulp and Paper, Durga, Reliance, Everest.", "strategy": "Find who built the NPPI PCC plant - possible route to other countries.", "risks": "Small volumes, recycled and agro fibre.", "next_steps": [], "key_numbers": [{"label": "NPPI", "value": "75 t/day, 150 t/day planned"}], "files": ["seed_20261014ag_nepal_mills_fillers"]}$cm$::jsonb),
  ('NZ', $cm$New Zealand$cm$, 'low', $cm$Most capacity closed - Whakatane board and Essity tissue remain$cm$, $cm$Most NZ paper capacity has closed. Whakatane (150 kt boxboard) and Essity Kawerau (55 kt tissue) remain. Omya grinds GCC at Te Kuiti.$cm$,
   $cm${"fillers": "Omya New Zealand (Te Kuiti), Graymont.", "mills": "Whakatane Mill, Essity Kawerau.", "strategy": "Approach Oji at group level, Opal through Australia.", "risks": "Shrinking base.", "next_steps": [], "key_numbers": [{"label": "Remaining FCC base", "value": "about 205 kt"}], "files": ["seed_20261014ah_newzealand_mills_fillers"]}$cm$::jsonb),
  ('PG', $cm$Papua New Guinea$cm$, 'low', $cm$Import-dependent - trace exporters$cm$, $cm$PNG imports most paper. Tissue makers may only convert. Better route: Indonesian, Malaysian and Chinese mills that ship to PNG.$cm$,
   $cm${"fillers": "Bayawaha (99.8 pct CaCO3, feed grade), Pacific Lime and Cement (quicklime project 2027).", "mills": "KK Kingston, Star Mountain, Niugini Paper.", "strategy": "Confirm KK Kingston's machine still runs.", "risks": "No confirmed paper machine.", "next_steps": [], "key_numbers": [], "files": ["seed_20261014ai_png_mills_fillers"]}$cm$::jsonb),
  ('TL', $cm$Timor-Leste$cm$, 'none', $cm$No mills and no paper filler makers$cm$, $cm$No paper mill and no paper-grade PCC or GCC. Paper is imported, about 95 pct of Indonesia and China.$cm$,
   $cm${"fillers": "None (TL Cement is a cement project).", "mills": "None - printers and converters only.", "strategy": "Review only if a mill or filler plant is announced.", "risks": "", "next_steps": [], "key_numbers": [], "files": ["handoff_20261015a_timorleste_no_rows"]}$cm$::jsonb),
  ('BN', $cm$Brunei$cm$, 'low', $cm$One small recycled tissue mill$cm$, $cm$No paper filler maker. EnEvo makes recycled tissue on its own machine (about 2 t/day). 79 pct of paper imports come of Malaysia and China.$cm$,
   $cm${"fillers": "None (Heidelberg 'PCC 52.5N' is cement).", "mills": "EnEvo.", "strategy": "Recycled-tissue proof only.", "risks": "Tiny volumes.", "next_steps": [], "key_numbers": [], "files": ["seed_20261015b_brunei_mill"]}$cm$::jsonb),
  ('KH', $cm$Cambodia$cm$, 'low', $cm$Converter market - one 120 kt project$cm$, $cm$Most Cambodian paper firms convert imports. Rongwei's 120 kt packaging project is the only new paper machine. Imports were USD 738m in 2024.$cm$,
   $cm${"fillers": "KPTT-Investment (industrial limestone powder).", "mills": "Rongwei, Sary Paper, Dynith.", "strategy": "Target the Vietnamese and Thai mills that export to Cambodia.", "risks": "Start-up not confirmed.", "next_steps": [], "key_numbers": [{"label": "Rongwei", "value": "120 kt design"}, {"label": "Imports 2024", "value": "USD 738m (China 52 pct, Vietnam 26 pct)"}], "files": ["seed_20261015c_cambodia_mills_fillers"]}$cm$::jsonb),
  ('LA', $cm$Laos$cm$, 'medium', $cm$Sun Paper Laos 800 kt packaging - approach via Sun Paper group$cm$, $cm$Laos is dominated by Sun Paper (800 kt packaging plus pulp). MCS makes GCC and lime in Khammouane.$cm$,
   $cm${"fillers": "MCS Mining Industry Lao, Viet Lao Stone (plant under construction), Dong Nhan Stone Laos plant.", "mills": "Sun Paper Laos, Khamhung, Asia Paper Mill.", "strategy": "Handle with the Sun Paper group account (Yanzhou). MCS as regional GCC partner with Thai links.", "risks": "Packaging grades - strength data first.", "next_steps": [], "key_numbers": [{"label": "Sun Paper Laos", "value": "800 kt paper + 700 kt pulp"}], "files": ["seed_20261015d_laos_mills_fillers"]}$cm$::jsonb),
  ('AU', $cm$Australia$cm$, 'medium', $cm$Boyer copy paper and tissue are the direct targets$cm$, $cm$Australian white-paper filler demand fell when Maryvale stopped white paper in 2023. Boyer (260 kt printing grades, copy paper 2026) and tissue mills are the direct targets. Omya grinds GCC at Bathurst.$cm$,
   $cm${"fillers": "Omya Australia (Bathurst, historical Geelong wet GCC), Imerys Burnie (historical).", "mills": "Boyer, ABC Tissue, Arbex Millicent, Solaris Paper, Visy Tumut, Opal Botany.", "strategy": "Boyer with Omya Australia, then tissue. Arbex and Solaris (APP) open other countries.", "risks": "Packaging majors need strength-proven FCC.", "next_steps": [], "key_numbers": [{"label": "Boyer", "value": "260 kt"}, {"label": "Visy", "value": "about 1.44 Mt packaging"}, {"label": "Opal Botany", "value": "420 kt"}], "files": ["seed_20261015e_australia_mills_fillers"]}$cm$::jsonb),
  ('PH', $cm$Philippines$cm$, 'medium', $cm$Printing and tissue mills under import pressure$cm$, $cm$Philippine capacity is 1.65 Mt but 1.32 Mt is packaging. About 250 kt printing and 50 kt tissue are the direct targets. Utilization fell to 56 pct in 2023.$cm$,
   $cm${"fillers": "Omya Mineral Philippines (GCC), Philstone, Kingstone, South Pacific Chemical (PCC listed), Busilak.", "mills": "Bataan 2020, Quanta Paper, TIPCO, Fifth Discipline, UPPC (SCGP).", "strategy": "Bataan 2020 and Quanta first with Omya Philippines.", "risks": "Import competition.", "next_steps": ["Research Alliance, Hansson, Rural, Vanson, Fedco printing mills"], "key_numbers": [{"label": "Capacity", "value": "1.65 Mt (22 mills)"}, {"label": "Utilization 2023", "value": "56 pct"}], "files": ["seed_20261015f_philippines_mills_fillers"]}$cm$::jsonb)
) as v(country_code, country_name, priority, headline, summary, sections)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name,
      priority     = excluded.priority,
      headline     = excluded.headline,
      summary      = excluded.summary,
      sections     = excluded.sections,
      checked_at   = excluded.checked_at,
      updated_at   = now();

select cm.country_code, cm.country_name, cm.priority,
       count(*) filter (where t.code = 'paper_mill')      as mills_in_urm,
       count(*) filter (where t.code = 'filler_supplier') as fillers_in_urm
from app.country_markets cm
left join app.parties p
  on p.country_code = cm.country_code and p.deleted_at is null
left join app.party_types t
  on t.id = p.party_type_id and t.code in ('paper_mill', 'filler_supplier')
where cm.deleted_at is null
group by cm.country_code, cm.country_name, cm.priority
order by case cm.priority when 'high' then 1 when 'medium' then 2 when 'low' then 3 when 'on_hold' then 4 else 5 end,
         cm.country_code;
