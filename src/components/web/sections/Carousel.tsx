'use client';
// src/components/web/sections/Carousel.tsx
// Generic carousel. Items live in a collection pool; the section's config
// chooses which item ids to show and in what order. This is the literal
// "register many in the carousel, then select which to build" requirement.
//
// config = {
//   title?, collection_key, selected_item_ids: string[] | 'all',
//   autoplay?: boolean, interval_ms?: number, per_view?: 1|2|3,
//   variant?: 'image' | 'card'
// }

import { useEffect, useState, useMemo, useCallback } from 'react';
import type { SectionProps } from '../SectionRenderer';
import type { CollectionItem } from '@/lib/web/types';
import { pickItems } from '@/lib/web/tenant';

interface CarouselConfig {
  title?: string;
  collection_key?: string;
  selected_item_ids?: string[] | 'all';
  autoplay?: boolean;
  interval_ms?: number;
  per_view?: 1 | 2 | 3;
  variant?: 'image' | 'card';
}

export function Carousel({ section, collections }: SectionProps) {
  const cfg = section.config as CarouselConfig;
  const pool = collections[cfg.collection_key ?? ''] ?? [];
  const items = useMemo(
    () => pickItems(pool, cfg.selected_item_ids),
    [pool, cfg.selected_item_ids],
  );

  const perView = cfg.per_view ?? 1;
  const pages = Math.max(1, Math.ceil(items.length / perView));
  const [page, setPage] = useState(0);

  const go = useCallback(
    (dir: number) => setPage((p) => (p + dir + pages) % pages),
    [pages],
  );

  useEffect(() => {
    if (!cfg.autoplay || pages < 2) return;
    const t = setInterval(() => setPage((p) => (p + 1) % pages), cfg.interval_ms ?? 5000);
    return () => clearInterval(t);
  }, [cfg.autoplay, cfg.interval_ms, pages]);

  if (!items.length) return null;

  return (
    <section className="mx-auto max-w-6xl px-6 py-16">
      {cfg.title && (
        <h2 className="mb-8 text-center text-3xl font-bold text-slate-800">
          {cfg.title}
        </h2>
      )}

      <div className="relative">
        <div className="overflow-hidden">
          <div
            className="flex transition-transform duration-500 ease-out"
            style={{ transform: `translateX(-${page * 100}%)` }}
          >
            {items.map((item) => (
              <div
                key={item.id}
                className="shrink-0 px-2"
                style={{ width: `${100 / perView}%` }}
              >
                <Slide item={item} variant={cfg.variant ?? 'image'} />
              </div>
            ))}
          </div>
        </div>

        {pages > 1 && (
          <>
            <button
              aria-label="previous"
              onClick={() => go(-1)}
              className="absolute -left-2 top-1/2 -translate-y-1/2 rounded-full bg-white/90 p-2 shadow hover:bg-white"
            >
              &#8249;
            </button>
            <button
              aria-label="next"
              onClick={() => go(1)}
              className="absolute -right-2 top-1/2 -translate-y-1/2 rounded-full bg-white/90 p-2 shadow hover:bg-white"
            >
              &#8250;
            </button>
            <div className="mt-6 flex justify-center gap-2">
              {Array.from({ length: pages }).map((_, i) => (
                <button
                  key={i}
                  aria-label={`go to ${i + 1}`}
                  onClick={() => setPage(i)}
                  className="h-2.5 w-2.5 rounded-full"
                  style={{
                    background: i === page ? 'var(--site-accent)' : '#cbd5e1',
                  }}
                />
              ))}
            </div>
          </>
        )}
      </div>
    </section>
  );
}

function Slide({ item, variant }: { item: CollectionItem; variant: 'image' | 'card' }) {
  const d = item.data as {
    url?: string; image?: string; alt?: string; caption?: string;
    body?: string; href?: string; youtube_id?: string;
  };
  const img = d.image ?? d.url;

  if (item.kind === 'youtube' && d.youtube_id) {
    return (
      <div className="aspect-video w-full overflow-hidden rounded-xl bg-black">
        <iframe
          title={item.title ?? 'video'}
          className="h-full w-full"
          src={`https://www.youtube.com/embed/${d.youtube_id}`}
          allow="encrypted-media"
        />
      </div>
    );
  }

  if (variant === 'card') {
    return (
      <div className="h-full rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        {img && (
          <img src={img} alt={d.alt ?? item.title ?? ''} className="mb-4 h-40 w-full rounded-lg object-cover" />
        )}
        {item.title && <h3 className="text-lg font-semibold text-slate-800">{item.title}</h3>}
        {d.body && <p className="mt-2 text-sm text-slate-600">{d.body}</p>}
      </div>
    );
  }

  return (
    <figure className="overflow-hidden rounded-xl">
      {img && <img src={img} alt={d.alt ?? item.title ?? ''} className="h-72 w-full object-cover" />}
      {(item.title || d.caption) && (
        <figcaption className="mt-3 text-center text-sm text-slate-600">
          {item.title ?? d.caption}
        </figcaption>
      )}
    </figure>
  );
}
