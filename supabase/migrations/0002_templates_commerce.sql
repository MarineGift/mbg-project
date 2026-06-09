-- =====================================================================
-- mbg-project : 0002 - page templates + e-commerce + crowdfunding
-- Run AFTER 0001_web_schema.sql in Supabase SQL Editor. ASCII-only.
-- Consolidates to a single main site (marinebiogroup) whose pages use
-- different templates; marine-gift is folded into /crowdfunding.
-- =====================================================================

-- ---------------------------------------------------------------------
-- pages.template : drives default sections + which structured data loads
-- ---------------------------------------------------------------------
alter table web.pages
  add column if not exists template text not null default 'landing'
    check (template in ('landing','content','crowdfunding','shop','product'));

-- site-level navigation (shared header/footer)
alter table web.sites
  add column if not exists nav jsonb not null default '[]'::jsonb;  -- [{label, href}]

-- ---------------------------------------------------------------------
-- domain aliases : one host -> (site, landing path). Lets marine-gift.com
-- resolve to the main site's /crowdfunding page.
-- ---------------------------------------------------------------------
create table if not exists web.domain_aliases (
  host          text primary key,          -- 'marine-gift.com'
  site_id       uuid not null references web.sites(id) on delete cascade,
  landing_path  text not null default '/',  -- '/crowdfunding'
  created_at    timestamptz not null default now()
);

-- =====================================================================
-- E-COMMERCE
-- =====================================================================
create table if not exists web.products (
  id          uuid primary key default gen_random_uuid(),
  site_id     uuid not null references web.sites(id) on delete cascade,
  slug        text not null,
  name        text not null,
  subtitle    text,
  description text,
  category    text,                          -- 'cosmetics','bio-sap','paper'
  tags        text[] not null default '{}',
  base_price  numeric(12,2),
  currency    text not null default 'USD',
  featured    boolean not null default false,
  status      text not null default 'active'
                check (status in ('draft','active','archived')),
  sort_order  int not null default 0,
  meta        jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (site_id, slug)
);
create index if not exists products_site_status on web.products (site_id, status, sort_order);
drop trigger if exists trg_products_touch on web.products;
create trigger trg_products_touch before update on web.products
  for each row execute function web.touch_updated_at();

create table if not exists web.product_variants (
  id              uuid primary key default gen_random_uuid(),
  product_id      uuid not null references web.products(id) on delete cascade,
  sku             text,
  name            text,                      -- 'Regular', 'Night', '8-pack'
  price           numeric(12,2) not null,
  compare_at_price numeric(12,2),
  stock           int,                       -- null = unlimited/made-to-order
  attributes      jsonb not null default '{}'::jsonb,
  is_default      boolean not null default false,
  sort_order      int not null default 0
);
create index if not exists variants_product on web.product_variants (product_id, sort_order);

create table if not exists web.product_images (
  id          uuid primary key default gen_random_uuid(),
  product_id  uuid not null references web.products(id) on delete cascade,
  url         text not null,
  alt         text,
  sort_order  int not null default 0
);
create index if not exists images_product on web.product_images (product_id, sort_order);

