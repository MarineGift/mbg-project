-- ============================================================
-- fix_gulshan_footprint_2026-07-17.sql
--
-- THE LAST GAP IN THE SATELLITE OPERATOR SET, and it is one company, not six.
--
-- 🔴 I SAID SIX AN HOUR AGO. THE DATA I ALREADY HAD SAID ONE.
-- scan_satellite_plants_unmatched lists every plant of every filler profile that
-- carries a footprint array, matched or not. It returned NINE ROWS, ALL ARTEMYN.
-- So Artemyn is the only profile with that array. And block 1 of
-- scan_mill_filler_pairs showed where the other operators already stand:
--     Specialty Minerals  ~60 party rows, one per plant, links already recorded
--     Mississippi Lime    2 mills / 2 high, linked
--     Double A            1 / 1, linked
--     Fimatec             1 / 0, linked - also present as SMI FMT (Japan - Shiraoi)
--     Taekyung BK         1 / 1, linked, and do_not_contact since 03:42 today
--     Gulshan             ZERO LINKS. Nothing at all.
-- SMI is already mapped BETTER than Artemyn was - sixty named plant rows against
-- one JSON array. There was never a six-operator job. There was Gulshan.
-- That is the eighth magnitude I asserted today before checking, and the eighth
-- one that was wrong.
--
-- ⭐ GULSHAN IS NOT ARTEMYN, AND THE DIFFERENCE IS THE WHOLE POINT.
-- Artemyn published a map of TOWNS. Every pair from it is a siting inference and
-- was recorded 'potential' / 'medium' for that reason.
-- GULSHAN NAMES ITS HOSTS. Off gulshanindia.com, read 2026-07-17:
--   manufacturing_unit.html
--     "This Onsite PCC plant was set up in 2013 at Muzaffarnagar, Uttar Pradesh
--      for a Paper Industry Company namely Silvertone Pulp & Paper Mill Pvt. Ltd."
--     "This Onsite PCC plant was set up in 2015 at Amlai, Madhya Pradesh for
--      Orient paper Mills (OPM), a Birla Group Company"
--   satellite-pcc-plant.html
--     "Gulshan Polyols Ltd is the first to introduce the concept of On-site PCC
--      plant in India, at the site of Magnum Papers ltd. This has been recorded
--      in the Limca Book of Records, 2010."
--   milestones.html
--     "Set up third On-site PCC plant for ITC Limited at Hooghly"
--     plus on-site plants at Sahibabad and Patiala, Punjab, and two turnkey
--     plants in Bangladesh - HOSTS NOT NAMED on those.
-- A named host is a STATED relationship. When these become party_supply_links
-- rows they are 'active', not 'potential'. That is a different confidence class
-- from every Artemyn pair recorded an hour ago, and it comes from the company
-- saying it rather than from two dots landing on one town.
--
-- ⛔ AND THE DISTINCTION GULSHAN ITSELF DRAWS, which must not be flattened.
-- satellite-pcc-plant.html also says: "Gulshan is supplying PCC for alkaline
-- paper to Paper Mills like ITC Ltd, TNPL, BILT, Shree Krishna Paper Mills Ltd
-- etc." THAT IS MERCHANT SUPPLY, NOT AN ON-SITE PLANT. Same page, same company,
-- two different relationships, and the page separates them. So does this file:
-- onsite_pcc_plants_named_hosts versus pcc_supply_not_onsite. Collapsing them
-- would manufacture four satellites that do not exist - and 'satellite' is not
-- even a member of link_type, which was checked before being assumed this time.
--
-- ⛔ NOT RECORDED: Trident Limited, Barnala, Punjab. A March 2026 item on a news
-- aggregator says Gulshan will build an on-site PCC slurry plant there. It is
-- NOT on gulshanindia.com in anything read today. Same call as SPB's mdoff@ - a
-- snippet is not a page. It goes in extra_data as an unverified lead and nowhere
-- else.
--
-- NO LINKS ARE WRITTEN HERE. The host mills need uuids and this session has none
-- for Magnum, Silvertone, Orient or ITC Hooghly. THE VERIFY BELOW LOOKS THEM UP -
-- one run gives the write and the host list together.
--
-- Targeted by name, uuid-free, per fix_burgo_domain_verified and
-- fix_saica_wrong_contact. Last statement is an UNCOMMENTED select. IDEMPOTENT.
-- No BEGIN / no DO blocks / no semicolons or bare 'into' in strings.
-- ============================================================


