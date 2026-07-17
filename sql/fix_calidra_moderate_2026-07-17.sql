-- ============================================================
-- fix_calidra_moderate_2026-07-17.sql
--
-- CALIDRA - MODERATE, and not what this row says it is.
--
-- The database has it as country MX, market_role "Multi-plant Mexico",
-- mineral_class 'lime'. Two of those three are wrong or misleading.
--
-- ------------------------------------------------------------
-- THEY MAKE PCC. TWO PLANTS OF IT.
--   calidra.com.ar: "abastece a importantes empresas de pintura de Argentina y
--   Chile con CARBONATO DE CALCIO PRECIPITADO (CCP) y natural (GCC)"
--   and, decisively:
--   "Grupo Calidra cuenta con DOS PLANTAS en San Juan que producen Carbonato de
--    Calcio Precipitado (CCP): LOS BERROS y LA LAJA. El 70% de su produccion se
--    destina a la INDUSTRIA DE LA PINTURA. El resto de ese 30% se va en
--    abastecimiento a mercados de caucho, PAPEL, agricola, y otro tanto a
--    quimicas y algunas empresas de cosmeticos."
--
--   Two PCC plants - Los Berros and La Laja. 70 percent of that PCC goes to
--   PAINT. Paper shares the remaining 30 percent with rubber, agriculture,
--   chemicals and cosmetics. So paper is perhaps five to ten percent of their PCC.
--
-- SO: mineral_class 'lime' is WRONG - they make PCC, GCC and lime. That is the
-- FOURTH mineral_class error today, after Mumal Microns (gcc where the role says
-- ultra-fine PCC), Ashapura Kaolin (gcc where the role says kaolin) and MLC (the
-- role was the wrong field there, not the class). The field is unreliable in both
-- directions now. Do not filter on it.
--
-- AND THE PCC IS IN ARGENTINA, NOT MEXICO. San Juan province. The row is tagged
-- MX. Grupo Calidra operates across Mexico, Honduras, Colombia, Peru, Argentina,
-- Chile and the Dominican Republic - 23 plants, 115 years, associated with the
-- Canadian lime company Graymont since 2003. A single country_code cannot hold a
-- company whose carbonate business is in a different country from its
-- headquarters, and this row picked the headquarters.
--
-- VERDICT MODERATE, on the Q-min shape: real PCC capability, wrong primary
-- market. Q-min is GCC-only and plastics-first with a banknote credential.
-- Calidra is PCC-and-GCC and paint-first with a slice of paper. Neither is Maruo
-- (which has no paper at all) and neither is Okutama.
--
-- ------------------------------------------------------------
-- A TRAP WORTH RECORDING FOR ANYONE READING SPANISH SOURCES
--   "papel" means PAPER and it also means ROLE.
--   Calidra's own home page says "la cal juega un PAPEL importante en la
--   estabilizacion del pH" - lime plays an important ROLE. Nothing to do with
--   paper.
--   The quote above is safe because "papel" sits inside a list of MARKETS -
--   caucho, papel, agricola. Context, not the word, decides.
--   Anyone grepping Spanish or Portuguese sources for "papel" will get false
--   positives, and this roster has Mexico, Argentina, Brazil and Spain rows.
--
-- No contact route recorded - the row is not resolved enough, and the question of
-- WHICH Calidra entity (the Mexican parent or the Argentine carbonate business)
-- would even be the counterparty is open.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set mineral_class = 'PCC + GCC + lime (was wrongly recorded as lime only)',
    market_role   = 'Latin American lime leader that also runs TWO PCC PLANTS - Los Berros and La Laja, San Juan, ARGENTINA, not Mexico. 70 percent of that PCC goes to paint. Paper shares the remaining 30 percent with rubber, agriculture, chemicals and cosmetics. 23 plants across Mexico, Honduras, Colombia, Peru, Argentina, Chile and the Dominican Republic. Associated with Graymont of Canada since 2003.',
    extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "moderate", "reason": "REAL PCC CAPABILITY, WRONG PRIMARY MARKET. Their own Argentine site states Grupo Calidra has TWO PLANTS in San Juan producing precipitated calcium carbonate - Los Berros and La Laja - and supplies paint companies in Argentina and Chile with both precipitated (CCP) and natural (GCC) carbonate. But 70 percent of that PCC production goes to the PAINT industry, and paper shares the remaining 30 percent with rubber, agriculture, chemicals and cosmetics. Paper is perhaps five to ten percent of their PCC. Same shape as Q-min - real capability, wrong focus. Not Maruo, which has no paper at all, and not Okutama.", "checked_at": "2026-07-17", "source": "calidra.com.ar, calidra.com, ANFACAL", "source_type": "marketing"}, "row_is_wrong": {"mineral_class_was": "lime", "mineral_class_is": "PCC + GCC + lime", "why_it_matters": "FOURTH mineral_class error today - after Mumal Microns (gcc where the role says ultra-fine PCC), Ashapura Kaolin (gcc where the role says kaolin), and MLC (there the market_role was the wrong field, not the class). The field is now unreliable in both directions. DO NOT FILTER THE ROSTER ON mineral_class.", "country_problem": "The row is tagged MX. THE PCC PLANTS ARE IN ARGENTINA - San Juan province. A single country_code cannot hold a company whose carbonate business sits in a different country from its headquarters, and this row picked the headquarters. Which Calidra entity would even be the counterparty - the Mexican parent or the Argentine carbonate business - is open.", "raised_at": "2026-07-17"}, "company": {"history": "Calidra S.A. founded 26 October 1931 - the group dates its trajectory to 1908 - and installed the first integral lime plant in Mexico in 1933", "scale": "23 production plants across the Americas, 115 years", "countries": ["Mexico", "Honduras", "Colombia", "Peru", "Argentina", "Chile", "Dominican Republic"], "partner": "associated with Graymont of Canada since 2003", "pcc_plants": ["Los Berros, San Juan, Argentina", "La Laja, San Juan, Argentina"], "other": "high-purity calcium hydroxide, ready-mixes, aragonite. FDA food-grade lines at Torreon (Coahuila) and Acajete (Puebla). Limestone above 95 percent CaCO3. In-house laboratories."}, "spanish_reading_trap": {"the_word": "papel", "means": "PAPER, and also ROLE", "example_from_their_own_site": "la cal juega un PAPEL importante en la estabilizacion del pH - lime plays an important ROLE. Nothing to do with paper.", "why_the_quote_above_is_safe": "It sits inside a list of MARKETS - caucho, papel, agricola. Context decides, not the word.", "who_this_affects": "Anyone grepping Spanish or Portuguese sources for papel will get false positives, and this roster has Mexico, Argentina, Brazil and Spain rows.", "raised_at": "2026-07-17"}, "contactability": {"not_recorded": "The row is not resolved enough to hold a contact route, and it is not clear which entity would be the counterparty."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] MODERATE, and the row was wrong twice. Calidra makes PCC - two plants at Los Berros and La Laja, San Juan, ARGENTINA - plus GCC, plus lime. mineral_class said lime only. 70 percent of the PCC goes to PAINT and paper shares the remaining 30 percent with rubber, agriculture, chemicals and cosmetics. The row is tagged MX but the carbonate business is Argentine. 23 plants, 7 countries, 115 years, associated with Graymont since 2003. Spanish trap - papel means both paper and role, and their own site uses it both ways.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'calidra'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.country_code, f.mineral_class,
