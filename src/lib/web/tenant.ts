// src/lib/web/tenant.ts  (REPLACES Phase 1 version)
// Resolve a site by hostname (including domain aliases) and load a page with
// any structured data its template needs (campaign for crowdfunding, products
// for shop). Flat selects + in-memory joins (no PostgREST embeds).

import { createClient } from '@supabase/supabase-js';
import type {
  Site, Page, Section, CollectionItem, RenderedPage,
  Campaign, RewardTier, Product, ProductVariant, ProductImage,
} from './types';

function webClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } },
  );
}

function normalizeHost(host: string): string {
  return (host.toLowerCase().split(':')[0] ?? '').trim();
}

export interface ResolvedHost {
  site: Site;
  landing_path: string;   // where '/' on this host should land ('/crowdfunding')
}

export async function resolveHost(host: string): Promise<ResolvedHost | null> {
  const h = normalizeHost(host);
  const sb = webClient();

  // 1) domain alias takes priority (marine-gift.com -> main site /crowdfunding)
  const { data: alias } = await sb
    .schema('web')
    .from('domain_aliases' as never)
    .select('site_id,landing_path')
    .eq('host', h)
    .maybeSingle();

  if (alias) {
    const a = alias as { site_id: string; landing_path: string };
    const site = await getSite({ id: a.site_id });
    if (site) return { site, landing_path: a.landing_path || '/' };
  }

  // 2) direct domain on the site row
  const site = await getSite({ host: h });
  if (site) return { site, landing_path: '/' };
  return null;
}

async function getSite(q: { id?: string; host?: string; slug?: string }): Promise<Site | null> {
  const sb = webClient();
  let query = sb.schema('web').from('sites' as never).select('*').limit(1);
  if (q.id) query = query.eq('id', q.id);
  else if (q.slug) query = query.eq('slug', q.slug);
  else if (q.host) query = query.contains('domains', [q.host]).eq('status', 'published');
  const { data } = await query.maybeSingle();
  return (data as unknown as Site) ?? null;
}

export async function resolveSiteBySlug(slug: string): Promise<Site | null> {
  return getSite({ slug });
}

export async function loadPage(site: Site, path: string): Promise<RenderedPage | null> {
  const sb = webClient();
  const wantPath = path && path !== '' ? path : '/';

  const { data: pageRow } = await sb
    .schema('web').from('pages' as never).select('*')
    .eq('site_id', site.id).eq('path', wantPath).eq('status', 'published')
    .limit(1).maybeSingle();
  if (!pageRow) return null;
  const page = pageRow as unknown as Page;

  const { data: sectionRows } = await sb
    .schema('web').from('sections' as never).select('*')
    .eq('page_id', page.id).eq('is_visible', true)
    .order('sort_order', { ascending: true });
  const sections = (sectionRows ?? []) as unknown as Section[];

  // collections pool (carousels, grids)
  const collections = await loadCollections(site.id);

  const rendered: RenderedPage = { site, page, sections, collections };

  // template-aware structured data
  if (page.template === 'crowdfunding') {
    rendered.campaign = await loadCampaign(site.id, page.id);
  }
  if (page.template === 'shop' || sections.some((s) => s.type === 'storefront')) {
    rendered.products = await loadProducts(site.id);
  }
  return rendered;
}

async function loadCollections(siteId: string): Promise<Record<string, CollectionItem[]>> {
  const sb = webClient();
  const { data: collRows } = await sb
    .schema('web').from('collections' as never).select('id,key').eq('site_id', siteId);
  const colls = (collRows ?? []) as Array<{ id: string; key: string }>;
  const out: Record<string, CollectionItem[]> = {};
  if (!colls.length) return out;
  const { data: itemRows } = await sb
    .schema('web').from('items' as never).select('*')
    .in('collection_id', colls.map((c) => c.id))
    .eq('is_active', true).order('sort_order', { ascending: true });
  const items = (itemRows ?? []) as unknown as CollectionItem[];
  for (const c of colls) out[c.key] = items.filter((i) => i.collection_id === c.id);
  return out;
}

async function loadCampaign(siteId: string, pageId: string): Promise<Campaign | undefined> {
  const sb = webClient();
  const { data: c } = await sb
    .schema('web').from('campaigns' as never).select('*')
    .eq('site_id', siteId).eq('page_id', pageId)
    .in('status', ['live', 'funded']).limit(1).maybeSingle();
  if (!c) return undefined;
  const campaign = c as unknown as Campaign;
  const { data: tierRows } = await sb
    .schema('web').from('reward_tiers' as never).select('*')
    .eq('campaign_id', campaign.id).order('sort_order', { ascending: true });
  campaign.tiers = (tierRows ?? []) as unknown as RewardTier[];
  return campaign;
}

async function loadProducts(siteId: string): Promise<Product[]> {
  const sb = webClient();
  const { data: prodRows } = await sb
    .schema('web').from('products' as never).select('*')
    .eq('site_id', siteId).eq('status', 'active')
    .order('sort_order', { ascending: true });
  const products = (prodRows ?? []) as unknown as Product[];
  if (!products.length) return [];

  const ids = products.map((p) => p.id);
  const { data: imgRows } = await sb
    .schema('web').from('product_images' as never).select('product_id,url,sort_order')
    .in('product_id', ids).order('sort_order', { ascending: true });
  const firstImg = new Map<string, string>();
  for (const r of (imgRows ?? []) as Array<{ product_id: string; url: string }>) {
    if (!firstImg.has(r.product_id)) firstImg.set(r.product_id, r.url);
  }

  // default variant id per product (for quick add-to-cart)
  const { data: varRows } = await sb
    .schema('web').from('product_variants' as never)
    .select('id,product_id,is_default,sort_order')
    .in('product_id', ids).order('sort_order', { ascending: true });
  const defVar = new Map<string, string>();
  for (const v of (varRows ?? []) as Array<{ id: string; product_id: string; is_default: boolean }>) {
    if (v.is_default) defVar.set(v.product_id, v.id);
    else if (!defVar.has(v.product_id)) defVar.set(v.product_id, v.id);
  }

  return products.map((p) => ({
    ...p,
    image: firstImg.get(p.id) ?? null,
    default_variant_id: defVar.get(p.id) ?? null,
  }));
}

// Single product (detail page route).
export async function loadProduct(siteId: string, slug: string): Promise<Product | null> {
  const sb = webClient();
  const { data: p } = await sb
    .schema('web').from('products' as never).select('*')
    .eq('site_id', siteId).eq('slug', slug).eq('status', 'active')
    .limit(1).maybeSingle();
  if (!p) return null;
  const product = p as unknown as Product;
  const { data: variants } = await sb
    .schema('web').from('product_variants' as never).select('*')
    .eq('product_id', product.id).order('sort_order', { ascending: true });
  const { data: images } = await sb
    .schema('web').from('product_images' as never).select('*')
    .eq('product_id', product.id).order('sort_order', { ascending: true });
  product.variants = (variants ?? []) as unknown as ProductVariant[];
  product.images = (images ?? []) as unknown as ProductImage[];
  product.image = product.images[0]?.url ?? null;
  return product;
}

export function pickItems(
  all: CollectionItem[],
  selected: string[] | 'all' | undefined,
): CollectionItem[] {
  if (!selected || selected === 'all') return all;
  const order = new Map(selected.map((id, i) => [id, i]));
  return all.filter((i) => order.has(i.id))
    .sort((a, b) => (order.get(a.id)! - order.get(b.id)!));
}
