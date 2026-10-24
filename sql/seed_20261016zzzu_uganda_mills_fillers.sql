-- ============================================================
-- seed_20261016zzzu_uganda_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Uganda update (reports 2026-10-17). Jinja and Njeru host several fillers
-- and mills - owner regex keeps them apart.
-- 1) Fillers if missing (3): A-One Investments, Gebal Minerals (incl.
--    African Minerals), Thompson Creek.
-- 2) Mills if missing (5) + plant blocks, priority 1-3: Global Paper
--    Products, Modern Laminates, EAPS. Uganda Pulp and Paper Mills and
--    Paper Toils no priority. Context (3).
-- 3) app.country_markets UG row (priority low).
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
           v.party_name, 'UG', v.region, v.city, v.website, 'active', 'uganda_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('a.?one invest', 'A-One Investments - Njeru', 'Buikwe', 'Njeru', null, 'A-One Investments(공장 Njeru, Kyaggwe Block 295 Plot 579·사무소 Jinja) 대리석·방해석 분쇄 Ultra White 활성 탄산칼슘 400~2,500 mesh, 백색도 97% 초과·Ca 93%(회사 발표), 종이 용도 명시.', 'A-One Investment Ltd, plant Plot 579 Kyaggwe Block 295, Njeru (Buikwe), office Vithaldas Road, Jinja - ground marble and calcite, Ultra White activated calcium carbonate 400-2,500 mesh, over 97 pct whiteness and 93 pct calcium claimed, paper named among uses.', 'UG check 2026-10-16: whiteness method unknown, ask for uncoated grade, D50 / D90, slurry and mill references. info@a-oneinvestments.com, +256 759 240 797. FCC co-production candidate 1 (near Modern Laminates and EAPS).'),
  ('gebal|african minerals limited|african minerals ltd', 'Gebal Minerals - Jinja', 'Jinja', 'Jinja', null, 'Gebal Minerals(2015, Nyanza Rd Jinja) 탄산칼슘 GC2~GC10·석회·카올린 — 제지·도료·플라스틱 충전제, Moroto 대리석·석회석(+케냐·이집트 원료), African Minerals Ltd 인수.', 'Gebal Minerals Limited (2015), Plot 7/9 Nyanza Road, Jinja - calcium carbonate GC2-GC10, lime, kaolin and mineral powders for paper, paint, plastics and ceramics, ore of Moroto (also Kenyan and Egyptian sources), took over African Minerals Ltd (BIO-financed carbonate and lime maker).', 'UG check 2026-10-16: PSD and brightness per grade, uncoated supply to confirm. info@gebalminerals.com, +256 703 020 124. Candidate 2.'),
  ('thompson creek', 'Thompson Creek Uganda - Jinja', 'Jinja', 'Jinja', null, 'Thompson Creek Uganda(Iganga Rd Jinja) 석회석·대리석 분말·골재·실리카, 고용량 파쇄.', 'Thompson Creek Uganda Ltd, 51-53 Iganga Road, Jinja - limestone and marble powder and aggregates, silica, high-capacity crushing.', 'UG check 2026-10-16: coarse grades - raw material only. Not added: System Star (Kenyan PCC distributor), Brenntag, Tororo and Hima Cement. No Ugandan paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%UG check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('a.?one invest', 'A-One Investments - Njeru', 'Buikwe', 'Njeru', null, 'A-One Investments(공장 Njeru, Kyaggwe Block 295 Plot 579·사무소 Jinja) 대리석·방해석 분쇄 Ultra White 활성 탄산칼슘 400~2,500 mesh, 백색도 97% 초과·Ca 93%(회사 발표), 종이 용도 명시.', 'A-One Investment Ltd, plant Plot 579 Kyaggwe Block 295, Njeru (Buikwe), office Vithaldas Road, Jinja - ground marble and calcite, Ultra White activated calcium carbonate 400-2,500 mesh, over 97 pct whiteness and 93 pct calcium claimed, paper named among uses.', 'UG check 2026-10-16: whiteness method unknown, ask for uncoated grade, D50 / D90, slurry and mill references. info@a-oneinvestments.com, +256 759 240 797. FCC co-production candidate 1 (near Modern Laminates and EAPS).'),
  ('gebal|african minerals limited|african minerals ltd', 'Gebal Minerals - Jinja', 'Jinja', 'Jinja', null, 'Gebal Minerals(2015, Nyanza Rd Jinja) 탄산칼슘 GC2~GC10·석회·카올린 — 제지·도료·플라스틱 충전제, Moroto 대리석·석회석(+케냐·이집트 원료), African Minerals Ltd 인수.', 'Gebal Minerals Limited (2015), Plot 7/9 Nyanza Road, Jinja - calcium carbonate GC2-GC10, lime, kaolin and mineral powders for paper, paint, plastics and ceramics, ore of Moroto (also Kenyan and Egyptian sources), took over African Minerals Ltd (BIO-financed carbonate and lime maker).', 'UG check 2026-10-16: PSD and brightness per grade, uncoated supply to confirm. info@gebalminerals.com, +256 703 020 124. Candidate 2.'),
  ('thompson creek', 'Thompson Creek Uganda - Jinja', 'Jinja', 'Jinja', null, 'Thompson Creek Uganda(Iganga Rd Jinja) 석회석·대리석 분말·골재·실리카, 고용량 파쇄.', 'Thompson Creek Uganda Ltd, 51-53 Iganga Road, Jinja - limestone and marble powder and aggregates, silica, high-capacity crushing.', 'UG check 2026-10-16: coarse grades - raw material only. Not added: System Star (Kenyan PCC distributor), Brenntag, Tororo and Hima Cement. No Ugandan paper PCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'uganda_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('A-One Investments - Njeru', 'GCC producer', 'Fine GCC with paper named - candidate 1', 'merchant', 'B', 'gcc'),
  ('Gebal Minerals - Jinja', 'GCC producer', 'GCC with paper named, Moroto ore - candidate 2', 'merchant', 'B', 'gcc'),
  ('Thompson Creek Uganda - Jinja', 'Limestone grinder', 'Coarse marble and limestone - raw material', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'uganda_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'UG', v.region, v.city, v.website, 'active', 'uganda_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('global paper products', 'mukono|kasenge', 'global paper', 'Global Paper Products - Mukono', 'Mukono', 'Mukono', null, 'Global Paper Products(1999, 공장 Kasenge Mukono·본사 Nakawa) 티슈 원지 점보롤 — 재생 17~24 gsm·혼합 17~24·버진 16~21 gsm, 탈묵, Luxury·B2S·Soft & Clean·Swan·Flamingo.', 'Global Paper Products Ltd (1999), plant Block 185 Plot 22-24, Kasenge, Mukono, HQ Nakawa Kampala - tissue jumbo rolls: recycled 17-24 gsm, blended 17-24 gsm, virgin 16-21 gsm, deinking, brands Luxury, B2S, Soft and Clean, Swan, Flamingo.', 'UG check 2026-10-16: output not public. globalpaperug@gmail.com, +256 39 217 9166.'),
  ('modern laminates', 'jinja|njeru', 'modern laminates', 'Modern Laminates - Jinja', 'Jinja', 'Jinja', null, 'Modern Laminates(Jinja–Kampala Rd Block 295 Plot 293) 다층 크라프트지·판지 — 유럽식 펄핑·Double Wire·QCS, 케냐·르완다 수출, 화장지 브랜드 보유.', 'Modern Laminates Ltd, Block 295 Plot 293, Jinja-Kampala Road - multi-ply kraft paper and board on recycled fibre, European pulping, double-wire forming, PLC and online QCS, exports to Kenya and Rwanda, also Modern Premium tissue brands.', 'UG check 2026-10-16: tissue base made in house or bought - to confirm. sales@modernpaper.co.ug, +256 750 165 867.'),
  ('east african packaging solutions|\meaps\M', 'njeru', 'east african packaging|eaps', 'East African Packaging Solutions - Njeru', 'Buikwe', 'Njeru', null, 'EAPS(2008, Plot 3 New Kampala Rd Njeru) 골판지 상자(월 3,600 t 발표)·2겹 크라프트지·펄프몰드 계란판, ISO 9001·45001·22000.', 'East African Packaging Solutions Ltd (2008), Plot 3 New Kampala Road, Njeru - corrugated boxes (3,600 t/month stated), 2-ply kraft paper and moulded-pulp egg trays of recovered paper, ISO 9001, 45001, 22000.', 'UG check 2026-10-16: box capacity is converting - confirm own kraft machine. sales@eapsl.com, +256 434 120 432.'),
  ('uganda pulp', 'jinja|kimaka', 'uganda pulp', 'Uganda Pulp & Paper Mills - Jinja', 'Jinja', 'Jinja', null, 'Uganda Pulp & Paper Mills(Plot M60 Kimaka Rd Jinja) Fluting·크라프트지 등록 — 가동 확인 필요.', 'Uganda Pulp and Paper Mills Ltd, Plot M60 Kimaka Road, Jinja - listed for fluting medium and kraft paper, current running status unknown.', 'UG check 2026-10-16: old phone +256 434 124175.'),
  ('paper toils', 'mukono|mbalala', 'paper toils', 'Paper Toils - Mukono', 'Mukono', 'Mukono', null, 'Paper Toils(2012, Mbalala Mukono) 폐지 기반 화장지·점보롤·지관·계란판.', 'Paper Toils (U) Ltd (2012), Plot 148 Block 183, Mbalala, Mukono - toilet tissue, jumbo rolls, paper cores and egg trays of recovered paper.', 'UG check 2026-10-16: pulping and machine specs not public. administrator@papertoils.com.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%UG check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('global paper products', 'mukono|kasenge', 'global paper', 'Global Paper Products(1999, 공장 Kasenge Mukono·본사 Nakawa) 티슈 원지 점보롤 — 재생 17~24 gsm·혼합 17~24·버진 16~21 gsm, 탈묵, Luxury·B2S·Soft & Clean·Swan·Flamingo.', 'Global Paper Products Ltd (1999), plant Block 185 Plot 22-24, Kasenge, Mukono, HQ Nakawa Kampala - tissue jumbo rolls: recycled 17-24 gsm, blended 17-24 gsm, virgin 16-21 gsm, deinking, brands Luxury, B2S, Soft and Clean, Swan, Flamingo.', 'UG check 2026-10-16: output not public. globalpaperug@gmail.com, +256 39 217 9166.'),
  ('modern laminates', 'jinja|njeru', 'modern laminates', 'Modern Laminates(Jinja–Kampala Rd Block 295 Plot 293) 다층 크라프트지·판지 — 유럽식 펄핑·Double Wire·QCS, 케냐·르완다 수출, 화장지 브랜드 보유.', 'Modern Laminates Ltd, Block 295 Plot 293, Jinja-Kampala Road - multi-ply kraft paper and board on recycled fibre, European pulping, double-wire forming, PLC and online QCS, exports to Kenya and Rwanda, also Modern Premium tissue brands.', 'UG check 2026-10-16: tissue base made in house or bought - to confirm. sales@modernpaper.co.ug, +256 750 165 867.'),
  ('east african packaging solutions|\meaps\M', 'njeru', 'east african packaging|eaps', 'EAPS(2008, Plot 3 New Kampala Rd Njeru) 골판지 상자(월 3,600 t 발표)·2겹 크라프트지·펄프몰드 계란판, ISO 9001·45001·22000.', 'East African Packaging Solutions Ltd (2008), Plot 3 New Kampala Road, Njeru - corrugated boxes (3,600 t/month stated), 2-ply kraft paper and moulded-pulp egg trays of recovered paper, ISO 9001, 45001, 22000.', 'UG check 2026-10-16: box capacity is converting - confirm own kraft machine. sales@eapsl.com, +256 434 120 432.'),
  ('uganda pulp', 'jinja|kimaka', 'uganda pulp', 'Uganda Pulp & Paper Mills(Plot M60 Kimaka Rd Jinja) Fluting·크라프트지 등록 — 가동 확인 필요.', 'Uganda Pulp and Paper Mills Ltd, Plot M60 Kimaka Road, Jinja - listed for fluting medium and kraft paper, current running status unknown.', 'UG check 2026-10-16: old phone +256 434 124175.'),
  ('paper toils', 'mukono|mbalala', 'paper toils', 'Paper Toils(2012, Mbalala Mukono) 폐지 기반 화장지·점보롤·지관·계란판.', 'Paper Toils (U) Ltd (2012), Plot 148 Block 183, Mbalala, Mukono - toilet tissue, jumbo rolls, paper cores and egg trays of recovered paper.', 'UG check 2026-10-16: pulping and machine specs not public. administrator@papertoils.com.'),
  ('imperial tissue', null, 'imperial tissue', null, null, 'UG check 2026-10-16: Imperial Tissue, Namanve - tissue converting (Dune, SkySoft, Comfex) - context only.'),
  ('riley packaging', null, 'riley packaging', null, null, 'UG check 2026-10-16: Riley Packaging, Mukono - 3 to 9-ply corrugated boxes - context only.'),
  ('picfare', null, 'picfare', null, null, 'UG check 2026-10-16: Picfare Industries, Jinja-Njeru - exercise books, printing, stationery - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'uganda_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('global paper products', 'mukono|kasenge', 'global paper'),
  ('modern laminates', 'jinja|njeru', 'modern laminates'),
  ('east african packaging solutions|\meaps\M', 'njeru', 'east african packaging|eaps'),
  ('uganda pulp', 'jinja|kimaka', 'uganda pulp'),
  ('paper toils', 'mukono|mbalala', 'paper toils'),
  ('imperial tissue', null, 'imperial tissue'),
  ('riley packaging', null, 'riley packaging'),
  ('picfare', null, 'picfare')
      ) as v(name_rx, city_rx, owner_rx)
    ) m
    where m.id is not null
      and not exists (select 1 from app.paper_mill_profile mp where mp.party_id = m.id);
    
update app.paper_mill_profile mp
    set extra_data = coalesce(mp.extra_data, '{}'::jsonb) || jsonb_build_object('plant',
          case when m.ctx then m.plant || coalesce(mp.extra_data -> 'plant', '{}'::jsonb)  -- context row: keep existing keys
               else m.plant end),
        main_products = coalesce(nullif(btrim(mp.main_products), ''), m.plant ->> 'products'),
        updated_at = now()
    from (
      select v.plant, v.ctx, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('global paper products', 'mukono|kasenge', 'global paper', false,
   $pj${"owner": "Global Paper Products", "priority": 1, "products": "Tissue jumbo rolls (virgin and recycled)", "grades": ["Tissue"], "pitch": "A-One / Gebal GCC + MBG FCC tissue trial", "approach": "Stepwise tissue trial - virgin and recycled separately.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('modern laminates', 'jinja|njeru', 'modern laminates', false,
   $pj${"owner": "Modern Laminates", "priority": 2, "products": "Multi-ply kraft, board, tissue", "grades": ["Kraft paper", "Board", "Tissue"], "approach": "Fibre-saving strength trial on board.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('east african packaging solutions|\meaps\M', 'njeru', 'east african packaging|eaps', false,
   $pj${"owner": "EAPS", "priority": 3, "products": "2-ply kraft, corrugated, moulded pulp", "grades": ["Kraft paper", "Moulded fibre"], "approach": "Confirm kraft machine, then trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('uganda pulp', 'jinja|kimaka', 'uganda pulp', false,
   $pj${"owner": "Uganda Pulp and Paper Mills", "products": "Fluting, kraft (listed)", "grades": ["Medium", "Kraft paper"], "approach": "Status first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('paper toils', 'mukono|mbalala', 'paper toils', false,
   $pj${"owner": "Paper Toils", "products": "Recycled tissue, cores, egg trays", "grades": ["Tissue", "Moulded fibre"], "approach": "Confirm machine.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('imperial tissue', null, 'imperial tissue', true,
   $pj${"owner": "Imperial Tissue", "products": "Imperial Tissue, Namanve - tissue converting (Dune, SkySoft, Comfex)", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('riley packaging', null, 'riley packaging', true,
   $pj${"owner": "Riley Packaging", "products": "Riley Packaging, Mukono - 3 to 9-ply corrugated boxes", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('picfare', null, 'picfare', true,
   $pj${"owner": "Picfare", "products": "Picfare Industries, Jinja-Njeru - exercise books, printing, stationery", "approach": "Converter - trace base-paper supplier.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'UG', 'Uganda', 'low',
   $cm$Jinja-Njeru cluster: A-One and Gebal GCC (paper named) next to Modern Laminates and EAPS kraft - Global Paper Products tissue jumbo rolls (Mukono)$cm$,
   $cm$Uganda pairs local GCC with real machines. GCC: A-One Investments Njeru (400-2,500 mesh, paper named), Gebal Minerals Jinja (GC2-GC10, Moroto ore, took over African Minerals), Thompson Creek (coarse). No PCC plant - PCC comes via Kenyan distributors. Mills: Global Paper Products Mukono (virgin and recycled tissue jumbo rolls 16-24 gsm), Modern Laminates Jinja (multi-ply kraft and board, double wire, exports to KE and RW), EAPS Njeru (2-ply kraft, corrugated, egg trays), Uganda Pulp and Paper Mills and Paper Toils (to confirm). Converters: Imperial Tissue, Riley, Picfare. Rwanda's Mingyang ships fluting here.$cm$,
   $cm${"fillers": "GCC: A-One Investments, Gebal Minerals, Thompson Creek. Not added: System Star, Brenntag, Tororo and Hima cement. No PCC.", "mills": "Tissue: Global Paper Products. Kraft and board: Modern Laminates, EAPS. To confirm: Uganda Pulp and Paper Mills, Paper Toils. Context: Imperial Tissue, Riley, Picfare.", "strategy": "Jinja-Njeru local model: A-One or Gebal GCC + MBG FCC process, tissue trial at Global Paper Products, strength trials at Modern Laminates and EAPS.", "risks": "Output unknown, company claims unverified.", "next_steps": ["Request A-One and Gebal PSD and brightness", "Propose a Global Paper Products tissue trial"], "key_numbers": [{"label": "A-One GCC", "value": "400-2,500 mesh"}, {"label": "EAPS boxes", "value": "3,600 t/month (converting)"}], "files": ["seed_20261016zzzu_uganda_mills_fillers"]}$cm$::jsonb,
   $cm$Jinja-Njeru 클러스터: A-One·Gebal GCC(제지 명시)와 Modern Laminates·EAPS 크라프트 인접 — Global Paper Products 티슈 점보롤(Mukono)$cm$,
   $cm$우간다는 현지 GCC 와 실제 초지기가 함께 있음. GCC: A-One Investments Njeru(400~2,500 mesh, 제지 명시), Gebal Minerals Jinja(GC2~GC10, Moroto 원료, African Minerals 인수), Thompson Creek(굵은 입도). PCC 공장 없음 — 케냐 유통업체 경유. 제지: Global Paper Products Mukono(버진·재생 티슈 점보롤 16~24 gsm), Modern Laminates Jinja(다층 크라프트·판지, 더블와이어, 케냐·르완다 수출), EAPS Njeru(2겹 크라프트·골판지·계란판), Uganda Pulp & Paper Mills·Paper Toils(확인 필요). 가공: Imperial Tissue, Riley, Picfare. 르완다 Mingyang 골심지가 우간다로 수출됨.$cm$,
   null, null,
   $cm$생산량 미공개 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('global paper products', 'mukono|kasenge', 'global paper'),
  ('modern laminates', 'jinja|njeru', 'modern laminates'),
  ('east african packaging solutions|\meaps\M', 'njeru', 'east african packaging|eaps'),
  ('uganda pulp', 'jinja|kimaka', 'uganda pulp'),
  ('paper toils', 'mukono|mbalala', 'paper toils'),
  ('imperial tissue', null, 'imperial tissue'),
  ('riley packaging', null, 'riley packaging'),
  ('picfare', null, 'picfare')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'uganda_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'uganda_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'a.?one invest' or p.party_name ~* 'gebal|african minerals limited|african minerals ltd' or p.party_name ~* 'thompson creek')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'UG'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'UG'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'UG'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'UG'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    