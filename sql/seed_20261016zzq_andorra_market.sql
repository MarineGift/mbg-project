-- ============================================================
-- seed_20261016zzq_andorra_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Andorra update (reports 2026-10-16). No paper machine, no paper filler
-- plant - market row only (priority none).
-- Last statement lists any AD rows plus any "Andorra"-named rows in other
-- countries (DS Smith Andorra, Teruel belongs to ES).
-- ============================================================

-- ---------- 5) COUNTRY MARKET ROW ----------
insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'AD', 'Andorra', 'none',
   $cm$No paper machine or paper filler plant - printers and converters only - serve via Spain and France$cm$,
   $cm$Andorra has no paper or board machine and no paper PCC or GCC plant. About 21 printing and graphics firms (Gràfiques Andorranes, Impremta Principat and others), stationery sellers (Carlin) and packaging designers (SC Comunicació). Paper products are imported (HS 482390 about USD 1.03 m and 240 t in 2024, mainly Spain, China, Austria, Germany, France). Note: DS Smith 'Andorra' is a corrugated plant in Andorra, Teruel (Spain) - not this country.$cm$,
   $cm${"fillers": "None. Nearest suppliers in Spain and France (Omya, Calmit Llierca, Reverté, SMI France).", "mills": "No paper machine. Printers and converters only.", "strategy": "No direct sales - covered by the Spain and France rows.", "risks": "Name clash with Andorra (Teruel, Spain).", "next_steps": ["Check that the DS Smith Andorra (Teruel) plant sits under ES, not AD"], "key_numbers": [{"label": "HS 482390 imports 2024", "value": "about USD 1.03 m, 240 t"}], "files": ["seed_20261016zzq_andorra_market"]}$cm$::jsonb,
   $cm$초지기·제지용 충전제 공장 없음 — 인쇄·가공업체뿐 — 스페인·프랑스 권역으로 관리$cm$,
   $cm$안도라에는 종이·판지 초지기와 제지용 PCC·GCC 공장 없음. 인쇄·그래픽 업체 약 21곳(Gràfiques Andorranes, Impremta Principat 등), 문구 유통(Carlin), 포장 디자인(SC Comunicació). 종이제품은 수입(HS 482390 2024 약 103만 달러·240 t, 스페인·중국·오스트리아·독일·프랑스). 주의: DS Smith 'Andorra' 는 스페인 Teruel 주 Andorra 시의 골판지 공장 — 안도라 공국 아님.$cm$,
   null, null,
   $cm$초지기 없음 — 직접 수요 없음$cm$,
   '2026-10-15'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name, priority = excluded.priority, headline = excluded.headline,
      summary = excluded.summary, sections = excluded.sections, headline_ko = excluded.headline_ko,
      summary_ko = excluded.summary_ko, fcc_potential_low_t = excluded.fcc_potential_low_t,
      fcc_potential_high_t = excluded.fcc_potential_high_t, fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

-- ---------- 6) VERIFY ----------
select 'filler' as kind, p.party_name as name,
       case when p.source = 'andorra_update_20261016' then 'added now' else 'already there' end as status, coalesce(p.country_code, '-') as priority,
       case when coalesce(p.intro_en, '') <> '' or coalesce(p.intro_ko, '') <> '' then 'intro ok' else 'no intro' end as intro
from app.parties p
where p.party_type_id = 3 and p.deleted_at is null and (false)
union all
select 'market', cm.country_code || ' ' || cm.country_name, cm.priority,
       coalesce(cm.fcc_potential_low_t::text, '-'), coalesce(cm.headline_ko, '-')
from app.country_markets cm
where cm.country_code = 'AD'
union all
select 'existing mill', p.party_name, coalesce(p.city, '-') || ' / ' || coalesce(p.source, '-'), '-', p.id::text
from app.parties p
where p.party_type_id = 2 and p.deleted_at is null and p.country_code = 'AD'
order by 1, 2;

-- ---------- 7) NAME-CLASH CHECK ----------
select p.country_code, p.party_type_id, p.party_name, coalesce(p.city, '-') as city, p.id
from app.parties p
where p.deleted_at is null
  and (p.country_code = 'AD' or p.party_name ~* 'andorra' or coalesce(p.city, '') ~* 'andorra')
order by 1, 3;
