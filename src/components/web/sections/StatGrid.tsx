// src/components/web/sections/StatGrid.tsx
// Numeric achievement grid (e.g. 15+ Patents, 50+ Papers). Server component.

import type { SectionProps } from '../SectionRenderer';

interface Stat { value: string; label: string; sub?: string }
interface Cfg { title?: string; subtitle?: string; stats?: Stat[] }

export function StatGrid({ section }: SectionProps) {
  const cfg = section.config as Cfg;
  const stats = cfg.stats ?? [];
  if (!stats.length) return null;
  return (
    <section className="py-16" style={{ background: 'var(--site-primary)' }}>
      <div className="mx-auto max-w-6xl px-6 text-white">
        {cfg.title && <h2 className="text-center text-3xl font-bold">{cfg.title}</h2>}
        {cfg.subtitle && <p className="mt-3 text-center text-white/70">{cfg.subtitle}</p>}
        <div className="mt-10 grid grid-cols-2 gap-6 md:grid-cols-4">
          {stats.map((s, i) => (
            <div key={i} className="text-center">
              <div className="text-4xl font-extrabold" style={{ color: 'var(--site-accent)' }}>{s.value}</div>
              <div className="mt-1 font-semibold">{s.label}</div>
              {s.sub && <div className="mt-1 text-xs text-white/60">{s.sub}</div>}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