-- ---------- 1) Gulshan's footprint, in its own words ----------
update app.filler_supplier_profile f
set extra_data = coalesce(f.extra_data, '{}'::jsonb) || jsonb_build_object(
      'footprint', jsonb_build_object(
        'source', 'gulshanindia.com',
        'source_type', 'company site',
        'pages_read', jsonb_build_array('manufacturing_unit.html', 'satellite-pcc-plant.html', 'milestones.html'),
        'checked_at', '2026-07-17',
        'evidence_class', 'NAMED HOSTS - the company states who each on-site plant was built for. This is not the Artemyn case, which published towns and required a siting inference. Links built off this are active, not potential.',
        'onsite_pcc_plants_named_hosts', jsonb_build_array(
          jsonb_build_object('host', 'Magnum Papers Ltd.', 'country', 'IN',
            'note', 'The first on-site PCC plant in India. Recorded in the Limca Book of Records 2010. Gulshan calls it the site of its first partnership.',
            'page', 'satellite-pcc-plant.html'),
          jsonb_build_object('host', 'Silvertone Pulp & Paper Mill Pvt. Ltd.', 'country', 'IN',
            'location', 'Muzaffarnagar, Uttar Pradesh', 'year', 2013,
            'note', 'Gulshan words - set up for a Paper Industry Company namely Silvertone Pulp and Paper Mill Pvt. Ltd. Same town as Gulshan own first calcium carbonate works.',
            'page', 'manufacturing_unit.html'),
          jsonb_build_object('host', 'Orient Paper Mills (OPM)', 'country', 'IN',
            'location', 'Amlai, Madhya Pradesh', 'year', 2015, 'group', 'Birla',
            'note', 'Gulshan words - set up for Orient paper Mills, a Birla Group Company.',
            'page', 'manufacturing_unit.html and milestones.html'),
          jsonb_build_object('host', 'ITC Limited', 'country', 'IN',
            'location', 'Hooghly', 'note', 'Milestones calls it the third on-site PCC plant. ITC Hooghly is a different mill to ITC Bhadrachalam, which is the Artemyn candidate.',
            'page', 'milestones.html')),
        'onsite_plants_host_unnamed', jsonb_build_array(
          jsonb_build_object('location', 'Sahibabad, IN', 'note', 'Milestones calls it the first on-site plant. Host not named.'),
          jsonb_build_object('location', 'Patiala, Punjab, IN', 'note', 'Host not named.'),
          jsonb_build_object('location', 'Bangladesh', 'count', 2, 'note', 'Two turnkey plants, PCC and WGCC. Hosts not named. A 2021 Paper Mart interview with director Arushi Jain claims SIX satellite plants in total including these two.')),
        'pcc_supply_not_onsite', jsonb_build_array('ITC Ltd', 'TNPL', 'BILT', 'Shree Krishna Paper Mills Ltd'),
        'supply_note', 'Gulshan own page separates these - it supplies PCC for alkaline paper to these mills. MERCHANT SUPPLY, NOT on-site plants. Do not promote them to satellites.',
        'caco3_capacity', 'Muzaffarnagar UP works, first established 1980, calcium carbonate capacity grown to roughly 150000 tonnes a year by its own account. Produces PCC, GCC and ACC, over 19 grades.',
        'people', 'Dr Vasant Chapnekar, named on satellite-pcc-plant.html as the technologist responsible for introducing PCC in alkaline paper in the USA, is stated to be associated with Gulshan. A named technical human, published by the company.',
        'unverified_lead', jsonb_build_object(
          'item', 'Trident Limited, Barnala, Punjab - on-site PCC slurry plant',
          'source', 'news aggregator, March 2026',
          'status', 'NOT on gulshanindia.com in anything read on 2026-07-17. A snippet is not a page. Confirm before use.')
      )),
    updated_at = now()
from app.parties p
where p.id = f.party_id
  and p.party_name ~* '^gulshan'
  and p.party_type_id = 3
  and p.deleted_at is null
  and f.deleted_at is null;


-- ---------- 2) VERIFY plus HOST LOOKUP - one run, both answers ----------
select v.probe,
       v.gulshan_says,
       p.party_name as roster_match,
       p.id         as mill_party_id,
       p.country_code,
       p.city,
       p.do_not_contact,
       (select string_agg(distinct pt.filler_relevance, ' / ')
        from app.paper_mill_paper_types mp
        join app.paper_types pt on pt.id = mp.paper_type_id
        where mp.mill_party_id = p.id) as filler_relevance,
       (select jsonb_array_length(g.extra_data #> '{footprint,onsite_pcc_plants_named_hosts}')
        from app.filler_supplier_profile g
        join app.parties gp on gp.id = g.party_id
        where gp.party_name ~* '^gulshan' and g.deleted_at is null limit 1) as gulshan_hosts_written
from (values
  ('magnum',        'Magnum Papers Ltd. - first on-site PCC in India, Limca 2010'),
  ('silvertone',    'Silvertone Pulp & Paper Mill - Muzaffarnagar UP, 2013'),
  ('orient paper',  'Orient Paper Mills - Amlai MP, Birla Group, 2015'),
  ('itc',           'ITC Limited Hooghly - third on-site plant'),
  ('shree krishna', 'Shree Krishna Paper Mills - MERCHANT SUPPLY ONLY, not on-site'),
  ('trident',       'Trident Barnala - UNVERIFIED, news aggregator only')
) as v(probe, gulshan_says)
left join app.parties p
  on p.party_type_id = 2
 and p.deleted_at is null
 and p.party_name ~* v.probe
order by v.probe, p.party_name;

-- HOW TO READ IT.
--
-- gulshan_hosts_written MUST READ 4 on every row. That is the write check. If it
-- is null, statement 1 matched nothing and the Gulshan profile row is named
-- something other than a leading 'gulshan' - send the name back.
--
-- roster_match null means this database does not hold that mill. Magnum Papers
-- and Silvertone are small Indian mills and their absence would be a roster hole,
-- not a mistake - the same shape as the nine unmatched Artemyn towns.
--
-- 'itc' WILL RETURN MORE THAN ONE ROW and that is correct, not a bug. ITC
-- Bhadrachalam is already recorded as an Artemyn candidate. The Hooghly unit is a
-- different mill. DO NOT link Gulshan to whichever ITC row appears first - read
-- the city column. A wrong pick here is the Saica error with better manners.
--
-- 'shree krishna' and 'trident' are printed so they are not forgotten and NOT so
-- they get linked. Shree Krishna is merchant supply by Gulshan's own page.
-- Trident is a news snippet.
--
-- WHAT COMES NEXT, once the ids are known: four 'active' links, and they are a
-- different animal from this morning's eight. Artemyn's pairs are inferred from
-- towns. Gulshan's are stated by the company. If Magnum, Silvertone, Orient and
-- ITC Hooghly all sit in this roster, that is four confirmed satellite pairs from
-- an operator that came back STRONG on the filler sweep yesterday - and India was
-- 4 of 7 there and 6 of 6 on grade fit this morning.
