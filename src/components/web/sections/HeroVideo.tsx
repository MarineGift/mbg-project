'use client';
// src/components/web/sections/HeroVideo.tsx
// Full-bleed hero with a rotating YouTube background. Videos come from a
// collection pool; config.selected_item_ids picks which to show ("register
// many, choose which to build"). Matches the look of both reference sites.

import { useEffect, useState, useMemo } from 'react';
import type { SectionProps } from '../SectionRenderer';
import { pickItems } from '@/lib/web/tenant';

interface Cta { label: string; href: string }
interface HeroConfig {
  collection_key?: string;
  selected_item_ids?: string[] | 'all';
  headline?: string;
  subhead?: string;
  ctas?: Cta[];
  rotate_ms?: number;
}

export function HeroVideo({ section, collections }: SectionProps) {
  const cfg = section.config as HeroConfig;
  const pool = collections[cfg.collection_key ?? 'hero_videos'] ?? [];
  const videos = useMemo(
    () =>
      pickItems(pool, cfg.selected_item_ids)
        .map((i) => (i.data as { youtube_id?: string }).youtube_id)
        .filter(Boolean) as string[],
    [pool, cfg.selected_item_ids],
  );

  const [idx, setIdx] = useState(0);
  useEffect(() => {
    if (videos.length < 2) return;
    const t = setInterval(
      () => setIdx((n) => (n + 1) % videos.length),
      cfg.rotate_ms ?? 12000,
    );
    return () => clearInterval(t);
  }, [videos.length, cfg.rotate_ms]);

  const current = videos[idx];

  return (
    <section className="relative flex h-[80vh] min-h-[520px] items-center justify-center overflow-hidden text-white">
      {current && (
        <iframe
          key={current}
          title="hero-bg"
          className="pointer-events-none absolute left-1/2 top-1/2 h-[120%] w-[120%] -translate-x-1/2 -translate-y-1/2 object-cover"
          src={`https://www.youtube.com/embed/${current}?autoplay=1&mute=1&loop=1&playlist=${current}&controls=0&showinfo=0&rel=0&modestbranding=1`}
          allow="autoplay; encrypted-media"
        />
      )}
      <div className="absolute inset-0 bg-black/45" />
      <div className="relative z-10 max-w-3xl px-6 text-center">
        {cfg.headline && (
          <h1 className="text-4xl font-bold leading-tight sm:text-5xl md:text-6xl">
            {cfg.headline}
          </h1>
        )}
        {cfg.subhead && (
          <p className="mt-4 text-lg text-white/85 sm:text-xl">{cfg.subhead}</p>
        )}
        {cfg.ctas?.length ? (
          <div className="mt-8 flex flex-wrap justify-center gap-4">
            {cfg.ctas.map((c, i) => (
              <a
                key={c.href}
                href={c.href}
                className={
                  i === 0
                    ? 'rounded-full px-7 py-3 font-semibold text-white'
                    : 'rounded-full border border-white/70 px-7 py-3 font-semibold text-white hover:bg-white/10'
                }
                style={i === 0 ? { background: 'var(--site-accent)' } : undefined}
              >
                {c.label}
              </a>
            ))}
          </div>
        ) : null}
      </div>
    </section>
  );
}
