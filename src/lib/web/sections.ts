// src/lib/web/sections.ts  (REPLACES Phase 1 version)
// Central registry describing each section type. The renderer uses it to map
// type -> component; the admin editor uses label/category to build the
// "add section" palette and to know which templates each section suits.

import type { SectionType, PageTemplate } from './types';

export interface SectionMeta {
  type: SectionType;
  label: string;
  category: 'hero' | 'content' | 'commerce' | 'data' | 'form';
  usesCollection?: boolean;       // pulls from collections/items pool
  templates?: PageTemplate[];     // templates where this section is offered
}

export const SECTION_REGISTRY: Record<SectionType, SectionMeta> = {
  hero_video:       { type: 'hero_video',       label: 'Video Hero',       category: 'hero',     usesCollection: true, templates: ['landing','crowdfunding','content'] },
  carousel:         { type: 'carousel',         label: 'Carousel',         category: 'content',  usesCollection: true },
  feature_steps:    { type: 'feature_steps',    label: 'Feature Steps',    category: 'content',  templates: ['landing','content'] },
  card_grid:        { type: 'card_grid',        label: 'Card Grid',        category: 'content',  usesCollection: true },
  stat_grid:        { type: 'stat_grid',        label: 'Stat Grid',        category: 'data',     templates: ['landing','content'] },
  data_table:       { type: 'data_table',       label: 'Data Table',       category: 'data',     usesCollection: true },
  cert_block:       { type: 'cert_block',        label: 'Certification',    category: 'content',  templates: ['landing','content'] },
  timeline:         { type: 'timeline',         label: 'Timeline',         category: 'content',  templates: ['landing','content'] },
  reward_tiers:     { type: 'reward_tiers',     label: 'Reward Tiers',     category: 'commerce', templates: ['crowdfunding'] },
  progress:         { type: 'progress',         label: 'Funding Progress', category: 'commerce', templates: ['crowdfunding'] },
  comparison_table: { type: 'comparison_table', label: 'Comparison Table', category: 'data' },
  faq:              { type: 'faq',              label: 'FAQ Accordion',    category: 'content' },
  story:            { type: 'story',            label: 'Story / Quote',    category: 'content' },
  cta_banner:       { type: 'cta_banner',        label: 'CTA Banner',       category: 'content' },
  storefront:       { type: 'storefront',       label: 'Storefront Grid',  category: 'commerce', templates: ['shop'] },
  product_detail:   { type: 'product_detail',   label: 'Product Detail',   category: 'commerce', templates: ['product'] },
  contact_form:     { type: 'contact_form',     label: 'Contact Form',     category: 'form' },
};

// Default section blueprint per template (used by admin "new page").
export const TEMPLATE_DEFAULTS: Record<PageTemplate, SectionType[]> = {
  landing:      ['hero_video', 'feature_steps', 'card_grid', 'stat_grid', 'contact_form'],
  content:      ['story'],
  crowdfunding: ['progress', 'reward_tiers', 'story', 'comparison_table', 'faq', 'contact_form'],
  shop:         ['storefront'],
  product:      ['product_detail'],
};

export function isKnownSection(t: string): t is SectionType {
  return t in SECTION_REGISTRY;
}
