// src/components/web/sections/DataTable.tsx
// Tabular data (patents, SCI journals). Reads a collection where each
// item.data.cells is a string[] aligned to config.columns. Falls back to
// config.rows for inline data. Server component.

import type { SectionProps } from '../SectionRenderer';

interface Cfg {
  title?: string; subtitle?: string; note?: string;
  columns: string[];
  collection_key?: string;
  rows?: string[][];
}

export function DataTable({ section, collections }: SectionProps) {
  const cfg = section.config as unknown as Cfg;
  const columns = cfg.columns ?? [];

  let rows: string[][] = cfg.rows ?? [];
  if (cfg.collection_key) {
    const items = collections[cfg.collection_key] ?? [];
    rows = items.map((i) => ((i.data as { cells?: string[] }).cells ?? []));
  }
  if (!rows.length || !columns.length) return null;

  return (
    <section className="py-16">
      <div className="mx-auto max-w-5xl px-6">
        {cfg.title && <h2 className="text-2xl font-bold text-slate-800">{cfg.title}</h2>}
        {cfg.subtitle && <p className="mt-2 text-sm text-slate-500">{cfg.subtitle}</p>}
        <div className="mt-6 overflow-x-auto rounded-xl border border-slate-200">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 text-slate-600">
              <tr>
                {columns.map((c, i) => (
                  <th key={i} className="px-4 py-2 font-semibold">{c}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {rows.map((r, ri) => (
                <tr key={ri} className="border-t border-slate-100 align-top">
                  {columns.map((_, ci) => (
                    <td key={ci} className="px-4 py-2 text-slate-700">{r[ci] ?? ''}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {cfg.note && <p className="mt-3 text-sm font-medium text-slate-500">{cfg.note}</p>}
      </div>
    </section>
  );
}
