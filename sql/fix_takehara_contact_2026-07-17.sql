-- ============================================================
-- fix_takehara_contact_2026-07-17.sql
--
-- TAKEHARA CHEMICAL - NOT A PAPER COMPANY. The Maruo pattern, a third time.
--
-- takehara-chem.jp/ja/product/index.html lists the whole product range:
--   colloidal calcium carbonate, barium sulphate, kaolin and clay,
--   food and pharmaceutical grades, masterbatch, talc,
--   ground calcium carbonate, secondary powder processing
--
-- And every application they describe points away from paper:
--   Sunlight series, their ultrafine GCC  -> plastics, paint, rubber
--   Whiteseal series, surface-modified    -> plastics and adhesives
--   Kaolin (JP-100, NN, 5M, Hardsil, ST)  -> paint, adhesives, rubber fillers,
--                                            agrochemicals, and Japanese
--                                            Pharmacopoeia kaolin for medicines
--                                            and cosmetics
--
-- PAPER IS IN NO APPLICATION LIST ON THE SITE.
--
-- They make colloidal PCC. They own their own mine - their GCC page says the
-- limestone comes from a mine the company owns, high purity, stable in quality
-- and volume. They grind from coarse to ultrafine with technology accumulated
-- since founding. Every ingredient of a good filler house is here, aimed at
-- resins.
--
-- THE ONE THING THAT CUTS THE OTHER WAY, RECORDED HONESTLY:
-- The homepage tagline reads, roughly, "from cars and houses and skyscrapers to
-- milk drinks and NEWSPAPERS - reliable technology supporting daily life."
-- Newspaper is in there. But that is a line of marketing poetry about where
-- their minerals end up, and no product page names paper as an application. One
-- evocative noun in a tagline is not a paper business. If it were enough, Maruo
-- would have passed too.
--
-- AN OBSERVATION WORTH KEEPING: Takehara and Maruo Calcium are IN THE SAME CITY.
-- Maruo at Nishioka, Uozumi-cho, Akashi. Takehara at Honmachi, Akashi. Two
-- calcium carbonate houses a few kilometres apart in Hyogo, and NEITHER sells to
-- paper. Akashi is a Japanese CaCO3 cluster - and it is a RESIN cluster, not a
-- paper one. The paper PCC lives elsewhere: Okutama in Tokyo, Bihoku in Okayama,
-- Shiraishi out of Osaka. That is a shape worth knowing before anyone ranks
-- Japanese filler rows by mineral again.
--
-- Founded 1902, renamed to the current name in 1964. Unlisted. HQ at 1-1-24
-- Honmachi, Akashi, Hyogo 673-0892. Plants at Fukushima (GCC, talc, barium
-- sulphate, secondary powder processing), Okayama, Takehara in Hiroshima, and
-- Tojo in Shobara. Sales offices in Tokyo and Osaka, plus an overseas base in
-- Malaysia.
--
-- osaka@takehara-chem.jp is published on their locations page. NOT RECORDED -
-- same rule as Maruo and Nittetsu. A contact route on a non-target is how a wrong
-- target becomes a sent message, and that is the third time today this rule has
-- kept an address out of the database.
--
-- IDEMPOTENT. Name-targeted. Nothing inserted, no contact route recorded.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================

