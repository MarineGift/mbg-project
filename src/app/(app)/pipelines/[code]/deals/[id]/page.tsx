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
import { listEmailTemplates } from '@/lib/queries/email-templates';
import { ActivityTabClient } from './log-activity-modal';
import { TasksTabClient } from './add-task-modal';
import { ChecklistTabClient } from './checklist-tab';

interface Props {
  params: { code: string; id: string };
  searchParams: { tab?: string | string[] };
}

const TAB_LABELS = {
  activity: 'Activity',
  tasks: 'Tasks',
  checklist: 'Checklist',
  history: 'History',
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

// --- deal_parties helpers (M:N companies) ---

const ROLE_ORDER: Record<string, number> = {
  lead: 0, co_investor: 1, participant: 2, advisor: 3, primary: 4,
};

function roleLabel(role: string): string {
  switch (role) {
    case 'lead': return 'Lead';
    case 'co_investor': return 'Co-investor';
    case 'participant': return 'Participant';
    case 'advisor': return 'Advisor';
    case 'primary': return 'Primary';
    default: return role;
  }
}

function sortDealParties(dps: any[]): any[] {
  return [...dps].sort(
    (a, b) =>
      (ROLE_ORDER[a.role] ?? 9) - (ROLE_ORDER[b.role] ?? 9) ||
      (a.parties?.party_name ?? '').localeCompare(b.parties?.party_name ?? '')
  );
}

function toNum(v: any): number | null {
  if (v == null) return null;
  const n = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? n : null;
}

function sumCommitments(dps: any[]): Record<string, number> {
  const out: Record<string, number> = {};
  for (const p of dps) {
    const n = toNum(p.commitment_amount);
    if (n != null) {
      const cur = p.currency || 'USD';
      out[cur] = (out[cur] ?? 0) + n;
    }
  }
  return out;
}

function fmtTotals(totals: Record<string, number>): string {
  const e = Object.entries(totals);
  if (e.length === 0) return '\u2014';
  return e.map(([cur, sum]) => fmtMoney(sum, cur)).join(' \u00b7 ');
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
      'deal_parties ( id, party_id, role, commitment_amount, currency, ' +
      '  parties ( id, party_name, country_code, website ) )'
    )
    .eq('id', params.id)
    .is('deleted_at', null)
    .maybeSingle();

  if (!dealRow) notFound();
  const d = dealRow as any;

  const dpSorted = sortDealParties((d.deal_parties ?? []) as any[]);
  const leadParty = dpSorted[0] ?? null;
  const commitmentTotals = sumCommitments(dpSorted);

  // Compose recipient context: the lead party's primary (or most-recent) contact.
  // Drives the "Send Email" dialog on the Activity tab.
  let composeContactId: string | null = null;
  let composeContactName: string | null = null;
  let composeContactEmail: string | null = null;
  if (leadParty?.party_id) {
    const { data: pc } = await supabase
      .schema('app')
      .from('contacts' as never)
      .select('id, full_name, given_name, family_name, email, is_primary, updated_at')
      .eq('party_id', leadParty.party_id)
      .is('deleted_at', null)
      .not('email', 'is', null)
      .order('is_primary', { ascending: false })
      .order('updated_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    const c = pc as
      | { id: string; full_name: string | null; given_name: string | null; family_name: string | null; email: string | null }
      | null;
    if (c) {
      composeContactId = c.id;
      composeContactName =
        c.full_name ?? ([c.given_name, c.family_name].filter(Boolean).join(' ') || null);
      composeContactEmail = c.email ?? null;
    }
  }
  // Templates for the Template tab of the compose dialog.
  const composeTemplates = await listEmailTemplates();

  const isCrowdfunding = d.pipeline?.code === 'crowdfunding';
  const availableTabs: TabId[] = isCrowdfunding
    ? ['activity', 'tasks', 'checklist', 'history', 'backers']
    : ['activity', 'tasks', 'checklist', 'history'];
  const rawTab = Array.isArray(searchParams.tab) ? searchParams.tab[0] : searchParams.tab;
  const activeTab: TabId =
    rawTab && (availableTabs as string[]).includes(rawTab) ? (rawTab as TabId) : 'activity';

  // Stage history (for the History tab). Stage names are resolved from the
  // deal's pipeline stages, so we don't depend on multi-FK embeds.
  const { data: pipeStages } = await supabase
    .schema('app')
    .from('stages' as never)
    .select('id, name, sort_order')
    .eq('pipeline_id', d.pipeline?.id)
    .order('sort_order', { ascending: true });
  const stageNameById = new Map<string, string>(
    ((pipeStages ?? []) as Array<{ id: string; name: string }>).map((st) => [st.id, st.name])
  );

  // Stage position within the pipeline (for the header progress bar). Reuses
  // the already-fetched pipeStages; no extra query.
  const orderedStages = (pipeStages ?? []) as Array<{ id: string; name: string }>;
  const stageCount = orderedStages.length;
  const stageIndex = d.stage
    ? orderedStages.findIndex(
        (s) => s.id === (d.stage as { id?: string }).id || s.name === d.stage!.name,
      )
    : -1;
  const stagePos = stageIndex >= 0 ? stageIndex + 1 : null;
  const { data: stageHistory } = await supabase
    .schema('app')
    .from('deal_stage_history' as never)
    .select('id, changed_at, from_stage_id, to_stage_id')
    .eq('deal_id', params.id)
    .order('changed_at', { ascending: false });
  const stageHistoryRows = (stageHistory ?? []) as Array<{
    id: string; changed_at: string; from_stage_id: string | null; to_stage_id: string;
  }>;

  let engagements: any[] = [];
  let engagementTypes: any[] = [];
  let tasks: any[] = [];
  let checklists: any[] = [];
  let backers: any[] = [];
  let rewardTiers: any[] = [];
  let activityTasks: Array<{ id: string; title: string; checklist_id?: string | null }> = [];

  if (activeTab === 'activity') {
    const [{ data: engData }, { data: typeData }, { data: taskOpts }] = await Promise.all([
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
      supabase
        .schema('app')
        .from('tasks' as never)
        .select('id, title, checklist_id')
        .eq('deal_id', params.id)
        .is('deleted_at', null)
        .order('created_at', { ascending: true }),
    ]);
    engagements = (engData ?? []) as any[];
    engagementTypes = (typeData ?? []) as any[];
    activityTasks = (taskOpts ?? []) as Array<{ id: string; title: string; checklist_id?: string | null }>;

    // checklists for the Activity composer's chained Checklist dropdown
    const { data: clOpts } = await supabase
      .schema('app')
      .from('deal_checklists' as never)
      .select('id, title')
      .eq('deal_id', params.id)
      .is('deleted_at', null)
      .order('sort_order', { ascending: true, nullsFirst: true })
      .order('created_at', { ascending: true });
    checklists = (clOpts ?? []) as any[];
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

    // Activity (engagement) count per task -- engagements.task_id, non-deleted.
    // No FK between engagements.task_id and tasks, so skip a PostgREST embed and
    // tally in JS from a flat task_id select (counts distinct rows, not inflated).
    const taskIds = tasks.map((t: any) => t.id).filter(Boolean) as string[];
    if (taskIds.length > 0) {
      const { data: engRows } = await supabase
        .schema('app')
        .from('engagements' as never)
        .select('task_id')
        .in('task_id', taskIds)
        .is('deleted_at', null);
      const counts: Record<string, number> = {};
      for (const e of (engRows ?? []) as any[]) {
        if (e.task_id) counts[e.task_id] = (counts[e.task_id] ?? 0) + 1;
      }
      tasks = tasks.map((t: any) => ({ ...t, _activityCount: counts[t.id] ?? 0 }));
    }

    const checklistIds = Array.from(
      new Set(tasks.map((t: any) => t.checklist_id).filter(Boolean))
    ) as string[];
    if (checklistIds.length > 0) {
      const { data: cs } = await supabase
        .schema('app')
        .from('deal_checklists' as never)
        .select('*')
        .in('id', checklistIds)
        .order('sort_order', { ascending: true, nullsFirst: true })
        .order('created_at', { ascending: true });
      checklists = (cs ?? []) as any[];
    }
  }

  if (activeTab === 'checklist') {
    const { data: cl } = await supabase
      .schema('app')
      .from('deal_checklists' as never)
      .select('*')
      .eq('deal_id', params.id)
      .is('deleted_at', null)
      .order('sort_order', { ascending: true, nullsFirst: true })
      .order('created_at', { ascending: true });
    checklists = (cl ?? []) as any[];
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
          {leadParty && (
            <span>
              {leadParty.parties?.party_name ?? '(unknown)'}
              {leadParty.parties?.country_code && (
                <span className="ml-1 opacity-60"> {'\u00b7'} {leadParty.parties.country_code}</span>
              )}
              {dpSorted.length > 1 && (
                <span className="ml-1 font-medium text-foreground">+{dpSorted.length - 1}</span>
              )}
            </span>
          )}
          {d.stage && (
            <>
              <span className="mx-1 opacity-40">{'\u00b7'}</span>
              <span>
                Stage{stagePos !== null ? ' ' + stagePos + '/' + stageCount : ''}:{' '}
                <span className="font-medium text-foreground">{d.stage.name}</span>
              </span>
            </>
          )}
          {Object.keys(commitmentTotals).length > 0 && (
            <>
              <span className="mx-1 opacity-40">{'\u00b7'}</span>
              <span className="font-medium text-foreground tabular-nums">
                {fmtTotals(commitmentTotals)}
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

        {stagePos !== null && stageCount > 1 && (
          <div className="mt-2 max-w-xs">
            <div className="mb-1 text-[11px] text-muted-foreground tabular-nums">
              Stage {stagePos} of {stageCount}
            </div>
            <div className="h-1.5 w-full overflow-hidden rounded-full bg-muted">
              <div
                className="h-full rounded-full bg-foreground/70 transition-all"
                style={{ width: Math.round((stagePos / stageCount) * 100) + '%' }}
              />
            </div>
          </div>
        )}
      </div>

      {/* Tab strip */}
      <div className="flex items-center gap-1 border-b bg-background px-6">
        {availableTabs.map((tabId) => {
          const active = activeTab === tabId;
          return (
            <Link
              key={tabId}
              href={'/pipelines/' + params.code + '/deals/' + params.id + '?tab=' + tabId}
              aria-current={active ? 'page' : undefined}
              className={
                'relative -mb-px rounded-t-md border px-4 py-2.5 text-sm transition ' +
                (active
                  ? 'border-b-0 border-t-2 border-t-foreground bg-card font-semibold text-foreground'
                  : 'border-transparent font-medium text-muted-foreground hover:bg-muted/60 hover:text-foreground')
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
              tasks={activityTasks}
              checklists={checklists}
              partyId={leadParty?.party_id ?? null}
              contactId={composeContactId}
              contactName={composeContactName}
              contactEmail={composeContactEmail}
              templates={composeTemplates.map((t) => ({
                id: t.id,
                name: t.name,
                category: t.category,
                subject: t.subject,
                body_plain: t.bodyPlain,
                body_html: t.bodyHtml,
                module: t.module,
              }))}
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
          {activeTab === 'checklist' && (
            <ChecklistTabClient
              pipelineCode={params.code}
              dealId={params.id}
              items={checklists}
            />
          )}
          {activeTab === 'history' && (
            <div>
              <h3 className="mb-3 text-xs font-medium uppercase tracking-wider text-muted-foreground">Stage history</h3>
              {stageHistoryRows.length === 0 ? (
                <div className="rounded-lg border p-8 text-center text-sm text-muted-foreground">
                  No stage changes recorded yet. Moving this deal between stages (on the board, the Gantt, or by drag-and-drop) will appear here.
                </div>
              ) : (
                <ol className="space-y-2">
                  {stageHistoryRows.map((h) => (
                    <li key={h.id} className="flex items-center gap-3 rounded-md border px-3 py-2 text-sm">
                      <span className="shrink-0 tabular-nums text-xs text-muted-foreground">
                        {new Date(h.changed_at).toLocaleString()}
                      </span>
                      <span className="text-foreground">
                        {h.from_stage_id ? (
                          <>
                            Moved to <b>{stageNameById.get(h.to_stage_id) ?? '-'}</b>{' '}
                            <span className="text-muted-foreground">
                              (from {stageNameById.get(h.from_stage_id) ?? '-'})
                            </span>
                          </>
                        ) : (
                          <>Created at <b>{stageNameById.get(h.to_stage_id) ?? '-'}</b></>
                        )}
                      </span>
                    </li>
                  ))}
                </ol>
              )}
            </div>
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
          {dpSorted.length > 0 && <CompaniesCard parties={dpSorted} />}
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
    ['Commitments', fmtTotals(sumCommitments((deal.deal_parties ?? []) as any[]))],
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

function CompaniesCard({ parties }: { parties: any[] }) {
  return (
    <div className="rounded-lg border bg-card">
      <div className="border-b px-3 py-2 text-[10px] font-medium uppercase tracking-wider text-muted-foreground">
        {parties.length > 1 ? 'Companies (' + parties.length + ')' : 'Company'}
      </div>
      <ul className="divide-y">
        {parties.map((p: any) => {
          const party = p.parties ?? {};
          const amt = toNum(p.commitment_amount);
          return (
            <li key={p.id} className="space-y-1 px-3 py-2 text-xs">
              <div className="flex items-center justify-between gap-2">
                <span className="text-sm font-medium text-foreground">
                  {party.party_name ?? '(unknown)'}
                </span>
                <span className="shrink-0 rounded-full bg-muted px-1.5 py-0.5 text-[10px] font-medium text-muted-foreground">
                  {roleLabel(p.role)}
                </span>
              </div>
              {amt != null && (
                <div className="tabular-nums text-foreground">
                  {fmtMoney(amt, p.currency || 'USD')}
                </div>
              )}
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
            </li>
          );
        })}
      </ul>
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
