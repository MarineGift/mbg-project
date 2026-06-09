// src/components/web/sections/Timeline.tsx
import type { SectionProps } from '../SectionRenderer';

interface Ev { year: string; title: string; body?: string }
interface Cfg { title?: string; subtitle?: string; events?: Ev[] }

export function Timeline({ section }: SectionProps) {
  const cfg = section.config as Cfg;
  const events = cfg.events ?? [];
  if (!events.length) return null;
  return (
    <section className="bg-slate-50 py-20">
      <div className="mx-auto max-w-3xl px-6">
        {cfg.title && <h2 className="text-center text-3xl font-bold text-slate-800">{cfg.title}</h2>}
        {cfg.subtitle && <p className="mt-3 text-center text-slate-500">{cfg.subtitle}</p>}
        <ol className="mt-12 space-y-8 border-l-2 border-slate-200 pl-6">
          {events.map((e, i) => (
            <li key={i} className="relative">
              <span className="absolute -left-[31px] top-1 h-4 w-4 rounded-full ring-4 ring-slate-50"
                style={{ background: 'var(--site-accent)' }} />
              <div className="text-sm font-bold" style={{ color: 'var(--site-primary)' }}>{e.year}</div>
              <h3 className="mt-0.5 text-lg font-semibold text-slate-800">{e.title}</h3>
              {e.body && <p className="mt-1 text-sm text-slate-600">{e.body}</p>}
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
