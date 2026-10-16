-- ============================================================
-- seed_20261015x_jamaica_mills.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Jamaica update - paper-company report (2026-10-15). No running paper
-- machine found - converters are not created as mills.
-- 1) Mill if missing + plant block (no priority): West Indies Pulp & Paper
--    (Freetown, Clarendon) - historical tissue base paper, status unknown.
--    Context, match only (9): Sanmerna, Quality Incorporations VII, Choi's,
--    HDB, Jiffy, Seven Industries, Jamaica Packaging Industries, AMG,
--    Sterling Packaging.
-- 2) app.country_markets JM row (priority low).
-- Fillers (Lydford Mining, Hodges) wait for the filler report.
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
           v.party_name, 'JM', v.region, v.city, v.website, 'active', 'jamaica_update_20261015',
           v.intro_ko, v.intro_en, v.notes, 'b25de8f2-1020-482f-9012-183f63883169'::uuid
    from (values
      ('west indies pulp', 'freetown|clarendon', 'west indies', 'West Indies Pulp & Paper (Freetown, Clarendon)', 'Clarendon', 'Freetown', null, '자메이카의 과거 티슈 원지·종이제품 제조사(Freetown, Clarendon 공장). 2004년 기존 티슈 사업이 Quality Incorporations VII 로 인수됨. 현재 초지기 가동 미확인.', 'West Indies Pulp and Paper Ltd. - historical tissue base-paper and paper-products maker with a plant at Freetown, Clarendon (office 6 Ashenheim Road, Kingston 11). Its tissue business was taken over in 2004 by Krishna Vaswani, forming Quality Incorporations VII.', 'JM check 2026-10-15: D&B lists it under pulp, paper and board, but no evidence of a running paper machine in 2026. +1 876-926-7423. Only papermaking history found in Jamaica.')
    ) as v(name_rx, city_rx, owner_rx, party_name, region, city, website, intro_ko, intro_en, notes)
    where (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) is null;
    
-- existing mill rows (incl. context rows): fill empty introduction, append memo once
    update app.parties p
    set intro_ko = coalesce(nullif(btrim(p.intro_ko), ''), m.intro_ko),
        intro_en = coalesce(nullif(btrim(p.intro_en), ''), m.intro_en),
        notes = case when m.notes is null or coalesce(p.notes, '') ilike '%JM check 2026-10-15%' then p.notes
                     else coalesce(nullif(btrim(p.notes), '') || ' | ', '') || m.notes end,
        updated_at = now()
    from (
      select v.intro_ko, v.intro_en, v.notes, (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('west indies pulp', 'freetown|clarendon', 'west indies', '자메이카의 과거 티슈 원지·종이제품 제조사(Freetown, Clarendon 공장). 2004년 기존 티슈 사업이 Quality Incorporations VII 로 인수됨. 현재 초지기 가동 미확인.', 'West Indies Pulp and Paper Ltd. - historical tissue base-paper and paper-products maker with a plant at Freetown, Clarendon (office 6 Ashenheim Road, Kingston 11). Its tissue business was taken over in 2004 by Krishna Vaswani, forming Quality Incorporations VII.', 'JM check 2026-10-15: D&B lists it under pulp, paper and board, but no evidence of a running paper machine in 2026. +1 876-926-7423. Only papermaking history found in Jamaica.'),
  ('sanmerna', null, 'sanmerna', null, null, 'JM check 2026-10-15: Tissue converter, 2A Ashenheim Rd, Kingston - over 120,000 rolls/day (2026), about 200 staff, imported virgin base paper (Indonesia, Turkey, China), new plant near Kingston port targeted for 2028 construction - converter, context only.'),
  ('quality incorporations', null, 'quality incorporations', null, null, 'JM check 2026-10-15: Toilet tissue converter, 258 Spanish Town Rd, Kingston (about 75 staff in 2019) - converter, context only.'),
  ('choi.?s manufacturing', null, 'choi.?s manufacturing', null, null, 'JM check 2026-10-15: Tissue and napkin converter (Happy Face, Swift) - converter, context only.'),
  ('\mhdb\M', null, '\mhdb\M', null, null, 'JM check 2026-10-15: Tissue and hand towel converter, Shannon Drive Freezone - converter, context only.'),
  ('jiffy', null, 'jiffy', null, null, 'JM check 2026-10-15: Paper bags, napkins, hand towels - converter - converter, context only.'),
  ('seven industries', null, 'seven industries', null, null, 'JM check 2026-10-15: Tissue, bags and hygiene products - converter - converter, context only.'),
  ('jamaica packaging', null, 'jamaica packaging', null, null, 'JM check 2026-10-15: Corrugated boxes and paper bags, 693 Spanish Town Rd, owns ex Corrpak - no liner machine - converter, context only.'),
  ('amg packaging', null, 'amg packaging', null, null, 'JM check 2026-10-15: Corrugated boxes (JSE junior market), tissue since 2015 - no paper machine found - converter, context only.'),
  ('sterling packaging', null, 'sterling packaging', null, null, 'JM check 2026-10-15: Corrugated and paper packaging - converter - converter, context only.')
      ) as v(name_rx, city_rx, owner_rx, intro_ko, intro_en, notes)
    ) m
    where p.id = m.id and coalesce(p.source, '') <> 'jamaica_update_20261015';
    
