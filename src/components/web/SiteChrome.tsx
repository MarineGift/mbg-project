// src/components/web/SiteChrome.tsx
// Shared header + footer for every tenant page. Nav comes from site.nav,
// colors from site.theme (exposed as CSS vars consumed by sections).

import type { ReactNode } from 'react';
import type { Site } from '@/lib/web/types';

export function SiteChrome({ site, children }: { site: Site; children: ReactNode }) {
  return (
    <div
      style={{
        ['--site-primary' as string]: site.theme?.primary ?? '#0b3d5c',
        ['--site-accent' as string]: site.theme?.accent ?? '#1fb6a6',
      }}
    >
      <header className="sticky top-0 z-50 border-b border-slate-200 bg-white/90 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-3">
          <a href="/" className="flex items-center gap-2">
            {site.theme?.logo_url ? (
              <img src={site.theme.logo_url} alt={site.name} className="h-9 w-auto rounded" />
            ) : (
              <span className="text-lg font-bold" style={{ color: 'var(--site-primary)' }}>{site.name}</span>
            )}
          </a>
          <nav className="hidden items-center gap-6 md:flex">
            {(site.nav ?? []).map((n) => (
              <a key={n.href} href={n.href} className="text-sm font-medium text-slate-600 hover:text-slate-900">
                {n.label}
              </a>
            ))}
            <a href="/shop" className="rounded-full px-4 py-1.5 text-sm font-semibold text-white"
              style={{ background: 'var(--site-accent)' }}>
              Shop
            </a>
          </nav>
        </div>
      </header>

      <main>{children}</main>

      <footer className="mt-16 border-t border-slate-200 bg-slate-50">
        <div className="mx-auto max-w-6xl px-6 py-10 text-sm text-slate-500">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <span className="font-semibold text-slate-700">{site.name}</span>
            <nav className="flex flex-wrap gap-4">
              {(site.nav ?? []).map((n) => (
                <a key={n.href} href={n.href} className="hover:text-slate-800">{n.label}</a>
              ))}
            </nav>
          </div>
          <p className="mt-6 text-xs text-slate-400">
            (c) {new Date().getFullYear()} {site.name}. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}
