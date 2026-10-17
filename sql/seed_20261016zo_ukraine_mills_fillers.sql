-- ============================================================
-- seed_20261016zo_ukraine_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Ukraine update (reports 2026-10-16). Every memo carries a war-risk note.
-- Occupied-area firms (Luhansk) not added - sanctions.
-- 1) Fillers if missing (3): NEOCARB (Renta-Prim), South Trade, Ekokarbo.
-- 2) Mills if missing (7) + plant blocks, priority 1-6: Kyiv CPM, Kokhavynska,
--    VGP, Zhytomyr Cardboard, Poninka, Lutsk Carton and Paper, plus Weidmann
--    Malyn (no priority). Context (3): Carton and Paper Company, Trypil,
--    Slovianski Shpalery.
-- 3) app.country_markets UA row (priority medium).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 1) FILLER ROWS IF MISSING ----------
    insert into app.parties
      (party_type_id, entity_type_id, party_name, country_code, region, city,
       website, status, source, intro_ko, intro_en, notes, organization_id)
    select 3::smallint,
           coalesce((select x.entity_type_id from app.parties x
                     where x.party_type_id = 3 and x.deleted_at is null
                     order by x.created_at limit 1), 1)::smallint,
           v.party_name, 'UA', v.region, v.city, v.website, 'active', 'ukraine_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('neocarb|renta-?prim', 'NEOCARB (Renta-Prim) - Dnipro', 'Dnipropetrovsk', 'Dnipro', null, '우크라이나 제지용 GCC 제조사 Renta-Prim(NEOCARB) — 천연 대리석, CaCO3 99% 초과·백색도 98% 초과, 독일 분쇄 기술·시험실. 제지용 NEOCARB Ultra·90·85·75·1~5 공식 판매.', 'LLC Renta-Prim (brand NEOCARB), 147 Bohdana Khmelnytskoho Ave, Dnipro - high-purity micronised GCC and microcalcite of natural marble (over 99 pct CaCO3, brightness over 98) on German grinding technology with own lab. Paper grades sold: NEOCARB Ultra, 90, 85, 75, 1, 2, 3, 4, 5 (coated and uncoated).', 'UA check 2026-10-16: PSD, capacity and wet slurry not public. info@neocarb.com.ua, +380 67 829 91 45. FCC partner candidate 1. War risk - check site status, power and logistics before any trial.'),
  ('south trade', 'South Trade LTD', null, null, null, '백악·탄산칼슘 위탁 분쇄(파쇄·건조·분쇄), 소량 시험~산업 물량.', 'SOUTH TRADE LTD LLC - toll crushing, drying and grinding of chalk and calcium carbonate, pilot to industrial lots.', 'UA check 2026-10-16: no wet ultrafine or paper slurry confirmed. War risk - check site status, power and logistics before any trial.'),
  ('ekokarbo|екокарбо', 'Ekokarbo', null, null, null, '천연 대리석·백운석·마이크로칼사이트·석회석·탄산칼슘 수입·가공·공급.', 'Ekokarbo - import, selection, processing and supply of marble, dolomite, microcalcite, limestone and calcium carbonate.', 'UA check 2026-10-16: paper grades not confirmed. Not added: Reaktiv Sloviansk and Slavyansk Soda Plant (PCC history in 2005 data, current status unknown), Vovchoiarivskyi Mining Plant (Luhansk region - occupied area, sanctions), Brenntag Ukraine (distributor). War risk - check site status, power and logistics before any trial.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%UA check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('neocarb|renta-?prim', 'NEOCARB (Renta-Prim) - Dnipro', 'Dnipropetrovsk', 'Dnipro', null, '우크라이나 제지용 GCC 제조사 Renta-Prim(NEOCARB) — 천연 대리석, CaCO3 99% 초과·백색도 98% 초과, 독일 분쇄 기술·시험실. 제지용 NEOCARB Ultra·90·85·75·1~5 공식 판매.', 'LLC Renta-Prim (brand NEOCARB), 147 Bohdana Khmelnytskoho Ave, Dnipro - high-purity micronised GCC and microcalcite of natural marble (over 99 pct CaCO3, brightness over 98) on German grinding technology with own lab. Paper grades sold: NEOCARB Ultra, 90, 85, 75, 1, 2, 3, 4, 5 (coated and uncoated).', 'UA check 2026-10-16: PSD, capacity and wet slurry not public. info@neocarb.com.ua, +380 67 829 91 45. FCC partner candidate 1. War risk - check site status, power and logistics before any trial.'),
  ('south trade', 'South Trade LTD', null, null, null, '백악·탄산칼슘 위탁 분쇄(파쇄·건조·분쇄), 소량 시험~산업 물량.', 'SOUTH TRADE LTD LLC - toll crushing, drying and grinding of chalk and calcium carbonate, pilot to industrial lots.', 'UA check 2026-10-16: no wet ultrafine or paper slurry confirmed. War risk - check site status, power and logistics before any trial.'),
  ('ekokarbo|екокарбо', 'Ekokarbo', null, null, null, '천연 대리석·백운석·마이크로칼사이트·석회석·탄산칼슘 수입·가공·공급.', 'Ekokarbo - import, selection, processing and supply of marble, dolomite, microcalcite, limestone and calcium carbonate.', 'UA check 2026-10-16: paper grades not confirmed. Not added: Reaktiv Sloviansk and Slavyansk Soda Plant (PCC history in 2005 data, current status unknown), Vovchoiarivskyi Mining Plant (Luhansk region - occupied area, sanctions), Brenntag Ukraine (distributor). War risk - check site status, power and logistics before any trial.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'ukraine_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('NEOCARB (Renta-Prim) - Dnipro', 'GCC producer', 'Paper-grade GCC - FCC partner candidate 1', 'merchant', 'B', 'gcc'),
  ('South Trade LTD', 'GCC producer', 'Toll grinder - pretreatment partner', 'merchant', 'C', 'gcc'),
  ('Ekokarbo', 'GCC supplier', 'Carbonate importer and processor', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'ukraine_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'UA', v.region, v.city, v.website, 'active', 'ukraine_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('kyiv cardboard|ки[їi]вськ[ии]й картонно|\mkcpm\M|kyiv cpm', 'obukhiv|обух', 'kyiv|ки[їi]в|pulp mill holding', 'Kyiv Cardboard and Paper Mill - Obukhiv', 'Kyiv Oblast', 'Obukhiv', null, '1982년부터 운영, 오스트리아 Pulp Mill Holding 소속 종합 제지(130 Kyivska St, Obukhiv). 위생용지(Obukhiv 65·Dyvo), 코팅·비코팅 판지, 골판지, 성형 펄프. 2025 매출 약 80.6억 UAH, 전쟁 중 무중단.', 'PJSC Kyiv Cardboard and Paper Mill (Pulp Mill Holding, Austria, running since 1982), 130 Kyivska St, Obukhiv (Kyiv Oblast) - tissue (Obukhiv 65, Dyvo), towels, napkins, coated and uncoated board, bag paper, corrugated packaging, moulded-pulp egg trays. 2025 sales about UAH 8.06 bn, did not stop production since 2022.', 'UA check 2026-10-16: machine capacities not public. War risk - check site status, power and logistics before any trial.'),
  ('kokhavyn|кохавин', 'hnizdych|гнізди', 'kokhavyn|кохавин', 'Kokhavynska Paper Factory - Hnizdychiv', 'Lviv Oblast', 'Hnizdychiv', null, 'Lviv 주 Hnizdychiv 위생용지 공장 — 화장지·위생용지·종이타월, 재생원료 처리 일 약 135 t(과거 자료), 2024 매출 상위 10. EBRD 지원·신규 공장 2,800만 유로 계획.', 'JSC Kokhavynska Paper Factory, Hnizdychiv (Lviv Oblast) - toilet tissue and towels mainly on recycled fibre (about 135 t/day recovered paper processed, older company data), top-10 Ukrainian paper company by 2024 sales, EBRD-supported, EUR 28 m new shop announced.', 'UA check 2026-10-16: 135 t/day is input, not output. War risk - check site status, power and logistics before any trial.'),
  ('\mvgp\M|\mruta\M', 'lutsk|луцьк', 'vgp|ruta|вгп', 'VGP (Ruta) - Lutsk', 'Volyn Oblast', 'Lutsk', null, 'Lutsk 위생용지 기업 VGP(Ruta) — 화장지·냅킨·키친타월, 23개국 수출, Gambini 신규 라인, 2024 매출 상위 10.', 'PJSC VGP (brand Ruta), Lutsk (Volyn) - toilet tissue, napkins, kitchen towel, exports to 23 countries, new Gambini converting line, top-10 by 2024 sales.', 'UA check 2026-10-16: own base-paper machine to confirm. War risk - check site status, power and logistics before any trial.'),
  ('zhytomyr cardboard|житомирськ[ии]й картонн', 'zhytomyr|житомир', 'zhytomyr|житомир', 'Zhytomyr Cardboard Factory - Zhytomyr', 'Zhytomyr Oblast', 'Zhytomyr', null, '2005년 설립(7 Stanyshivskyi Sq) 재생 판지·골판지 포장·계란 성형 펄프.', 'LLC Zhytomyr Cardboard Factory (2005, EDRPOU 33644098), 7 Stanyshivskyi Square, Zhytomyr - recycled board, corrugated packaging, moulded-pulp egg trays.', 'UA check 2026-10-16: capacity not public. War risk - check site status, power and logistics before any trial.'),
  ('poninka|понінк', 'poninka|понінк', 'poninka|понінк', 'Poninka Carton and Paper Factory - Poninka', 'Khmelnytskyi Oblast', 'Poninka', null, '1787년부터 이어진 재생지 일관 공장(34 Peremohy St) — 종이·판지·골판지, 2020-08 월 약 8,000 t.', 'Poninka Carton and Paper Factory - Ukraine (papermaking since 1787), 34 Peremohy St, Poninka (Khmelnytskyi) - integrated recovered-paper supply, paper and board making and corrugated products, about 8,000 t paper and board in 2020-08.', 'UA check 2026-10-16: monthly figure is 2020 - not current. info@pkpf.com.ua, +380 67 311 10 40. War risk - check site status, power and logistics before any trial.'),
  ('lutsk carton|луцька картонно', 'lutsk|луцьк', 'lutsk carton|луцька картон', 'Lutsk Carton and Paper Factory - Lutsk', 'Volyn Oblast', 'Lutsk', null, 'Lutsk 판지·종이제품 공장.', 'Lutsk Carton and Paper Factory, Lutsk (Volyn) - board and paper products.', 'UA check 2026-10-16: machine and output not public. War risk - check site status, power and logistics before any trial.'),
  ('weidmann.*malyn|malyn paper|малинськ', 'malyn|малин', 'weidmann|malyn', 'Weidmann Malyn Paper Mill - Malyn', 'Zhytomyr Oblast', 'Malyn', null, 'Weidmann(1999 인수) Malyn 전기절연지·변압기 절연판지·산업용 특수지, 2025 매출 약 26.4억 UAH.', 'Weidmann Malyn Paper Mill (Weidmann, Switzerland, since 1999), 66 Prykhodka St, Malyn (Zhytomyr) - electrical insulation paper, transformer pressboard, technical specialty paper. 2025 sales about UAH 2.64 bn.', 'UA check 2026-10-16: insulation grades do not suit carbonate filler. War risk - check site status, power and logistics before any trial.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%UA check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kyiv cardboard|ки[їi]вськ[ии]й картонно|\mkcpm\M|kyiv cpm', 'obukhiv|обух', 'kyiv|ки[їi]в|pulp mill holding', '1982년부터 운영, 오스트리아 Pulp Mill Holding 소속 종합 제지(130 Kyivska St, Obukhiv). 위생용지(Obukhiv 65·Dyvo), 코팅·비코팅 판지, 골판지, 성형 펄프. 2025 매출 약 80.6억 UAH, 전쟁 중 무중단.', 'PJSC Kyiv Cardboard and Paper Mill (Pulp Mill Holding, Austria, running since 1982), 130 Kyivska St, Obukhiv (Kyiv Oblast) - tissue (Obukhiv 65, Dyvo), towels, napkins, coated and uncoated board, bag paper, corrugated packaging, moulded-pulp egg trays. 2025 sales about UAH 8.06 bn, did not stop production since 2022.', 'UA check 2026-10-16: machine capacities not public. War risk - check site status, power and logistics before any trial.'),
  ('kokhavyn|кохавин', 'hnizdych|гнізди', 'kokhavyn|кохавин', 'Lviv 주 Hnizdychiv 위생용지 공장 — 화장지·위생용지·종이타월, 재생원료 처리 일 약 135 t(과거 자료), 2024 매출 상위 10. EBRD 지원·신규 공장 2,800만 유로 계획.', 'JSC Kokhavynska Paper Factory, Hnizdychiv (Lviv Oblast) - toilet tissue and towels mainly on recycled fibre (about 135 t/day recovered paper processed, older company data), top-10 Ukrainian paper company by 2024 sales, EBRD-supported, EUR 28 m new shop announced.', 'UA check 2026-10-16: 135 t/day is input, not output. War risk - check site status, power and logistics before any trial.'),
  ('\mvgp\M|\mruta\M', 'lutsk|луцьк', 'vgp|ruta|вгп', 'Lutsk 위생용지 기업 VGP(Ruta) — 화장지·냅킨·키친타월, 23개국 수출, Gambini 신규 라인, 2024 매출 상위 10.', 'PJSC VGP (brand Ruta), Lutsk (Volyn) - toilet tissue, napkins, kitchen towel, exports to 23 countries, new Gambini converting line, top-10 by 2024 sales.', 'UA check 2026-10-16: own base-paper machine to confirm. War risk - check site status, power and logistics before any trial.'),
  ('zhytomyr cardboard|житомирськ[ии]й картонн', 'zhytomyr|житомир', 'zhytomyr|житомир', '2005년 설립(7 Stanyshivskyi Sq) 재생 판지·골판지 포장·계란 성형 펄프.', 'LLC Zhytomyr Cardboard Factory (2005, EDRPOU 33644098), 7 Stanyshivskyi Square, Zhytomyr - recycled board, corrugated packaging, moulded-pulp egg trays.', 'UA check 2026-10-16: capacity not public. War risk - check site status, power and logistics before any trial.'),
  ('poninka|понінк', 'poninka|понінк', 'poninka|понінк', '1787년부터 이어진 재생지 일관 공장(34 Peremohy St) — 종이·판지·골판지, 2020-08 월 약 8,000 t.', 'Poninka Carton and Paper Factory - Ukraine (papermaking since 1787), 34 Peremohy St, Poninka (Khmelnytskyi) - integrated recovered-paper supply, paper and board making and corrugated products, about 8,000 t paper and board in 2020-08.', 'UA check 2026-10-16: monthly figure is 2020 - not current. info@pkpf.com.ua, +380 67 311 10 40. War risk - check site status, power and logistics before any trial.'),
  ('lutsk carton|луцька картонно', 'lutsk|луцьк', 'lutsk carton|луцька картон', 'Lutsk 판지·종이제품 공장.', 'Lutsk Carton and Paper Factory, Lutsk (Volyn) - board and paper products.', 'UA check 2026-10-16: machine and output not public. War risk - check site status, power and logistics before any trial.'),
  ('weidmann.*malyn|malyn paper|малинськ', 'malyn|малин', 'weidmann|malyn', 'Weidmann(1999 인수) Malyn 전기절연지·변압기 절연판지·산업용 특수지, 2025 매출 약 26.4억 UAH.', 'Weidmann Malyn Paper Mill (Weidmann, Switzerland, since 1999), 66 Prykhodka St, Malyn (Zhytomyr) - electrical insulation paper, transformer pressboard, technical specialty paper. 2025 sales about UAH 2.64 bn.', 'UA check 2026-10-16: insulation grades do not suit carbonate filler. War risk - check site status, power and logistics before any trial.'),
  ('carton and paper company', null, 'carton and paper company', null, null, 'UA check 2026-10-16: Paper and board products - machine to confirm - context only. War risk - check site status, power and logistics before any trial.'),
  ('trypil|трипіл', null, 'trypil|трипіл', null, null, 'UA check 2026-10-16: Corrugated packaging, Kyiv - converter - context only. War risk - check site status, power and logistics before any trial.'),
  ('slovianski shpalery|слов.янські шпалери', null, 'slovianski shpalery|слов.янські шпалери', null, null, 'UA check 2026-10-16: Wallpaper, Koriukivka - base-paper making to confirm - context only. War risk - check site status, power and logistics before any trial.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'ukraine_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kyiv cardboard|ки[їi]вськ[ии]й картонно|\mkcpm\M|kyiv cpm', 'obukhiv|обух', 'kyiv|ки[їi]в|pulp mill holding'),
  ('kokhavyn|кохавин', 'hnizdych|гнізди', 'kokhavyn|кохавин'),
  ('\mvgp\M|\mruta\M', 'lutsk|луцьк', 'vgp|ruta|вгп'),
  ('zhytomyr cardboard|житомирськ[ии]й картонн', 'zhytomyr|житомир', 'zhytomyr|житомир'),
  ('poninka|понінк', 'poninka|понінк', 'poninka|понінк'),
  ('lutsk carton|луцька картонно', 'lutsk|луцьк', 'lutsk carton|луцька картон'),
  ('weidmann.*malyn|malyn paper|малинськ', 'malyn|малин', 'weidmann|malyn'),
  ('carton and paper company', null, 'carton and paper company'),
  ('trypil|трипіл', null, 'trypil|трипіл'),
  ('slovianski shpalery|слов.янські шпалери', null, 'slovianski shpalery|слов.янські шпалери')
      ) as v(name_rx, city_rx, owner_rx)
    ) m
    where m.id is not null
      and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);
    
update app.paper_mill_profile mp
    set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant', m.plant),
        main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
        updated_at = now()
    from (
      select v.plant, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kyiv cardboard|ки[їi]вськ[ии]й картонно|\mkcpm\M|kyiv cpm', 'obukhiv|обух', 'kyiv|ки[їi]в|pulp mill holding',
   $pj${"owner": "Pulp Mill Holding", "priority": 1, "products": "Tissue, coated and uncoated board, corrugated, moulded pulp", "grades": ["Tissue", "Coated board"], "pitch": "Tissue FCC 5 pct pilot plus a separate board trial", "approach": "Lead Ukrainian account - NEOCARB as local GCC.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kokhavyn|кохавин', 'hnizdych|гнізди', 'kokhavyn|кохавин',
   $pj${"owner": "Kokhavynska", "priority": 2, "products": "Toilet tissue, towels", "grades": ["Tissue"], "pitch": "Recycled tissue FCC 3-5 pct", "approach": "Second tissue account.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mvgp\M|\mruta\M', 'lutsk|луцьк', 'vgp|ruta|вгп',
   $pj${"owner": "VGP", "priority": 3, "products": "Toilet tissue, napkins, towels", "grades": ["Tissue"], "approach": "Confirm base-paper making first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('zhytomyr cardboard|житомирськ[ии]й картонн', 'zhytomyr|житомир', 'zhytomyr|житомир',
   $pj${"owner": "Zhytomyr Cardboard Factory", "priority": 4, "products": "Recycled board, corrugated, moulded pulp", "grades": ["Board", "Medium"], "approach": "Co-development - board strength and moulded pulp.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('poninka|понінк', 'poninka|понінк', 'poninka|понінк',
   $pj${"owner": "Poninka", "priority": 5, "products": "Recycled paper and board, corrugated", "grades": ["Testliner", "Medium"], "approach": "SCT, RCT, burst trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lutsk carton|луцька картонно', 'lutsk|луцьк', 'lutsk carton|луцька картон',
   $pj${"owner": "Lutsk Carton and Paper", "priority": 6, "products": "Board, paper products", "grades": ["Board"], "approach": "Collect machine data.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('weidmann.*malyn|malyn paper|малинськ', 'malyn|малин', 'weidmann|malyn',
   $pj${"owner": "Weidmann", "products": "Electrical insulation paper, pressboard", "grades": ["Specialty paper"], "approach": "No FCC fit except possible filter or packaging lines.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('carton and paper company', null, 'carton and paper company',
   $pj${"owner": "Carton and Paper Company (Lviv)", "products": "Paper and board products - machine to confirm", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('trypil|трипіл', null, 'trypil|трипіл',
   $pj${"owner": "Trypil Packaging Plant", "products": "Corrugated packaging, Kyiv - converter", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('slovianski shpalery|слов.янські шпалери', null, 'slovianski shpalery|слов.янські шпалери',
   $pj${"owner": "Slovianski Shpalery", "products": "Wallpaper, Koriukivka - base-paper making to confirm", "approach": "Converter or to confirm.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'UA', 'Ukraine', 'medium',
   $cm$Kyiv CPM tissue and board, Kokhavynska and VGP tissue - paper-grade GCC at NEOCARB (Dnipro) - war risk$cm$,
   $cm$Ukraine has a real tissue and board base: Kyiv Cardboard and Paper Mill (Obukhiv, tissue plus coated board, UAH 8.06 bn 2025, ran through the war), Kokhavynska (Lviv, recycled tissue), VGP Ruta (Lutsk tissue), Zhytomyr Cardboard, Poninka and Lutsk recycled board, Weidmann Malyn insulation paper. NEOCARB (Renta-Prim, Dnipro) sells paper-grade GCC (over 99 pct, brightness over 98). PCC was made at Reaktiv Sloviansk and Slavyansk Soda Plant in the past - status unknown. Occupied areas (Luhansk, parts of Donetsk) are sanctioned. War affects power, logistics and site access.$cm$,
   $cm${"fillers": "Paper GCC: NEOCARB (Renta-Prim, Dnipro). Toll grinding: South Trade. Importer and processor: Ekokarbo. Historical PCC: Reaktiv Sloviansk, Slavyansk Soda Plant. Not added: Vovchoiarivskyi (Luhansk, occupied), Brenntag.", "mills": "Tissue: Kyiv CPM Obukhiv, Kokhavynska, VGP Ruta. Board and recycled: Zhytomyr Cardboard, Poninka, Lutsk Carton and Paper. Specialty: Weidmann Malyn. Context: Carton and Paper Company Lviv, Trypil Packaging, Slovianski Shpalery.", "strategy": "Kyiv CPM tissue 5 pct pilot and board trial, then Kokhavynska, with NEOCARB as local GCC producer. Fibre saving is the main story - most mills run recycled fibre.", "risks": "War - power, logistics, site safety. Occupied-area sanctions. No current capacity data.", "next_steps": ["Contact Kyiv CPM technical", "Ask NEOCARB for PSD and wet capability"], "key_numbers": [{"label": "Kyiv CPM 2025 sales", "value": "about UAH 8.06 bn"}, {"label": "Weidmann Malyn 2025 sales", "value": "about UAH 2.64 bn"}], "files": ["seed_20261016zo_ukraine_mills_fillers"]}$cm$::jsonb,
   $cm$Kyiv CPM 티슈·판지, Kokhavynska·VGP 티슈 — NEOCARB(드니프로) 제지용 GCC — 전쟁 리스크$cm$,
   $cm$우크라이나 티슈·판지 기반: Kyiv CPM(Obukhiv, 티슈+코팅판지, 2025 매출 80.6억 UAH, 전쟁 중 무중단), Kokhavynska(재생 티슈), VGP Ruta(티슈), Zhytomyr·Poninka·Lutsk 재생 판지, Weidmann Malyn 절연지. NEOCARB(드니프로)가 제지용 GCC 판매(99%+, 백색도 98+). PCC 는 Reaktiv·Slavyansk Soda 과거 생산, 현재 미확인. 점령지역(루한스크 등)은 제재 대상. 전력·물류 리스크.$cm$,
   null, null,
   $cm$공장별 생산량 미공개 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('kyiv cardboard|ки[їi]вськ[ии]й картонно|\mkcpm\M|kyiv cpm', 'obukhiv|обух', 'kyiv|ки[їi]в|pulp mill holding'),
  ('kokhavyn|кохавин', 'hnizdych|гнізди', 'kokhavyn|кохавин'),
  ('\mvgp\M|\mruta\M', 'lutsk|луцьк', 'vgp|ruta|вгп'),
  ('zhytomyr cardboard|житомирськ[ии]й картонн', 'zhytomyr|житомир', 'zhytomyr|житомир'),
  ('poninka|понінк', 'poninka|понінк', 'poninka|понінк'),
  ('lutsk carton|луцька картонно', 'lutsk|луцьк', 'lutsk carton|луцька картон'),
  ('weidmann.*malyn|malyn paper|малинськ', 'malyn|малин', 'weidmann|malyn'),
  ('carton and paper company', null, 'carton and paper company'),
  ('trypil|трипіл', null, 'trypil|трипіл'),
  ('slovianski shpalery|слов.янські шпалери', null, 'slovianski shpalery|слов.янські шпалери')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'ukraine_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'ukraine_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'neocarb|renta-?prim' or p.party_name ~* 'south trade' or p.party_name ~* 'ekokarbo|екокарбо')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'UA'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'UA'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'UA'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UA'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    