// src/app/(app)/campaigns/[id]/dataroom/page.tsx
//
// A campaign's Data Room: its Drive folders + prep checklist.
// Reached from the "Data Room" button on the campaign detail header.
// Tables: app.campaign_folders / app.campaign_materials (scoped to the campaign).

import Link from 'next/link';
import { notFound } from 'next/navigation';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { cn } from '@/lib/utils';

export const dynamic = 'force-dynamic';

type Status = 'not_started' | 'in_progress' | 'ready' | 'private';

type Campaign = { id: string; name: string; description: string | null };
type Folder = { id: string; name: string; drive_folder_id: string; sort_order: number };
type Item = {
  id: string; campaign_id: string; section: string; item_key: string;
  label: string; detail: string | null; status: Status; sort_order: number;
};

const DRIVE = 'https://drive.google.com/drive/folders/';

const STATUS_META: Record<Status, { label: string; dot: string; badge: string }> = {
  ready:       { label: 'Ready',       dot: 'bg-emerald-500', badge: 'bg-emerald-100 text-emerald-700' },
  in_progress: { label: 'In progress', dot: 'bg-amber-500',   badge: 'bg-amber-100 text-amber-700' },
  not_started: { label: 'Not started', dot: 'bg-zinc-400',    badge: 'bg-zinc-100 text-zinc-600' },
  private:     { label: 'Private',     dot: 'bg-rose-500',     badge: 'bg-rose-100 text-rose-700' },
};
const NEXT: Record<Status, Status> = {
  not_started: 'in_progress', in_progress: 'ready', ready: 'not_started', private: 'private',
};

async function advanceStatus(formData: FormData) {
  'use server';
  const campaign_id = String(formData.get('campaign_id') ?? '');
  const item_key = String(formData.get('item_key') ?? '');
  const status = String(formData.get('status') ?? '');
  if (!campaign_id || !item_key || !status) return;
  const supabase = await createSupabaseServerClient();
  await supabase
    .schema('app')
    .from('campaign_materials' as never)
    .update({ status, updated_at: new Date().toISOString() } as never)
    .eq('campaign_id' as never, campaign_id)
    .eq('item_key' as never, item_key);
  revalidatePath(`/campaigns/${campaign_id}/dataroom`);
}

export default async function CampaignDataRoomPage({ params }: { params: { id: string } }) {
  const supabase = await createSupabaseServerClient();

  const { data: campaignRow } = await supabase
    .schema('app')
    .from('campaigns' as never)
    .select('id, name, description')
    .eq('id' as never, params.id)
    .maybeSingle();

  const campaign = (campaignRow ?? null) as unknown as Campaign | null;
  if (!campaign) notFound();

  const [{ data: folderData }, { data: itemData }] = await Promise.all([
    supabase.schema('app').from('campaign_folders' as never)
      .select('id, name, drive_folder_id, sort_order')
      .eq('campaign_id' as never, params.id)
      .order('sort_order', { ascending: true }),
    supabase.schema('app').from('campaign_materials' as never)
      .select('id, campaign_id, section, item_key, label, detail, status, sort_order')
      .eq('campaign_id' as never, params.id)
      .order('sort_order', { ascending: true }),
  ]);

  const folders = (folderData ?? []) as unknown as Folder[];
  const items = (itemData ?? []) as unknown as Item[];

  const tracked = items.filter((i) => i.status !== 'private');
  const readyCount = tracked.filter((i) => i.status === 'ready').length;
  const pct = tracked.length ? Math.round((readyCount / tracked.length) * 100) : 0;

  const sectionOrder: string[] = [];
  const bySection: Record<string, Item[]> = {};
  for (const it of items) {
    if (!bySection[it.section]) { bySection[it.section] = []; sectionOrder.push(it.section); }
    bySection[it.section]!.push(it);
  }

  return (
    <div className="mx-auto max-w-5xl space-y-6 p-6">
      <div>
        <Link href={`/campaigns/${params.id}`} className="text-sm text-muted-foreground hover:text-foreground">
          ← {campaign.name}
        </Link>
      </div>

      <header className="space-y-1">
        <h1 className="text-xl font-semibold">Data Room</h1>
        {campaign.description && <p className="text-sm text-muted-foreground">{campaign.description}</p>}
      </header>

      {tracked.length > 0 && (
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
      )}

      <section className="space-y-2">
        <h2 className="text-sm font-semibold">Folders (Google Drive)</h2>
        {folders.length === 0 ? (
          <p className="text-sm text-muted-foreground">
            No folders yet. Add rows to app.campaign_folders for this campaign.
          </p>
        ) : (
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
            {folders.map((f) => (
              <a
                key={f.id}
                href={DRIVE + f.drive_folder_id}
                target="_blank"
                rel="noopener noreferrer"
                className="rounded-md border px-3 py-2 text-sm transition-colors hover:bg-accent hover:text-accent-foreground"
              >
                {f.name} ↗
              </a>
            ))}
          </div>
        )}
        <p className="text-xs text-muted-foreground">
          Uploads happen in Drive. Sign in as the data-room owner account to view.
        </p>
      </section>

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
                  <span className={cn('shrink-0 rounded-full px-2 py-0.5 text-[11px] font-medium', meta.badge)}>
                    {meta.label}
                  </span>
                  {r.status !== 'private' && (
                    <form action={advanceStatus} className="shrink-0">
                      <input type="hidden" name="campaign_id" value={r.campaign_id} />
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