-- carts (anonymous token or logged-in user)
create table if not exists web.carts (
  id          uuid primary key default gen_random_uuid(),
  site_id     uuid not null references web.sites(id) on delete cascade,
  token       text,                          -- anon cookie id
  user_id     uuid,
  status      text not null default 'open'
                check (status in ('open','converted','abandoned')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists carts_token on web.carts (token);
drop trigger if exists trg_carts_touch on web.carts;
create trigger trg_carts_touch before update on web.carts
  for each row execute function web.touch_updated_at();

create table if not exists web.cart_items (
  id          uuid primary key default gen_random_uuid(),
  cart_id     uuid not null references web.carts(id) on delete cascade,
  variant_id  uuid not null references web.product_variants(id),
  qty         int not null default 1 check (qty > 0),
  unit_price  numeric(12,2) not null,
  unique (cart_id, variant_id)
);

-- orders
create table if not exists web.orders (
  id           uuid primary key default gen_random_uuid(),
  site_id      uuid not null references web.sites(id) on delete cascade,
  order_no     text not null unique,
  email        text,
  name         text,
  phone        text,
  shipping     jsonb not null default '{}'::jsonb,  -- address fields
  subtotal     numeric(12,2) not null default 0,
  shipping_fee numeric(12,2) not null default 0,
  total        numeric(12,2) not null default 0,
  currency     text not null default 'USD',
  status       text not null default 'pending'
                 check (status in ('pending','paid','fulfilled','cancelled','refunded')),
  payment_ref  text,                          -- Stripe/PG reference
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists orders_site_status on web.orders (site_id, status, created_at desc);
drop trigger if exists trg_orders_touch on web.orders;
create trigger trg_orders_touch before update on web.orders
  for each row execute function web.touch_updated_at();

create table if not exists web.order_items (
  id           uuid primary key default gen_random_uuid(),
  order_id     uuid not null references web.orders(id) on delete cascade,
  product_name text not null,
  variant_name text,
  sku          text,
  qty          int not null,
  unit_price   numeric(12,2) not null,
  line_total   numeric(12,2) not null
);
create index if not exists order_items_order on web.order_items (order_id);

-- =====================================================================
-- CROWDFUNDING
-- =====================================================================
create table if not exists web.campaigns (
  id            uuid primary key default gen_random_uuid(),
  site_id       uuid not null references web.sites(id) on delete cascade,
  page_id       uuid references web.pages(id) on delete set null,
  slug          text not null,
  title         text not null,
  story         text,
  video_id      text,                         -- hero youtube id
  goal_amount   numeric(14,2) not null,
  raised_amount numeric(14,2) not null default 0,
  backers_count int not null default 0,
  currency      text not null default 'USD',
  start_at      timestamptz,
  end_at        timestamptz,
  status        text not null default 'live'
                  check (status in ('draft','live','funded','closed')),
  meta          jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (site_id, slug)
);
drop trigger if exists trg_campaigns_touch on web.campaigns;
create trigger trg_campaigns_touch before update on web.campaigns
  for each row execute function web.touch_updated_at();

create table if not exists web.reward_tiers (
  id              uuid primary key default gen_random_uuid(),
  campaign_id     uuid not null references web.campaigns(id) on delete cascade,
  name            text not null,
  price           numeric(12,2) not null,
  compare_at_price numeric(12,2),
  description     text,
  includes        jsonb not null default '[]'::jsonb,  -- array of strings
  est_delivery    text,
  limited_qty     int,                          -- null = unlimited
  claimed_qty     int not null default 0,
  backers_count   int not null default 0,
  is_popular      boolean not null default false,
  sort_order      int not null default 0
);
create index if not exists tiers_campaign on web.reward_tiers (campaign_id, sort_order);

create table if not exists web.pledges (
  id            uuid primary key default gen_random_uuid(),
  campaign_id   uuid not null references web.campaigns(id) on delete cascade,
  tier_id       uuid references web.reward_tiers(id),
  name          text,
  email         text,
  country       text,
  amount        numeric(12,2),
  status        text not null default 'pledged'
                  check (status in ('pledged','confirmed','cancelled')),
  submission_id uuid references web.submissions(id),  -- bridge to unified inbox
  created_at    timestamptz not null default now()
);
create index if not exists pledges_campaign on web.pledges (campaign_id, created_at desc);

-- =====================================================================
-- RLS for new public-readable tables
-- =====================================================================
alter table web.products         enable row level security;
alter table web.product_variants enable row level security;
alter table web.product_images   enable row level security;
alter table web.campaigns        enable row level security;
alter table web.reward_tiers     enable row level security;
alter table web.domain_aliases   enable row level security;

drop policy if exists p_products_public on web.products;
create policy p_products_public on web.products for select using (status = 'active');
drop policy if exists p_variants_public on web.product_variants;
create policy p_variants_public on web.product_variants for select using (true);
drop policy if exists p_images_public on web.product_images;
create policy p_images_public on web.product_images for select using (true);
drop policy if exists p_campaigns_public on web.campaigns;
create policy p_campaigns_public on web.campaigns for select using (status in ('live','funded'));
drop policy if exists p_tiers_public on web.reward_tiers;
create policy p_tiers_public on web.reward_tiers for select using (true);
drop policy if exists p_aliases_public on web.domain_aliases;
create policy p_aliases_public on web.domain_aliases for select using (true);

-- =====================================================================
-- IA CONSOLIDATION : marinebiogroup becomes the single main site
-- =====================================================================

-- nav for the main site
update web.sites
set nav = '[
  {"label":"Technology","href":"/#technology"},
  {"label":"Products","href":"/#products"},
  {"label":"Shop","href":"/shop"},
  {"label":"Crowd Funding","href":"/crowdfunding"},
  {"label":"Research","href":"/#research"},
  {"label":"About","href":"/#about"},
  {"label":"Contact","href":"/#contact"}
]'::jsonb
where slug = 'marinebiogroup';

-- retire the standalone marinepad site (free its domains for the alias)
update web.sites set domains = '{}', status = 'archived' where slug = 'marinepad';

-- point marine-gift / marinepad domains at the main site's /crowdfunding
insert into web.domain_aliases (host, site_id, landing_path)
select v.host, (select id from web.sites where slug = 'marinebiogroup'), '/crowdfunding'
from (values ('marine-gift.com'), ('marinepad.com'), ('www.marinepad.com')) as v(host)
on conflict (host) do update
  set site_id = excluded.site_id, landing_path = excluded.landing_path;

-- crowdfunding + shop pages on the main site
insert into web.pages (site_id, path, title, template, meta)
select s.id, '/crowdfunding', 'Marine Pad - Biodegradable Period Care', 'crowdfunding',
       '{"description":"World first 100 percent biodegradable period care."}'::jsonb
from web.sites s where s.slug = 'marinebiogroup'
  and not exists (select 1 from web.pages p where p.site_id = s.id and p.path = '/crowdfunding');

insert into web.pages (site_id, path, title, template, meta)
select s.id, '/shop', 'Shop', 'shop',
       '{"description":"Marine nanofiber products."}'::jsonb
from web.sites s where s.slug = 'marinebiogroup'
  and not exists (select 1 from web.pages p where p.site_id = s.id and p.path = '/shop');

-- crowdfunding sections (campaign data is loaded by template, not stored here)
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'progress', 0, '{}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/crowdfunding'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.type = 'progress');

insert into web.sections (page_id, type, sort_order, config)
select p.id, 'reward_tiers', 1, '{"title":"Support Marine Pad"}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/crowdfunding'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.type = 'reward_tiers');