--        f.extra_data #>> '{fcc_fit,verdict}'            as fcc_fit,
--        f.extra_data #>> '{row_is_wrong,country_problem}' is not null as country_flagged
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'calidra' and p.deleted_at is null;


-- ---------- MEXICO, FINISHED. THREE ROWS, ZERO TARGETS. ----------
--   Calidra              moderate - PCC exists but it is Argentine and paint-first
--   Imerys Mexico        no       - Imerys exited paper in 2024
--   Mexalit / Cemex Min. n/a      - TWO COMPANIES IN ONE ROW. Cannot be contacted.
--                                   No website, no evidence_level. Flagged earlier.
--
-- Mexico looked like Saudi and turned out slightly better: one row with real PCC,
-- pointed at paint, in the wrong country.
--
-- ---------- TWENTY-ONE OPENED ----------
--   TOP      Artemyn
--   STRONG   Okutama, Gulshan, Bihoku, Shiraishi, 20 Microns, Zantat, Wolkem, MLC
--   moderate Q-min, Huber, Calidra
--   HOLD     Fimatec, F.M.T. Thailand - on an argument that no longer applies
--   OUT      Maruo, Takehara, Nittetsu, IMI Fabi, Carmeuse, Kaolin (Malaysia),
--            Thiele, Imerys x3, Maaden
--
-- ---------- WHAT IS LEFT: INDIA SIX ----------
--   Ashapura Group / Ashapura Microns          - two entities in one row, flagged
--   Ashapura Kaolin / White Performance Min.   - same website as the above
--   Kunal Calcium         role "Domestic carbonate producer", class pcc
--   Mumal Microns         role "Ultra-fine PCC producer", class gcc
--   Shikhar Microns       role "GCC producer"
--   Yamuna Calcium        role "North-India carbonate producer", class both
--
-- India is where the upside is. 20 Microns, Gulshan and Wolkem all came back
-- STRONG - three for three - and these six are the same kind of company. Nowhere
-- else in this roster has that hit rate. Japan went 3 for 7. The USA went 1 for 4.
-- Saudi and Mexico went 0.
