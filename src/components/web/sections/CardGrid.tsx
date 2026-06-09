'use client';
// src/components/web/sections/CardGrid.tsx
// Tabbed card grid (e.g. Products showcase). Reads a collection pool; each
// item.data = { image, category, description, tags[] }. Category tabs are
// derived from the items. Distinct from the shop Storefront (this is content,
// not commerce).

import { useMemo, useState } from 'react';
import type { SectionProps } from '../SectionRenderer';

interface Cfg {
  title?: string; subtitle?: string;
  collection_key?: string; tabs?: boolean; columns?: 2 | 3 | 4;
}

interface CardData { image?: string; category?: string; description?: string; tags?: string[] }

export function CardGrid({ section, collections }: SectionProps) {
  const cfg = section.config as Cfg;
  const items = collections[cfg.collection_key ?? ''] ?? [];
  const [cat, setCat] = useState('All');

  const categories = useMemo(() => {
    const set = new Set<string>();
    items.forEach((i) => {
      const c = (i.data as CardData).category;
      if (c) set.add(c);
    });
    return ['All', ...Array.from(set)];
  }, [items]);

  const visible = cat === 'All'
    ? items
    : items.filter((i) => (i.data as CardData).category === cat);

  if (!items.length) return null;
  const cols = cfg.columns ?? 4;
  const gridCls = cols === 2 ? 'sm:grid-cols-2'
    : cols === 3 ? 'sm:grid-cols-2 lg:grid-cols-3'
    : 'sm:grid-cols-2 lg:grid-cols-4';

  return (
    <section id="products" className="py-20">
      <div className="mx-auto max-w-6xl px-6">
        {cfg.title && <h2 className="text-center text-3xl font-bold text-slate-800">{cfg.title}</h2>}
        {cfg.subtitle && (
          <p className="mx-auto mt-3 max-w-2xl text-center text-slate-500">{cfg.subtitle}</p>
        )}

        {cfg.tabs && categories.length > 2 && (
          <div className="mt-8 flex flex-wrap justify-center gap-2">
            {categories.map((c) => (
              <button key={c} onClick={() => setCat(c)}
                className="rounded-full px-4 py-1.5 text-sm font-medium"
                style={c === cat
                  ? { background: 'var(--site-primary)', color: '#fff' }
                  : { background: '#f1f5f9', color: '#475569' }}>
                {c}
              </button>
            ))}
          </div>
        )}

        <div className={`mt-10 grid gap-6 ${gridCls}`}>
          {visible.map((item) => {
            const d = item.data as CardData;
            return (
              <div key={item.id} className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
                {d.image && (
                  <div className="aspect-[4/3] overflow-hidden bg-slate-100">
                    <img src={d.image} alt={item.title ?? ''} className="h-full w-full object-cover" />
                  </div>
                )}
                <div className="p-5">
                  {d.category && (
                    <span className="text-xs font-medium uppercase tracking-wide text-slate-400">{d.category}</span>
                  )}
                  {item.title && <h3 className="mt-1 text-lg font-semibold text-slate-800">{item.title}</h3>}
                  {d.description && <p className="mt-2 text-sm text-slate-600">{d.description}</p>}
                  {d.tags && d.tags.length > 0 && (
                    <div className="mt-3 flex flex-wrap gap-1.5">
                      {d.tags.map((t, j) => (
                        <span key={j} className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs text-slate-600">{t}</span>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
