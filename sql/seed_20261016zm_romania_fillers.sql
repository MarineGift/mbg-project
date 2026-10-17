-- ============================================================
-- seed_20261016zm_romania_fillers.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Romania filler report (2026-10-16). The mill part of the paste was the
-- Serbia report again, so no Romanian mills yet.
-- 1) Fillers if missing (3): Omya Calcita Voislova, Carmeuse Romania,
--    Tempo Invest.
-- 2) app.country_markets RO row (provisional, medium). Verify lists any
--    existing RO mills.
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
           v.party_name, 'RO', v.region, v.city, v.website, 'active', 'romania_fillers_20261016',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('omya.*(calcita|roman)', 'Omya Calcita - Voislova', 'Caraș-Severin', 'Voislova', null, 'Omya 루마니아 법인 Omya Calcita(1995) — Voislova(Zăvoi, Caraș-Severin) 대리석 미분쇄 공장, 부쿠레슈티 영업. 2025 매출 1.57억 RON·71명, ISO 9001·14001·45001.', 'Omya Calcita SRL (1995, Omya group), plant at Voislova 202, Zăvoi (Caraș-Severin) grinding marble to natural calcium carbonate powders (20, 60, 90 micron grades listed), sales office Str. Doina Cornea 2F, Bucharest. 2025 sales RON 156.8 m, 71 staff, ISO 9001, 14001, 45001.', 'RO check 2026-10-16: paper grades at Voislova and any Romanian PCC not confirmed. +40 21 200 95 00. Royalty licensee at Omya HQ level.'),
  ('carmeuse.*(roman|bra[sș]ov|c[aâ]mpulung|deva|fieni)', 'Carmeuse Romania - Brașov', 'Brașov', 'Brașov', null, 'Carmeuse 루마니아(본사 Brașov) — Câmpulung·Deva/Chișcădaga·Fieni·Pojoga 석회석·생석회·소석회. 그룹 차원 PCC 용 석회 솔루션.', 'Carmeuse Holding SRL, Str. Carierei 127A, Brașov - limestone, quicklime and hydrated lime plants at Câmpulung (Argeș), Deva / Chișcădaga and Pojoga (Hunedoara), Fieni (Dâmbovița). The group supplies lime and know-how for PCC making.', 'RO check 2026-10-16: no Romanian PCC or paper GCC confirmed. office@carmeuse.ro, +40 368 729 002. Lime partner for a future PCC or FCC line.'),
  ('tempo invest', 'Tempo Invest - Murfatlar', 'Constanța', 'Murfatlar', null, '2003년 설립 루마니아 독립 탄산칼슘 채굴·가공(Murfatlar) — 아스팔트·사료·농업·플라스틱·건축용. 2025 매출 2,373만 RON, 134명.', 'Tempo Invest SRL (2003, CUI 15815436), Strada Credinței 1, Murfatlar (Constanța) - independent calcium carbonate quarrying and processing for asphalt filler, feed, agriculture, plastics, rubber and building. 2025 sales RON 23.7 m, 134 staff, small net loss.', 'RO check 2026-10-16: no paper grade. +40 241 234 214. Possible OEM pilot partner. No paper PCC plant found in Romania.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where not exists (
      select 1 from app.parties p
      where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
    );

    -- existing filler rows: fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), v.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), v.intro_en),
        notes = case when coalesce(p.notes, '') ilike '%RO check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || v.notes end,
        updated_at = now()
    from (values
      ('omya.*(calcita|roman)', 'Omya Calcita - Voislova', 'Caraș-Severin', 'Voislova', null, 'Omya 루마니아 법인 Omya Calcita(1995) — Voislova(Zăvoi, Caraș-Severin) 대리석 미분쇄 공장, 부쿠레슈티 영업. 2025 매출 1.57억 RON·71명, ISO 9001·14001·45001.', 'Omya Calcita SRL (1995, Omya group), plant at Voislova 202, Zăvoi (Caraș-Severin) grinding marble to natural calcium carbonate powders (20, 60, 90 micron grades listed), sales office Str. Doina Cornea 2F, Bucharest. 2025 sales RON 156.8 m, 71 staff, ISO 9001, 14001, 45001.', 'RO check 2026-10-16: paper grades at Voislova and any Romanian PCC not confirmed. +40 21 200 95 00. Royalty licensee at Omya HQ level.'),
  ('carmeuse.*(roman|bra[sș]ov|c[aâ]mpulung|deva|fieni)', 'Carmeuse Romania - Brașov', 'Brașov', 'Brașov', null, 'Carmeuse 루마니아(본사 Brașov) — Câmpulung·Deva/Chișcădaga·Fieni·Pojoga 석회석·생석회·소석회. 그룹 차원 PCC 용 석회 솔루션.', 'Carmeuse Holding SRL, Str. Carierei 127A, Brașov - limestone, quicklime and hydrated lime plants at Câmpulung (Argeș), Deva / Chișcădaga and Pojoga (Hunedoara), Fieni (Dâmbovița). The group supplies lime and know-how for PCC making.', 'RO check 2026-10-16: no Romanian PCC or paper GCC confirmed. office@carmeuse.ro, +40 368 729 002. Lime partner for a future PCC or FCC line.'),
  ('tempo invest', 'Tempo Invest - Murfatlar', 'Constanța', 'Murfatlar', null, '2003년 설립 루마니아 독립 탄산칼슘 채굴·가공(Murfatlar) — 아스팔트·사료·농업·플라스틱·건축용. 2025 매출 2,373만 RON, 134명.', 'Tempo Invest SRL (2003, CUI 15815436), Strada Credinței 1, Murfatlar (Constanța) - independent calcium carbonate quarrying and processing for asphalt filler, feed, agriculture, plastics, rubber and building. 2025 sales RON 23.7 m, 134 staff, small net loss.', 'RO check 2026-10-16: no paper grade. +40 241 234 214. Possible OEM pilot partner. No paper PCC plant found in Romania.')
    ) as v(guard_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where p.party_type_id = 3 and p.deleted_at is null and p.party_name ~* v.guard_rx
      and coalesce(p.source, '') <> 'romania_fillers_20261016';
    
insert into app.filler_supplier_profile
      (party_id, organization_id, supplier_type, market_role, supply_model, evidence_level,
       mineral_class, industry_source, extra_data, created_at, updated_at)
    select p.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, d.supplier_type, d.market_role, d.supply_model, d.evidence_level,
           d.mineral_class, 'industry-research', '{}'::jsonb, now(), now()
    from app.parties p
    join (values
      ('Omya Calcita - Voislova', 'GCC producer', 'Omya Romania GCC plant - royalty licensee (Omya HQ)', 'merchant', 'B', 'gcc'),
  ('Carmeuse Romania - Brașov', 'Lime producer', 'Lime base - future PCC partner', 'merchant', 'C', 'pcc'),
  ('Tempo Invest - Murfatlar', 'GCC producer', 'Independent carbonate maker - OEM candidate', 'merchant', 'C', 'gcc')
    ) as d(party_name, supplier_type, market_role, supply_model, evidence_level, mineral_class)
      on p.party_name = d.party_name
    where p.party_type_id = 3 and p.deleted_at is null and p.source = 'romania_fillers_20261016'
      and not exists (select 1 from app.filler_supplier_profile fp where fp.party_id = p.id);
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'RO', 'Romania', 'medium',
   $cm$Provisional - Omya Calcita GCC at Voislova, Carmeuse lime, Tempo Invest - mill report pending$cm$,
   $cm$Filler side only so far: Omya Calcita runs a marble GCC plant at Voislova (licensee, RON 157 m sales), Carmeuse has four lime plants (PCC raw-material partner), Tempo Invest is an independent carbonate maker at Murfatlar. No Romanian paper PCC plant was found. Priority is provisional until the Romanian paper-mill report is entered.$cm$,
   $cm${"fillers": "GCC: Omya Calcita Voislova (licensee), Tempo Invest Murfatlar. Lime: Carmeuse Romania (Câmpulung, Deva, Fieni, Pojoga). No PCC found.", "mills": "Mill report not yet entered (the paste repeated the Serbia report).", "strategy": "Omya Calcita via Omya HQ, Carmeuse for a lime-based PCC or FCC line. Mills to follow.", "risks": "No mill data yet.", "next_steps": ["Enter the Romania paper-company report"], "key_numbers": [{"label": "Omya Calcita 2025", "value": "RON 156.8 m sales, 71 staff"}], "files": ["seed_20261016zm_romania_fillers"]}$cm$::jsonb,
   $cm$임시 — Omya Calcita Voislova GCC, Carmeuse 석회, Tempo Invest — 제지기업 보고서 대기$cm$,
   $cm$충전제만 입력: Omya Calcita 가 Voislova 대리석 GCC 공장 운영(라이선시, 2025 매출 1.57억 RON), Carmeuse 석회 공장 4곳(PCC 원료 파트너), Tempo Invest(Murfatlar 독립 탄산칼슘). 루마니아 제지용 PCC 공장 미확인. 우선순위는 제지기업 보고서 입력 전 임시값.$cm$,
   null, null,
   $cm$제지사 미입력$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
select 'filler' as kind, p.party_name as name,
       case when p.source = 'romania_fillers_20261016' then 'added now' else 'already there' end as status, coalesce(p.country_code, '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (p.party_name ~* 'omya.*(calcita|roman)' or p.party_name ~* 'carmeuse.*(roman|bra[sș]ov|c[aâ]mpulung|deva|fieni)' or p.party_name ~* 'tempo invest')
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'RO'
union all
select 'existing mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'), '-', p.id::text
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'RO'
order by 1, 2;