-- shop storefront section
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'storefront', 0,
       '{"title":"Our Products","show_categories":true}'::jsonb
from web.pages p join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/shop'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.type = 'storefront');

-- campaign + 5 real reward tiers (from marine-gift.com)
insert into web.campaigns (site_id, page_id, slug, title, story, video_id,
                           goal_amount, raised_amount, backers_count, status)
select s.id, p.id, 'marine-pad', 'Marine Pad: A Gift from the Sea',
       'The world first 100 percent biodegradable period care made from marine nano-fibers.',
       '4Xf3McA6dVU', 100000, 47892, 427, 'live'
from web.sites s
join web.pages p on p.site_id = s.id and p.path = '/crowdfunding'
where s.slug = 'marinebiogroup'
  and not exists (select 1 from web.campaigns c where c.site_id = s.id and c.slug = 'marine-pad');

insert into web.reward_tiers (campaign_id, name, price, compare_at_price, description,
                              includes, est_delivery, limited_qty, backers_count, is_popular, sort_order)
select c.id, t.name, t.price, t.cmp, t.descr, t.inc::jsonb, t.deliv, t.lim, t.backers, t.pop, t.ord
from web.campaigns c
cross join (values
  ('Early Bird - Single Pack', 15, 25, 'Perfect for trying Marine Pad for the first time',
   '["1 pack of Marine Pad (8 pads)","Digital thank you card","Exclusive updates"]', 'March 2025', 373, 127, false, 0),
  ('Starter Pack', 35, 50, 'Great value for new Marine Pad users',
   '["3 packs (24 pads)","Organic cotton pouch","Digital sustainability guide","Backer updates"]', 'March 2025', NULL, 89, true, 1),
  ('Complete Care Bundle', 65, 95, 'Everything you need for sustainable period care',
   '["6 packs (48 pads)","Premium pouch","Travel case","Printed guide","Stickers","Priority support"]', 'March 2025', NULL, 156, true, 2),
  ('Champion Supporter', 120, 180, 'For those who want to make a real impact',
   '["12 packs (96 pads)","Gift box packaging","Signed letter","Branded water bottle","Webinar access","Supporter wall"]', 'March 2025', NULL, 43, false, 3),
  ('Ocean Guardian', 250, 350, 'Ultimate supporter package with exclusive perks',
   '["24 packs (192 pads)","Limited edition tote","Personal video thank you","Merch bundle","Early access","Launch event invite","Impact certificate"]', 'March 2025', 88, 12, false, 4)
) as t(name, price, cmp, descr, inc, deliv, lim, backers, pop, ord)
where c.slug = 'marine-pad'
  and c.site_id = (select id from web.sites where slug = 'marinebiogroup')
  and not exists (select 1 from web.reward_tiers r where r.campaign_id = c.id and r.name = t.name);

-- sample shop products (from marinebiogroup catalog)
insert into web.products (site_id, slug, name, subtitle, category, base_price, currency, featured, sort_order)
select s.id, v.slug, v.name, v.sub, v.cat, v.price, 'USD', v.feat, v.ord
from web.sites s
cross join (values
  ('natural-soap',     'Natural Soap',    'Marine nanofiber gentle cleansing',     'cosmetics', 18, true, 0),
  ('face-mask',        'Face Mask',       'Marine collagen deep hydration',        'cosmetics', 24, true, 1),
  ('sun-screen',       'Sun Screen',      'Broad-spectrum UV defense',             'cosmetics', 22, false, 2),
  ('tone-up',          'Tone Up Cream',   'Instant brightening',                   'cosmetics', 26, false, 3),
  ('marine-pad-box',   'Marine Pad',      'Biodegradable sanitary pad (8-pack)',   'bio-sap',   15, true, 4),
  ('paper-filler',     'Paper Filler',    'Eco-friendly pulp-reducing additive',   'paper',    NULL, false, 5)
) as v(slug, name, sub, cat, price, feat, ord)
where s.slug = 'marinebiogroup'
  and not exists (select 1 from web.products p where p.site_id = s.id and p.slug = v.slug);

-- a default variant per product so add-to-cart works out of the box
insert into web.product_variants (product_id, sku, name, price, stock, is_default)
select p.id, upper(replace(p.slug,'-','_')), 'Default',
       coalesce(p.base_price, 0), 100, true
from web.products p
join web.sites s on s.id = p.site_id and s.slug = 'marinebiogroup'
where not exists (select 1 from web.product_variants v where v.product_id = p.id);

-- =====================================================================
-- done
-- =====================================================================
