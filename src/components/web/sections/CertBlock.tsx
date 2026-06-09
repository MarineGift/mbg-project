// src/components/web/sections/CertBlock.tsx
// Certification / award block: heading + body + certificate image + detail
// cards (e.g. NET certification). Server component.

import type { SectionProps } from '../SectionRenderer';

interface Card { title: string; body?: string }
interface Cfg { title?: string; body?: string; image?: string; cards?: Card[] }

export function CertBlock({ section }: SectionProps) {
  const cfg = section.config as Cfg;
  return (
    <section className="bg-slate-50 py-20">
      <div className="mx-auto max-w-6xl px-6">
        {cfg.title && <h2 className="text-center text-3xl font-bold text-slate-800">{cfg.title}</h2>}
        {cfg.body && <p className="mx-auto mt-3 max-w-2xl text-center text-slate-600">{cfg.body}</p>}
        <div className="mt-10 grid items-start gap-10 md:grid-cols-2">
          {cfg.image && (
            <img src={cfg.image} alt={cfg.title ?? 'certificate'}
              className="w-full rounded-2xl border border-slate-200 bg-white object-contain shadow-sm" />
          )}
          {cfg.cards && cfg.cards.length > 0 && (
            <div className="space-y-4">
              {cfg.cards.map((c, i) => (
                <div key={i} className="rounded-xl border border-slate-200 bg-white p-5">
                  <h4 className="font-semibold" style={{ color: 'var(--site-primary)' }}>{c.title}</h4>
                  {c.body && <p className="mt-1 text-sm text-slate-600">{c.body}</p>}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </section>
  );
}
