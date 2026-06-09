// src/components/web/sections/FeatureSteps.tsx
// Stepped process (e.g. Core Technology: Biomass -> Nanoization -> Applications)
// with an optional row of innovation cards beneath. Server component.

import type { SectionProps } from '../SectionRenderer';

interface Step { title: string; body?: string; badges?: string[]; images?: string[] }
interface Card { title: string; body?: string }
interface Cfg { title?: string; subtitle?: string; steps?: Step[]; cards?: Card[] }

export function FeatureSteps({ section }: SectionProps) {
  const cfg = section.config as Cfg;
  const steps = cfg.steps ?? [];
  const cards = cfg.cards ?? [];

  return (
    <section id="technology" className="bg-slate-50 py-20">
      <div className="mx-auto max-w-6xl px-6">
        {cfg.title && <h2 className="text-center text-3xl font-bold text-slate-800">{cfg.title}</h2>}
        {cfg.subtitle && (
          <p className="mx-auto mt-3 max-w-2xl text-center text-slate-500">{cfg.subtitle}</p>
        )}

        {steps.length > 0 && (
          <div className="mt-12 grid gap-8 md:grid-cols-3">
            {steps.map((s, i) => (
              <div key={i} className="rounded-2xl bg-white p-6 shadow-sm">
                <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-full text-sm font-bold text-white"
                  style={{ background: 'var(--site-primary)' }}>{i + 1}</div>
                <h3 className="text-lg font-semibold text-slate-800">{s.title}</h3>
                {s.body && <p className="mt-2 whitespace-pre-line text-sm text-slate-600">{s.body}</p>}
                {s.images && s.images.length > 0 && (
                  <div className="mt-4 flex gap-2">
                    {s.images.map((url, j) => (
                      <img key={j} src={url} alt="" className="h-20 w-full rounded-lg object-cover" />
                    ))}
                  </div>
                )}
                {s.badges && s.badges.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-1.5">
                    {s.badges.map((b, j) => (
                      <span key={j} className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs text-slate-600">{b}</span>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}

        {cards.length > 0 && (
          <div className="mt-12 grid gap-6 sm:grid-cols-3">
            {cards.map((c, i) => (
              <div key={i} className="rounded-xl border border-slate-200 bg-white p-6 text-center">
                <h4 className="font-semibold text-slate-800">{c.title}</h4>
                {c.body && <p className="mt-2 text-sm text-slate-600">{c.body}</p>}
              </div>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}
