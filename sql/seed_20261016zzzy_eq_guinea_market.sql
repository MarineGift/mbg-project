-- ============================================================
-- seed_20261016zzzy_eq_guinea_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Equatorial Guinea (GQ) update (reports 2026-10-17). No paper filler.
-- 1) Mill if missing (1, no priority): Evita Office Line (sheeting).
--    Context (5): printers.
-- 2) app.country_markets GQ row (priority none).
-- Idempotent. Last statement is a verification select.
-- ============================================================

-- ---------- 2) MILL ROWS IF MISSING ----------
        insert into app.parties
          (party_type_id, entity_type_id, party_name, country_code, region, city,
           website, status, source, intro_ko, intro_en, notes, organization_id)
        select 2::smallint,
               coalesce((select x.entity_type_id from app.parties x
                         where x.party_type_id = 2 and x.deleted_at is null
                         order by x.created_at limit 1), 1)::smallint,
               v.party_name, 'GQ', v.region, v.city, v.website, 'active', 'eq_guinea_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('evita', 'bata|ntobo', 'evita', 'Evita Office Line (Grupo Evita) - Bata', 'Litoral', 'Bata', null, 'Grupo Evita Evita Office Line(Ntobo, Bata–Mbini 도로 KM 8) — 2021-03-11 BDEAC 17억 FCFA 종이공장 자금, A4 80 g/m² 복사용지 재단·자동포장(시간당 5박스)·공책·서적·서류철·봉투, 2022-09-05 CEMAC 원산지 인정.', 'Evita Office Line S.L. (Grupo Evita), Ntobo, KM 8 Bata-Mbini road, Bata - BDEAC financed a paper plant (FCFA 1.7 bn, signed 2021-03-11, 70 jobs), the site cuts and packs 80 g/m2 A4 copy paper (about 5 boxes/hour) and makes notebooks, books, folders and envelopes, CEMAC origin status for five products 2022-09-05.', 'GQ check 2026-10-16: line looks like sheeting, not a paper machine - confirm base-paper source. info@grupoevita.com, +240 222 404 040.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GQ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%GQ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GQ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('evita', 'bata|ntobo', 'evita', 'Grupo Evita Evita Office Line(Ntobo, Bata–Mbini 도로 KM 8) — 2021-03-11 BDEAC 17억 FCFA 종이공장 자금, A4 80 g/m² 복사용지 재단·자동포장(시간당 5박스)·공책·서적·서류철·봉투, 2022-09-05 CEMAC 원산지 인정.', 'Evita Office Line S.L. (Grupo Evita), Ntobo, KM 8 Bata-Mbini road, Bata - BDEAC financed a paper plant (FCFA 1.7 bn, signed 2021-03-11, 70 jobs), the site cuts and packs 80 g/m2 A4 copy paper (about 5 boxes/hour) and makes notebooks, books, folders and envelopes, CEMAC origin status for five products 2022-09-05.', 'GQ check 2026-10-16: line looks like sheeting, not a paper machine - confirm base-paper source. info@grupoevita.com, +240 222 404 040.'),
  ('wac services', null, 'wac services', null, null, 'GQ check 2026-10-16: WAC Services, Malabo and Bata - commercial printing, stationery - context only.'),
  ('ocean print', null, 'ocean print', null, null, 'GQ check 2026-10-16: Digital printing, Malabo - context only.'),
  ('imprenta carioca', null, 'imprenta carioca', null, null, 'GQ check 2026-10-16: Printing and publishing, Bata - context only.'),
  ('papeler[ií]a litoral', null, 'papeler[ií]a litoral', null, null, 'GQ check 2026-10-16: Imprenta Papelería Litoral, Bata - printing and stationery - context only.'),
  ('tecnobioko', null, 'tecnobioko', null, null, 'GQ check 2026-10-16: Digital and wide-format printing, Malabo - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'eq_guinea_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GQ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('evita', 'bata|ntobo', 'evita'),
  ('wac services', null, 'wac services'),
  ('ocean print', null, 'ocean print'),
  ('imprenta carioca', null, 'imprenta carioca'),
  ('papeler[ií]a litoral', null, 'papeler[ií]a litoral'),
  ('tecnobioko', null, 'tecnobioko')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GQ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('evita', 'bata|ntobo', 'evita', false,
   $pj${"owner": "Grupo Evita", "products": "A4 copy paper (sheeting), notebooks, envelopes", "grades": ["Copy paper"], "approach": "Confirm machine, else trace reel suppliers.", "to_collect": ["Current PCC / GCC supplier, grade and loading per grade", "Ash content, basis weight, retention aid, furnish", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('wac services', null, 'wac services', true,
   $pj${"owner": "WAC Services", "products": "WAC Services, Malabo and Bata - commercial printing, stationery", "approach": "Printer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('ocean print', null, 'ocean print', true,
   $pj${"owner": "Ocean Print", "products": "Digital printing, Malabo", "approach": "Printer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('imprenta carioca', null, 'imprenta carioca', true,
   $pj${"owner": "Imprenta Carioca", "products": "Printing and publishing, Bata", "approach": "Printer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('papeler[ií]a litoral', null, 'papeler[ií]a litoral', true,
   $pj${"owner": "Litoral", "products": "Imprenta Papelería Litoral, Bata - printing and stationery", "approach": "Printer.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('tecnobioko', null, 'tecnobioko', true,
   $pj${"owner": "Tecnobioko", "products": "Digital and wide-format printing, Malabo", "approach": "Printer.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, ctx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'GQ', 'Equatorial Guinea', 'none',
   $cm$No paper machine or paper filler plant confirmed - Evita Office Line copy-paper sheeting at Bata - printers in Malabo and Bata$cm$,
   $cm$Equatorial Guinea has no confirmed paper machine and no paper PCC or GCC maker - USGS lists little non-fuel mining. Evita Office Line (Grupo Evita, Bata) got BDEAC funding for a paper plant (2021) and now cuts and packs 80 gsm A4 copy paper and makes notebooks and envelopes with CEMAC origin status - a sheeting line, base-paper source to confirm. Printers: WAC Services, Ocean Print, Imprenta Carioca, Litoral, Tecnobioko. HS 48 supply mainly China, Spain, Türkiye, India (2024). Gas could supply CO2 for a PCC plant in theory, but there is no demand.$cm$,
   $cm${"fillers": "None.", "mills": "To confirm: Evita Office Line (sheeting). Context: five printers.", "strategy": "Ask Evita for its reel supplier, use Grupo Evita's CEMAC distribution as a contact route.", "risks": "No direct volume.", "next_steps": ["Ask Evita whether it runs a paper machine"], "key_numbers": [{"label": "BDEAC loan 2021", "value": "FCFA 1.7 bn"}], "files": ["seed_20261016zzzy_eq_guinea_market"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 미확인 — Bata Evita Office Line 복사용지 재단 — Malabo·Bata 인쇄업체$cm$,
   $cm$적도기니에는 확인된 초지기·제지용 PCC·GCC 제조사 없음 — USGS 상 비연료 광업 미미. Evita Office Line(Grupo Evita, Bata)이 2021 BDEAC 자금으로 종이공장을 세워 80 gsm A4 복사용지 재단·포장, 공책·봉투 생산(CEMAC 원산지 인정) — 재단 라인, 원지 출처 확인 필요. 인쇄: WAC Services, Ocean Print, Imprenta Carioca, Litoral, Tecnobioko. HS 48 주로 중국·스페인·튀르키예·인도(2024). 천연가스 CO2 로 PCC 가능성은 이론상, 수요 없음.$cm$,
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
      ('evita', 'bata|ntobo', 'evita'),
  ('wac services', null, 'wac services'),
  ('ocean print', null, 'ocean print'),
  ('imprenta carioca', null, 'imprenta carioca'),
  ('papeler[ií]a litoral', null, 'papeler[ií]a litoral'),
  ('tecnobioko', null, 'tecnobioko')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'eq_guinea_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GQ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'eq_guinea_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'GQ'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'GQ'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'GQ'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'GQ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    