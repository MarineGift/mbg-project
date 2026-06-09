-- =====================================================================
-- mbg-project : SaaS multi-tenant site builder ("web" schema)
-- Run in Supabase SQL Editor. ASCII-only. Idempotent where practical.
-- Multibyte content lives in JSONB values only (never in identifiers).
-- =====================================================================

create schema if not exists web;

-- ---------------------------------------------------------------------
-- updated_at trigger helper
-- ---------------------------------------------------------------------
create or replace function web.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- =====================================================================
-- sites : one row per tenant homepage
-- =====================================================================
create table if not exists web.sites (
  id            uuid primary key default gen_random_uuid(),
  slug          text not null unique,                 -- 'marinebiogroup'
  name          text not null,
  primary_domain text,                                -- 'www.marinebiogroup.com'
  domains       text[] not null default '{}',         -- all hostnames mapped here
  locale        text not null default 'en',
  theme         jsonb not null default '{}'::jsonb,    -- {primary, accent, font, logo_url}
  meta          jsonb not null default '{}'::jsonb,    -- default SEO meta
  status        text not null default 'draft'
                  check (status in ('draft','published','archived')),
  owner_id      uuid,                                  -- auth.users.id (SaaS owner)
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists sites_domains_gin on web.sites using gin (domains);
drop trigger if exists trg_sites_touch on web.sites;
create trigger trg_sites_touch before update on web.sites
  for each row execute function web.touch_updated_at();

-- site membership for multi-user SaaS access (owner + collaborators)
create table if not exists web.site_members (
  site_id   uuid not null references web.sites(id) on delete cascade,
  user_id   uuid not null,
  role      text not null default 'editor'
              check (role in ('owner','editor','viewer')),
  created_at timestamptz not null default now(),
  primary key (site_id, user_id)
);

-- =====================================================================
-- pages : routes within a site
-- =====================================================================
create table if not exists web.pages (
  id          uuid primary key default gen_random_uuid(),
  site_id     uuid not null references web.sites(id) on delete cascade,
  path        text not null default '/',              -- '/', '/paper-filler'
  title       text,
  meta        jsonb not null default '{}'::jsonb,      -- {description, keywords, og}
  is_home     boolean not null default false,
  status      text not null default 'published'
                check (status in ('draft','published')),
  sort_order  int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (site_id, path)
);
drop trigger if exists trg_pages_touch on web.pages;
create trigger trg_pages_touch before update on web.pages
  for each row execute function web.touch_updated_at();

-- =====================================================================
-- sections : ordered content blocks (the templatized structure)
--   type   = section registry key (hero_video, carousel, contact_form ...)
--   config = all per-section settings (multibyte text lives here)
-- =====================================================================
create table if not exists web.sections (
  id          uuid primary key default gen_random_uuid(),
  page_id     uuid not null references web.pages(id) on delete cascade,
  type        text not null,
  sort_order  int not null default 0,
  is_visible  boolean not null default true,
  config      jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists sections_page_order on web.sections (page_id, sort_order);
drop trigger if exists trg_sections_touch on web.sections;
create trigger trg_sections_touch before update on web.sections
  for each row execute function web.touch_updated_at();

-- =====================================================================
-- collections + items : reusable content pools
--   A "carousel" / "card_grid" section references items by id, so the
--   same pool can be registered once and selected per section.
-- =====================================================================
create table if not exists web.collections (
  id          uuid primary key default gen_random_uuid(),
  site_id     uuid not null references web.sites(id) on delete cascade,
  key         text not null,                          -- 'hero_videos','products'
  name        text,
  created_at  timestamptz not null default now(),
  unique (site_id, key)
);

create table if not exists web.items (
  id            uuid primary key default gen_random_uuid(),
  collection_id uuid not null references web.collections(id) on delete cascade,
  kind          text not null default 'generic'
                  check (kind in ('generic','image','video','youtube','product','reward','patent')),
  title         text,
  data          jsonb not null default '{}'::jsonb,    -- url, alt, price, tags, etc.
  sort_order    int not null default 0,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);
create index if not exists items_collection_order on web.items (collection_id, sort_order);

-- =====================================================================
-- submissions : UNIFIED inbox for every form on every site
--   Denormalized name/email/etc. for fast listing + search.
--   linked_party_id bridges into the existing CRM (app.parties).
-- =====================================================================
create table if not exists web.submissions (
  id            uuid primary key default gen_random_uuid(),
  site_id       uuid not null references web.sites(id) on delete cascade,
  page_id       uuid references web.pages(id) on delete set null,
  form_type     text not null default 'contact',      -- 'contact','signup','consult'
  name          text,
  email         text,
  phone         text,
  company       text,
  interest      text,
  message       text,
  data          jsonb not null default '{}'::jsonb,    -- full raw payload
  status        text not null default 'new'
                  check (status in ('new','read','replied','archived','spam')),
  assigned_to   uuid,
  linked_party_id uuid,                                -- app.parties.id (optional)
  source_host   text,
  ip            inet,
  user_agent    text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists submissions_site_status on web.submissions (site_id, status, created_at desc);
create index if not exists submissions_email on web.submissions (email);
drop trigger if exists trg_submissions_touch on web.submissions;
create trigger trg_submissions_touch before update on web.submissions
  for each row execute function web.touch_updated_at();

-- replies sent from the integrated admin inbox (ties to sendOutboundEmail)
create table if not exists web.submission_replies (
  id              uuid primary key default gen_random_uuid(),
  submission_id   uuid not null references web.submissions(id) on delete cascade,
  body            text not null,
  subject         text,
  sent_by         uuid,
  email_message_id text,
  status          text not null default 'queued'
                    check (status in ('queued','sent','failed')),
  created_at      timestamptz not null default now()
);
create index if not exists replies_submission on web.submission_replies (submission_id, created_at);

-- =====================================================================
-- Row Level Security
--   Server code uses the service role (bypasses RLS). These policies
--   cover anon public-read of published content and owner access.
-- =====================================================================
alter table web.sites      enable row level security;
alter table web.pages      enable row level security;
alter table web.sections   enable row level security;
alter table web.collections enable row level security;
alter table web.items      enable row level security;
alter table web.submissions enable row level security;
alter table web.submission_replies enable row level security;

-- public read of published sites/pages/sections/collections/items
drop policy if exists p_sites_public_read on web.sites;
create policy p_sites_public_read on web.sites
  for select using (status = 'published');

drop policy if exists p_pages_public_read on web.pages;
create policy p_pages_public_read on web.pages
  for select using (status = 'published');

drop policy if exists p_sections_public_read on web.sections;
create policy p_sections_public_read on web.sections
  for select using (is_visible = true);

drop policy if exists p_collections_public_read on web.collections;
create policy p_collections_public_read on web.collections for select using (true);

drop policy if exists p_items_public_read on web.items;
create policy p_items_public_read on web.items for select using (is_active = true);

-- anyone (anon) may INSERT a submission (public form), but never read them
drop policy if exists p_submissions_public_insert on web.submissions;
create policy p_submissions_public_insert on web.submissions
  for insert with check (true);

-- =====================================================================
-- SEED : the two existing sites (idempotent via NOT EXISTS guards)
-- =====================================================================
insert into web.sites (slug, name, primary_domain, domains, locale, status, theme)
select 'marinebiogroup', 'Marinebio Group', 'www.marinebiogroup.com',
       array['www.marinebiogroup.com','marinebiogroup.com'], 'en', 'published',
       '{"primary":"#0b3d5c","accent":"#1fb6a6","logo_url":"https://static.readdy.ai/image/e97325bca996f1ce3b54a2c00c06237a/316a2b7fdbb9930ebedac283acd4ea0e.jpeg"}'::jsonb
where not exists (select 1 from web.sites where slug = 'marinebiogroup');

insert into web.sites (slug, name, primary_domain, domains, locale, status, theme)
select 'marinepad', 'Marine Pad', 'marine-gift.com',
       array['marine-gift.com','marinepad.com','www.marinepad.com'], 'en', 'published',
       '{"primary":"#0e7490","accent":"#ec4899"}'::jsonb
where not exists (select 1 from web.sites where slug = 'marinepad');

-- home pages
insert into web.pages (site_id, path, title, is_home, meta)
select s.id, '/', 'Marine Nanofiber Technology Leader', true,
       '{"description":"World-leading marine nanofiber technology."}'::jsonb
from web.sites s
where s.slug = 'marinebiogroup'
  and not exists (select 1 from web.pages p where p.site_id = s.id and p.path = '/');

insert into web.pages (site_id, path, title, is_home, meta)
select s.id, '/', 'Revolutionary Biodegradable Period Care', true,
       '{"description":"World first 100 percent biodegradable period care."}'::jsonb
from web.sites s
where s.slug = 'marinepad'
  and not exists (select 1 from web.pages p where p.site_id = s.id and p.path = '/');

-- hero_videos collection for marinebiogroup + items (the 5 YouTube IDs found)
insert into web.collections (site_id, key, name)
select s.id, 'hero_videos', 'Hero Background Videos'
from web.sites s
where s.slug = 'marinebiogroup'
  and not exists (select 1 from web.collections c where c.site_id = s.id and c.key = 'hero_videos');

insert into web.items (collection_id, kind, title, data, sort_order)
select c.id, 'youtube', v.title,
       jsonb_build_object('youtube_id', v.yid), v.ord
from web.collections c
cross join (values
  ('4Xf3McA6dVU', 'Marinepad eco friendly sanitary pad', 0),
  ('3HqpDmSSc-c', 'MaskPack Kickstarter', 1),
  ('Nu0bOMa0Uwk', 'Marinebio KOTRA Netherlands', 2),
  ('EWrK9sXcfW4', 'K CON LA 2019', 3),
  ('aEUPjkScyvQ', 'Tech innovation award', 4)
) as v(yid, title, ord)
where c.key = 'hero_videos'
  and c.site_id = (select id from web.sites where slug = 'marinebiogroup')
  and not exists (
    select 1 from web.items i where i.collection_id = c.id
      and i.data->>'youtube_id' = v.yid
  );

-- home page sections for marinebiogroup : hero_video (carousel of videos) + contact_form
insert into web.sections (page_id, type, sort_order, config)
select p.id, 'hero_video', 0,
       jsonb_build_object(
         'collection_key','hero_videos',
         'selected_item_ids','all',
         'headline','Marine Nanofiber Innovation',
         'subhead','Discover our breakthrough marine biotechnology',
         'ctas', jsonb_build_array(
            jsonb_build_object('label','Explore Technology','href','#technology'),
            jsonb_build_object('label','View Products','href','#products')
         )
       )
from web.pages p
join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.type = 'hero_video');

insert into web.sections (page_id, type, sort_order, config)
select p.id, 'contact_form', 90,
       jsonb_build_object(
         'title','Get in Touch',
         'recipient','yunyoung.heo@marinebiogroup.com',
         'fields', jsonb_build_array('name','email','company','phone','interest','message'),
         'interests', jsonb_build_array('Cosmetics','Bio-SAP','Paper','Custom Solution','General Inquiry')
       )
from web.pages p
join web.sites s on s.id = p.site_id
where s.slug = 'marinebiogroup' and p.path = '/'
  and not exists (select 1 from web.sections x where x.page_id = p.id and x.type = 'contact_form');

-- =====================================================================
-- done
-- =====================================================================
