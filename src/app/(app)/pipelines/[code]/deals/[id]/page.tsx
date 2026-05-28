// src/app/(app)/pipelines/[code]/deals/[id]/page.tsx
// Deal detail (industry-standard layout) -- WIRED v5.
//
// v5 change: Tasks tab now uses <TasksTabClient> (client wrapper) which
//            adds an "Add task" button + modal in the tab header. Same
//            pattern as ActivityTabClient.
//
// All other tabs (Backers) and the right rail stay server-rendered.

import Link from 'next/link';
import { notFound } from 'next/navigation';
import {
  ChevronLeft,
  ExternalLink,
  FileText,
} from 'lucide-react';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { ActivityTabClient } from './log-activity-modal';
import { TasksTabClient } from './add-task-modal';

interface Props {
  params: { code: string; id: string };
  searchParams: { tab?: string | string[] };
}

const TAB_LABELS = {
  activity: 'Activity',
  tasks: 'Tasks',
  backers: 'Backers',
} as const;
type TabId = keyof typeof TAB_LABELS;

// ============================================================
// Formatters
// ============================================================

function fmtMoney(amount: number | null | undefined, currency: string | null | undefined): string {
  if (amount == null) return '\u2014';
  const cur = currency || 'USD';
  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: cur,
      maximumFractionDigits: 0,
    }).format(amount);
  } catch {
    return amount.toLocaleString() + ' ' + cur;
  }
}

function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '\u2014';
  const d = new Date(iso);
  if (isNaN(d.getTime())) return '\u2014';
  return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}

function contactDisplayName(c: any): string {
  if (!c) return '';
  if (c.full_name) return c.full_name;
  if (c.given_name && c.family_name) return c.given_name + ' ' + c.family_name;
  return c.given_name || c.family_name || '';
}

// ============================================================
// Page (server component)
// ============================================================

