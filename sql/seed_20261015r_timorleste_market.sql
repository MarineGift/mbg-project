-- ============================================================
-- seed_20261015r_timorleste_market.sql
--
-- >>> IN THE SUPABASE SQL EDITOR: PRESS Ctrl+A (SELECT ALL) THEN RUN. <<<
--
-- Timor-Leste market row (reports 2026-10-14) - fills the TL row of
-- app.country_markets so /markets/TL and the country combobox show the full
-- research. No mill or filler rows: the country has no paper machine and no
-- paper-grade PCC / GCC maker (printers, recyclers and TL Cement excluded).
-- Priority stays as stored if the row exists (none = no target).
-- Idempotent. Last statement is a verification select.
-- ============================================================

insert into app.country_markets
  (organization_id, country_code, country_name, priority, headline, summary, sections,
   headline_ko, summary_ko, fcc_potential_low_t, fcc_potential_high_t, fcc_potential_basis_ko, checked_at)
values
  ('b25de8f2-1020-482f-9012-183f63883169'::uuid, 'TL', 'Timor-Leste', 'none',
   $cm$No paper mill and no paper-grade filler maker - paper is imported, mainly Indonesia and China$cm$,
   $cm$No paper machine and no paper-grade PCC or GCC in Timor-Leste. Limestone is tied to the TL Cement project in Baucau (still Announced in 2026). Local firms are printers, converters and recyclers. About USD 15.7 m of HS 48 paper products arrived in 2024, about 94.5 pct of it Indonesian and Chinese - the FCC opportunity sits with those exporting mills.$cm$,
   $cm${"fillers": "No paper-grade PCC or GCC producer and no global filler plant. Limestone exists (Baucau, Bucoli deposit) but only for the TL Cement project - USD 400m special investment agreement 2016, about 1.65 Mt/yr clinker planned, still Announced in 2026. Not added to URM.", "mills": "No paper machine of any kind (printing, tissue, board). Printers and converters only - Planet Printing, Gráfica Nacional (government supplier VG0001), MAX ADS, Instant Shop, QUES KEV, Imprensa Nacional. Recyclers Caltech and Circul-R collect paper but make none. None added to URM.", "strategy": "No local FCC customer. Work the supply side instead - Indonesian and Chinese mills that ship paper to Timor-Leste (already in URM under ID and CN). Re-check only if a paper mill or filler plant is announced.", "risks": "No demand base. Trade data conflict (Timor-Leste reports 1.38 t of Indonesian calcium carbonate imports in 2023, China reports 55.38 t exports).", "next_steps": ["Re-check if a paper mill or filler plant is announced", "Trace which Indonesian mills supply printing paper and tissue to Dili"], "key_numbers": [{"label": "HS 48 paper imports 2024", "value": "about USD 15.68 m (exporter-reported)"}, {"label": "Indonesia and China share", "value": "about 94.5 pct"}, {"label": "Printing and writing paper imports 2024", "value": "about 1,581 t"}, {"label": "Paper machines", "value": "none"}], "files": ["seed_20261015r_timorleste_market", "handoff_20261015a_timorleste_no_rows"]}$cm$::jsonb,
   $cm$제지공장·충전제 제조사 없음 — 종이는 인도네시아·중국에서 수입$cm$,
   $cm$원지 생산설비와 제지용 PCC·GCC 제조사가 없음. 석회석은 Baucau TL Cement 시멘트 프로젝트(2026년에도 발표 단계)용. 현지 업체는 인쇄·가공·재활용뿐. 2024년 HS 48 수입 약 1,568만 달러 중 인도네시아·중국 약 94.5% — FCC 기회는 수출 제지사 쪽(URM 의 ID·CN 밀).$cm$,
   null, null,
   $cm$초지기 없음 — 산정 불가$cm$,
   '2026-10-14'::date)
on conflict (organization_id, country_code) do update
  set country_name = excluded.country_name,
      priority = coalesce(app.country_markets.priority, excluded.priority),
      headline = excluded.headline, summary = excluded.summary, sections = excluded.sections,
      headline_ko = excluded.headline_ko, summary_ko = excluded.summary_ko,
      fcc_potential_low_t = excluded.fcc_potential_low_t, fcc_potential_high_t = excluded.fcc_potential_high_t,
      fcc_potential_basis_ko = excluded.fcc_potential_basis_ko,
      checked_at = excluded.checked_at, updated_at = now();

select cm.country_code, cm.country_name, cm.priority, cm.headline_ko,
       jsonb_array_length(coalesce(cm.sections -> 'key_numbers', '[]'::jsonb)) as key_numbers,
       (select count(*) from app.countries c where upper(c.code) = 'TL') as in_countries,
       cm.checked_at
from app.country_markets cm
where cm.country_code = 'TL' and cm.deleted_at is null;
