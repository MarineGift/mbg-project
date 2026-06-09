// src/components/web/sections/CtaBanner.tsx
import type { SectionProps } from '../SectionRenderer';

interface Cfg { title?: string; body?: string; cta?: { label: string; href: string } }

export function CtaBanner({ section }: SectionProps) {
  const cfg = section.config as Cfg;
  return (
    <section className="py-16">
      <div className="mx-auto max-w-4xl px-6">
        <div className="rounded-3xl p-10 text-center text-white"
          style={{ background: 'linear-gradient(135deg, var(--site-primary), var(--site-accent))' }}>
          {cfg.title && <h2 className="text-2xl font-bold sm:text-3xl">{cfg.title}</h2>}
          {cfg.body && <p className="mx-auto mt-3 max-w-xl text-white/85">{cfg.body}</p>}
          {cfg.cta && (
            <a href={cfg.cta.href}
              className="mt-6 inline-block rounded-full bg-white px-7 py-3 font-semibold"
              style={{ color: 'var(--site-primary)' }}>
              {cfg.cta.label}
            </a>
          )}
        </div>
      </div>
    </section>
  );
}
