'use client';
// src/components/web/sections/Storefront.tsx
// Shop product grid. Reads products loaded by the shop template. Category
// tabs are derived from the products themselves. Cards link to product detail;
// a quick "Add" uses the default variant.

import { useMemo, useState, useTransition } from 'react';
import type { SectionProps } from '../SectionRenderer';
import type { Product } from '@/lib/web/types';
import { addToCart } from '@/lib/web/commerce-actions';

interface Cfg { title?: string; show_categories?: boolean }

export function Storefront({ section, products, site }: SectionProps) {
  const cfg = section.config as Cfg;
  const list = products ?? [];
  const [cat, setCat] = useState<string>('all');

  const categories = useMemo(() => {
    const set = new Set<string>();
    list.forEach((p) => p.category && set.add(p.category));
    return ['all', ...Array.from(set)];
  }, [list]);

  const visible = cat === 'all' ? list : list.filter((p) => p.category === cat);
  if (!list.length) return null;

  return (
    <section id="shop" className="mx-auto max-w-6xl px-6 py-16">
      {cfg.title && (
        <h2 className="mb-8 text-center text-3xl font-bold text-slate-800">{cfg.title}</h2>
      )}

      {cfg.show_categories && categories.length > 2 && (
        <div className="mb-8 flex flex-wrap justify-center gap-2">
          {categories.map((c) => (
            <button key={c} onClick={() => setCat(c)}
              className="rounded-full px-4 py-1.5 text-sm font-medium capitalize"
              style={c === cat
                ? { background: 'var(--site-primary)', color: '#fff' }
                : { background: '#f1f5f9', color: '#475569' }}>
              {c}
            </button>
          ))}
        </div>
      )}

      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {visible.map((p) => <ProductCard key={p.id} product={p} siteId={site.id} />)}
      </div>
    </section>
  );
}

function ProductCard({ product, siteId }: { product: Product; siteId: string }) {
  const [pending, start] = useTransition();
  const [added, setAdded] = useState(false);

  const price = product.base_price;
  const priceText = price != null
    ? new Intl.NumberFormat('en-US', { style: 'currency', currency: product.currency }).format(price)
    : 'Contact for quote';

  const quickAdd = () => {
    if (!product.default_variant_id) return;
    start(async () => {
      const res = await addToCart({ site_id: siteId, variant_id: product.default_variant_id! });
      if (res.ok) setAdded(true);
    });
  };

  return (
    <div className="group flex flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:shadow-md">
      <a href={`/shop/${product.slug}`} className="block aspect-square overflow-hidden bg-slate-100">
        {product.image ? (
          <img src={product.image} alt={product.name} className="h-full w-full object-cover transition group-hover:scale-105" />
        ) : (
          <div className="flex h-full items-center justify-center text-slate-300">No image</div>
        )}
      </a>
      <div className="flex flex-1 flex-col p-5">
        {product.category && (
          <span className="text-xs font-medium uppercase tracking-wide text-slate-400">{product.category}</span>
        )}
        <a href={`/shop/${product.slug}`} className="mt-1 text-lg font-semibold text-slate-800 hover:underline">
          {product.name}
        </a>
        {product.subtitle && <p className="mt-1 line-clamp-2 text-sm text-slate-500">{product.subtitle}</p>}
        <div className="mt-4 flex items-center justify-between">
          <span className="font-bold text-slate-900">{priceText}</span>
          {price != null && (
            <button onClick={quickAdd} disabled={pending || added}
              className="rounded-lg px-3 py-1.5 text-sm font-semibold text-white disabled:opacity-60"
              style={{ background: 'var(--site-accent)' }}>
              {added ? 'Added' : pending ? '...' : 'Add'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