export default async function DealDetailPage({ params, searchParams }: Props) {
  const supabase = await createSupabaseServerClient();

  const { data: dealRow } = await supabase
    .schema('app')
    .from('deals' as never)
    .select(
      'id, deal_name, status, value_amount, value_currency, ' +
      'expected_close_date, probability_pct, priority, notes, ' +
      'source, last_activity_at, created_at, ' +
      'pipeline:pipelines(id, code, name), ' +
      'stage:stages(id, code, name), ' +
      'party:parties(id, party_name, country_code, website)'
    )
    .eq('id', params.id)
    .is('deleted_at', null)
    .maybeSingle();

  if (!dealRow) notFound();
  const d = dealRow as any;

  const isCrowdfunding = d.pipeline?.code === 'crowdfunding';
  const availableTabs: TabId[] = isCrowdfunding
    ? ['activity', 'tasks', 'backers']
    : ['activity', 'tasks'];
  const rawTab = Array.isArray(searchParams.tab) ? searchParams.tab[0] : searchParams.tab;
  const activeTab: TabId =
    rawTab && (availableTabs as string[]).includes(rawTab) ? (rawTab as TabId) : 'activity';

  let engagements: any[] = [];
  let engagementTypes: any[] = [];
  let tasks: any[] = [];
  let checklists: any[] = [];
  let backers: any[] = [];
  let rewardTiers: any[] = [];

  if (activeTab === 'activity') {
    const [{ data: engData }, { data: typeData }] = await Promise.all([
      supabase
        .schema('app')
        .from('engagements' as never)
        .select('*, engagement_type:engagement_types!engagement_type_id(*)')
        .eq('deal_id', params.id)
        .is('deleted_at', null)
        .order('occurred_at', { ascending: false })
        .limit(50),
      supabase
        .schema('app')
        .from('engagement_types' as never)
        .select('*')
        .order('sort_order', { ascending: true }),
    ]);
    engagements = (engData ?? []) as any[];
    engagementTypes = (typeData ?? []) as any[];
  }

  if (activeTab === 'tasks') {
    const { data: ts } = await supabase
      .schema('app')
      .from('tasks' as never)
      .select('*')
      .eq('deal_id', params.id)
      .is('deleted_at', null)
      .order('due_at', { ascending: true, nullsFirst: false });
    tasks = (ts ?? []) as any[];

    const checklistIds = Array.from(
      new Set(tasks.map((t: any) => t.checklist_id).filter(Boolean))
    ) as string[];
    if (checklistIds.length > 0) {
      const { data: cs } = await supabase
        .schema('app')
        .from('deal_checklists' as never)
        .select('*')
        .in('id', checklistIds);
      checklists = (cs ?? []) as any[];
    }
  }

  if (activeTab === 'backers') {
    const [{ data: bs }, { data: rts }] = await Promise.all([
      supabase
        .schema('app')
        .from('deal_backers' as never)
        .select('*, contact:contacts(id, full_name, given_name, family_name)')
        .eq('deal_id', params.id)
        .order('pledged_at', { ascending: false }),
      supabase
        .schema('app')
        .from('reward_tiers' as never)
        .select('*')
        .eq('deal_id', params.id)
        .order('pledge_from', { ascending: true }),
    ]);
    backers = (bs ?? []) as any[];
    rewardTiers = (rts ?? []) as any[];
  }

  return (
    <div className="flex h-full flex-col">
      {/* Header */}
      <div className="border-b bg-background px-6 py-4">
        <Link
          href={'/pipelines/' + params.code}
          className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground"
        >
          <ChevronLeft className="h-3 w-3" />
          {d.pipeline?.name ?? 'Pipeline'}
        </Link>

        <h1 className="mt-1 text-xl font-semibold text-foreground">{d.deal_name}</h1>

        <div className="mt-2 flex flex-wrap items-center gap-x-1 gap-y-1 text-xs text-muted-foreground">
          {d.party && (
            <span>
              {d.party.party_name}
              {d.party.country_code && (
                <span className="ml-1 opacity-60"> {'\u00b7'} {d.party.country_code}</span>
              )}
            </span>
          )}
          {d.stage && (
            <>
              <span className="mx-1 opacity-40">{'\u00b7'}</span>
              <span>
                Stage: <span className="font-medium text-foreground">{d.stage.name}</span>
              </span>
            </>
          )}
          {d.value_amount != null && (
            <>
              <span className="mx-1 opacity-40">{'\u00b7'}</span>
              <span className="font-medium text-foreground tabular-nums">
                {fmtMoney(d.value_amount, d.value_currency)}
              </span>
            </>
          )}
          {d.probability_pct != null && (
            <>
              <span className="mx-1 opacity-40">{'\u00b7'}</span>
              <span>{d.probability_pct}%</span>
            </>
          )}
        </div>
      </div>

      {/* Tab strip */}
      <div className="flex items-center gap-1 border-b bg-background px-6">
        {availableTabs.map((tabId) => {
          const active = activeTab === tabId;
          return (
            <Link
              key={tabId}
              href={'/pipelines/' + params.code + '/deals/' + params.id + '?tab=' + tabId}
              className={
                'border-b-2 px-3 py-2 text-sm transition ' +
                (active
                  ? 'border-foreground text-foreground font-medium'
                  : 'border-transparent text-muted-foreground hover:text-foreground')
              }
            >
              {TAB_LABELS[tabId]}
            </Link>
          );
        })}
      </div>

      {/* Two-column body */}
      <div className="flex flex-1 overflow-hidden">
        <div className="flex-1 overflow-y-auto p-6">
          {activeTab === 'activity' && (
            <ActivityTabClient
              pipelineCode={params.code}
              dealId={params.id}
              engagements={engagements}
              engagementTypes={engagementTypes}
            />
          )}
          {activeTab === 'tasks' && (
            <TasksTabClient
              pipelineCode={params.code}
              dealId={params.id}
              tasks={tasks}
              checklists={checklists}
            />
          )}
          {activeTab === 'backers' && (
            <BackersPanel
              backers={backers}
              rewardTiers={rewardTiers}
              dealCurrency={d.value_currency}
              dealValue={d.value_amount}
            />
          )}
        </div>

        <aside className="w-80 shrink-0 space-y-3 overflow-y-auto border-l bg-muted/20 p-4">
          <PropertyCard deal={d} />
          {d.party && <CompanyCard party={d.party} />}
          {d.notes && <NotesCard notes={d.notes} />}
        </aside>
      </div>
    </div>
  );
}

