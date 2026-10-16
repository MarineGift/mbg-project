-- ============================================================
-- seed_20261016v_tajikistan_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Tajikistan paper-company report (2026-10-16). Filler report returned
-- no content - no filler rows.
-- 1) Mills if missing (3) + plant blocks, no priority (machines unconfirmed):
--    Kogazi Tojik, Kogazi Sugd, Durakhshon Buston. Context (6): Quttii Tojik,
--    Cekhi Kartonbarori Isfara, ALFA PET, Afzaliyat Grupp, Forsiyon,
--    Borkhaltai Sugd.
-- 2) app.country_markets TJ row (priority low).
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
               v.party_name, 'TJ', v.region, v.city, v.website, 'active', 'tajikistan_update_20261016',
               v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
        from (values
          ('kogazi tojik|қоғази тоҷик|когази точик', 'khujand|худжанд', 'kogazi tojik|когази точик|қоғази', 'Kogazi Tojik - Khujand', 'Sughd', 'Khujand', null, 'Khujand 북동 산업지구의 종이·판지 공장(Қоғази тоҷик). 지역 폐지 재활용 이력(2015), 초지기·생산능력 미확인.', 'Kogazi Tojik LLC (Қоғази тоҷик), north-east industrial zone, Khujand (Sughd) - listed as a cardboard and paper factory, recycled local waste paper (2015 city report) and planned more pulping lines.', 'TJ check 2026-10-16: paper machine and output not confirmed - first question is whether it makes base paper. +992 92 855 0000. Name also appears with Quttii Tojik box lines.'),
  ('kogazi sugd|когази сугд', 'sughd|ergashev', 'kogazi sugd|когази сугд', 'Kogazi Sugd', 'Sughd', null, null, 'Sughd 의 종이·판지 제조·판매 업체(ООО «Когази Сугд»), 폐지·비도공 종이 원료 거래.', 'Kogazi Sugd LLC (ООО «Когази Сугд»), Ergasheva Street, Sughd - paper and board making and sales, waste paper and uncoated paper trade.', 'TJ check 2026-10-16: paper machine and grade not confirmed. +992 98 598 7200.'),
  ('durakhshon|дурахшон', 'buston|chkalovsk|бустон', 'durakhshon|дурахшон', 'Durakhshon Buston - Buston', 'Sughd', 'Buston', null, 'Buston(Chkalovsk) 화장지·냅킨 시설(2019-08, 월 50 t 원료) + 색지 시설(2022-08, 월 20 t, 약 700만 소모니, 중국산 설비).', 'Durakhshon Buston LLC, Internatsionalnaya Street, Chkalovsk / Buston (Sughd) - toilet tissue and napkin plant opened 2019-08 (about 50 t/month raw material, local recovered fibre) and a coloured-paper plant opened 2022-08 (20 t/month, 240 t/yr, about TJS 7 m, Chinese equipment).', 'TJ check 2026-10-16: whether the tissue plant runs its own machine or converts rolls is not confirmed. +992 92 721 3527.')
        ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
        where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
        
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%TJ check 2026-10-16%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kogazi tojik|қоғази тоҷик|когази точик', 'khujand|худжанд', 'kogazi tojik|когази точик|қоғази', 'Khujand 북동 산업지구의 종이·판지 공장(Қоғази тоҷик). 지역 폐지 재활용 이력(2015), 초지기·생산능력 미확인.', 'Kogazi Tojik LLC (Қоғази тоҷик), north-east industrial zone, Khujand (Sughd) - listed as a cardboard and paper factory, recycled local waste paper (2015 city report) and planned more pulping lines.', 'TJ check 2026-10-16: paper machine and output not confirmed - first question is whether it makes base paper. +992 92 855 0000. Name also appears with Quttii Tojik box lines.'),
  ('kogazi sugd|когази сугд', 'sughd|ergashev', 'kogazi sugd|когази сугд', 'Sughd 의 종이·판지 제조·판매 업체(ООО «Когази Сугд»), 폐지·비도공 종이 원료 거래.', 'Kogazi Sugd LLC (ООО «Когази Сугд»), Ergasheva Street, Sughd - paper and board making and sales, waste paper and uncoated paper trade.', 'TJ check 2026-10-16: paper machine and grade not confirmed. +992 98 598 7200.'),
  ('durakhshon|дурахшон', 'buston|chkalovsk|бустон', 'durakhshon|дурахшон', 'Buston(Chkalovsk) 화장지·냅킨 시설(2019-08, 월 50 t 원료) + 색지 시설(2022-08, 월 20 t, 약 700만 소모니, 중국산 설비).', 'Durakhshon Buston LLC, Internatsionalnaya Street, Chkalovsk / Buston (Sughd) - toilet tissue and napkin plant opened 2019-08 (about 50 t/month raw material, local recovered fibre) and a coloured-paper plant opened 2022-08 (20 t/month, 240 t/yr, about TJS 7 m, Chinese equipment).', 'TJ check 2026-10-16: whether the tissue plant runs its own machine or converts rolls is not confirmed. +992 92 721 3527.'),
  ('quttii tojik|қуттии тоҷик', null, 'quttii tojik|қуттии тоҷик', null, null, 'TJ check 2026-10-16: Corrugated box lines at Kansoy (phase 2 2026-03-29): 15 t/day raw material, about 30,000 boxes/day, 130 staff, 70 pct local raw material - converter - context only.'),
  ('kartonbarori isfara|isfara.*(carton|картон)', null, 'kartonbarori isfara|isfara.*(carton|картон)', null, null, 'TJ check 2026-10-16: Carton boxes, Isfara - converter - context only.'),
  ('alfa pet', null, 'alfa pet', null, null, 'TJ check 2026-10-16: Paper products listing, Gafurov - context only.'),
  ('afzaliyat', null, 'afzaliyat', null, null, 'TJ check 2026-10-16: Paper products listing, Dushanbe - context only.'),
  ('forsiyon', null, 'forsiyon', null, null, 'TJ check 2026-10-16: Paper products listing, Bokhtar - context only.'),
  ('borkhaltai', null, 'borkhaltai', null, null, 'TJ check 2026-10-16: Paper products listing, Unchi - context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'tajikistan_update_20261016';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kogazi tojik|қоғази тоҷик|когази точик', 'khujand|худжанд', 'kogazi tojik|когази точик|қоғази'),
  ('kogazi sugd|когази сугд', 'sughd|ergashev', 'kogazi sugd|когази сугд'),
  ('durakhshon|дурахшон', 'buston|chkalovsk|бустон', 'durakhshon|дурахшон'),
  ('quttii tojik|қуттии тоҷик', null, 'quttii tojik|қуттии тоҷик'),
  ('kartonbarori isfara|isfara.*(carton|картон)', null, 'kartonbarori isfara|isfara.*(carton|картон)'),
  ('alfa pet', null, 'alfa pet'),
  ('afzaliyat', null, 'afzaliyat'),
  ('forsiyon', null, 'forsiyon'),
  ('borkhaltai', null, 'borkhaltai')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('kogazi tojik|қоғази тоҷик|когази точик', 'khujand|худжанд', 'kogazi tojik|когази точик|қоғази',
   $pj${"owner": "Kogazi Tojik", "products": "Recycled paper and board (to confirm)", "grades": ["Board"], "approach": "Confirm own base-paper making first.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kogazi sugd|когази сугд', 'sughd|ergashev', 'kogazi sugd|когази сугд',
   $pj${"owner": "Kogazi Sugd", "products": "Paper and board (to confirm)", "approach": "Confirm machine and grade.", "to_collect": ["Current filler use, if any", "SCT, RCT, CMT, burst and drainage baseline", "Which grades or plies could take a filler", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('durakhshon|дурахшон', 'buston|chkalovsk|бустон', 'durakhshon|дурахшон',
   $pj${"owner": "Durakhshon Buston", "products": "Toilet tissue, napkins, coloured paper", "grades": ["Tissue", "Coloured paper"], "approach": "Confirm a tissue machine - then 1-10 pct trial talk.", "to_collect": ["Machine type and main grammages", "Virgin versus recycled fibre", "Softness, absorbency, tensile, dust limits", "Who approves a machine trial"], "checked_at": "2026-10-16"}$pj$::jsonb),
  ('quttii tojik|қуттии тоҷик', null, 'quttii tojik|қуттии тоҷик',
   $pj${"owner": "Quttii Tojik", "products": "Corrugated box lines at Kansoy (phase 2 2026-03-29): 15 t/day raw material, about 30,000 boxes/day, 130 staff, 70 pct local raw material - converter", "approach": "Converter or listing only.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('kartonbarori isfara|isfara.*(carton|картон)', null, 'kartonbarori isfara|isfara.*(carton|картон)',
   $pj${"owner": "Cekhi Kartonbarori Isfara", "products": "Carton boxes, Isfara - converter", "approach": "Converter or listing only.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('alfa pet', null, 'alfa pet',
   $pj${"owner": "ALFA PET", "products": "Paper products listing, Gafurov", "approach": "Converter or listing only.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('afzaliyat', null, 'afzaliyat',
   $pj${"owner": "Afzaliyat Grupp", "products": "Paper products listing, Dushanbe", "approach": "Converter or listing only.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('forsiyon', null, 'forsiyon',
   $pj${"owner": "Forsiyon", "products": "Paper products listing, Bokhtar", "approach": "Converter or listing only.", "checked_at": "2026-10-16"}$pj$::jsonb),
  ('borkhaltai', null, 'borkhaltai',
   $pj${"owner": "Borkhaltai Sugd", "products": "Paper products listing, Unchi", "approach": "Converter or listing only.", "checked_at": "2026-10-16"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'TJ', 'Tajikistan', 'low',
   $cm$Small recycled board and tissue makers in Sughd - no paper machine confirmed, no paper filler maker$cm$,
   $cm$Tajikistan's paper sector is small and centred in Sughd: Kogazi Tojik (Khujand) and Kogazi Sugd are listed as paper and board makers, Durakhshon Buston runs tissue (about 50 t/month raw material) and coloured-paper (20 t/month) plants, and box lines such as Quttii Tojik (15 t/day raw material, 2026) convert. None has a confirmed paper machine yet. The filler report did not return content - Karon-Calcite and Marmar Stone were named as local GCC raw-material firms. Wood, paper and printing output H1 2026: TJS 433 m.$cm$,
   $cm${"fillers": "Filler report empty. Named only: Karon-Calcite and Marmar Stone (GCC raw material) - details to collect.", "mills": "Listed paper and board: Kogazi Tojik (Khujand), Kogazi Sugd. Tissue and coloured paper: Durakhshon Buston. Converters (context): Quttii Tojik, Cekhi Kartonbarori Isfara, ALFA PET, Afzaliyat Grupp, Forsiyon, Borkhaltai Sugd.", "strategy": "Confirm a running paper machine first - small market, no direct FCC volume yet.", "risks": "No confirmed machine, very small volumes.", "next_steps": ["Re-run the Tajikistan filler report", "Ask Kogazi Tojik and Durakhshon Buston about their machines"], "key_numbers": [{"label": "Wood, paper, printing output H1 2026", "value": "TJS 433 m"}, {"label": "Quttii Tojik", "value": "15 t/day raw material, 30,000 boxes/day"}], "files": ["seed_20261016v_tajikistan_mills"]}$cm$::jsonb,
   $cm$Sughd 의 소형 재생 판지·티슈 업체 — 초지기 미확인, 제지용 충전제 업체 없음$cm$,
   $cm$타지키스탄 제지산업은 소규모·Sughd 중심: Kogazi Tojik(Khujand)·Kogazi Sugd 는 종이·판지 업체로 등재, Durakhshon Buston 은 티슈(월 원료 50 t)·색지(월 20 t), Quttii Tojik 등은 상자 가공. 초지기 확인된 곳 없음. 충전제 보고서는 내용 없음 — Karon-Calcite·Marmar Stone 만 언급.$cm$,
   null, null,
   $cm$초지기 미확인 — 산정 보류$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('kogazi tojik|қоғази тоҷик|когази точик', 'khujand|худжанд', 'kogazi tojik|когази точик|қоғази'),
  ('kogazi sugd|когази сугд', 'sughd|ergashev', 'kogazi sugd|когази сугд'),
  ('durakhshon|дурахшон', 'buston|chkalovsk|бустон', 'durakhshon|дурахшон'),
  ('quttii tojik|қуттии тоҷик', null, 'quttii tojik|қуттии тоҷик'),
  ('kartonbarori isfara|isfara.*(carton|картон)', null, 'kartonbarori isfara|isfara.*(carton|картон)'),
  ('alfa pet', null, 'alfa pet'),
  ('afzaliyat', null, 'afzaliyat'),
  ('forsiyon', null, 'forsiyon'),
  ('borkhaltai', null, 'borkhaltai')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'tajikistan_update_20261016' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'tajikistan_update_20261016' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'TJ'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'TJ'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'TJ'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'TJ'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    