-- ---------- 3) PLANT BLOCKS ----------
    insert into app.paper_mill_profile (party_id, organization_id, extra_data, created_at, updated_at)
    select distinct m.id, 'b25de8f2-1020-482f-9012-183f63883169'::uuid, '{}'::jsonb, now(), now()
    from (
      select (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('west indies pulp', 'freetown|clarendon', 'west indies'),
  ('sanmerna', null, 'sanmerna'),
  ('quality incorporations', null, 'quality incorporations'),
  ('choi.?s manufacturing', null, 'choi.?s manufacturing'),
  ('\mhdb\M', null, '\mhdb\M'),
  ('jiffy', null, 'jiffy'),
  ('seven industries', null, 'seven industries'),
  ('jamaica packaging', null, 'jamaica packaging'),
  ('amg packaging', null, 'amg packaging'),
  ('sterling packaging', null, 'sterling packaging')
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
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1) as id
      from (values
      ('west indies pulp', 'freetown|clarendon', 'west indies',
   $pj${"owner": "West Indies Pulp and Paper", "products": "Tissue base paper (historical)", "grades": ["Tissue"], "approach": "Confirm whether the Freetown machine still exists - otherwise Jamaica has no paper machine.", "to_collect": ["Machine still installed or scrapped", "Current owner of the Freetown site"], "checked_at": "2026-10-15"}$pj$::jsonb),
  ('sanmerna', null, 'sanmerna',
   $pj${"owner": "Sanmerna Paper Products", "products": "Tissue converter, 2A Ashenheim Rd, Kingston - over 120,000 rolls/day (2026), about 200 staff, imported virgin base paper (Indonesia, Turkey, China), new plant near Kingston port targeted for 2028 construction", "approach": "Converter - buys base paper abroad. Use for FCC-paper end-product tests or as a path to its paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('quality incorporations', null, 'quality incorporations',
   $pj${"owner": "Quality Incorporations VII", "products": "Toilet tissue converter, 258 Spanish Town Rd, Kingston (about 75 staff in 2019)", "approach": "Converter - buys base paper abroad. Use for FCC-paper end-product tests or as a path to its paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('choi.?s manufacturing', null, 'choi.?s manufacturing',
   $pj${"owner": "Choi's Manufacturing", "products": "Tissue and napkin converter (Happy Face, Swift)", "approach": "Converter - buys base paper abroad. Use for FCC-paper end-product tests or as a path to its paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('\mhdb\M', null, '\mhdb\M',
   $pj${"owner": "HDB Manufacturers and Distributors", "products": "Tissue and hand towel converter, Shannon Drive Freezone", "approach": "Converter - buys base paper abroad. Use for FCC-paper end-product tests or as a path to its paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('jiffy', null, 'jiffy',
   $pj${"owner": "Jiffy Manufacturing", "products": "Paper bags, napkins, hand towels - converter", "approach": "Converter - buys base paper abroad. Use for FCC-paper end-product tests or as a path to its paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('seven industries', null, 'seven industries',
   $pj${"owner": "Seven Industries", "products": "Tissue, bags and hygiene products - converter", "approach": "Converter - buys base paper abroad. Use for FCC-paper end-product tests or as a path to its paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('jamaica packaging', null, 'jamaica packaging',
   $pj${"owner": "Jamaica Packaging Industries (COPI)", "products": "Corrugated boxes and paper bags, 693 Spanish Town Rd, owns ex Corrpak - no liner machine", "approach": "Converter - buys base paper abroad. Use for FCC-paper end-product tests or as a path to its paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('amg packaging', null, 'amg packaging',
   $pj${"owner": "AMG Packaging and Paper", "products": "Corrugated boxes (JSE junior market), tissue since 2015 - no paper machine found", "approach": "Converter - buys base paper abroad. Use for FCC-paper end-product tests or as a path to its paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb),
  ('sterling packaging', null, 'sterling packaging',
   $pj${"owner": "Sterling Packaging", "products": "Corrugated and paper packaging - converter", "approach": "Converter - buys base paper abroad. Use for FCC-paper end-product tests or as a path to its paper suppliers.", "checked_at": "2026-10-15"}$pj$::jsonb)
      ) as v(name_rx, city_rx, owner_rx, plant)
    ) m
    where mp.party_id = m.id;
    
-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'JM', 'Jamaica', 'low',
   $cm$No running paper machine found - tissue and box converters on imported base paper$cm$,
   $cm$Jamaica converts imported base paper: tissue (Sanmerna over 120,000 rolls/day, Quality Incorporations VII, Choi's, HDB) and corrugated boxes (Jamaica Packaging Industries, AMG, Sterling). The only papermaking history is West Indies Pulp and Paper at Freetown, Clarendon - current status unknown. Sanmerna plans a new plant near Kingston port (construction targeted 2028). Local GCC (Lydford Mining, Hodges Aggregates and Powders) named in the earlier filler report, still to enter.$cm$,
   $cm${"fillers": "Filler report to enter - earlier research named Lydford Mining and Hodges Aggregates and Powders as GCC producers.", "mills": "Papermaking history: West Indies Pulp and Paper (Freetown, Clarendon) - status unknown. Converters (context only): Sanmerna, Quality Incorporations VII, Choi's, HDB, Jiffy, Seven Industries, Jamaica Packaging Industries (ex Corrpak), AMG Packaging and Paper, Sterling Packaging.", "strategy": "No direct FCC customer unless a machine runs. Watch the Sanmerna new plant. Supply route - FCC paper made by foreign mills for Jamaican converters, local GCC as raw material.", "risks": "No paper machine confirmed.", "next_steps": ["Confirm the Freetown machine", "Follow the Sanmerna new-plant plan", "Enter the Jamaica filler report"], "files": ["seed_20261015x_jamaica_mills"]}$cm$::jsonb,
   $cm$가동 중인 초지기 미확인 — 수입 원지를 쓰는 티슈·골판지 가공업체 중심$cm$,
   $cm$자메이카는 수입 원지 가공 시장(티슈 Sanmerna 일 12만 롤+·Quality Incorporations VII·Choi's·HDB, 골판지 JPI·AMG·Sterling). 원지 제조 이력은 West Indies Pulp & Paper(Freetown, Clarendon) 뿐이고 현재 가동 미확인. Sanmerna 가 킹스턴항 인근 신공장 검토(2028 착공 목표). 충전제(Lydford Mining·Hodges) 보고서 입력 대기.$cm$,
   null, null,
   $cm$가동 초지기 미확인 — 산정 불가$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
    with v(name_rx, city_rx, owner_rx) as (values
      ('west indies pulp', 'freetown|clarendon', 'west indies'),
  ('sanmerna', null, 'sanmerna'),
  ('quality incorporations', null, 'quality incorporations'),
  ('choi.?s manufacturing', null, 'choi.?s manufacturing'),
  ('\mhdb\M', null, '\mhdb\M'),
  ('jiffy', null, 'jiffy'),
  ('seven industries', null, 'seven industries'),
  ('jamaica packaging', null, 'jamaica packaging'),
  ('amg packaging', null, 'amg packaging'),
  ('sterling packaging', null, 'sterling packaging')
    )
    select 'mill' as kind, coalesce(p.party_name, 'MISSING ' || v.name_rx) as name,
           case when p.source = 'jamaica_update_20261015' then 'added now' when p.id is null then '-' else 'already there' end as status,
           coalesce(mp.extra_data #>> '{plant,priority}', '-') as priority,
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
    from v
    left join app.parties p on p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1)
    left join app.paper_mill_profile mp on mp.party_id = p.id
    union all
    select 'filler', p.party_name,
           case when p.source = 'jamaica_update_20261015' then 'added now' else 'already there' end, coalesce(p.country_code, '-'),
           case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end
    from app.parties p
    where p.party_type_id = 3 and p.deleted_at is null and (false)
    union all
    select 'link', f.party_name || ' -> ' || m.party_name, l.link_type || ' / ' || coalesce(l.confidence, '-'), '-', coalesce(l.extra_data ->> 'batch', '-')
    from app.party_supply_links l
    join app.parties f on f.id = l.filler_party_id
    join app.parties m on m.id = l.mill_party_id
    where l.deleted_at is null and m.country_code = 'JM'
    union all
    select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
           coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
    from app.country_markets cm
    where cm.country_code = 'JM'
    union all
    select 'other mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'),
           coalesce(mp.extra_data #>> '{plant,priority}', '-'), p.id::text
    from app.parties p
    left join app.paper_mill_profile mp on mp.party_id = p.id
    where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'JM'
      and not exists (select 1 from v where p.id = (select y.id from app.parties y
          where y.party_type_id = 2 and y.deleted_at is null and y.country_code = 'JM'
            and (y.party_name ~* v.name_rx
                 or (v.city_rx is not null and coalesce(y.city, '') ~* v.city_rx and y.party_name ~* v.owner_rx))
          order by (y.party_name ~* v.name_rx) desc, y.created_at
          limit 1))
    order by 1, 4, 2;
    