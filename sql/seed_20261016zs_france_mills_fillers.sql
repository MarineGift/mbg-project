-- ============================================================
-- seed_20261016zs_france_mills_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- France update (reports 2026-10-16). Existing FR rows likely - name regex
-- OR city + owner regex first. Laval-sur-Vologne (Lucart, Papeteries des
-- Vosges) and Bousbecque (WEPA, Ahlstrom) kept apart by owner regex.
-- 1) Fillers if missing (2): Omya SAS, Specialty Minerals France.
-- 2) Mills if missing (13) + plant blocks, priority 1-10, plus Norske Skog
--    Golbey, Condat, Kimberly-Clark (no priority). Context (22).
-- 3) Supply link (1): SMI -> Sylvamo Saillat (2022 list, to confirm).
-- 4) app.country_markets FR row (priority high).
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
           v.party_name, 'FR', v.region, v.city, v.website, 'active', 'france_update_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(france|omey)|omya sas', 'Omya SAS - Omey', 'Grand Est', 'Omey', null, 'Omya 프랑스 법인(6 Rue Pierre Semard, Omey) — 백악·탄산칼슘 가공, 프랑스 약 8개 사업장·340명, 과거 Orgon·Salses 석회석 거점. 제지·플라스틱·도료.', 'Omya SAS, 6 Rue Pierre Semard, Omey (Marne) - chalk and calcium carbonate processing, about 8 French sites and 340 staff, historical limestone sites at Orgon and Salses / Tautavel-Vingrau, for paper, plastics, paint and adhesives.', 'FR check 2026-10-16: paper output per French plant not public. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('(specialty minerals|minerals technologies).*(france|saillat|quimperl)', 'Specialty Minerals France - Saillat and Quimperlé (satellite PCC)', 'Nouvelle-Aquitaine', 'Saillat-sur-Vienne', null, 'MTI SEC 2022 사업장 목록의 프랑스 위성 PCC 2곳 — Saillat-sur-Vienne(Haute-Vienne)·Quimperlé(Bretagne). 2005 자료 프랑스 위성 PCC 3곳 12.5만~17.5만 t.', 'Specialty Minerals (Minerals Technologies) satellite PCC plants in France listed in the MTI 2022 filing: Saillat-sur-Vienne (Haute-Vienne) and Quimperlé (Brittany). Three French satellites totalled about 125,000-175,000 t/yr in 2005.', 'FR check 2026-10-16: 2026 status, capacity and host contracts to confirm. SMI is the MBG tissue-track partner (NDA) - raise trials through that relationship.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%FR check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(france|omey)|omya sas', 'Omya SAS - Omey', 'Grand Est', 'Omey', null, 'Omya 프랑스 법인(6 Rue Pierre Semard, Omey) — 백악·탄산칼슘 가공, 프랑스 약 8개 사업장·340명, 과거 Orgon·Salses 석회석 거점. 제지·플라스틱·도료.', 'Omya SAS, 6 Rue Pierre Semard, Omey (Marne) - chalk and calcium carbonate processing, about 8 French sites and 340 staff, historical limestone sites at Orgon and Salses / Tautavel-Vingrau, for paper, plastics, paint and adhesives.', 'FR check 2026-10-16: paper output per French plant not public. Royalty licensee at Omya HQ level - Multifill and FiberLean compete with FCC.'),
  ('(specialty minerals|minerals technologies).*(france|saillat|quimperl)', 'Specialty Minerals France - Saillat and Quimperlé (satellite PCC)', 'Nouvelle-Aquitaine', 'Saillat-sur-Vienne', null, 'MTI SEC 2022 사업장 목록의 프랑스 위성 PCC 2곳 — Saillat-sur-Vienne(Haute-Vienne)·Quimperlé(Bretagne). 2005 자료 프랑스 위성 PCC 3곳 12.5만~17.5만 t.', 'Specialty Minerals (Minerals Technologies) satellite PCC plants in France listed in the MTI 2022 filing: Saillat-sur-Vienne (Haute-Vienne) and Quimperlé (Brittany). Three French satellites totalled about 125,000-175,000 t/yr in 2005.', 'FR check 2026-10-16: 2026 status, capacity and host contracts to confirm. SMI is the MBG tissue-track partner (NDA) - raise trials through that relationship.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'france_update_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya SAS - Omey', 'GCC and PCC supplier', 'Omya France - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Specialty Minerals France - Saillat and Quimperlé (satellite PCC)', 'PCC producer', 'SMI French satellites - three-way trial route', 'satellite', 'B', 'pcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'france_update_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'FR', v.region, v.city, v.website, 'active', 'france_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('sylvamo.*saillat|saillat', 'saillat', 'sylvamo|international paper', 'Sylvamo - Saillat-sur-Vienne', 'Nouvelle-Aquitaine', 'Saillat-sur-Vienne', null, '1894년 설립 통합 펄프·제지(Saillat-sur-Vienne, 약 600명) — 복사·인쇄·필기용지·시장 펄프. SMI 위성 PCC 거점 지역.', 'Sylvamo Saillat mill (founded 1894, ex International Paper), Saillat-sur-Vienne (Haute-Vienne) - integrated pulp and paper, office copy, printing and premium writing paper plus market pulp, about 600 staff. Same town as an SMI satellite PCC listed in 2022.', 'FR check 2026-10-16: capacity not public here. Current PCC supplier contract to confirm.'),
  ('clairefontaine', '[eé]tival', 'clairefontaine|exacompta', 'Papeteries de Clairefontaine - Étival-Clairefontaine', 'Grand Est', 'Étival-Clairefontaine', null, '프랑스 대표 고급 필기·사무·백색 인쇄용지 제조(19 Rue de l Abbaye, Étival-Clairefontaine), Exacompta Clairefontaine 계열.', 'Papeteries de Clairefontaine (Exacompta Clairefontaine group), 19 Rue de l Abbaye, Étival-Clairefontaine (Vosges) - premium writing, office and white printing paper.', 'FR check 2026-10-16: capacity not public here.'),
  ('essity.*kunheim|kunheim', 'kunheim', 'essity|lotus', 'Essity - Kunheim', 'Grand Est', 'Kunheim', null, 'Essity Kunheim 티슈(화장지·키친타월·티슈) + 글로벌 위생지 R&D 거점.', 'Essity Kunheim (Haut-Rhin) - toilet tissue, kitchen towel and facial (Lotus), also an Essity global hygiene-tissue R&D centre. Other French tissue sites: Gien, Hondouville (recycles over 110 kt/yr paper and cartons), Le Theil-sur-Huisne.', 'FR check 2026-10-16: capacity not public here.'),
  ('lucart.*laval|lucart', 'laval-sur-vologne', 'lucart', 'Lucart France - Laval-sur-Vologne', 'Grand Est', 'Laval-sur-Vologne', null, 'Lucart 프랑스 티슈 공장(Laval-sur-Vologne).', 'Lucart France, Laval-sur-Vologne (Vosges) - tissue mill.', 'FR check 2026-10-16: capacity not public here.'),
  ('\mwepa\M', 'troyes|bousbecque', 'wepa', 'WEPA France - Bousbecque', 'Hauts-de-France', 'Bousbecque', null, 'WEPA 프랑스 위생용지(Troyes·Bousbecque).', 'WEPA France - hygiene tissue mills at Bousbecque and Troyes.', 'FR check 2026-10-16: capacity not public here. One row for both sites.'),
  ('sofidel.*(frouard|roanne)|sofidel france', 'frouard|roanne', 'sofidel', 'Sofidel France - Frouard', 'Grand Est', 'Frouard', null, 'Sofidel 프랑스 티슈(Frouard·Roanne).', 'Sofidel France - tissue mills at Frouard and Roanne.', 'FR check 2026-10-16: capacity not public here.'),
  ('mandeure', 'mandeure', 'mandeure', 'Papeterie de Mandeure - Mandeure', 'Bourgogne-Franche-Comté', 'Mandeure', null, 'Mandeure 인쇄·필기용지.', 'Papeterie de Mandeure, Mandeure (Doubs) - printing and writing paper.', 'FR check 2026-10-16: capacity not public here.'),
  ('papeteries des vosges', 'laval-sur-vologne', 'papeteries des vosges', 'Papeteries des Vosges - Laval-sur-Vologne', 'Grand Est', 'Laval-sur-Vologne', null, 'Laval-sur-Vologne 고급 인쇄·특수지.', 'Papeteries des Vosges, Laval-sur-Vologne (Vosges) - fine printing and specialty papers.', 'FR check 2026-10-16: capacity not public here.'),
  ('\mict france|ict.*pannes', 'pannes', '\mict\M|tronchetti', 'ICT France - Pannes', 'Centre-Val de Loire', 'Pannes', null, 'ICT Group 프랑스 위생용지(Pannes).', 'ICT France (ICT Group), Pannes (Loiret) - hygiene tissue.', 'FR check 2026-10-16: capacity not public here.'),
  ('ahlstrom.*(france|pont|bousbecque)', 'pont-[eé]v[eê]que|pont-audemer|bousbecque', 'ahlstrom', 'Ahlstrom France', null, null, null, 'Ahlstrom 프랑스 여과지·기능성 특수지(Pont-Évêque·Pont-Audemer·Bousbecque 등).', 'Ahlstrom France - filter and functional specialty papers at Pont-Évêque, Pont-Audemer, Bousbecque and other sites.', 'FR check 2026-10-16: one group row - site split to collect.'),
  ('norske skog.*golbey|golbey', 'golbey', 'norske skog', 'Norske Skog Golbey', 'Grand Est', 'Golbey', null, 'Golbey 신문용지 + PM1 재생 골판지원지 전환(2025-10 인수 완료, 2027 상반기 완전 가동 목표).', 'Norske Skog Golbey (Vosges) - newsprint plus PM1 converted to recycled containerboard (asset purchase completed 2025-10, full run targeted H1 2027).', 'FR check 2026-10-16: containerboard shift lowers filler use.'),
  ('condat', 'lardin', 'lecta|condat', 'Papeteries de Condat (Lecta) - Le Lardin-Saint-Lazare', 'Nouvelle-Aquitaine', 'Le Lardin-Saint-Lazare', null, 'Lecta Condat — 과거 양면 코팅지(PM4)·글라신(PM8), 경영난·설비 축소(2026-09 상원 답변).', 'Papeteries de Condat (Lecta), Le Lardin-Saint-Lazare (Dordogne) - formerly double-coated paper (PM4) and glassine (PM8), cut back amid financial difficulty (French Senate answer 2026-09).', 'FR check 2026-10-16: glassine needs transparency - poor carbonate fit. Status to confirm.'),
  ('kimberly.*villey|villey-saint', 'villey', 'kimberly', 'Kimberly-Clark - Villey-Saint-Étienne', 'Grand Est', 'Villey-Saint-Étienne', null, 'Kimberly-Clark 프랑스 위생용지(Villey-Saint-Étienne, Sotteville-lès-Rouen 별도).', 'Kimberly-Clark France - tissue at Villey-Saint-Étienne (Meurthe-et-Moselle), also a site at Sotteville-lès-Rouen.', 'FR check 2026-10-16: paper machine scope to confirm.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%FR check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sylvamo.*saillat|saillat', 'saillat', 'sylvamo|international paper', '1894년 설립 통합 펄프·제지(Saillat-sur-Vienne, 약 600명) — 복사·인쇄·필기용지·시장 펄프. SMI 위성 PCC 거점 지역.', 'Sylvamo Saillat mill (founded 1894, ex International Paper), Saillat-sur-Vienne (Haute-Vienne) - integrated pulp and paper, office copy, printing and premium writing paper plus market pulp, about 600 staff. Same town as an SMI satellite PCC listed in 2022.', 'FR check 2026-10-16: capacity not public here. Current PCC supplier contract to confirm.'),
  ('clairefontaine', '[eé]tival', 'clairefontaine|exacompta', '프랑스 대표 고급 필기·사무·백색 인쇄용지 제조(19 Rue de l Abbaye, Étival-Clairefontaine), Exacompta Clairefontaine 계열.', 'Papeteries de Clairefontaine (Exacompta Clairefontaine group), 19 Rue de l Abbaye, Étival-Clairefontaine (Vosges) - premium writing, office and white printing paper.', 'FR check 2026-10-16: capacity not public here.'),
  ('essity.*kunheim|kunheim', 'kunheim', 'essity|lotus', 'Essity Kunheim 티슈(화장지·키친타월·티슈) + 글로벌 위생지 R&D 거점.', 'Essity Kunheim (Haut-Rhin) - toilet tissue, kitchen towel and facial (Lotus), also an Essity global hygiene-tissue R&D centre. Other French tissue sites: Gien, Hondouville (recycles over 110 kt/yr paper and cartons), Le Theil-sur-Huisne.', 'FR check 2026-10-16: capacity not public here.'),
  ('lucart.*laval|lucart', 'laval-sur-vologne', 'lucart', 'Lucart 프랑스 티슈 공장(Laval-sur-Vologne).', 'Lucart France, Laval-sur-Vologne (Vosges) - tissue mill.', 'FR check 2026-10-16: capacity not public here.'),
  ('\mwepa\M', 'troyes|bousbecque', 'wepa', 'WEPA 프랑스 위생용지(Troyes·Bousbecque).', 'WEPA France - hygiene tissue mills at Bousbecque and Troyes.', 'FR check 2026-10-16: capacity not public here. One row for both sites.'),
  ('sofidel.*(frouard|roanne)|sofidel france', 'frouard|roanne', 'sofidel', 'Sofidel 프랑스 티슈(Frouard·Roanne).', 'Sofidel France - tissue mills at Frouard and Roanne.', 'FR check 2026-10-16: capacity not public here.'),
  ('mandeure', 'mandeure', 'mandeure', 'Mandeure 인쇄·필기용지.', 'Papeterie de Mandeure, Mandeure (Doubs) - printing and writing paper.', 'FR check 2026-10-16: capacity not public here.'),
  ('papeteries des vosges', 'laval-sur-vologne', 'papeteries des vosges', 'Laval-sur-Vologne 고급 인쇄·특수지.', 'Papeteries des Vosges, Laval-sur-Vologne (Vosges) - fine printing and specialty papers.', 'FR check 2026-10-16: capacity not public here.'),
  ('\mict france|ict.*pannes', 'pannes', '\mict\M|tronchetti', 'ICT Group 프랑스 위생용지(Pannes).', 'ICT France (ICT Group), Pannes (Loiret) - hygiene tissue.', 'FR check 2026-10-16: capacity not public here.'),
  ('ahlstrom.*(france|pont|bousbecque)', 'pont-[eé]v[eê]que|pont-audemer|bousbecque', 'ahlstrom', 'Ahlstrom 프랑스 여과지·기능성 특수지(Pont-Évêque·Pont-Audemer·Bousbecque 등).', 'Ahlstrom France - filter and functional specialty papers at Pont-Évêque, Pont-Audemer, Bousbecque and other sites.', 'FR check 2026-10-16: one group row - site split to collect.'),
  ('norske skog.*golbey|golbey', 'golbey', 'norske skog', 'Golbey 신문용지 + PM1 재생 골판지원지 전환(2025-10 인수 완료, 2027 상반기 완전 가동 목표).', 'Norske Skog Golbey (Vosges) - newsprint plus PM1 converted to recycled containerboard (asset purchase completed 2025-10, full run targeted H1 2027).', 'FR check 2026-10-16: containerboard shift lowers filler use.'),
  ('condat', 'lardin', 'lecta|condat', 'Lecta Condat — 과거 양면 코팅지(PM4)·글라신(PM8), 경영난·설비 축소(2026-09 상원 답변).', 'Papeteries de Condat (Lecta), Le Lardin-Saint-Lazare (Dordogne) - formerly double-coated paper (PM4) and glassine (PM8), cut back amid financial difficulty (French Senate answer 2026-09).', 'FR check 2026-10-16: glassine needs transparency - poor carbonate fit. Status to confirm.'),
  ('kimberly.*villey|villey-saint', 'villey', 'kimberly', 'Kimberly-Clark 프랑스 위생용지(Villey-Saint-Étienne, Sotteville-lès-Rouen 별도).', 'Kimberly-Clark France - tissue at Villey-Saint-Étienne (Meurthe-et-Moselle), also a site at Sotteville-lès-Rouen.', 'FR check 2026-10-16: paper machine scope to confirm.'),
  ('essity.*gien', null, 'essity.*gien', null, null, 'FR check 2026-10-16: Gien tissue - 2.6 m rolls and 7 m tissues per day - context only.'),
  ('essity.*hondouville', null, 'essity.*hondouville', null, null, 'FR check 2026-10-16: Hondouville recycled tissue - over 110 kt/yr recovered paper and cartons - context only.'),
  ('essity.*theil', null, 'essity.*theil', null, null, 'FR check 2026-10-16: Le Theil-sur-Huisne tissue - context only.'),
  ('canson', null, 'canson', null, null, 'FR check 2026-10-16: Art and drawing paper, Annonay - context only.'),
  ('everbal', null, 'everbal', null, null, 'FR check 2026-10-16: Recycled printing and writing paper, Evergnicourt - context only.'),
  ('zuber rieder', null, 'zuber rieder', null, null, 'FR check 2026-10-16: Fine specialty paper, Boussières - context only.'),
  ('papeteries de vizille|vizille', null, 'papeteries de vizille|vizille', null, null, 'FR check 2026-10-16: Specialty and packaging paper, Vizille - context only.'),
  ('gascogne', null, 'gascogne', null, null, 'FR check 2026-10-16: Kraft paper, Mimizan - context only.'),
  ('papeco', null, 'papeco', null, null, 'FR check 2026-10-16: Tissue, Coutances - context only.'),
  ('mp hygi[eè]ne', null, 'mp hygi[eè]ne', null, null, 'FR check 2026-10-16: Tissue, Annonay - context only.'),
  ('fregata', null, 'fregata', null, null, 'FR check 2026-10-16: Tissue, Charavines - context only.'),
  ('le bourray', null, 'le bourray', null, null, 'FR check 2026-10-16: Tissue, Saint-Mars-la-Brière - context only.'),
  ('smurfit.*(biganos|facture|rethel)', null, 'smurfit.*(biganos|facture|rethel)', null, null, 'FR check 2026-10-16: Kraftliner and containerboard, Biganos, Rethel - context only.'),
  ('ds smith.*(rouen|kaysersberg|contoire)|international paper.*rouen', null, 'ds smith.*(rouen|kaysersberg|contoire)|international paper.*rouen', null, null, 'FR check 2026-10-16: Containerboard, Rouen, Kaysersberg, Contoire-Hamel - context only.'),
  ('saica.*(laveyron|nogent|venizel)', null, 'saica.*(laveyron|nogent|venizel)', null, null, 'FR check 2026-10-16: Recycled containerboard, Laveyron, Nogent-sur-Seine, Venizel - context only.'),
  ('\mvpk\M.*alizay|alizay', null, '\mvpk\M.*alizay|alizay', null, null, 'FR check 2026-10-16: Recycled packaging, Alizay - context only.'),
  ('blue paper', null, 'blue paper', null, null, 'FR check 2026-10-16: Recycled containerboard, Strasbourg - context only.'),
  ('palm.*descartes', null, 'palm.*descartes', null, null, 'FR check 2026-10-16: Containerboard, Descartes - context only.'),
  ('gemdoubs', null, 'gemdoubs', null, null, 'FR check 2026-10-16: Recycled containerboard, Novillars - context only.'),
  ('norpaper', null, 'norpaper', null, null, 'FR check 2026-10-16: Containerboard, Blendecques, Nantes - context only.'),
  ('rossmann', null, 'rossmann', null, null, 'FR check 2026-10-16: Packaging paper, Sainte-Croix-aux-Mines - context only.'),
  ('allard', null, 'allard', null, null, 'FR check 2026-10-16: Containerboard, Aubigné-Racan - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'france_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sylvamo.*saillat|saillat', 'saillat', 'sylvamo|international paper'),
  ('clairefontaine', '[eé]tival', 'clairefontaine|exacompta'),
  ('essity.*kunheim|kunheim', 'kunheim', 'essity|lotus'),
  ('lucart.*laval|lucart', 'laval-sur-vologne', 'lucart'),
  ('\mwepa\M', 'troyes|bousbecque', 'wepa'),
  ('sofidel.*(frouard|roanne)|sofidel france', 'frouard|roanne', 'sofidel'),
  ('mandeure', 'mandeure', 'mandeure'),
  ('papeteries des vosges', 'laval-sur-vologne', 'papeteries des vosges'),
  ('\mict france|ict.*pannes', 'pannes', '\mict\M|tronchetti'),
  ('ahlstrom.*(france|pont|bousbecque)', 'pont-[eé]v[eê]que|pont-audemer|bousbecque', 'ahlstrom'),
  ('norske skog.*golbey|golbey', 'golbey', 'norske skog'),
  ('condat', 'lardin', 'lecta|condat'),
  ('kimberly.*villey|villey-saint', 'villey', 'kimberly'),
  ('essity.*gien', null, 'essity.*gien'),
  ('essity.*hondouville', null, 'essity.*hondouville'),
  ('essity.*theil', null, 'essity.*theil'),
  ('canson', null, 'canson'),
  ('everbal', null, 'everbal'),
  ('zuber rieder', null, 'zuber rieder'),
  ('papeteries de vizille|vizille', null, 'papeteries de vizille|vizille'),
  ('gascogne', null, 'gascogne'),
  ('papeco', null, 'papeco'),
  ('mp hygi[eè]ne', null, 'mp hygi[eè]ne'),
  ('fregata', null, 'fregata'),
  ('le bourray', null, 'le bourray'),
  ('smurfit.*(biganos|facture|rethel)', null, 'smurfit.*(biganos|facture|rethel)'),
  ('ds smith.*(rouen|kaysersberg|contoire)|international paper.*rouen', null, 'ds smith.*(rouen|kaysersberg|contoire)|international paper.*rouen'),
  ('saica.*(laveyron|nogent|venizel)', null, 'saica.*(laveyron|nogent|venizel)'),
  ('\mvpk\M.*alizay|alizay', null, '\mvpk\M.*alizay|alizay'),
  ('blue paper', null, 'blue paper'),
  ('palm.*descartes', null, 'palm.*descartes'),
  ('gemdoubs', null, 'gemdoubs'),
  ('norpaper', null, 'norpaper'),
  ('rossmann', null, 'rossmann'),
  ('allard', null, 'allard')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('sylvamo.*saillat|saillat', 'saillat', 'sylvamo|international paper',
   $pj${"owner": "Sylvamo", "priority": 1, "products": "Office copy paper, printing and writing, market pulp", "grades": ["UWF", "Copy paper"], "pitch": "Sylvamo + SMI + MBG three-way FCC trial (as in Brazil)", "approach": "Lead French account.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('clairefontaine', '[eé]tival', 'clairefontaine|exacompta',
   $pj${"owner": "Exacompta Clairefontaine", "priority": 2, "products": "Premium writing and office paper", "grades": ["UWF"], "pitch": "Quality-kept pulp saving, FCC 3-5-10 pct at 70-100 g/m2", "approach": "Second French printing account.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*kunheim|kunheim', 'kunheim', 'essity|lotus',
   $pj${"owner": "Essity", "priority": 3, "products": "Tissue", "grades": ["Tissue"], "pitch": "Tissue FCC through the Kunheim R&D centre", "approach": "Global R&D route.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('lucart.*laval|lucart', 'laval-sur-vologne', 'lucart',
   $pj${"owner": "Lucart", "priority": 4, "products": "Tissue", "grades": ["Tissue"], "approach": "Recycled tissue trial - link with Lucart Italy.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mwepa\M', 'troyes|bousbecque', 'wepa',
   $pj${"owner": "WEPA", "priority": 5, "products": "Tissue", "grades": ["Tissue"], "approach": "European tissue network.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('sofidel.*(frouard|roanne)|sofidel france', 'frouard|roanne', 'sofidel',
   $pj${"owner": "Sofidel", "priority": 6, "products": "Tissue", "grades": ["Tissue"], "approach": "Group trial path with Sofidel Italy.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mandeure', 'mandeure', 'mandeure',
   $pj${"owner": "Papeterie de Mandeure", "priority": 7, "products": "Printing and writing paper", "grades": ["UWF"], "approach": "Mid-size printing trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papeteries des vosges', 'laval-sur-vologne', 'papeteries des vosges',
   $pj${"owner": "Papeteries des Vosges", "priority": 8, "products": "Fine printing and specialty paper", "grades": ["UWF", "Specialty paper"], "approach": "Specialty trial.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mict france|ict.*pannes', 'pannes', '\mict\M|tronchetti',
   $pj${"owner": "ICT Group", "priority": 9, "products": "Tissue", "grades": ["Tissue"], "approach": "Link with ICT Italy and Spain.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ahlstrom.*(france|pont|bousbecque)', 'pont-[eé]v[eê]que|pont-audemer|bousbecque', 'ahlstrom',
   $pj${"owner": "Ahlstrom", "priority": 10, "products": "Filter and specialty paper", "grades": ["Specialty paper"], "approach": "Functional specialty co-development.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('norske skog.*golbey|golbey', 'golbey', 'norske skog',
   $pj${"owner": "Norske Skog", "products": "Newsprint, recycled containerboard", "grades": ["Newsprint", "Testliner"], "approach": "Recycled-fibre strength trial later.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('condat', 'lardin', 'lecta|condat',
   $pj${"owner": "Lecta", "products": "Glassine, coated paper (reduced)", "grades": ["Specialty paper"], "approach": "Conditional - check status.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kimberly.*villey|villey-saint', 'villey', 'kimberly',
   $pj${"owner": "Kimberly-Clark", "products": "Tissue, industrial wipers", "grades": ["Tissue"], "approach": "Industrial wipers first.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*gien', null, 'essity.*gien',
   $pj${"owner": "Essity", "products": "Gien tissue - 2.6 m rolls and 7 m tissues per day", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*hondouville', null, 'essity.*hondouville',
   $pj${"owner": "Essity", "products": "Hondouville recycled tissue - over 110 kt/yr recovered paper and cartons", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('essity.*theil', null, 'essity.*theil',
   $pj${"owner": "Essity", "products": "Le Theil-sur-Huisne tissue", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('canson', null, 'canson',
   $pj${"owner": "Canson", "products": "Art and drawing paper, Annonay", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('everbal', null, 'everbal',
   $pj${"owner": "Everbal", "products": "Recycled printing and writing paper, Evergnicourt", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('zuber rieder', null, 'zuber rieder',
   $pj${"owner": "Zuber Rieder", "products": "Fine specialty paper, Boussières", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papeteries de vizille|vizille', null, 'papeteries de vizille|vizille',
   $pj${"owner": "Papeteries de Vizille", "products": "Specialty and packaging paper, Vizille", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('gascogne', null, 'gascogne',
   $pj${"owner": "Gascogne Papier", "products": "Kraft paper, Mimizan", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papeco', null, 'papeco',
   $pj${"owner": "PAPECO", "products": "Tissue, Coutances", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('mp hygi[eè]ne', null, 'mp hygi[eè]ne',
   $pj${"owner": "MP Hygiène", "products": "Tissue, Annonay", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('fregata', null, 'fregata',
   $pj${"owner": "Fregata Hygiène", "products": "Tissue, Charavines", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('le bourray', null, 'le bourray',
   $pj${"owner": "Papeterie Le Bourray", "products": "Tissue, Saint-Mars-la-Brière", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('smurfit.*(biganos|facture|rethel)', null, 'smurfit.*(biganos|facture|rethel)',
   $pj${"owner": "Smurfit Westrock", "products": "Kraftliner and containerboard, Biganos, Rethel", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ds smith.*(rouen|kaysersberg|contoire)|international paper.*rouen', null, 'ds smith.*(rouen|kaysersberg|contoire)|international paper.*rouen',
   $pj${"owner": "International Paper (DS Smith)", "products": "Containerboard, Rouen, Kaysersberg, Contoire-Hamel", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('saica.*(laveyron|nogent|venizel)', null, 'saica.*(laveyron|nogent|venizel)',
   $pj${"owner": "Saica", "products": "Recycled containerboard, Laveyron, Nogent-sur-Seine, Venizel", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('\mvpk\M.*alizay|alizay', null, '\mvpk\M.*alizay|alizay',
   $pj${"owner": "VPK", "products": "Recycled packaging, Alizay", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('blue paper', null, 'blue paper',
   $pj${"owner": "Blue Paper", "products": "Recycled containerboard, Strasbourg", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('palm.*descartes', null, 'palm.*descartes',
   $pj${"owner": "Palm", "products": "Containerboard, Descartes", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('gemdoubs', null, 'gemdoubs',
   $pj${"owner": "Gemdoubs", "products": "Recycled containerboard, Novillars", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('norpaper', null, 'norpaper',
   $pj${"owner": "NorPaper", "products": "Containerboard, Blendecques, Nantes", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('rossmann', null, 'rossmann',
   $pj${"owner": "Rossmann", "products": "Packaging paper, Sainte-Croix-aux-Mines", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('allard', null, 'allard',
   $pj${"owner": "Allard Emballages", "products": "Containerboard, Aubigné-Racan", "approach": "Collect data.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 4) SUPPLY LINKS ----------
insert into app.party_supply_links
  (id, organization_id, mill_party_id, filler_party_id, link_type,
   product_grade, volume_estimate, confidence, active_since, active_until,
   notes, extra_data, created_at, updated_at)
select gen_random_uuid(), 'b25de8f2-1020-482f-9012-183f63883169'::uuid, m.id, f.id, v.link_type, 'PCC filler-grade', v.vol, v.conf, v.since, v.until, v.label,
       jsonb_build_object('supply_structure', v.structure, 'source', v.src, 'batch', 'france_update_20261016', 'researched_at', '2026-10-15'),
       now(), now()
from (values
  ('sylvamo.*saillat|saillat', 'saillat', 'sylvamo|international paper', '(specialty minerals|minerals technologies).*(france|saillat|quimperl)', 'active', 'medium', null::date, null::date, null, 'satellite PCC at the mill', 'MTI 2022 SEC property list', 'SMI satellite PCC at Saillat-sur-Vienne (2022 list) - 2026 status and contract to confirm')
) as v(name_rx, city_rx, owner_rx, filler_rx, link_type, conf, since, until, vol, structure, src, label)
cross join lateral (select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id) m
cross join lateral (
  select x.id from app.parties x
  where x.party_type_id = 3 and x.deleted_at is null and x.party_name ~* v.filler_rx
  order by x.created_at limit 1
) f
where m.id is not null
  and not exists (select 1 from app.party_supply_links l
                  where l.mill_party_id = m.id and l.filler_party_id = f.id and l.deleted_at is null);

-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'FR', 'France', 'high',
   $cm$73 mills - Sylvamo Saillat and Clairefontaine printing paper, Essity, Lucart, WEPA, Sofidel tissue - Omya France and SMI satellite PCC (Saillat, Quimperlé)$cm$,
   $cm$France has 73 paper mills (COPACEL). FCC-fit: Sylvamo Saillat (integrated UWF, SMI satellite PCC in the same town) and Clairefontaine (premium writing), Mandeure, Papeteries des Vosges, plus tissue at Essity (Kunheim R&D, Gien, Hondouville), Lucart, WEPA, Sofidel, ICT, Kimberly-Clark. Large containerboard (Smurfit Westrock, IP / DS Smith, Saica, Norske Skog Golbey PM1 conversion). Fillers: Omya SAS (Omey, licensee) and SMI satellites at Saillat and Quimperlé (2022 filing). Imerys sold its paper-minerals business to Flacks Group in 2024 - former Imerys sites now under Flacks.$cm$,
   $cm${"fillers": "GCC: Omya SAS (Omey, Orgon, Salses). Satellite PCC: SMI Saillat-sur-Vienne and Quimperlé. Imerys paper minerals sold to Flacks Group 2024 (24 plants, EUR 370 m sales) - follow up Flacks. Lime: Lhoist, Carmeuse (raw only, not added).", "mills": "Printing: Sylvamo Saillat, Clairefontaine, Mandeure, Papeteries des Vosges. Tissue: Essity Kunheim, Lucart, WEPA, Sofidel, ICT France, Kimberly-Clark. Specialty: Ahlstrom, Condat (reduced). Newsprint and liner: Norske Skog Golbey. Context: about 22 more mills.", "strategy": "Sylvamo Saillat + SMI + MBG three-way trial (mirrors Brazil), Clairefontaine quality-kept pulp saving, Essity Kunheim R&D for tissue. Omya via HQ.", "risks": "SMI and Omya control fillers, Omya competing tech, Condat and Lecta status.", "next_steps": ["Raise a Saillat three-way trial with SMI and Sylvamo", "Identify the Flacks Group company holding ex-Imerys paper minerals"], "key_numbers": [{"label": "Paper mills", "value": "73 (COPACEL)"}, {"label": "Satellite PCC 2005", "value": "3 units, 125-175 kt/yr"}, {"label": "Imerys paper minerals sale", "value": "2024-07 to Flacks, EUR 150 m"}], "files": ["seed_20261016zs_france_mills_fillers"]}$cm$::jsonb,
   $cm$제지공장 73곳 — Sylvamo Saillat·Clairefontaine 인쇄용지, Essity·Lucart·WEPA·Sofidel 티슈 — Omya France·SMI 위성 PCC(Saillat·Quimperlé)$cm$,
   $cm$프랑스 제지공장 73곳(COPACEL). FCC 적합: Sylvamo Saillat(통합 UWF, 같은 도시에 SMI 위성 PCC)·Clairefontaine(고급 필기)·Mandeure·Papeteries des Vosges, 티슈 Essity(Kunheim R&D·Gien·Hondouville)·Lucart·WEPA·Sofidel·ICT·Kimberly-Clark. 대형 골판지원지 다수. 충전제: Omya SAS(Omey, 라이선시), SMI 위성 PCC Saillat·Quimperlé(2022 공시). Imerys 제지용 광물사업은 2024 Flacks Group 에 매각.$cm$,
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
      ('sylvamo.*saillat|saillat', 'saillat', 'sylvamo|international paper'),
  ('clairefontaine', '[eé]tival', 'clairefontaine|exacompta'),
  ('essity.*kunheim|kunheim', 'kunheim', 'essity|lotus'),
  ('lucart.*laval|lucart', 'laval-sur-vologne', 'lucart'),
  ('\mwepa\M', 'troyes|bousbecque', 'wepa'),
  ('sofidel.*(frouard|roanne)|sofidel france', 'frouard|roanne', 'sofidel'),
  ('mandeure', 'mandeure', 'mandeure'),
  ('papeteries des vosges', 'laval-sur-vologne', 'papeteries des vosges'),
  ('\mict france|ict.*pannes', 'pannes', '\mict\M|tronchetti'),
  ('ahlstrom.*(france|pont|bousbecque)', 'pont-[eé]v[eê]que|pont-audemer|bousbecque', 'ahlstrom'),
  ('norske skog.*golbey|golbey', 'golbey', 'norske skog'),
  ('condat', 'lardin', 'lecta|condat'),
  ('kimberly.*villey|villey-saint', 'villey', 'kimberly'),
  ('essity.*gien', null, 'essity.*gien'),
  ('essity.*hondouville', null, 'essity.*hondouville'),
  ('essity.*theil', null, 'essity.*theil'),
  ('canson', null, 'canson'),
  ('everbal', null, 'everbal'),
  ('zuber rieder', null, 'zuber rieder'),
  ('papeteries de vizille|vizille', null, 'papeteries de vizille|vizille'),
  ('gascogne', null, 'gascogne'),
  ('papeco', null, 'papeco'),
  ('mp hygi[eè]ne', null, 'mp hygi[eè]ne'),
  ('fregata', null, 'fregata'),
  ('le bourray', null, 'le bourray'),
  ('smurfit.*(biganos|facture|rethel)', null, 'smurfit.*(biganos|facture|rethel)'),
  ('ds smith.*(rouen|kaysersberg|contoire)|international paper.*rouen', null, 'ds smith.*(rouen|kaysersberg|contoire)|international paper.*rouen'),
  ('saica.*(laveyron|nogent|venizel)', null, 'saica.*(laveyron|nogent|venizel)'),
  ('\mvpk\M.*alizay|alizay', null, '\mvpk\M.*alizay|alizay'),
  ('blue paper', null, 'blue paper'),
  ('palm.*descartes', null, 'palm.*descartes'),
  ('gemdoubs', null, 'gemdoubs'),
  ('norpaper', null, 'norpaper'),
  ('rossmann', null, 'rossmann'),
  ('allard', null, 'allard')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'france_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'france_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(france|omey)|omya sas' or p.party_name ~* '(specialty minerals|minerals technologies).*(france|saillat|quimperl)')
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'FR'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'FR'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'FR'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'FR'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    