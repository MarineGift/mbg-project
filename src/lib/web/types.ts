// src/lib/web/types.ts  (REPLACES Phase 1 version)
// Types for the SaaS site-builder. Adds page templates, e-commerce and
// crowdfunding. Keep in sync with 0001 + 0002 migrations.

export type SiteStatus = 'draft' | 'published' | 'archived';
export type PageTemplate = 'landing' | 'content' | 'crowdfunding' | 'shop' | 'product';

export interface SiteTheme {
  primary?: string;
  accent?: string;
  font?: string;
  logo_url?: string;
}

export interface NavItem { label: string; href: string }

export interface Site {
  id: string;
  slug: string;
  name: string;
  primary_domain: string | null;
  domains: string[];
  locale: string;
  theme: SiteTheme;
  nav: NavItem[];
  meta: Record<string, unknown>;
  status: SiteStatus;
  owner_id: string | null;
}

export interface Page {
  id: string;
  site_id: string;
  path: string;
  title: string | null;
  template: PageTemplate;
  meta: { description?: string; keywords?: string; og?: Record<string, string> };
  is_home: boolean;
  status: 'draft' | 'published';
  sort_order: number;
}

export interface Section {
  id: string;
  page_id: string;
  type: SectionType;
  sort_order: number;
  is_visible: boolean;
  config: Record<string, unknown>;
}

export interface CollectionItem {
  id: string;
  collection_id: string;
  kind: 'generic' | 'image' | 'video' | 'youtube' | 'product' | 'reward' | 'patent';
  title: string | null;
  data: Record<string, unknown>;
  sort_order: number;
  is_active: boolean;
}

// ---- e-commerce ------------------------------------------------------
export interface ProductVariant {
  id: string;
  product_id: string;
  sku: string | null;
  name: string | null;
  price: number;
  compare_at_price: number | null;
  stock: number | null;
  attributes: Record<string, unknown>;
  is_default: boolean;
  sort_order: number;
}

export interface ProductImage {
  id: string; product_id: string; url: string; alt: string | null; sort_order: number;
}

export interface Product {
  id: string;
  site_id: string;
  slug: string;
  name: string;
  subtitle: string | null;
  description: string | null;
  category: string | null;
  tags: string[];
  base_price: number | null;
  currency: string;
  featured: boolean;
  status: 'draft' | 'active' | 'archived';
  sort_order: number;
  // joined-in for convenience
  image?: string | null;
  default_variant_id?: string | null;
  variants?: ProductVariant[];
  images?: ProductImage[];
}

// ---- crowdfunding ----------------------------------------------------
export interface RewardTier {
  id: string;
  campaign_id: string;
  name: string;
  price: number;
  compare_at_price: number | null;
  description: string | null;
  includes: string[];
  est_delivery: string | null;
  limited_qty: number | null;
  claimed_qty: number;
  backers_count: number;
  is_popular: boolean;
  sort_order: number;
}

export interface Campaign {
  id: string;
  site_id: string;
  page_id: string | null;
  slug: string;
  title: string;
  story: string | null;
  video_id: string | null;
  goal_amount: number;
  raised_amount: number;
  backers_count: number;
  currency: string;
  start_at: string | null;
  end_at: string | null;
  status: 'draft' | 'live' | 'funded' | 'closed';
  tiers?: RewardTier[];
}

// The payload a rendered page needs. Structured data (campaign/products) is
// attached by the loader based on page.template.
export interface RenderedPage {
  site: Site;
  page: Page;
  sections: Section[];
  collections: Record<string, CollectionItem[]>;
  campaign?: Campaign;        // template === 'crowdfunding'
  products?: Product[];       // template === 'shop' (or storefront section)
}

export type SectionType =
  | 'hero_video'
  | 'feature_steps'
  | 'card_grid'
  | 'stat_grid'
  | 'data_table'
  | 'cert_block'
  | 'timeline'
  | 'reward_tiers'
  | 'progress'
  | 'comparison_table'
  | 'faq'
  | 'story'
  | 'carousel'
  | 'cta_banner'
  | 'storefront'
  | 'product_detail'
  | 'contact_form';

export interface SubmissionInput {
  site_id: string;
  page_id?: string | null;
  form_type?: string;
  name?: string; email?: string; phone?: string; company?: string;
  interest?: string; message?: string;
  data?: Record<string, unknown>;
  source_host?: string;
}
