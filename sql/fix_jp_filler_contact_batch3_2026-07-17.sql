-- ============================================================
-- fix_jp_filler_contact_batch3_2026-07-17.sql
--
-- NITTETSU MINING - NOT A FILLER PRODUCER. A limestone miner.
--
-- nittetsukou.co.jp/industry/resources/mineral_product.html lists what they
-- actually sell, and the answer is rock, sorted by size:
--   80-40mm, 40-20mm, 30-10mm, 20-05mm, -5mm, -3mm, -30mm for cement
-- End uses named: steel, cement, quicklime and slaked lime, concrete aggregate,
-- feed and fertiliser, wastewater neutralisation. Paper appears elsewhere on the
-- site as one of many limestone end-uses - glass, sugar, flue gas desulphurisation
-- and so on - not as a product line.
--
-- Scale is not the issue. They mine about 18 million tonnes of limestone a year,
-- among the largest in Japan, from Torigatayama in Kochi (the country's biggest),
-- Shiriya, Ikura, Higashishikagoe, Oita, Hachinohe and Funao. Their subsidiary
-- Kuzuu Sekkai Saiseki produces over 80 percent of Japan's dolomite. Founded 1939
-- out of the mining division of Japan Iron and Steel, roots back to 1899.
--
-- They are the company a filler producer BUYS FROM. FCC needs a licensee with
-- PCC or fine GCC processing and mill relationships. Nittetsu has neither - it
-- has the mountain.
--
-- Their inorganic paper line (flame-retardant and calcium-carbonate paper made
-- from aluminium hydroxide and CaCO3 powders, for fire-rated building materials
-- and insulation board) is a downstream product, not a filler business. It also
-- points the wrong way - they CONSUME calcium carbonate powder there.
--
-- The contact form at nittetsukou.co.jp/contact/ is a general corporate feedback
-- channel - it opens by inviting opinions, requests and questions about the
-- company, and asks under-18s to get a guardian's consent first. Not a technical
-- door. NOT RECORDED, on the same rule as Maruo: a contact route on a non-target
-- is how a wrong target becomes a sent message.
--
-- WHY THIS ONE MATTERS. Nittetsu sat in the target list as evidence B, Japan,
-- calcium carbonate - three attributes that all read as a fit. It sells 80mm
-- gravel. Third disqualification of the sweep, third time nothing in the database
-- could have caught it, third time the company's own product page did in one
-- look.
--
-- Running tally - Maruo no, Bihoku strong, Shiraishi strong, Okutama strong,
-- Fimatec hold, F.M.T. Thailand hold, Nittetsu no. Seven opened, three strong.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted, nothing deleted, no contact route
-- recorded.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "no", "reason": "A LIMESTONE MINER, NOT A FILLER PRODUCER. Their own product page sells rock sorted by size - 80-40mm, 40-20mm, 30-10mm, 20-05mm, -5mm, -3mm, and -30mm for cement - with end uses in steel, cement, lime, concrete aggregate, feed and fertiliser, and wastewater neutralisation. Paper appears on the site only as one of many downstream uses of limestone, alongside glass, sugar and flue gas desulphurisation. There is no paper filler line, no PCC, no fine GCC. This is the company a filler producer buys FROM. FCC needs a licensee with processing and mill relationships - Nittetsu has the mountain.", "checked_at": "2026-07-17", "source": "nittetsukou.co.jp product and business pages", "source_type": "marketing"}, "what_they_are": {"scale": "about 18 million tonnes of limestone a year, among the largest in Japan", "mines": ["Torigatayama, Kochi - the largest in Japan, ships by 60000-tonne vessel", "Shiriya, Aomori", "Ikura, Okayama", "Higashishikagoe, Hokkaido", "Oita", "Hachinohe Mine", "Funao Mine, Fukuoka"], "dolomite": "subsidiary Kuzuu Sekkai Saiseki, Sano, Tochigi - over 80 percent of Japanese output", "founded": "1939, from the mining division of Japan Iron and Steel, roots to the state-run Yawata works of 1899", "hq": "Yusen Building 6F, 2-3-2 Marunouchi, Chiyoda-ku, Tokyo 100-8377", "diversified": "machinery and environment (flocculants, dust collectors), real estate, mega solar and geothermal steam production with Kyushu Electric"}, "inorganic_paper_note": {"what": "The ore division sells inorganic paper - flame-retardant and calcium-carbonate paper made from aluminium hydroxide and CaCO3 powders, used in fire-rated building materials and insulation board.", "why_not_a_fit": "Downstream product, not a filler business. It points the wrong way - this line CONSUMES calcium carbonate powder rather than producing filler grades."}, "contactability": {"form_exists": true, "url_not_recorded": "nittetsukou.co.jp/contact/ is a general corporate feedback channel - it invites opinions, requests and questions about the company and asks under-18s for guardian consent. Not a technical or product door. DELIBERATELY NOT RECORDED - this is not a target, and a recorded contact route on a non-target is how a wrong target becomes a sent message.", "checked_at": "2026-07-17"}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] NOT AN FCC TARGET. Nittetsu Mining sells limestone by size grade - 80-40mm down to -3mm. No paper filler line, no PCC, no fine GCC. They are upstream of the filler industry, not in it. Sat in the list as evidence B / Japan / calcium carbonate, which all read as a fit until the product page was opened. Keep the row - they are a real limestone supplier and useful market intelligence, and their 18 million tonnes a year makes them a raw material counterparty for any Japanese licensee. Do not enrol, do not build a form.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'nittetsu|日鉄鉱業'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.contact_form_url,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit,
--        left(f.extra_data #>> '{fcc_fit,reason}', 60) as why
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'nittetsu|日鉄鉱業' and p.deleted_at is null;
-- EXPECT - fcc_fit 'no', contact_form_url still null.


-- ---------- THE SWEEP SO FAR ----------
--   Maruo Calcium      no     - sealant and resin PCC, paper not in its list
--   Bihoku Funka       STRONG - paper-grade CaCO3, neutral papermaking, cost-down
--   Shiraishi Group    STRONG - paper listed, UFPCC+PCC+GCC, open testing lab
--   Okutama Kogyo      STRONG - over 90% of Japanese paper PCC, departments named
--   Fimatec            HOLD   - on-site PCC runs on Specialty Minerals technology
--   F.M.T. (Thailand)  HOLD   - Fimatec subsidiary
--   Nittetsu Mining    no     - limestone miner, sells rock by the centimetre
--
-- SEVEN OPENED. THREE STRONG. Four removed or held before a single message was
-- sent to any of them.
--
-- That ratio is the argument for doing this at all. The database ranked all seven
-- as plausible filler suppliers. It was right about three.
--
-- Still to sweep - Takehara Chemical and the remainder of the JP nine, then
-- Zantat (MY, Bursa-listed), Q-min (TH, listed), Gulshan Polyols (IN).
--
-- And Artemyn remains first. 17 carbonate plants, a P&B lab at Par Moor, and
-- Chris Nutbeem's name on a public page.
