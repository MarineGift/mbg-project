// src/components/web/sections/Story.tsx
// Flexible text block: heading + body + optional image (left/right), optional
// quote, optional feature cards, optional CTAs. Covers About/Vision, Research
// intro, Founder story, and Core Values (features-only, no image).

import type { SectionProps } from '../SectionRenderer';

interface Feature { title: string; body?: string }
interface Cta { label: string; href: string }
interface Cfg {
  id?: string;
  title?: string;
  body?: string;
  image?: string;
  image_side?: 'left' | 'right';
  quote?: string;
  features?: Feature[];
  ctas?: Cta[];
}

export function Story({ section }: SectionProps) {
  const cfg = section.config as Cfg;
  const hasImage = Boolean(cfg.image);
  const imgRight = cfg.image_side !== 'left';

  const text = (
    <div className="flex-1">
      {cfg.title && <h2 className="text-3xl font-bold text-slate-800">{cfg.title}</h2>}
      {cfg.body && <p className="mt-4 whitespace-pre-line text-slate-600">{cfg.body}</p>}
      {cfg.quote && (
        <blockquote className="mt-6 border-l-4 pl-4 italic text-slate-700"
          style={{ borderColor: 'var(--site-accent)' }}>
          {cfg.quote}
        </blockquote>
      )}
      {cfg.ctas && cfg.ctas.length > 0 && (
        <div className="mt-6 flex flex-wrap gap-3">
          {cfg.ctas.map((c, i) => (
            <a key={i} href={c.href}
              className="rounded-full px-6 py-2.5 text-sm font-semibold text-white"
              style={{ background: i === 0 ? 'var(--site-primary)' : 'var(--site-accent)' }}>
              {c.label}
            </a>
          ))}
        </div>
      )}
    </div>
  );

  return (
    <section id={cfg.id} className="py-20">
      <div className="mx-auto max-w-6xl px-6">
        {hasImage ? (
          <div className={`flex flex-col items-center gap-10 ${imgRight ? 'md:flex-row' : 'md:flex-row-reverse'}`}>
            {text}
            <div className="flex-1">
              <img src={cfg.image} alt={cfg.title ?? ''} className="w-full rounded-2xl object-cover shadow-sm" />
            </div>
          </div>
        ) : (
          <div className="mx-auto max-w-3xl text-center">{text}</div>
        )}

        {cfg.features && cfg.features.length > 0 && (
          <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
            {cfg.features.map((f, i) => (
              <div key={i} className="rounded-xl border border-slate-200 bg-white p-6">
                <h4 className="font-semibold text-slate-800">{f.title}</h4>
                {f.body && <p className="mt-2 text-sm text-slate-600">{f.body}</p>}
              </div>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}
