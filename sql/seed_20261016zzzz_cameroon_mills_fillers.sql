-- ============================================================
-- seed_20261016zzzz_cameroon_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Cameroon update (reports 2026-10-17).
-- 1) Filler if missing (1): CIMENCAM (Figuil limestone).
-- 2) Mill if missing (1, no priority): SITRACEL. Context (13).
-- 3) app.country_markets CM row (priority none).
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
           v.party_name, 'CM', v.region, v.city, v.website, 'active', 'cameroon_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('cimencam|cimenteries du cameroun', 'CIMENCAM - Figuil', 'North', 'Figuil', null, 'CIMENCAM 시멘트·석회석 — Figuil 석회석 채석 명목 연 약 27.5만 t(USGS 2019), Douala·Yaoundé 인근 시설.', 'Cimenteries du Cameroun (CIMENCAM) - cement and limestone, Figuil quarry about 275,000 t/yr nominal (USGS 2019), plants near Douala and Yaoundé.', 'CM check 2026-10-16: cement stone - untested for paper. A 2026 Douala-basin study reports about 99 pct CaCO3 in some beds (Mungo River, Mbalangi, Ediki). Not added: CIMAF Cameroun, Dangote Cement Cameroon (cement), ASCOM SARL Akwa, SPIEX, AFOMA-CM (carbonate traders). Tunisian MBS lists Cameroon exports. No Cameroonian paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%CM check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('cimencam|cimenteries du cameroun', 'CIMENCAM - Figuil', 'North', 'Figuil', null, 'CIMENCAM 시멘트·석회석 — Figuil 석회석 채석 명목 연 약 27.5만 t(USGS 2019), Douala·Yaoundé 인근 시설.', 'Cimenteries du Cameroun (CIMENCAM) - cement and limestone, Figuil quarry about 275,000 t/yr nominal (USGS 2019), plants near Douala and Yaoundé.', 'CM check 2026-10-16: cement stone - untested for paper. A 2026 Douala-basin study reports about 99 pct CaCO3 in some beds (Mungo River, Mbalangi, Ediki). Not added: CIMAF Cameroun, Dangote Cement Cameroon (cement), ASCOM SARL Akwa, SPIEX, AFOMA-CM (carbonate traders). Tunisian MBS lists Cameroon exports. No Cameroonian paper PCC or GCC.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'cameroon_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('CIMENCAM - Figuil', 'Limestone owner (cement)', 'Limestone - raw-material lead', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'cameroon_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'CM', v.region, v.city, v.website, 'active', 'cameroon_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('sitracel', 'yaound[eé]|efoulan|douala', 'sitracel', 'SITRACEL - Yaoundé', 'Centre', 'Yaoundé', null, 'SITRACEL(1978, Efoulan Yaoundé·Douala) 화장지·키친타월·냅킨·여성용품·기저귀·노트·복사용지, 생산장비 28대(디렉터리) — 초지기 여부 미확인.', 'SITRACEL S.A. (Société Industrielle de Traitement de Cellulose, 1978), Efoulan, Yaoundé, plus Douala - toilet tissue, towels, napkins, feminine and baby care, exercise books and copy paper, 28 production machines per a directory (not all paper machines).', 'CM check 2026-10-16: ask whether it runs a tissue machine or buys jumbo rolls. info@sitracel.com, +237 222 31 78 20.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CM check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sitracel', 'yaound[eé]|efoulan|douala', 'sitracel', 'SITRACEL(1978, Efoulan Yaoundé·Douala) 화장지·키친타월·냅킨·여성용품·기저귀·노트·복사용지, 생산장비 28대(디렉터리) — 초지기 여부 미확인.', 'SITRACEL S.A. (Société Industrielle de Traitement de Cellulose, 1978), Efoulan, Yaoundé, plus Douala - toilet tissue, towels, napkins, feminine and baby care, exercise books and copy paper, 28 production machines per a directory (not all paper machines).', 'CM check 2026-10-16: ask whether it runs a tissue machine or buys jumbo rolls. info@sitracel.com, +237 222 31 78 20.'),
  ('sita industry', null, 'sita industry', null, null, 'CM check 2026-10-16: SITA Industry, Boadibo Douala (2000) - notebooks and reams, absorbed by SITRACEL 2018 - context only.'),
  ('socarto', null, 'socarto', null, null, 'CM check 2026-10-16: SOCARTO (1972), Bassa Ndokoti Douala - 1-6 ply kraft sacks, paper cutting - corrugating reported idle - context only.'),
  ('samco paper', null, 'samco paper', null, null, 'CM check 2026-10-16: SAMCO Paper (1992), Ombe sheeting plant, Limbe - imports reels, sells to CF, TD, GQ - context only.'),
  ('moore paragon', null, 'moore paragon', null, null, 'CM check 2026-10-16: Moore Paragon Cameroun, Bonabéri - board and printing - status to confirm - context only.'),
  ('\msafca\M', null, '\msafca\M', null, null, 'CM check 2026-10-16: SAFCA, Douala - notebooks - context only.'),
  ('printpak', null, 'printpak', null, null, 'CM check 2026-10-16: Printpak, Douala - printing and packaging - context only.'),
  ('packing industry company|\mpic sarl', null, 'packing industry company|\mpic sarl', null, null, 'CM check 2026-10-16: Packing Industry Company, Bassa Douala - adhesive, coated and offset papers - context only.'),
  ('cellucam', null, 'cellucam', null, null, 'CM check 2026-10-16: CELLUCAM, Edéa - pulp mill opened 1980, liquidated 1986 - context only.'),
  ('plasticam', null, 'plasticam', null, null, 'CM check 2026-10-16: PLASTICAM (1961), Bassa Douala - corrugated boxes plus plastic packaging, two plants - liner source to confirm - context only.'),
  ('\msati sarl|africaine de transformation industrielle', null, '\msati sarl|africaine de transformation industrielle', null, null, 'CM check 2026-10-16: SATI SARL, Douala - corrugated boxes - context only.'),
  ('greystone', null, 'greystone', null, null, 'CM check 2026-10-16: Greystone Manufacturing, Odza Yaoundé - PaperOne copy-paper distribution, 2,500 m2 warehouse, 20 kt/yr production plan - context only.'),
  ('tiof', null, 'tiof', null, null, 'CM check 2026-10-16: TIOF Hygienic and Paper Industry, Yaoundé - listed converter - context only.'),
  ('le menn', null, 'le menn', null, null, 'CM check 2026-10-16: Le Menn Paper Converting, Limbe - listed converter - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'cameroon_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sitracel', 'yaound[eé]|efoulan|douala', 'sitracel'),
  ('sita industry', null, 'sita industry'),
  ('socarto', null, 'socarto'),
  ('samco paper', null, 'samco paper'),
  ('moore paragon', null, 'moore paragon'),
  ('\msafca\M', null, '\msafca\M'),
  ('printpak', null, 'printpak'),
  ('packing industry company|\mpic sarl', null, 'packing industry company|\mpic sarl'),
  ('cellucam', null, 'cellucam'),
  ('plasticam', null, 'plasticam'),
  ('\msati sarl|africaine de transformation industrielle', null, '\msati sarl|africaine de transformation industrielle'),
  ('greystone', null, 'greystone'),
  ('tiof', null, 'tiof'),
  ('le menn', null, 'le menn')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sitracel', 'yaound[eé]|efoulan|douala', 'sitracel', false,
   $pj${"owner": "SITRACEL", "products": "Tissue products, notebooks", "grades": ["Tissue"], "approach": "Confirm tissue machine first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sita industry', null, 'sita industry', true,
   $pj${"owner": "SITRACEL group", "products": "SITA Industry, Boadibo Douala (2000) - notebooks and reams, absorbed by SITRACEL 2018", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('socarto', null, 'socarto', true,
   $pj${"owner": "SOCARTO", "products": "SOCARTO (1972), Bassa Ndokoti Douala - 1-6 ply kraft sacks, paper cutting - corrugating reported idle", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('samco paper', null, 'samco paper', true,
   $pj${"owner": "SAMCO", "products": "SAMCO Paper (1992), Ombe sheeting plant, Limbe - imports reels, sells to CF, TD, GQ", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('moore paragon', null, 'moore paragon', true,
   $pj${"owner": "Moore Paragon", "products": "Moore Paragon Cameroun, Bonabéri - board and printing - status to confirm", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\msafca\M', null, '\msafca\M', true,
   $pj${"owner": "SAFCA", "products": "SAFCA, Douala - notebooks", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('printpak', null, 'printpak', true,
   $pj${"owner": "Printpak", "products": "Printpak, Douala - printing and packaging", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('packing industry company|\mpic sarl', null, 'packing industry company|\mpic sarl', true,
   $pj${"owner": "PIC", "products": "Packing Industry Company, Bassa Douala - adhesive, coated and offset papers", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('cellucam', null, 'cellucam', true,
   $pj${"owner": "(closed)", "products": "CELLUCAM, Edéa - pulp mill opened 1980, liquidated 1986", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('plasticam', null, 'plasticam', true,
   $pj${"owner": "PLASTICAM", "products": "PLASTICAM (1961), Bassa Douala - corrugated boxes plus plastic packaging, two plants - liner source to confirm", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\msati sarl|africaine de transformation industrielle', null, '\msati sarl|africaine de transformation industrielle', true,
   $pj${"owner": "SATI", "products": "SATI SARL, Douala - corrugated boxes", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('greystone', null, 'greystone', true,
   $pj${"owner": "Greystone Manufacturing", "products": "Greystone Manufacturing, Odza Yaoundé - PaperOne copy-paper distribution, 2,500 m2 warehouse, 20 kt/yr production plan", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('tiof', null, 'tiof', true,
   $pj${"owner": "TIOF", "products": "TIOF Hygienic and Paper Industry, Yaoundé - listed converter", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('le menn', null, 'le menn', true,
   $pj${"owner": "Le Menn", "products": "Le Menn Paper Converting, Limbe - listed converter", "approach": "Converter, distributor or closed.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CM', 'Cameroon', 'none',
   $cm$No confirmed paper machine since CELLUCAM closed (1986) - SITRACEL tissue (to confirm), SOCARTO sacks, SAMCO sheeting for CEMAC - CIMENCAM limestone$cm$,
   $cm$Cameroon's paper sector converts imported reels: SITRACEL (Yaoundé and Douala tissue and notebooks - machine to confirm), SITA Industry, SOCARTO (kraft sacks), PLASTICAM and SATI (corrugated), SAMCO Paper (Ombe sheeting, sells to CAR, Chad, Equatorial Guinea), Moore Paragon, SAFCA (Fotso group), Printpak, PIC, TIOF, Le Menn, and Greystone (copy-paper distributor with a 20 kt plan). FAO listed about 5 kt capacity in 2002. The Edéa pulp mill CELLUCAM closed in 1986. 2023 imports incl. about 7.6 kt HS 480560 and 5 kt hygiene products. No paper PCC or GCC: CIMENCAM (Figuil limestone 275 kt), cement makers, carbonate traders, Tunisian MBS imports, and 99 pct CaCO3 beds reported in the Douala basin (2026 study). Douala is the CEMAC paper hub.$cm$,
   $cm${"fillers": "Limestone: CIMENCAM. Not added: CIMAF, Dangote, ASCOM, SPIEX, AFOMA-CM. No PCC or GCC.", "mills": "To confirm: SITRACEL. Context: SITA Industry, SOCARTO, PLASTICAM, SATI, SAMCO Paper, Greystone (20 kt plan), Moore Paragon, SAFCA, Printpak, PIC, TIOF, Le Menn, CELLUCAM (closed).", "strategy": "Confirm SITRACEL's machine. Use SAMCO and SOCARTO to trace overseas reel suppliers serving CEMAC.", "risks": "No confirmed machine, past pulp-mill failure.", "next_steps": ["Ask SITRACEL about tissue machines", "Ask SAMCO which mills supply its reels"], "key_numbers": [{"label": "HS 4818 imports 2023", "value": "about 5 kt"}, {"label": "Figuil quarry", "value": "about 275 kt/yr"}], "files": ["seed_20261016zzzz_cameroon_mills_fillers"]}$cm$::jsonb,
   $cm$CELLUCAM 폐쇄(1986) 후 초지기 미확인 — SITRACEL 티슈(확인 필요), SOCARTO 포대, SAMCO CEMAC 재단 유통 — CIMENCAM 석회석$cm$,
   $cm$카메룬 제지업은 수입 원지 가공: SITRACEL(Yaoundé·Douala 티슈·노트 — 초지기 확인), SITA Industry, SOCARTO(크라프트 포대), PLASTICAM·SATI(골판지), SAMCO Paper(Ombe 재단, CAR·차드·적도기니 판매), Moore Paragon, SAFCA(Fotso), Printpak, PIC, TIOF, Le Menn, Greystone(복사용지 유통, 2만 t 계획). FAO 2002 약 5천 t. Edéa 펄프공장 CELLUCAM 1986 폐쇄. 2023 수입 HS 480560 약 7.6천 t·위생지 5천 t 등. 제지용 PCC·GCC 없음: CIMENCAM(Figuil 석회석 27.5만 t), 시멘트사, 탄산칼슘 상사, 튀니지 MBS 수입, Douala 분지 99% CaCO3 층 보고(2026). Douala 가 CEMAC 종이 거점.$cm$,
   null, null,
   $cm$초지기 미확인 — 산정 안 함$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('sitracel', 'yaound[eé]|efoulan|douala', 'sitracel'),
  ('sita industry', null, 'sita industry'),
  ('socarto', null, 'socarto'),
  ('samco paper', null, 'samco paper'),
  ('moore paragon', null, 'moore paragon'),
  ('\msafca\M', null, '\msafca\M'),
  ('printpak', null, 'printpak'),
  ('packing industry company|\mpic sarl', null, 'packing industry company|\mpic sarl'),
  ('cellucam', null, 'cellucam'),
  ('plasticam', null, 'plasticam'),
  ('\msati sarl|africaine de transformation industrielle', null, '\msati sarl|africaine de transformation industrielle'),
  ('greystone', null, 'greystone'),
  ('tiof', null, 'tiof'),
  ('le menn', null, 'le menn')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'cameroon_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'cameroon_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'cimencam|cimenteries du cameroun')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'CM'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'CM'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CM'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    