-- ============================================================
-- 미국 주요 VC 30개 시드 데이터 (실제 컬럼 구조에 맞춤)
-- ============================================================
-- parties 테이블에 `industry` 컬럼은 없음.
-- 산업 정보는 모두 industry_tags 배열에 포함.
-- ============================================================

INSERT INTO app.parties (
    organization_id, name, legal_name, module, party_type,
    tier, country_code, region, city,
    website, industry_tags, source,
    notes, created_by
) VALUES

-- ────────────────────────────────────────────────
-- TIER 1 — Top Venture Capital Firms (AUM $25B+)
-- ────────────────────────────────────────────────

('b25de8f2-1020-482f-9012-183f63883169', 'Andreessen Horowitz',
 'AH Capital Management, LLC', 'investor', 'company',
 'tier_1', 'US', 'California', 'Menlo Park',
 'https://a16z.com',
 ARRAY['Venture Capital','AI','Crypto','Enterprise','American Dynamism'],
 'web_search',
 'AUM ~$90B (2026). Founded by Marc Andreessen & Ben Horowitz. Strong in AI, crypto, fintech, biotech.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Sequoia Capital',
 'Sequoia Capital Operations, LLC', 'investor', 'company',
 'tier_1', 'US', 'California', 'Menlo Park',
 'https://sequoiacap.com',
 ARRAY['Venture Capital','Seed','Growth','Enterprise','Consumer'],
 'web_search',
 'AUM ~$85B. Founded 1972 by Don Valentine. Evergreen fund model since 2021. Notable: Apple, Google, Stripe, WhatsApp.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'General Catalyst',
 'General Catalyst Group Management, LLC', 'investor', 'company',
 'tier_1', 'US', 'Massachusetts', 'Cambridge',
 'https://www.generalcatalyst.com',
 ARRAY['Venture Capital','Healthcare','AI','Fintech','Defense'],
 'web_search',
 'AUM ~$25B. Offices in Cambridge, San Francisco, NYC. Long-term partnership approach. Healthcare AI focus.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Lightspeed Venture Partners',
 'Lightspeed Management Company, LLC', 'investor', 'company',
 'tier_1', 'US', 'California', 'Menlo Park',
 'https://lsvp.com',
 ARRAY['Venture Capital','AI','Enterprise','Fintech','Consumer'],
 'web_search',
 'AUM ~$25B. Raised $9B fund late 2025. 60%+ recent investments in AI. Backed Anthropic, xAI, Databricks.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Founders Fund',
 'Founders Fund Management, LLC', 'investor', 'company',
 'tier_1', 'US', 'California', 'San Francisco',
 'https://foundersfund.com',
 ARRAY['Venture Capital','Deep Tech','Defense','AI','Space'],
 'web_search',
 'Founded by Peter Thiel. Backed SpaceX, Palantir, Stripe, Facebook. Strong in deep tech and defense.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Accel',
 'Accel Management Company, LLC', 'investor', 'company',
 'tier_1', 'US', 'California', 'Palo Alto',
 'https://www.accel.com',
 ARRAY['Venture Capital','Early Stage','Growth','Enterprise SaaS'],
 'web_search',
 'AUM ~$50B. Offices in Palo Alto & London. Led Facebook Series A. Backed Spotify, Slack, Dropbox, Atlassian.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Tiger Global Management',
 'Tiger Global Management, LLC', 'investor', 'company',
 'tier_1', 'US', 'New York', 'New York City',
 'https://www.tigerglobal.com',
 ARRAY['Venture Capital','Growth','Late Stage','Tech','E-commerce'],
 'web_search',
 'AUM $90B+. Aggressive late-stage investor. 9 fintech unicorns. Global focus including emerging markets.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Insight Partners',
 'Insight Venture Management, LLC', 'investor', 'company',
 'tier_1', 'US', 'New York', 'New York City',
 'https://www.insightpartners.com',
 ARRAY['Venture Capital','Growth','Enterprise SaaS','ScaleUp'],
 'web_search',
 'AUM $90B+. Focus on growth-stage software/tech-enabled companies. ScaleUp Group post-investment support.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Kleiner Perkins',
 'KPCB Holdings, Inc.', 'investor', 'company',
 'tier_1', 'US', 'California', 'Menlo Park',
 'https://www.kleinerperkins.com',
 ARRAY['Venture Capital','Healthcare','Enterprise','Hardtech','Consumer'],
 'web_search',
 'Founded 1972. $2M-20M typical checks Seed-Series B. Strong in regulated/scientific sectors. Backed Genentech, Google, Slack.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Bessemer Venture Partners',
 'Deer VII & Co., LLC', 'investor', 'company',
 'tier_1', 'US', 'New York', 'Larchmont',
 'https://www.bvp.com',
 ARRAY['Venture Capital','SaaS','Fintech','Cloud','Healthcare'],
 'web_search',
 'Global firm. Strong in SaaS/cloud/fintech. Portfolio: Toast, Alloy, Betterment, Pinterest.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Thrive Capital',
 'Thrive Capital Management, LLC', 'investor', 'company',
 'tier_1', 'US', 'New York', 'New York City',
 'https://thrivecap.com',
 ARRAY['Venture Capital','Growth','AI','Consumer','Internet'],
 'web_search',
 'AUM $26.8B (2025). Led by Josh Kushner. Backed Instagram, Stripe, OpenAI, Anduril.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

-- ────────────────────────────────────────────────
-- TIER 2 — Established VC Firms (AUM $5-25B)
-- ────────────────────────────────────────────────

('b25de8f2-1020-482f-9012-183f63883169', 'Greylock Partners',
 'Greylock Management Corporation', 'investor', 'company',
 'tier_2', 'US', 'California', 'Menlo Park',
 'https://greylock.com',
 ARRAY['Venture Capital','Seed','Series A','Enterprise','Consumer'],
 'web_search',
 'Founded 1965. Backed Airbnb, Discord, Figma, LinkedIn, Roblox, Workday.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Benchmark',
 'Benchmark Capital Management, LLC', 'investor', 'company',
 'tier_2', 'US', 'California', 'San Francisco',
 'https://www.benchmark.com',
 ARRAY['Venture Capital','Early Stage','Consumer','Marketplaces','SaaS'],
 'web_search',
 'Equal partnership structure. Backed eBay, Twitter, Uber, Snapchat, Discord.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'NEA — New Enterprise Associates',
 'New Enterprise Associates, Inc.', 'investor', 'company',
 'tier_2', 'US', 'California', 'Menlo Park',
 'https://www.nea.com',
 ARRAY['Venture Capital','Healthcare','Tech','Early Stage','Growth'],
 'web_search',
 'AUM ~$25B. Offices in Menlo Park, NYC, DC. Multi-stage. Strong in healthcare and tech.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Khosla Ventures',
 'Khosla Ventures, LLC', 'investor', 'company',
 'tier_2', 'US', 'California', 'Menlo Park',
 'https://www.khoslaventures.com',
 ARRAY['Venture Capital','Deep Tech','ClimaTech','AI','Biotech'],
 'web_search',
 'Founded by Vinod Khosla. Strong in deep tech, climate, AI. Early backer of OpenAI, Impossible Foods.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Index Ventures',
 'Index Ventures Management, LLP', 'investor', 'company',
 'tier_2', 'US', 'California', 'San Francisco',
 'https://www.indexventures.com',
 ARRAY['Venture Capital','Fintech','Gaming','E-commerce','Infrastructure'],
 'web_search',
 'Offices in SF, London, NYC. Portfolio: Robinhood, Adyen, Revolut, Figma, Discord, Roblox.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'GV — Google Ventures',
 'GV Management Company, LLC', 'investor', 'company',
 'tier_2', 'US', 'California', 'Mountain View',
 'https://www.gv.com',
 ARRAY['Venture Capital','AI','Life Sciences','Enterprise','Consumer'],
 'web_search',
 'Alphabet/Google venture arm. Backed Uber, Slack, Nest, Stripe, Lemonade.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Battery Ventures',
 'Battery Management Corp.', 'investor', 'company',
 'tier_2', 'US', 'Massachusetts', 'Boston',
 'https://www.battery.com',
 ARRAY['Venture Capital','Enterprise SaaS','Industrial Tech','Growth'],
 'web_search',
 'AUM ~$13B. Offices in Boston, SF, San Mateo, NYC, London. Enterprise & industrial tech focus.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'IVP — Institutional Venture Partners',
 'IVP Management Company, LLC', 'investor', 'company',
 'tier_2', 'US', 'California', 'Menlo Park',
 'https://www.ivp.com',
 ARRAY['Venture Capital','Growth','Late Stage','Tech'],
 'web_search',
 'Founded 1980. Late-stage focused. Backed Twitter, Snap, Slack, Datadog.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Spark Capital',
 'Spark Management Partners, LLC', 'investor', 'company',
 'tier_2', 'US', 'Massachusetts', 'Boston',
 'https://www.sparkcapital.com',
 ARRAY['Venture Capital','Consumer','Media','Commerce','SaaS'],
 'web_search',
 'Offices in Boston, SF, NYC. Backed Twitter, Discord, Coinbase, Postmates.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'CRV — Charles River Ventures',
 'CRV Management, LLC', 'investor', 'company',
 'tier_2', 'US', 'California', 'Palo Alto',
 'https://www.crv.com',
 ARRAY['Venture Capital','Seed','Series A','AI','Cybersecurity','DevTools'],
 'web_search',
 'Founded 1970. $750M latest fund. Pure seed/Series A. Any partner can commit within 24h.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Coatue Management',
 'Coatue Management, LLC', 'investor', 'company',
 'tier_2', 'US', 'New York', 'New York City',
 'https://www.coatue.com',
 ARRAY['Venture Capital','Growth','AI','Tech','Hedge Fund'],
 'web_search',
 'Tech-focused hedge fund + venture. Strong in growth-stage AI investments.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Felicis Ventures',
 'Felicis Ventures Management Company, LLC', 'investor', 'company',
 'tier_2', 'US', 'California', 'Menlo Park',
 'https://www.felicis.com',
 ARRAY['Venture Capital','Early Stage','Seed','Series A','Consumer','Enterprise'],
 'web_search',
 'Founded by Aydin Senkut. Backed Adyen, Shopify, Twitch, Cruise, Notion.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

-- ────────────────────────────────────────────────
-- TIER 3 — Specialized / Seed / Accelerator
-- ────────────────────────────────────────────────

('b25de8f2-1020-482f-9012-183f63883169', 'Y Combinator',
 'Y Combinator Management, LLC', 'investor', 'company',
 'tier_3', 'US', 'California', 'Mountain View',
 'https://www.ycombinator.com',
 ARRAY['Accelerator','Pre-Seed','Seed','Network'],
 'web_search',
 'Top accelerator. $500K standard deal. Backed Airbnb, Stripe, Coinbase, DoorDash, Instacart, Dropbox.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'First Round Capital',
 'First Round Management, LLC', 'investor', 'company',
 'tier_3', 'US', 'California', 'San Francisco',
 'https://firstround.com',
 ARRAY['Venture Capital','Seed','Pre-Seed','Hands-on Support'],
 'web_search',
 'Pure seed-stage firm. Hands-on operator approach. Backed Uber, Square, Notion, Roblox.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Pear VC',
 'Pear Ventures Management, LLC', 'investor', 'company',
 'tier_3', 'US', 'California', 'Menlo Park',
 'https://pear.vc',
 ARRAY['Venture Capital','Pre-Seed','Seed','Early Stage','Founder Support'],
 'web_search',
 'Pre-seed/seed specialist. Stanford ties. Backed DoorDash, Guardant Health, Branch.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'BoxGroup',
 'BoxGroup, LLC', 'investor', 'company',
 'tier_3', 'US', 'New York', 'New York City',
 'https://www.boxgroup.com',
 ARRAY['Venture Capital','Pre-Seed','Seed','Multi-sector'],
 'web_search',
 'NYC seed/pre-seed. Backed Plaid, Roblox, Vine, Stripe (seed).',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'NFX',
 'NFX Capital Management, LLC', 'investor', 'company',
 'tier_3', 'US', 'California', 'San Francisco',
 'https://www.nfx.com',
 ARRAY['Venture Capital','Pre-Seed','Seed','Network Effects','Marketplaces'],
 'web_search',
 'Network-effects-focused seed firm. $400K+ standard. Open-source investor tools (Signal).',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'USV — Union Square Ventures',
 'Union Square Ventures, LLC', 'investor', 'company',
 'tier_3', 'US', 'New York', 'New York City',
 'https://www.usv.com',
 ARRAY['Venture Capital','Crypto','Web3','Fintech','Climate'],
 'web_search',
 'Thesis-driven firm. Strong in Web3/crypto. Backed Twitter, Etsy, Stripe, Coinbase, Twilio.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0'),

('b25de8f2-1020-482f-9012-183f63883169', 'Ribbit Capital',
 'Ribbit Management Company, LLC', 'investor', 'company',
 'tier_3', 'US', 'California', 'Palo Alto',
 'https://ribbitcap.com',
 ARRAY['Venture Capital','Fintech','Crypto','Insurance','Banking'],
 'web_search',
 'Fintech-only specialist. Backed Robinhood, Coinbase, Brex, Nubank, Revolut.',
 '551fc4a0-b365-47eb-bf2f-0c3f594001c0');

-- ============================================================
-- 검증
-- ============================================================
SELECT
    tier,
    COUNT(*) AS count
FROM app.parties
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND module = 'investor'
  AND deleted_at IS NULL
GROUP BY tier
ORDER BY tier;

SELECT COUNT(*) AS total_investors
FROM app.parties
WHERE organization_id = 'b25de8f2-1020-482f-9012-183f63883169'
  AND module = 'investor'
  AND deleted_at IS NULL;