// ============================================================
// Backers panel (unchanged)
// ============================================================

function BackersPanel({
  backers,
  rewardTiers,
  dealCurrency,
  dealValue,
}: {
  backers: any[];
  rewardTiers: any[];
  dealCurrency: string;
  dealValue: number | null;
}) {
  const pledgedByCurrency: Record<string, number> = {};
  for (const b of backers) {
    const cur = b.pledge_currency || dealCurrency || 'USD';
    pledgedByCurrency[cur] = (pledgedByCurrency[cur] ?? 0) + Number(b.pledge_amount ?? 0);
  }
  const primaryCurrency = dealCurrency || Object.keys(pledgedByCurrency)[0] || 'USD';
  const primaryPledged = pledgedByCurrency[primaryCurrency] ?? 0;
  const goal = dealValue ?? 0;
  const pctFunded = goal > 0 ? Math.round((primaryPledged / goal) * 100) : 0;

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-3 gap-3">
        <SummaryCard label="Backers" value={backers.length.toString()} />
        <SummaryCard
          label="Pledged"
          value={fmtMoney(primaryPledged, primaryCurrency)}
          sub={
            Object.keys(pledgedByCurrency).length > 1
              ? '+' + (Object.keys(pledgedByCurrency).length - 1) + ' more currency'
              : undefined
          }
        />
        <SummaryCard
          label="Goal"
          value={fmtMoney(goal, primaryCurrency)}
          sub={pctFunded + '% funded'}
        />
      </div>

      {rewardTiers.length > 0 && (
        <div className="rounded-lg border bg-card">
          <div className="border-b px-4 py-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">
            Reward tiers
          </div>
          <table className="w-full text-sm">
            <thead className="bg-muted/30 text-xs text-muted-foreground">
              <tr>
                <th className="px-4 py-2 text-left font-medium">Name</th>
                <th className="px-4 py-2 text-right font-medium">Pledge from</th>
                <th className="px-4 py-2 text-right font-medium">Claimed</th>
                <th className="px-4 py-2 text-right font-medium">Limit</th>
                <th className="px-4 py-2 text-left font-medium">Est. delivery</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {rewardTiers.map((rt: any) => (
                <tr key={rt.id}>
                  <td className="px-4 py-2 font-medium">
                    {rt.tier_name || rt.name || '\u2014'}
                  </td>
                  <td className="px-4 py-2 text-right tabular-nums">
                    {fmtMoney(rt.pledge_from, rt.currency || dealCurrency)}
                  </td>
                  <td className="px-4 py-2 text-right tabular-nums">{rt.claimed_count ?? 0}</td>
                  <td className="px-4 py-2 text-right tabular-nums">
                    {rt.limit_qty != null ? rt.limit_qty : '\u221e'}
                  </td>
                  <td className="px-4 py-2 text-muted-foreground">
                    {rt.estimated_delivery ? fmtDate(rt.estimated_delivery) : '\u2014'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="rounded-lg border bg-card">
        <div className="border-b px-4 py-2 text-xs font-medium uppercase tracking-wider text-muted-foreground">
          Backers
        </div>
        {backers.length === 0 ? (
          <div className="px-4 py-6 text-center text-xs text-muted-foreground/70">
            No backers yet
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-muted/30 text-xs text-muted-foreground">
              <tr>
                <th className="px-4 py-2 text-left font-medium">Name</th>
                <th className="px-4 py-2 text-right font-medium">Pledge</th>
                <th className="px-4 py-2 text-left font-medium">Country</th>
                <th className="px-4 py-2 text-left font-medium">Status</th>
                <th className="px-4 py-2 text-left font-medium">Pledged at</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {backers.map((b: any) => {
                const cName = contactDisplayName(b.contact);
                const shown = b.is_anonymous
                  ? null
                  : cName || b.display_name || 'Backer';
                return (
                  <tr key={b.id}>
                    <td className="px-4 py-2">
                      {b.is_anonymous ? (
                        <span className="italic text-muted-foreground">Anonymous</span>
                      ) : b.contact_id ? (
                        <Link
                          href={'/contacts/' + b.contact_id}
                          className="text-foreground hover:underline"
                        >
                          {shown}
                        </Link>
                      ) : (
                        <span className="text-foreground">{shown}</span>
                      )}
                    </td>
                    <td className="px-4 py-2 text-right tabular-nums">
                      {fmtMoney(b.pledge_amount, b.pledge_currency || dealCurrency)}
                    </td>
                    <td className="px-4 py-2 text-muted-foreground">{b.country_code || '\u2014'}</td>
                    <td className="px-4 py-2">
                      <StatusBadge status={b.reward_status || b.status || 'pledged'} />
                    </td>
                    <td className="px-4 py-2 text-xs text-muted-foreground">
                      {b.pledged_at ? fmtDate(b.pledged_at) : '\u2014'}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colorMap: Record<string, string> = {
    pledged: 'bg-blue-50 text-blue-700 ring-blue-200',
    collected: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
    refunded: 'bg-zinc-50 text-zinc-700 ring-zinc-200',
    cancelled: 'bg-zinc-50 text-zinc-700 ring-zinc-200',
    failed: 'bg-rose-50 text-rose-700 ring-rose-200',
  };
  const cls = colorMap[status] || 'bg-zinc-50 text-zinc-700 ring-zinc-200';
  return (
    <span
      className={
        'inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium capitalize ring-1 ring-inset ' +
        cls
      }
    >
      {status}
    </span>
  );
}

function SummaryCard({ label, value, sub }: { label: string; value: string; sub?: string }) {
  return (
    <div className="rounded-lg border bg-card px-3 py-2">
      <div className="text-[10px] uppercase tracking-wider text-muted-foreground">{label}</div>
      <div className="mt-1 text-lg font-semibold text-foreground tabular-nums">{value}</div>
      {sub && <div className="mt-0.5 text-[10px] text-muted-foreground">{sub}</div>}
    </div>
  );
}

// ============================================================
// Right rail
// ============================================================

function PropertyCard({ deal }: { deal: any }) {
  const rows: Array<[string, React.ReactNode]> = [
    ['Stage', deal.stage?.name ?? '\u2014'],
    ['Value', fmtMoney(deal.value_amount, deal.value_currency)],
    ['Probability', deal.probability_pct != null ? deal.probability_pct + '%' : '\u2014'],
    ['Close date', fmtDate(deal.expected_close_date)],
    ['Priority', deal.priority ? <span className="capitalize">{deal.priority}</span> : '\u2014'],
    ['Status', deal.status ? <span className="capitalize">{deal.status}</span> : '\u2014'],
    ['Source', deal.source ?? '\u2014'],
  ];
  return (
    <div className="rounded-lg border bg-card">
      <div className="border-b px-3 py-2 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
        About this deal
      </div>
      <dl className="divide-y text-xs">
        {rows.map(([label, val]) => (
          <div key={label} className="flex items-center justify-between gap-2 px-3 py-1.5">
            <dt className="text-muted-foreground">{label}</dt>
            <dd className="text-right text-foreground tabular-nums">{val}</dd>
          </div>
        ))}
      </dl>
    </div>
  );
}

function CompanyCard({ party }: { party: any }) {
  return (
    <div className="rounded-lg border bg-card">
      <div className="border-b px-3 py-2 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
        Company
      </div>
      <div className="space-y-1 px-3 py-2 text-xs">
        <div className="text-sm font-medium text-foreground">{party.party_name}</div>
        {party.country_code && (
          <div className="text-muted-foreground">{party.country_code}</div>
        )}
        {party.website && (
          <a
            href={party.website.startsWith('http') ? party.website : 'https://' + party.website}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-foreground hover:underline"
          >
            {party.website.replace(/^https?:\/\//, '')}
            <ExternalLink className="h-3 w-3" />
          </a>
        )}
      </div>
    </div>
  );
}

function NotesCard({ notes }: { notes: string }) {
  return (
    <div className="rounded-lg border bg-card">
      <div className="flex items-center gap-1.5 border-b px-3 py-2 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
        <FileText className="h-3 w-3" />
        Notes
      </div>
      <div className="whitespace-pre-wrap px-3 py-2 text-xs text-foreground">{notes}</div>
    </div>
  );
}
