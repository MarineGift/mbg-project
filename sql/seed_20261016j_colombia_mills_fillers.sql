-- ============================================================
-- seed_20261016j_colombia_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Colombia update (reports 2026-10-15). Introduction -> intro_ko / intro_en
-- (only when empty), detail -> notes once with 'CO check 2026-10-15'.
-- 1) Fillers if missing (6): Omya Andina Guarne, Microminerales, Procomin,
--    Colminerales, Minerales y Triturados del Caribe, Procesadora de
--    Minerales Andina.
-- 2) Mills if missing (14) + plant blocks, priority 1-8: Propal Yumbo and
--    Guachené, Papeles Nacionales, Essity Cajicá and Medellín, Unibol,
--    Kimberly-Clark Puerto Tejada and Barbosa, Smurfit Westrock Cali
--    (Barbosa, Barranquilla no priority), Cartones América, Papelsa, Empacor.
--    Context: Corrugados de Colombia.
-- 3) app.country_markets CO row (priority high).
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
           v.party_name, 'CO', v.region, v.city, v.website, 'active', 'colombia_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(andina|colombia)', 'Omya Andina - Guarne', 'Antioquia', 'Guarne', null, 'Omya 콜롬비아 법인 Omya Andina — Guarne(Autopista Medellín–Bogotá Km 30) GCC 공장. Omyacarb F-CG(98%, D50 1.0 μm, D98 6 μm, Ry 94%, 2013 자료).', 'Omya Andina S.A.S. - GCC plant at Autopista Medellín - Bogotá Km 30, Guarne (Antioquia): limestone crushing and grinding for paper, plastics and paint, Omyacarb F-CG data sheet (98 pct CaCO3, D50 1.0 micron, D98 6 micron, Ry 94 pct, 2013).', 'CO check 2026-10-15: PCC at Guarne not confirmed. +57 604 562 7676. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('microminerales', 'Microminerales', 'Antioquia', 'Puerto Triunfo', null, '1985년 Caolines Impalpables 로 시작한 광물 업체. Copacabana·Puerto Triunfo 시설, 2007 Puerto Triunfo 탄산칼슘 공장, 2017 설비 개선.', 'Microminerales S.A.S. (started 1985 as Caolines Impalpables) - natural calcium carbonate and non-metallic minerals at Copacabana and Puerto Triunfo (Antioquia), Puerto Triunfo carbonate plant built 2007, upgraded 2017.', 'CO check 2026-10-15: ultrafine, wet slurry and paper sales not confirmed.'),
  ('procomin', 'Procomin', 'Cundinamarca', 'Madrid', null, '1992년부터 광물 미분쇄(Madrid–Facatativá, Carretera de Occidente Km 26). CaCO3·카올린·활석·중정석.', 'Procomin S.A.S., Carretera Nacional de Occidente Km 26, Madrid - Facatativá (Cundinamarca) - mineral micronising since 1992: calcium carbonate, kaolin, talc, barite for paint, plastics, ceramics and construction (paper listed for kaolin).', 'CO check 2026-10-15: paper-grade GCC not confirmed. comercial@procomin.co, +57 314 442 6449. Near Bogotá mills.'),
  ('colminerales|colombiana de minerales', 'Colombiana de Minerales (Colminerales)', null, null, null, '1996년부터 탄산칼슘·비금속광물 가공(Huila 석회석).', 'Colombiana de Minerales (Colminerales) - calcium carbonate and non-metallic mineral processing since 1996, own mills since 1997, Huila limestone.', 'CO check 2026-10-15: paper grades and capacity not public.'),
  ('triturados del caribe', 'Minerales y Triturados del Caribe', null, null, null, '카리브 지역 석회석·중정석 분쇄·위탁가공. GCC 250~1,200 mesh, TGM 분쇄라인 3기(시간당 10~30 t).', 'Minerales y Triturados del Caribe - limestone and barite grinding and toll milling in the Caribbean region: GCC 250, 325, 400 and 1,200 mesh on three TGM mills (10-30 t/h).', 'CO check 2026-10-15: toll-milling candidate - fibre dispersion and slurry not available.'),
  ('procesadora de minerales andina', 'Procesadora de Minerales Andina', 'Antioquia', 'Puerto Triunfo', null, 'Puerto Triunfo(Alto Rico) 석회석 채굴·분쇄 GCC, 월 약 1,500 t(8시간 교대).', 'Procesadora de Minerales Andina S.A.S., Alto Rico, Puerto Triunfo (Antioquia) - natural and coated GCC, about 1,500 t/month on one 8-hour shift, mainly oil and agro markets.', 'CO check 2026-10-15: comercial@pmineralesandina.com. Not added: Barahona (CALPREC PCC distributor). No paper PCC plant or MTI site found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%CO check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(andina|colombia)', 'Omya Andina - Guarne', 'Antioquia', 'Guarne', null, 'Omya 콜롬비아 법인 Omya Andina — Guarne(Autopista Medellín–Bogotá Km 30) GCC 공장. Omyacarb F-CG(98%, D50 1.0 μm, D98 6 μm, Ry 94%, 2013 자료).', 'Omya Andina S.A.S. - GCC plant at Autopista Medellín - Bogotá Km 30, Guarne (Antioquia): limestone crushing and grinding for paper, plastics and paint, Omyacarb F-CG data sheet (98 pct CaCO3, D50 1.0 micron, D98 6 micron, Ry 94 pct, 2013).', 'CO check 2026-10-15: PCC at Guarne not confirmed. +57 604 562 7676. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('microminerales', 'Microminerales', 'Antioquia', 'Puerto Triunfo', null, '1985년 Caolines Impalpables 로 시작한 광물 업체. Copacabana·Puerto Triunfo 시설, 2007 Puerto Triunfo 탄산칼슘 공장, 2017 설비 개선.', 'Microminerales S.A.S. (started 1985 as Caolines Impalpables) - natural calcium carbonate and non-metallic minerals at Copacabana and Puerto Triunfo (Antioquia), Puerto Triunfo carbonate plant built 2007, upgraded 2017.', 'CO check 2026-10-15: ultrafine, wet slurry and paper sales not confirmed.'),
  ('procomin', 'Procomin', 'Cundinamarca', 'Madrid', null, '1992년부터 광물 미분쇄(Madrid–Facatativá, Carretera de Occidente Km 26). CaCO3·카올린·활석·중정석.', 'Procomin S.A.S., Carretera Nacional de Occidente Km 26, Madrid - Facatativá (Cundinamarca) - mineral micronising since 1992: calcium carbonate, kaolin, talc, barite for paint, plastics, ceramics and construction (paper listed for kaolin).', 'CO check 2026-10-15: paper-grade GCC not confirmed. comercial@procomin.co, +57 314 442 6449. Near Bogotá mills.'),
  ('colminerales|colombiana de minerales', 'Colombiana de Minerales (Colminerales)', null, null, null, '1996년부터 탄산칼슘·비금속광물 가공(Huila 석회석).', 'Colombiana de Minerales (Colminerales) - calcium carbonate and non-metallic mineral processing since 1996, own mills since 1997, Huila limestone.', 'CO check 2026-10-15: paper grades and capacity not public.'),
  ('triturados del caribe', 'Minerales y Triturados del Caribe', null, null, null, '카리브 지역 석회석·중정석 분쇄·위탁가공. GCC 250~1,200 mesh, TGM 분쇄라인 3기(시간당 10~30 t).', 'Minerales y Triturados del Caribe - limestone and barite grinding and toll milling in the Caribbean region: GCC 250, 325, 400 and 1,200 mesh on three TGM mills (10-30 t/h).', 'CO check 2026-10-15: toll-milling candidate - fibre dispersion and slurry not available.'),
  ('procesadora de minerales andina', 'Procesadora de Minerales Andina', 'Antioquia', 'Puerto Triunfo', null, 'Puerto Triunfo(Alto Rico) 석회석 채굴·분쇄 GCC, 월 약 1,500 t(8시간 교대).', 'Procesadora de Minerales Andina S.A.S., Alto Rico, Puerto Triunfo (Antioquia) - natural and coated GCC, about 1,500 t/month on one 8-hour shift, mainly oil and agro markets.', 'CO check 2026-10-15: comercial@pmineralesandina.com. Not added: Barahona (CALPREC PCC distributor). No paper PCC plant or MTI site found.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'colombia_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Andina - Guarne', 'GCC producer', 'Omya Colombia GCC - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Microminerales', 'GCC producer', 'Local GCC - production partner candidate', 'merchant', 'C', 'gcc'),
  ('Procomin', 'GCC producer', 'Bogotá-area grinder', 'merchant', 'C', 'gcc'),
  ('Colombiana de Minerales (Colminerales)', 'GCC producer', 'GCC grinder', 'merchant', 'C', 'gcc'),
  ('Minerales y Triturados del Caribe', 'GCC producer', 'Toll grinder', 'merchant', 'C', 'gcc'),
  ('Procesadora de Minerales Andina', 'GCC producer', 'Small GCC maker - raw material or trial', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'colombia_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'CO', v.region, v.city, v.website, 'active', 'colombia_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('propal.*yumbo|carvajal pulpa.*yumbo', 'yumbo', 'propal|carvajal', 'Propal - Yumbo', 'Valle del Cauca', 'Yumbo', null, 'Carvajal Pulpa y Papel(Propal) Yumbo 공장 — 사탕수수 바가스 펄프(섬유 80% 이상 대체원료) 인쇄·필기용지·포장용지. 2023 매출 약 1.16조 페소.', 'Carvajal Pulpa y Papel S.A. (Propal, Organización Carvajal) - Yumbo (Valle del Cauca) mill: printing, writing and packaging paper and board on sugarcane bagasse (over 80 pct of fibre is non-wood, also rice straw). Group over 1,200 staff, 2023 sales about COP 1.163 trillion.', 'CO check 2026-10-15: capacity not public.'),
  ('propal.*guachen|carvajal pulpa.*guachen', 'guachen', 'propal|carvajal', 'Propal - Guachené', 'Cauca', 'Guachené', null, 'Propal Guachené(Cauca) 제지공장 — 바가스 펄프 인쇄·필기·포장용지.', 'Carvajal Pulpa y Papel (Propal) - Guachené (Cauca) mill, bagasse-based printing and packaging papers.', 'CO check 2026-10-15: capacity not public.'),
  ('papeles nacionales', 'pereira', 'papeles nacionales', 'Papeles Nacionales - Pereira', 'Risaralda', 'Pereira', null, 'Pereira 티슈 제조사(탈묵 재생펄프 + 천연펄프). 브랜드 Suave Gold·Rosal Plus·Favorita·Joya·SaniTisu.', 'Papeles Nacionales S.A.S., Pereira - Cartago road, Risaralda - tissue on a blend of deinked recycled pulp and virgin pulp: toilet tissue, napkins, hygiene paper, brands Suave Gold, Rosal Plus, Favorita, Joya, SaniTisu.', 'CO check 2026-10-15: capacity not public.'),
  ('familia.*cajic|essity.*cajic', 'cajic', 'familia|essity', 'Essity (Grupo Familia) - Cajicá', 'Cundinamarca', 'Cajicá', null, 'Essity(2021 Grupo Familia 95.8% 인수) 콜롬비아 핵심 티슈 공장 Cajicá, 연 7만 t(2025). Medellín 라인 이전 중(2026-08).', 'Essity / Grupo Familia (Essity holds 95.8 pct since 2021) - Cajicá (Cundinamarca), main Colombian tissue mill, 70,000 t/yr (2025), receiving the Medellín lines since 2026-08. Colombia is the second-largest Essity market in Latin America (SEK 5.2 bn sales 2024).', 'CO check 2026-10-15: post-transfer capacity to confirm.'),
  ('familia.*medell|essity.*medell', 'medell', 'familia|essity', 'Essity (Grupo Familia) - Medellín', 'Antioquia', 'Medellín', null, 'Essity Medellín 티슈 공장 연 3만 t — 2026-08부터 Cajicá 로 단계 이전.', 'Essity / Grupo Familia - Medellín (Antioquia) tissue mill, 30,000 t/yr (2025), lines moving to Cajicá since 2026-08.', 'CO check 2026-10-15: likely winding down - check before contact.'),
  ('unibol', 'soledad', 'unibol', 'Unibol - Soledad', 'Atlántico', 'Soledad', null, '1948년 설립(Soledad, Atlántico). 1968부터 크라프트 초지, 1985부터 티슈(Nube), 재생섬유 중심, 2021 제2 초지기 현대화.', 'Unibol S.A.S. (1948), Km 7 Autopista Aeropuerto, Soledad (Atlántico) - kraft paper since 1968 and tissue since 1985 (Nube toilet tissue, napkins, towels) mainly on recycled fibre, second machine modernised since 2021.', 'CO check 2026-10-15: capacity not public. +57 605 336 6700, servicliente@unibol.com.co.'),
  ('papeles del cauca|kimberly.*puerto tejada', 'puerto tejada', 'kimberly|papeles del cauca', 'Kimberly-Clark - Papeles del Cauca (Puerto Tejada)', 'Cauca', 'Puerto Tejada', null, 'Colombiana Kimberly Colpapel 의 Papeles del Cauca(Puerto Tejada) — 화장지·미용티슈·냅킨·타월.', 'Colombiana Kimberly Colpapel S.A. - Papeles del Cauca, Puerto Tejada (Cauca): toilet tissue, facial, napkins, towels (Scott, Kleenex).', 'CO check 2026-10-15: site data is in older sustainability reports - current scale to confirm.'),
  ('kimberly.*barbosa', 'barbosa', 'kimberly|colpapel', 'Kimberly-Clark - Barbosa', 'Antioquia', 'Barbosa', null, 'Kimberly-Clark Barbosa(Antioquia) — 산업용 위생지·Airflex·특수지.', 'Colombiana Kimberly Colpapel - Barbosa (Antioquia): away-home tissue, Airflex and specialty papers (Kimberly-Clark Antioquia Global).', 'CO check 2026-10-15: confirmed active in recent Kimberly-Clark material.'),
  ('(smurfit|westrock|cart[oó]n de colombia).*cali', 'cali', 'smurfit|westrock|cart[oó]n de colombia', 'Smurfit Westrock - Cali', 'Valle del Cauca', 'Cali', null, 'Smurfit Westrock 콜롬비아 Cali 제지공장 — 골판지 원지 12.9만 + 판지 7만 + 크라프트 12.1만 = 32만 t(2025 말).', 'Smurfit Westrock (ex Cartón de Colombia) - Cali mill: 129,000 t containerboard, 70,000 t boxboard and 121,000 t kraft paper, 320,000 t/yr (end 2025, SEC).', 'CO check 2026-10-15: Colombia total 524 kt in three mills.'),
  ('(smurfit|westrock|cart[oó]n de colombia).*barbosa', 'barbosa', 'smurfit|westrock|cart[oó]n de colombia', 'Smurfit Westrock - Barbosa', 'Antioquia', 'Barbosa', null, 'Smurfit Westrock Barbosa 골판지 원지 연 12.7만 t.', 'Smurfit Westrock - Barbosa (Antioquia) containerboard mill, 127,000 t/yr (end 2025).', 'CO check 2026-10-15: strength-critical.'),
  ('(smurfit|westrock|cart[oó]n de colombia).*barranquilla', 'barranquilla', 'smurfit|westrock|cart[oó]n de colombia', 'Smurfit Westrock - Barranquilla', 'Atlántico', 'Barranquilla', null, 'Smurfit Westrock Barranquilla 골판지 원지 연 7.7만 t(2024 제지 680만 달러 투자).', 'Smurfit Westrock - Barranquilla (Atlántico) containerboard mill, 77,000 t/yr (end 2025), USD 6.8 m mill investment 2024.', 'CO check 2026-10-15: strength-critical.'),
  ('cartones am[eé]rica', 'cali', 'cartones am', 'Cartones América - Cali', 'Valle del Cauca', 'Cali', null, 'Cartones América Cali 제지공장(1970 가동, 2018 증설) — 판지·골판지 원지, 페루·에콰도르·칠레·아르헨티나 사업.', 'Cartones América S.A., Calle 70 Norte 2A-130, Cali - paper mill since 1970 (capacity raised 2018): board and corrugating base paper, box plants in Cali and Mosquera, also operating in Peru, Ecuador, Chile, Argentina.', 'CO check 2026-10-15: capacity not public. +57 602 387 6990.'),
  ('papelsa', 'barbosa', 'papelsa', 'Papelsa - Barbosa', 'Antioquia', 'Barbosa', null, '1978년 설립 재생 골판지 원지 전문(제지공장 Barbosa, 골판지 Barbosa·Bogotá).', 'Papelsa (1978) - recycled corrugating base paper mill at Barbosa (Antioquia), box plants at Barbosa and Bogotá.', 'CO check 2026-10-15: capacity not public.'),
  ('empacor', 'fontib[oó]n|bogot', 'empacor', 'Empacor - Fontibón (Bogotá)', 'Bogotá', 'Bogotá', null, '1981년 자체 제지공장(Fontibón) — 100% 재생 라이너·골심지, 2013 약 30% 증설.', 'Empacor S.A. - own paper mill at Fontibón, Bogotá since 1981 (capacity up about 30 pct in 2013): 100 pct recycled liner and medium, two box plants.', 'CO check 2026-10-15: capacity not public.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%CO check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('propal.*yumbo|carvajal pulpa.*yumbo', 'yumbo', 'propal|carvajal', 'Carvajal Pulpa y Papel(Propal) Yumbo 공장 — 사탕수수 바가스 펄프(섬유 80% 이상 대체원료) 인쇄·필기용지·포장용지. 2023 매출 약 1.16조 페소.', 'Carvajal Pulpa y Papel S.A. (Propal, Organización Carvajal) - Yumbo (Valle del Cauca) mill: printing, writing and packaging paper and board on sugarcane bagasse (over 80 pct of fibre is non-wood, also rice straw). Group over 1,200 staff, 2023 sales about COP 1.163 trillion.', 'CO check 2026-10-15: capacity not public.'),
  ('propal.*guachen|carvajal pulpa.*guachen', 'guachen', 'propal|carvajal', 'Propal Guachené(Cauca) 제지공장 — 바가스 펄프 인쇄·필기·포장용지.', 'Carvajal Pulpa y Papel (Propal) - Guachené (Cauca) mill, bagasse-based printing and packaging papers.', 'CO check 2026-10-15: capacity not public.'),
  ('papeles nacionales', 'pereira', 'papeles nacionales', 'Pereira 티슈 제조사(탈묵 재생펄프 + 천연펄프). 브랜드 Suave Gold·Rosal Plus·Favorita·Joya·SaniTisu.', 'Papeles Nacionales S.A.S., Pereira - Cartago road, Risaralda - tissue on a blend of deinked recycled pulp and virgin pulp: toilet tissue, napkins, hygiene paper, brands Suave Gold, Rosal Plus, Favorita, Joya, SaniTisu.', 'CO check 2026-10-15: capacity not public.'),
  ('familia.*cajic|essity.*cajic', 'cajic', 'familia|essity', 'Essity(2021 Grupo Familia 95.8% 인수) 콜롬비아 핵심 티슈 공장 Cajicá, 연 7만 t(2025). Medellín 라인 이전 중(2026-08).', 'Essity / Grupo Familia (Essity holds 95.8 pct since 2021) - Cajicá (Cundinamarca), main Colombian tissue mill, 70,000 t/yr (2025), receiving the Medellín lines since 2026-08. Colombia is the second-largest Essity market in Latin America (SEK 5.2 bn sales 2024).', 'CO check 2026-10-15: post-transfer capacity to confirm.'),
  ('familia.*medell|essity.*medell', 'medell', 'familia|essity', 'Essity Medellín 티슈 공장 연 3만 t — 2026-08부터 Cajicá 로 단계 이전.', 'Essity / Grupo Familia - Medellín (Antioquia) tissue mill, 30,000 t/yr (2025), lines moving to Cajicá since 2026-08.', 'CO check 2026-10-15: likely winding down - check before contact.'),
  ('unibol', 'soledad', 'unibol', '1948년 설립(Soledad, Atlántico). 1968부터 크라프트 초지, 1985부터 티슈(Nube), 재생섬유 중심, 2021 제2 초지기 현대화.', 'Unibol S.A.S. (1948), Km 7 Autopista Aeropuerto, Soledad (Atlántico) - kraft paper since 1968 and tissue since 1985 (Nube toilet tissue, napkins, towels) mainly on recycled fibre, second machine modernised since 2021.', 'CO check 2026-10-15: capacity not public. +57 605 336 6700, servicliente@unibol.com.co.'),
  ('papeles del cauca|kimberly.*puerto tejada', 'puerto tejada', 'kimberly|papeles del cauca', 'Colombiana Kimberly Colpapel 의 Papeles del Cauca(Puerto Tejada) — 화장지·미용티슈·냅킨·타월.', 'Colombiana Kimberly Colpapel S.A. - Papeles del Cauca, Puerto Tejada (Cauca): toilet tissue, facial, napkins, towels (Scott, Kleenex).', 'CO check 2026-10-15: site data is in older sustainability reports - current scale to confirm.'),
  ('kimberly.*barbosa', 'barbosa', 'kimberly|colpapel', 'Kimberly-Clark Barbosa(Antioquia) — 산업용 위생지·Airflex·특수지.', 'Colombiana Kimberly Colpapel - Barbosa (Antioquia): away-home tissue, Airflex and specialty papers (Kimberly-Clark Antioquia Global).', 'CO check 2026-10-15: confirmed active in recent Kimberly-Clark material.'),
  ('(smurfit|westrock|cart[oó]n de colombia).*cali', 'cali', 'smurfit|westrock|cart[oó]n de colombia', 'Smurfit Westrock 콜롬비아 Cali 제지공장 — 골판지 원지 12.9만 + 판지 7만 + 크라프트 12.1만 = 32만 t(2025 말).', 'Smurfit Westrock (ex Cartón de Colombia) - Cali mill: 129,000 t containerboard, 70,000 t boxboard and 121,000 t kraft paper, 320,000 t/yr (end 2025, SEC).', 'CO check 2026-10-15: Colombia total 524 kt in three mills.'),
  ('(smurfit|westrock|cart[oó]n de colombia).*barbosa', 'barbosa', 'smurfit|westrock|cart[oó]n de colombia', 'Smurfit Westrock Barbosa 골판지 원지 연 12.7만 t.', 'Smurfit Westrock - Barbosa (Antioquia) containerboard mill, 127,000 t/yr (end 2025).', 'CO check 2026-10-15: strength-critical.'),
  ('(smurfit|westrock|cart[oó]n de colombia).*barranquilla', 'barranquilla', 'smurfit|westrock|cart[oó]n de colombia', 'Smurfit Westrock Barranquilla 골판지 원지 연 7.7만 t(2024 제지 680만 달러 투자).', 'Smurfit Westrock - Barranquilla (Atlántico) containerboard mill, 77,000 t/yr (end 2025), USD 6.8 m mill investment 2024.', 'CO check 2026-10-15: strength-critical.'),
  ('cartones am[eé]rica', 'cali', 'cartones am', 'Cartones América Cali 제지공장(1970 가동, 2018 증설) — 판지·골판지 원지, 페루·에콰도르·칠레·아르헨티나 사업.', 'Cartones América S.A., Calle 70 Norte 2A-130, Cali - paper mill since 1970 (capacity raised 2018): board and corrugating base paper, box plants in Cali and Mosquera, also operating in Peru, Ecuador, Chile, Argentina.', 'CO check 2026-10-15: capacity not public. +57 602 387 6990.'),
  ('papelsa', 'barbosa', 'papelsa', '1978년 설립 재생 골판지 원지 전문(제지공장 Barbosa, 골판지 Barbosa·Bogotá).', 'Papelsa (1978) - recycled corrugating base paper mill at Barbosa (Antioquia), box plants at Barbosa and Bogotá.', 'CO check 2026-10-15: capacity not public.'),
  ('empacor', 'fontib[oó]n|bogot', 'empacor', '1981년 자체 제지공장(Fontibón) — 100% 재생 라이너·골심지, 2013 약 30% 증설.', 'Empacor S.A. - own paper mill at Fontibón, Bogotá since 1981 (capacity up about 30 pct in 2013): 100 pct recycled liner and medium, two box plants.', 'CO check 2026-10-15: capacity not public.'),
  ('corrugados de colombia', null, 'corrugados de colombia', null, null, 'CO check 2026-10-15: Corrugados de Colombia - corrugated packaging, converter, context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'colombia_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('propal.*yumbo|carvajal pulpa.*yumbo', 'yumbo', 'propal|carvajal'),
  ('propal.*guachen|carvajal pulpa.*guachen', 'guachen', 'propal|carvajal'),
  ('papeles nacionales', 'pereira', 'papeles nacionales'),
  ('familia.*cajic|essity.*cajic', 'cajic', 'familia|essity'),
  ('familia.*medell|essity.*medell', 'medell', 'familia|essity'),
  ('unibol', 'soledad', 'unibol'),
  ('papeles del cauca|kimberly.*puerto tejada', 'puerto tejada', 'kimberly|papeles del cauca'),
  ('kimberly.*barbosa', 'barbosa', 'kimberly|colpapel'),
  ('(smurfit|westrock|cart[oó]n de colombia).*cali', 'cali', 'smurfit|westrock|cart[oó]n de colombia'),
  ('(smurfit|westrock|cart[oó]n de colombia).*barbosa', 'barbosa', 'smurfit|westrock|cart[oó]n de colombia'),
  ('(smurfit|westrock|cart[oó]n de colombia).*barranquilla', 'barranquilla', 'smurfit|westrock|cart[oó]n de colombia'),
  ('cartones am[eé]rica', 'cali', 'cartones am'),
  ('papelsa', 'barbosa', 'papelsa'),
  ('empacor', 'fontib[oó]n|bogot', 'empacor'),
  ('corrugados de colombia', null, 'corrugados de colombia')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('propal.*yumbo|carvajal pulpa.*yumbo', 'yumbo', 'propal|carvajal',
   $pj${"owner": "Carvajal (Propal)", "priority": 1, "products": "Printing and writing, packaging paper, board (bagasse)", "grades": ["Printing and writing", "Board"], "pitch": "Bagasse-pulp saving with FCC at equal brightness and opacity", "approach": "Lead Colombian account - check retention, drainage, tensile, smoothness on bagasse furnish. Omya Andina as producer.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('propal.*guachen|carvajal pulpa.*guachen', 'guachen', 'propal|carvajal',
   $pj${"owner": "Carvajal (Propal)", "priority": 1, "products": "Printing and writing, packaging paper", "grades": ["Printing and writing"], "approach": "Second Propal site.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papeles nacionales', 'pereira', 'papeles nacionales',
   $pj${"owner": "Papeles Nacionales", "priority": 2, "products": "Toilet tissue, napkins", "grades": ["Tissue"], "pitch": "Low-dose FCC on recycled and virgin blends", "approach": "Local tissue pilot.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('familia.*cajic|essity.*cajic', 'cajic', 'familia|essity',
   $pj${"owner": "Essity", "priority": 3, "products": "Toilet tissue, household tissue", "grades": ["Tissue"], "capacity": {"value": 70000, "unit": "metric_t", "year": "Essity 2025", "source": "essity.com"}, "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 1, "fcc_loading": 0.03}], "note": "Tissue trial assumption 3 pct - planning only."}, "approach": "Essity technical approval, trial 1-5 pct.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('familia.*medell|essity.*medell', 'medell', 'familia|essity',
   $pj${"owner": "Essity", "priority": 3, "products": "Tissue", "grades": ["Tissue"], "capacity": {"value": 30000, "unit": "metric_t", "year": "Essity 2025 (moving to Cajicá)", "source": "essity.com"}, "approach": "Check status - lines moving.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('unibol', 'soledad', 'unibol',
   $pj${"owner": "Unibol", "priority": 4, "products": "Kraft paper, toilet tissue, napkins, towels", "grades": ["Tissue", "Kraft paper"], "approach": "Tissue trial first, kraft later.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papeles del cauca|kimberly.*puerto tejada', 'puerto tejada', 'kimberly|papeles del cauca',
   $pj${"owner": "Kimberly-Clark", "priority": 5, "products": "Toilet tissue, facial, napkins, towels", "grades": ["Tissue"], "approach": "Global approval programme.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('kimberly.*barbosa', 'barbosa', 'kimberly|colpapel',
   $pj${"owner": "Kimberly-Clark", "priority": 5, "products": "Industrial tissue, Airflex", "grades": ["Tissue"], "approach": "After Puerto Tejada.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('(smurfit|westrock|cart[oó]n de colombia).*cali', 'cali', 'smurfit|westrock|cart[oó]n de colombia',
   $pj${"owner": "Smurfit Westrock", "priority": 6, "products": "Containerboard, boxboard, kraft paper", "grades": ["Containerboard", "Boxboard", "Kraft paper"], "capacity": {"value": 320000, "unit": "metric_t", "year": "Smurfit Westrock 2025 (end 2025)", "source": "SEC"}, "capacity_split": [{"label": "Containerboard", "value_t": 129000}, {"label": "Boxboard", "value_t": 70000}, {"label": "Kraft", "value_t": 121000}], "fcc": {"royalty_usd_per_t": 15, "scenarios": [{"label": "Base", "utilization": 1, "fcc_share": 0.2188, "fcc_loading": 0.05}], "note": "Boxboard line only, 5 pct - planning scenario."}, "approach": "Boxboard and selected kraft at low dose.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('(smurfit|westrock|cart[oó]n de colombia).*barbosa', 'barbosa', 'smurfit|westrock|cart[oó]n de colombia',
   $pj${"owner": "Smurfit Westrock", "products": "Containerboard", "grades": ["Containerboard"], "capacity": {"value": 127000, "unit": "metric_t", "year": "Smurfit Westrock 2025", "source": "SEC"}, "approach": "Later, after packaging-grade FCC is proven.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('(smurfit|westrock|cart[oó]n de colombia).*barranquilla', 'barranquilla', 'smurfit|westrock|cart[oó]n de colombia',
   $pj${"owner": "Smurfit Westrock", "products": "Containerboard", "grades": ["Containerboard"], "capacity": {"value": 77000, "unit": "metric_t", "year": "Smurfit Westrock 2025", "source": "SEC"}, "approach": "Later.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('cartones am[eé]rica', 'cali', 'cartones am',
   $pj${"owner": "Cartones América", "priority": 7, "products": "Board, corrugating base paper", "grades": ["Board", "Medium"], "approach": "Inner-ply trial.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('papelsa', 'barbosa', 'papelsa',
   $pj${"owner": "Papelsa", "priority": 8, "products": "Recycled corrugating base paper", "grades": ["Testliner", "Medium"], "approach": "Strength-hold pre-check.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('empacor', 'fontib[oó]n|bogot', 'empacor',
   $pj${"owner": "Empacor", "priority": 8, "products": "Recycled liner and medium", "grades": ["Testliner", "Medium"], "approach": "Strength-hold pre-check.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('corrugados de colombia', null, 'corrugados de colombia',
   $pj${"owner": "Corrugados de Colombia", "products": "Corrugated packaging", "approach": "Converter.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'CO', 'Colombia', 'high',
   $cm$Propal bagasse printing paper, Essity, Papeles Nacionales and Unibol tissue - Omya Andina GCC at Guarne$cm$,
   $cm$Omya Andina runs a GCC plant at Guarne (Antioquia) - an MBG licensee. Local GCC: Microminerales, Procomin, Colminerales, Minerales y Triturados del Caribe, Procesadora de Minerales Andina - no paper PCC plant. Fibre mix 2022: 68 pct recycled, 19 pct wood pulp, 11 pct bagasse. Lead mill Propal (Yumbo, Guachené - bagasse printing and writing), tissue at Essity (Cajicá 70 kt, Medellín 30 kt moving), Papeles Nacionales, Unibol, Kimberly-Clark. Smurfit Westrock runs 524 kt in Cali, Barbosa, Barranquilla, plus Cartones América, Papelsa, Empacor.$cm$,
   $cm${"fillers": "Licensee: Omya Andina Guarne (Omyacarb F-CG D50 1 micron). Local GCC: Microminerales (Puerto Triunfo), Procomin (Madrid), Colminerales, Minerales y Triturados del Caribe (toll grinding), Procesadora de Minerales Andina (1,500 t/month). Not added: Barahona (CALPREC PCC distributor). No MTI site.", "mills": "Printing and writing: Propal Yumbo and Guachené. Tissue: Essity Cajicá and Medellín, Papeles Nacionales Pereira, Unibol Soledad, Kimberly-Clark Puerto Tejada and Barbosa. Packaging: Smurfit Westrock Cali (320 kt), Barbosa (127 kt), Barranquilla (77 kt), Cartones América Cali, Papelsa Barbosa, Empacor Bogotá.", "strategy": "Propal printing-paper trial and Papeles Nacionales tissue trial, with Omya Andina as producer. Essity and Kimberly-Clark through group approval. Packaging later.", "risks": "Guarne is a long haul to the Cali cluster - slurry transport. Omya has competing tech. Essity Medellín winding down.", "next_steps": ["Propose a bagasse-pulp FCC trial to Propal", "Ask Omya Andina about slurry supply to Cali"], "key_numbers": [{"label": "Fibre mix 2022", "value": "recycled 68, wood 19, bagasse 11 pct (ANDI)"}, {"label": "Smurfit Westrock Colombia", "value": "524 kt in 3 mills"}, {"label": "Essity Colombia tissue", "value": "100 kt (Cajicá 70, Medellín 30)"}], "files": ["seed_20261016j_colombia_mills_fillers"]}$cm$::jsonb,
   $cm$Propal 바가스 인쇄용지 + Essity·Papeles Nacionales·Unibol 티슈 — Omya Andina Guarne GCC 공장$cm$,
   $cm$라이선시 Omya Andina 가 Guarne(Antioquia) GCC 공장 운영. 현지 GCC: Microminerales·Procomin·Colminerales·Triturados del Caribe·Procesadora Andina, 제지용 PCC 없음. 섬유 원료 2022: 재생 68%, 목재 19%, 바가스 11%. 1순위 Propal(Yumbo·Guachené 바가스 인쇄·필기), 티슈 Essity(Cajicá 7만·Medellín 3만 이전 중)·Papeles Nacionales·Unibol·Kimberly-Clark. Smurfit Westrock 52.4만 t(Cali·Barbosa·Barranquilla), Cartones América·Papelsa·Empacor.$cm$,
   3000, 6500,
   $cm$Essity 10만 t × 3% + Smurfit Cali 판지 7만 t × 5% (Propal 톤수 미공개로 제외)$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('propal.*yumbo|carvajal pulpa.*yumbo', 'yumbo', 'propal|carvajal'),
  ('propal.*guachen|carvajal pulpa.*guachen', 'guachen', 'propal|carvajal'),
  ('papeles nacionales', 'pereira', 'papeles nacionales'),
  ('familia.*cajic|essity.*cajic', 'cajic', 'familia|essity'),
  ('familia.*medell|essity.*medell', 'medell', 'familia|essity'),
  ('unibol', 'soledad', 'unibol'),
  ('papeles del cauca|kimberly.*puerto tejada', 'puerto tejada', 'kimberly|papeles del cauca'),
  ('kimberly.*barbosa', 'barbosa', 'kimberly|colpapel'),
  ('(smurfit|westrock|cart[oó]n de colombia).*cali', 'cali', 'smurfit|westrock|cart[oó]n de colombia'),
  ('(smurfit|westrock|cart[oó]n de colombia).*barbosa', 'barbosa', 'smurfit|westrock|cart[oó]n de colombia'),
  ('(smurfit|westrock|cart[oó]n de colombia).*barranquilla', 'barranquilla', 'smurfit|westrock|cart[oó]n de colombia'),
  ('cartones am[eé]rica', 'cali', 'cartones am'),
  ('papelsa', 'barbosa', 'papelsa'),
  ('empacor', 'fontib[oó]n|bogot', 'empacor'),
  ('corrugados de colombia', null, 'corrugados de colombia')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'colombia_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'colombia_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(andina|colombia)' or p.party_name ~* 'microminerales' or p.party_name ~* 'procomin' or p.party_name ~* 'colminerales|colombiana de minerales' or p.party_name ~* 'triturados del caribe' or p.party_name ~* 'procesadora de minerales andina')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'CO'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'CO'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'CO'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'CO'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    