update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || '{"fcc_fit": {"verdict": "no", "reason": "PAPER IS IN NO APPLICATION LIST ON THEIR SITE. The product index reads - colloidal calcium carbonate, barium sulphate, kaolin and clay, food and pharmaceutical grades, masterbatch, talc, ground calcium carbonate, secondary powder processing. Every described use points at resins: the Sunlight ultrafine GCC goes to plastics, paint and rubber, the surface-modified Whiteseal series to plastics and adhesives, and the kaolin grades to paint, adhesives, rubber, agrochemicals, medicines and cosmetics. They make colloidal PCC and own their own limestone mine, so every ingredient of a filler house is here - aimed at resins. Same shape as Maruo Calcium. Right mineral, wrong market.", "checked_at": "2026-07-17", "source": "takehara-chem.jp product pages", "source_type": "marketing"}, "the_one_counter_signal": {"what": "The homepage tagline mentions newspapers - roughly, from cars and houses and skyscrapers to milk drinks and newspapers.", "why_it_does_not_change_the_verdict": "A line of marketing poetry about where their minerals end up. No product page names paper as an application. One evocative noun in a tagline is not a paper business - if it were enough, Maruo would have passed too.", "raised_at": "2026-07-17"}, "akashi_cluster": {"observation": "Takehara and Maruo Calcium are IN THE SAME CITY - Maruo at Nishioka, Uozumi-cho, Akashi, and Takehara at Honmachi, Akashi. Two calcium carbonate houses a few kilometres apart in Hyogo, and NEITHER sells to paper.", "why_it_matters": "Akashi is a Japanese CaCO3 cluster and it is a RESIN cluster, not a paper one. The paper PCC lives elsewhere - Okutama in Tokyo, Bihoku in Okayama, Shiraishi out of Osaka. Worth knowing before anyone ranks Japanese filler rows by mineral again.", "raised_at": "2026-07-17"}, "what_they_are": {"founded": "1902, renamed to the current name in 1964", "listed": false, "hq": "1-1-24 Honmachi, Akashi, Hyogo 673-0892", "plants": ["Fukushima - GCC, talc, barium sulphate, secondary powder processing", "Okayama", "Takehara, Hiroshima", "Tojo, Shobara, Hiroshima - tel 0847-72-2191"], "offices": "Tokyo and Osaka sales offices, plus an overseas base in Malaysia", "own_mine": "Their GCC page states the limestone comes from a mine the company owns - high purity, stable in quality and volume", "brands": ["Sunlight - ultrafine GCC", "Whiteseal - surface-modified Sunlight", "kaolin JP-100 / NN / 5M / Hardsil / ST"]}, "contactability": {"not_recorded": "osaka@takehara-chem.jp is published on their locations page. DELIBERATELY NOT RECORDED - this is not a target, and a contact route on a non-target is how a wrong target becomes a sent message. Third time today this rule has kept an address out of the database - Maruo, Nittetsu, Takehara."}}'::jsonb,
    notes = coalesce(f.notes, '') || E'\n[homepage-check 2026-07-17] NOT AN FCC TARGET. Takehara makes colloidal PCC, ultrafine GCC, talc, barium sulphate and kaolin, owns its own mine, and sells all of it to plastics, paint, rubber, adhesives, agrochemicals and pharma. Paper is in no application list. The Maruo pattern. Note - Takehara and Maruo are both in Akashi, Hyogo, and neither sells to paper. Akashi is a resin cluster. Keep the row for market intelligence. Do not enrol, do not build a form.',
    updated_at = now()
from app.parties p
where f.party_id = p.id and p.party_name ~* 'takehara|竹原'
  and f.deleted_at is null and p.deleted_at is null
  and coalesce(f.notes, '') not like '%[homepage-check 2026-07-17]%';


-- ---------- VERIFY ----------
-- select p.party_name, p.city, p.contact_form_url,
--        f.extra_data #>> '{fcc_fit,verdict}' as fcc_fit,
--        (select count(*) from app.contacts c where c.party_id = p.id and c.deleted_at is null) as contacts
-- from app.parties p
-- join app.filler_supplier_profile f on f.party_id = p.id and f.deleted_at is null
-- where p.party_name ~* 'takehara|竹原' and p.deleted_at is null;
-- EXPECT - 'no', no form URL, contacts unchanged.


-- ---------- THE JAPANESE ROSTER, FINISHED ----------
--   Okutama Kogyo      STRONG - over 90% of Japanese paper PCC, departments named
--   Bihoku Funka       STRONG - neutral papermaking filler, cost-down, own mine
--   Shiraishi Group    STRONG - UFPCC+PCC+GCC, paper listed, open testing lab
--   Fimatec            HOLD   - on-site PCC runs on Specialty Minerals technology
--   Maruo Calcium      no     - sealant and resin PCC, Akashi
--   Takehara Chemical  no     - colloidal PCC and kaolin for resins, Akashi
--   Nittetsu Mining    no     - limestone miner, sells rock by the centimetre
--
-- SEVEN JAPANESE ROWS OPENED. THREE ARE TARGETS.
-- The database ranked all seven as plausible filler suppliers. It was right about
-- three, and the three it was right about are not the three anyone would have
-- picked by size - Nittetsu is the biggest company on the list and it is out.
--
-- The whole sweep so far:
--   Artemyn TOP, Okutama STRONG, Gulshan STRONG, Bihoku STRONG, Shiraishi STRONG,
--   20 Microns STRONG, Zantat STRONG, Q-min moderate,
--   Fimatec HOLD, F.M.T. Thailand HOLD, Maruo no, Takehara no, Nittetsu no.
--
-- THIRTEEN OPENED. SEVEN STRONG OR BETTER. FIVE REMOVED OR HELD.
