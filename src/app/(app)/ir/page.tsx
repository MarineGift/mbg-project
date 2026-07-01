// src/app/(app)/ir/page.tsx
//
// IR / Fundraise dashboard. Two jobs:
//   1) One-click links into the Google Drive data-room folders (uploads happen
//      in Drive; this is fast navigation + a single source of truth).
//   2) A fundraise-prep checklist backed by app.ir_checklist (org-scoped via
//      RLS). Status is advanced with an inline Server Action -- no client island.
//
// Server component; lives in (app) so it inherits the sidebar/topbar layout.
// Seed the rows once with supabase/migrations/*_ir_checklist.sql, then reload.

import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { cn } from '@/lib/utils';

export const dynamic = 'force-dynamic';

type Status = 'not_started' | 'in_progress' | 'ready' | 'private';

type Row = {
  id: string;
  section: string;
  item_key: string;
  label: string;
  detail: string | null;
  status: Status;
  sort_order: number;
};

const STATUS_META: Record<Status, { label: string; dot: string; badge: string }> = {
  ready:       { label: 'Ready',       dot: 'bg-emerald-500', badge: 'bg-emerald-100 text-emerald-700' },
  in_progress: { label: 'In progress', dot: 'bg-amber-500',   badge: 'bg-amber-100 text-amber-700' },
  not_started: { label: 'Not started', dot: 'bg-zinc-400',    badge: 'bg-zinc-100 text-zinc-600' },
  private:     { label: 'Private',     dot: 'bg-rose-500',     badge: 'bg-rose-100 text-rose-700' },
};

// Advance not_started -> in_progress -> ready -> not_started. 'private' is fixed.
const NEXT: Record<Status, Status> = {
  not_started: 'in_progress',
  in_progress: 'ready',
  ready: 'not_started',
  private: 'private',
};

// Google Drive data-room folders. Uploads happen in Drive; sign in as the
// data-room owner account to view. IDs are stable for this org.
const DRIVE = 'https://drive.google.com/drive/folders/';
const FOLDERS: ReadonlyArray<{ name: string; id: string }> = [
  { name: 'IR Data Room (top)',   id: '1xIgu2Cdkf5kKXYeRn9Vy50l6QHLUQ3Zj' },
  { name: '00 · Pitch deck',      id: '1UqHcdR2rytFk6ML-25iJA-j0ddlR1p0A' },
  { name: '01 · One-pager',       id: '1xWxiR0qxH4Qd6J1ikxSWT4f0bwFK9q51' },
  { name: '02 · Data room',       id: '1EZOTpzKrLeBkXY4Z01ZqbVyveBeZe2pf' },
  { name: '03 · Investor targets', id: '1URF8eVrOiotvXqnOXQTM1nK2YXxCxEsb' },
  { name: '04 · Outreach',        id: '1yv2mk5CbGGh4g9GWRiEk4xeBydSk21CU' },
  { name: '05 · Archive',         id: '119EJzgHVe2fcWbmvlZzmYzu5wGa45pRQ' },
];

async function advanceStatus(formData: FormData) {
  'use server';
  const item_key = String(formData.get('item_key') ?? '');
  const status = String(formData.get('status') ?? '');
  if (!item_key || !status) return;
  const supabase = await createSupabaseServerClient();
  await supabase
    .schema('app')
    .from('ir_checklist' as never)
    .update({ status, updated_at: new Date().toISOString() } as never)
    .eq('item_key' as never, item_key);
  revalidatePath('/ir');
}

export default async function IrPage() {
  const supabase = await createSupabaseServerClient();
  const { data, error } = await supabase
    .schema('app')
    .from('ir_checklist' as never)
    .select('id, section, item_key, label, detail, status, sort_order')
    .order('sort_order', { ascending: true });

  const rows = (data ?? []) as unknown as Row[];

  const tracked = rows.filter((r) => r.status !== 'private');
  const readyCount = tracked.filter((r) => r.status === 'ready').length;
  const pct = tracked.length ? Math.round((readyCount / tracked.length) * 100) : 0;

  // Group by section, preserving first-seen (sort_order) order.
  const sectionOrder: string[] = [];
  const bySection: Record<string, Row[]> = {};
  for (const r of rows) {
    if (!bySection[r.section]) {
      bySection[r.section] = [];
      sectionOrder.push(r.section);
    }
    bySection[r.section]!.push(r);
  }

  return (
    <div className="mx-auto max-w-5xl space-y-6 p-6">
      <header className="space-y-1">
        <h1 className="text-xl font-semibold">IR · Fundraise</h1>
        <p className="text-sm text-muted-foreground">
          Seed round — $1M for 5% · $20M pre-money. First meeting: Jul 8, 2026 · Andrew Haughian (Pangaea Ventures).
        </p>
      </header>

      {/* Readiness */}
      <div className="rounded-lg border bg-card p-4">
        <div className="mb-2 flex items-center justify-between">
          <span className="text-sm font-medium">Readiness</span>
          <span className="tabular-nums text-sm text-muted-foreground">
            {readyCount}/{tracked.length} ready · {pct}%
          </span>
        </div>
        <div className="h-2 w-full overflow-hidden rounded-full bg-muted">
          <div className="h-full rounded-full bg-emerald-500" style={{ width: pct + '%' }} />
        </div>
      </div>

      {/* Data-room folders */}
      <section className="space-y-2">
        <h2 className="text-sm font-semibold">Data-room folders (Google Drive)</h2>
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
          {FOLDERS.map((f) => (
            <a
              key={f.id}
              href={DRIVE + f.id}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-md border px-3 py-2 text-sm transition-colors hover:bg-accent hover:text-accent-foreground"
            >
              {f.name} ↗
            </a>
          ))}
        </div>
        <p className="text-xs text-muted-foreground">
          Uploads happen in Drive. Sign in as the data-room owner account to view.
        </p>
      </section>

      {/* Checklist */}
      {error && (
        <p className="text-sm text-rose-600">
          Could not load the checklist. Run the ir_checklist migration in Supabase, then reload.
        </p>
      )}

      {sectionOrder.map((section) => (
        <section key={section} className="space-y-2">
          <h2 className="text-sm font-semibold">{section}</h2>
          <ul className="divide-y rounded-lg border bg-card">
            {bySection[section]!.map((r) => {
              const meta = STATUS_META[r.status];
              return (
                <li key={r.item_key} className="flex items-start gap-3 p-3">
                  <span className={cn('mt-1 h-2.5 w-2.5 shrink-0 rounded-full', meta.dot)} aria-hidden />
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-medium">{r.label}</div>
                    {r.detail && <div className="text-xs text-muted-foreground">{r.detail}</div>}
                  </div>
                  <span
                    className={cn(
                      'shrink-0 rounded-full px-2 py-0.5 text-[11px] font-medium',
                      meta.badge,
                    )}
                  >
                    {meta.label}
                  </span>
                  {r.status !== 'private' && (
                    <form action={advanceStatus} className="shrink-0">
                      <input type="hidden" name="item_key" value={r.item_key} />
                      <input type="hidden" name="status" value={NEXT[r.status]} />
                      <button
                        type="submit"
                        title="Advance status"
                        className="rounded-md border px-2 py-0.5 text-xs text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
                      >
                        ✓
                      </button>
                    </form>
                  )}
                </li>
              );
            })}
          </ul>
        </section>
      ))}
    </div>
  );
}
