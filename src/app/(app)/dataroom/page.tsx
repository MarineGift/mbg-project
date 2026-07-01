// src/app/(app)/dataroom/page.tsx
//
// Data Rooms - list view (like Campaigns). Each row is one deal/effort with its
// own Drive folders + prep checklist. Select one to open /dataroom/[id].
// Tables: app.data_rooms / app.data_room_folders / app.data_room_items.

import Link from 'next/link';
import { revalidatePath } from 'next/cache';
import { createSupabaseServerClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

type Room = {
  id: string;
  name: string;
  subtitle: string | null;
  status: string;
  sort_order: number;
};
type ItemLite = { data_room_id: string; status: string };

async function createRoom(formData: FormData) {
  'use server';
  const name = String(formData.get('name') ?? '').trim();
  if (!name) return;
  const subtitle = String(formData.get('subtitle') ?? '').trim() || null;
  const supabase = await createSupabaseServerClient();
  await supabase
    .schema('app')
    .from('data_rooms' as never)
    .insert({ name, subtitle, status: 'active', sort_order: 100 } as never);
  revalidatePath('/dataroom');
}

export default async function DataRoomsPage() {
  const supabase = await createSupabaseServerClient();

  const [{ data: roomData }, { data: itemData }] = await Promise.all([
    supabase
      .schema('app')
      .from('data_rooms' as never)
      .select('id, name, subtitle, status, sort_order')
      .order('sort_order', { ascending: true }),
    supabase
      .schema('app')
      .from('data_room_items' as never)
      .select('data_room_id, status'),
  ]);

  const rooms = (roomData ?? []) as unknown as Room[];
  const items = (itemData ?? []) as unknown as ItemLite[];

  // readiness per room (ready / tracked, excluding 'private')
  const agg = new Map<string, { ready: number; tracked: number }>();
  for (const it of items) {
    if (it.status === 'private') continue;
    const a = agg.get(it.data_room_id) ?? { ready: 0, tracked: 0 };
    a.tracked += 1;
    if (it.status === 'ready') a.ready += 1;
    agg.set(it.data_room_id, a);
  }

  return (
    <div className="mx-auto max-w-4xl space-y-6 p-6">
      <header className="space-y-1">
        <h1 className="text-xl font-semibold">Data Rooms</h1>
        <p className="text-sm text-muted-foreground">
          One room per deal or effort - Drive folders + a prep checklist. Select one to open it.
        </p>
      </header>

      {rooms.length === 0 ? (
        <p className="text-sm text-muted-foreground">
          No data rooms yet. Run the data_rooms migration in Supabase, or create one below.
        </p>
      ) : (
        <ul className="space-y-2">
          {rooms.map((r) => {
            const a = agg.get(r.id) ?? { ready: 0, tracked: 0 };
            const pct = a.tracked ? Math.round((a.ready / a.tracked) * 100) : 0;
            return (
              <li key={r.id}>
                <Link
                  href={`/dataroom/${r.id}`}
                  className="block rounded-lg border bg-card p-4 transition-colors hover:bg-accent hover:text-accent-foreground"
                >
                  <div className="flex items-center justify-between gap-3">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-medium">{r.name}</span>
                        {r.status === 'archived' && (
                          <span className="rounded-full bg-zinc-100 px-2 py-0.5 text-[11px] text-zinc-600">
                            archived
                          </span>
                        )}
                      </div>
                      {r.subtitle && (
                        <div className="truncate text-sm text-muted-foreground">{r.subtitle}</div>
                      )}
                    </div>
                    <div className="shrink-0 text-right">
                      <div className="tabular-nums text-sm text-muted-foreground">
                        {a.ready}/{a.tracked} ready
                      </div>
                      <div className="mt-1 h-1.5 w-28 overflow-hidden rounded-full bg-muted">
                        <div className="h-full rounded-full bg-emerald-500" style={{ width: pct + '%' }} />
                      </div>
                    </div>
                  </div>
                </Link>
              </li>
            );
          })}
        </ul>
      )}

      {/* create */}
      <form action={createRoom} className="rounded-lg border bg-card p-4">
        <p className="mb-2 text-sm font-medium">New data room</p>
        <div className="flex flex-col gap-2 sm:flex-row">
          <input
            name="name"
            required
            placeholder="Name (e.g. Series A - Acme Capital)"
            className="flex-1 rounded-md border bg-background px-3 py-2 text-sm"
          />
          <input
            name="subtitle"
            placeholder="Subtitle (optional)"
            className="flex-1 rounded-md border bg-background px-3 py-2 text-sm"
          />
          <button
            type="submit"
            className="rounded-md border bg-foreground px-4 py-2 text-sm font-medium text-background transition-opacity hover:opacity-90"
          >
            Create
          </button>
        </div>
        <p className="mt-2 text-xs text-muted-foreground">
          New rooms start empty. Add folders / checklist items in app.data_room_folders and
          app.data_room_items (copy the seed room as a template).
        </p>
      </form>
    </div>
  );
}
