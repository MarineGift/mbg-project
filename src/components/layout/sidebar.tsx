// src/components/layout/sidebar.tsx
//
// Pipeline-centric sidebar.
// PIPELINES section is driven live by app.pipelines (org-scoped via RLS,
// excluding the 'default' technical fallback). A static fallback keeps the
// sidebar rendering even before the fetch resolves -- and if it ever fails.
//
// Responsive:
//   - Desktop (md+): in-flow <aside>, collapsible (w-16 / w-60) as before.
//   - Mobile (<md): hidden in-flow; rendered as an overlay drawer controlled by
//     `mobileOpen` (toggled by the hamburger in AppShell). Tapping a link or the
//     backdrop closes it.
//
// Preserves existing app integrations:
//   - named export `Sidebar` (consumed by AppShell)
//   - useUiStore: collapse + drafts/inbox/tasks badges
//   - useTranslations('nav') / ('common')
//   - shadcn/ui Button + Separator, cn(), theme tokens
//   - Settings link in the bottom slot, root '/' for Dashboard

'use client';

import Link from 'next/link';
import { usePathname, useSearchParams } from 'next/navigation';
import { useEffect, useState, Fragment } from 'react';
import { useTranslations } from 'next-intl';
import {
  Inbox,
  CheckSquare,
  Settings as SettingsIcon,
  LayoutDashboard,
  Menu,
  X,
  Send,
  CalendarDays,
  Megaphone,
  BarChart3,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { cn } from '@/lib/utils';
import { useUiStore } from '@/lib/stores/ui-store';
import { createSupabaseBrowserClient } from '@/lib/supabase/client';

type Pipeline = { id: string; code: string; name: string; sort_order: number; dealCount?: number };

// Pipeline code -> dot color. Existing module-* theme tokens are reused where
// they already exist; new pipelines get standard Tailwind colors.
const PIPELINE_DOT: Record<string, string> = {
  investor:         'bg-party-investor',
  paper_mill:       'bg-party-buyer',
  filler_supplier:  'bg-amber-500',
  crowdfunding:     'bg-rose-500',
  government_grant: 'bg-violet-500',
  partner:          'bg-orange-500',
  self:             'bg-teal-600',
};
const FALLBACK_DOT = 'bg-zinc-400';

// Static fallback list -- used as the initial state and if the live fetch
// fails. Matches app.pipelines for marinebiogroup (default excluded).
const STATIC_PIPELINES: Pipeline[] = [
  { id: 'static-1', code: 'investors',        name: 'Investors',        sort_order: 1 },
  { id: 'static-2', code: 'paper_mill',       name: 'Paper Mill',       sort_order: 2 },
  { id: 'static-3', code: 'filler_suppliers', name: 'Filler Suppliers', sort_order: 3 },
  { id: 'static-4', code: 'crowdfunding',     name: 'Crowdfunding',     sort_order: 4 },
  { id: 'static-5', code: 'government_grant', name: 'Government Grant', sort_order: 5 },
];

// Directory section -- party-list (info) pages, distinct from pipelines (workflow).
// Links to /[partyType]/parties where partyType is the enum code.
type DirectoryItem = { code: string; name: string };
const DIRECTORY_ITEMS: readonly DirectoryItem[] = [
  { code: 'investor',        name: 'Investors' },
  { code: 'paper_mill',      name: 'Paper Mills' },
  { code: 'filler_supplier', name: 'Filler Suppliers' },
  { code: 'partner',         name: 'Partners' },
  { code: 'self',            name: 'MarineBio Group' },
] as const;

interface NavItem {
  href: string;
  labelKey: string;
  icon: typeof Inbox;
  badgeKey?: 'pendingDraftCount' | 'inboxUnreadCount' | 'openTaskCount' | 'sentCount' | 'calendarUpcomingCount' | 'campaignsActiveCount';
  /** Optional explicit label; bypasses tNav(labelKey) when set. */
  label?: string;
}

const TOP_ITEMS: readonly NavItem[] = [
  { href: '/',         labelKey: 'dashboard', icon: LayoutDashboard },
  // AI Drafts moved into Inbox (Inbox shows Inbound / Outbound / AI Drafts),
  // so the standalone /drafts sidebar item was removed.
  { href: '/inbox',    labelKey: 'inbox',     icon: Inbox,       badgeKey: 'inboxUnreadCount' },
  { href: '/sent',     labelKey: 'sent',      icon: Send,        badgeKey: 'sentCount' },
  // To-Do board (standalone task engine, app.todo_items). The deal-scoped
  // engagement tasks at /tasks stay as a route for reuse inside deal detail,
  // but no longer have a top-level sidebar link. Explicit label avoids
  // touching the next-intl messages files.
  { href: '/todo',     labelKey: 'tasks',     icon: CheckSquare, label: 'To-Do', badgeKey: 'openTaskCount' },
  { href: '/calendar', labelKey: 'calendar',  icon: CalendarDays, badgeKey: 'calendarUpcomingCount' },
  { href: '/campaigns', labelKey: 'campaigns', icon: Megaphone, label: 'Campaigns', badgeKey: 'campaignsActiveCount' },
  { href: '/reports',  labelKey: 'reports',   icon: BarChart3, label: 'Reports' },
] as const;

const BOTTOM_ITEMS: readonly NavItem[] = [
  { href: '/settings', labelKey: 'settings', icon: SettingsIcon },
] as const;

// Inbox sub-items, shown indented under the Inbox link. They map onto the inbox
// page filters (direction + hasDraft) so the same list/query is reused.
type InboxSubItem = { label: string; href: string; countKey: 'inbound' | 'outbound' | 'drafts'; match: (sp: URLSearchParams) => boolean };
const INBOX_SUBITEMS: readonly InboxSubItem[] = [
  {
    label: 'In Bound',
    href: '/inbox?direction=inbound',
    countKey: 'inbound',
    match: (sp) => !sp.get('hasDraft') && (sp.get('direction') ?? 'inbound') === 'inbound',
  },
  {
    label: 'Out Bound',
    href: '/inbox?direction=outbound',
    countKey: 'outbound',
    match: (sp) => !sp.get('hasDraft') && sp.get('direction') === 'outbound',
  },
  {
    label: 'AI Drafts',
    href: '/inbox?hasDraft=1',
    countKey: 'drafts',
    match: (sp) => !!sp.get('hasDraft'),
  },
] as const;

interface SidebarProps {
  /** Mobile drawer open state (managed by AppShell). Ignored on desktop. */
  mobileOpen?: boolean;
  /** Called when the mobile drawer should close (link tap / backdrop / X). */
  onMobileClose?: () => void;
}

export function Sidebar({ mobileOpen = false, onMobileClose }: SidebarProps = {}) {
  const collapsed = useUiStore((s) => s.sidebarCollapsed);
  const toggleSidebar = useUiStore((s) => s.toggleSidebar);
  const tNav = useTranslations('nav');
  const pathname = usePathname();
  const searchParams = useSearchParams();

  // Live counts fetched directly by the sidebar (the ui-store badge values are
  // never populated anywhere, so we query Supabase here instead).
  type SidebarCounts = {
    inboxUnread: number;     // unread inbound
    inbound: number;         // total inbound
    outboundUnread: number;  // unread outbound (usually 0)
    outbound: number;        // total outbound
    draftsPending: number;   // drafts pending review
    draftsTotal: number;     // total drafts
    todoOpen: number;
    sent: number;             // outbound messages (non-deleted)
    calendarUpcoming: number; // events starting now or later
    campaignsActive: number;  // campaigns with status='active'
    parties: Record<string, number>; // keyed by party_type code
  };
  const [counts, setCounts] = useState<SidebarCounts>({
    inboxUnread: 0, inbound: 0, outboundUnread: 0, outbound: 0,
    draftsPending: 0, draftsTotal: 0, todoOpen: 0,
    sent: 0, calendarUpcoming: 0, campaignsActive: 0, parties: {},
  });

  const badges = {
    pendingDraftCount: counts.draftsPending,
    inboxUnreadCount: counts.inboxUnread,
    openTaskCount: counts.todoOpen,
    sentCount: counts.sent,
    calendarUpcomingCount: counts.calendarUpcoming,
    campaignsActiveCount: counts.campaignsActive,
  };

  // A/B pairs for the inbox sub-items (shown as "A/B", e.g. unread/total).
  const subPairs: Record<'inbound' | 'outbound' | 'drafts', [number, number]> = {
    inbound:  [counts.inboxUnread, counts.inbound],
    outbound: [counts.outboundUnread, counts.outbound],
    drafts:   [counts.draftsPending, counts.draftsTotal],
  };

  const [pipelines, setPipelines] = useState<Pipeline[]>(STATIC_PIPELINES);
  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const supabase = createSupabaseBrowserClient();
        // Gotcha #45: .schema('app') without cast, .from('TABLE' as never) with cast
        const { data, error } = await supabase
          .schema('app')
          .from('pipelines' as never)
          .select('id, code, name, sort_order')
          .eq('is_active', true)
          .neq('code', 'default')
          .order('sort_order', { ascending: true });
        if (!alive) return;
        if (!error && data) {
          const base = data as unknown as Pipeline[];
          // Per-pipeline deal count, EXCLUDING soft-deleted deals. The previous
          // `deals(count)` embed had no deleted_at filter, so it over-counted
          // (e.g. seeded-then-deleted deals). This mirrors the directory's
          // non-deleted head-count pattern below so the badge matches the board.
          const countResults = await Promise.all(
            base.map((p) =>
              supabase
                .schema('app')
                .from('deals' as never)
                .select('id', { count: 'exact', head: true })
                .eq('pipeline_id' as never, p.id)
                .is('deleted_at' as never, null)
            )
          );
          if (!alive) return;
          setPipelines(
            base.map((p, i) => ({
              id: p.id,
              code: p.code,
              name: p.name,
              sort_order: p.sort_order,
              dealCount: (countResults[i] as any).count ?? 0,
            }))
          );
        }
      } catch (e) {
        // Keep STATIC_PIPELINES as the fallback if anything fails.
        console.warn('[sidebar] live pipelines fetch failed, using static fallback:', e);
      }
    })();
    return () => { alive = false; };
  }, []);

  // Fetch badge counts (inbox / inbound / outbound / drafts / open todos /
  // parties per type). All defensive: any failure leaves that count at 0.
  useEffect(() => {
    let alive = true;
    (async () => {
      try {
        const supabase = createSupabaseBrowserClient();
        const comm = () => supabase.schema('app').from('communications' as never);
        const [
          unreadRes, inboundRes, outboundUnreadRes, outboundRes, draftsPendingRes, draftsTotalRes,
          partyTypesRes, todoOpenRes, sentRes, calendarRes, campaignsRes,
        ] = await Promise.all([
          comm().select('id', { count: 'exact', head: true }).eq('direction', 'inbound').is('read_at' as never, null).is('deleted_at' as never, null),
          comm().select('id', { count: 'exact', head: true }).eq('direction', 'inbound').is('deleted_at' as never, null),
          comm().select('id', { count: 'exact', head: true }).eq('direction', 'outbound').is('read_at' as never, null).is('deleted_at' as never, null),
          comm().select('id', { count: 'exact', head: true }).eq('direction', 'outbound').is('deleted_at' as never, null),
          supabase.schema('ai').from('drafts' as never).select('id', { count: 'exact', head: true }).eq('status', 'pending_review'),
          supabase.schema('ai').from('drafts' as never).select('id', { count: 'exact', head: true }),
          supabase.schema('app').from('party_types' as never).select('id, code'),
          // Open To-Do items: todo_items.status is plain text (todo/backlog/
          // in_progress/review/done); open = not 'done' and not archived. The old
          // status_option_id column does not exist (42703 broke this badge).
          supabase.schema('app').from('todo_items' as never).select('id', { count: 'exact', head: true }).neq('status' as never, 'done').is('archived_at' as never, null),
          // Sent: outbound, non-deleted.
          comm().select('id', { count: 'exact', head: true }).eq('direction', 'outbound').is('deleted_at' as never, null),
          // Calendar: events starting now or later.
          supabase.schema('app').from('calendar_events' as never).select('id', { count: 'exact', head: true }).gte('start_at' as never, new Date().toISOString()),
          // Campaigns: active.
          supabase.schema('app').from('campaigns' as never).select('id', { count: 'exact', head: true }).eq('status', 'active'),
        ]);
        if (!alive) return;

        // Parties per type code — head counts per type (a plain select() caps at
        // 1000 rows and would undercount, e.g. paper_mill 1067).
        const typeRows = ((partyTypesRes as any).data ?? []) as Array<{ id: number; code: string }>;
        const partyCountResults = await Promise.all(
          typeRows.map((t) =>
            supabase
              .schema('app')
              .from('parties' as never)
              .select('id', { count: 'exact', head: true })
              .eq('party_type_id' as never, t.id)
              .is('deleted_at' as never, null)
              // match the directory page default view: hide auto-created stub
              // parties (notes ILIKE 'Auto-created%'), so e.g. paper_mill counts
              // 717 here too instead of 1033.
              .or('notes.is.null,notes.not.ilike.Auto-created%')
          )
        );
        if (!alive) return;
        const parties: Record<string, number> = {};
        typeRows.forEach((t, i) => {
          parties[t.code] = (partyCountResults[i] as any).count ?? 0;
        });

        // Open todos = items not in the 'done' status (computed by the head
        // count query above).
        const todoOpen = (todoOpenRes as any).count ?? 0;

        setCounts({
          inboxUnread: (unreadRes as any).count ?? 0,
          inbound: (inboundRes as any).count ?? 0,
          outboundUnread: (outboundUnreadRes as any).count ?? 0,
          outbound: (outboundRes as any).count ?? 0,
          draftsPending: (draftsPendingRes as any).count ?? 0,
          draftsTotal: (draftsTotalRes as any).count ?? 0,
          todoOpen,
          sent: (sentRes as any).count ?? 0,
          calendarUpcoming: (calendarRes as any).count ?? 0,
          campaignsActive: (campaignsRes as any).count ?? 0,
          parties,
        });
      } catch (e) {
        console.warn('[sidebar] counts fetch failed:', e);
      }
    })();
    return () => { alive = false; };
  }, []);

  const widthCls = collapsed ? 'w-16' : 'w-60';

  // Inner content is rendered both in the desktop aside and the mobile drawer.
  // `isCollapsed` only applies on desktop; the mobile drawer is always expanded.
  // `mobile` swaps the header's collapse toggle for a close (X) button and makes
  // nav links close the drawer on tap.
  const renderBody = (opts: { isCollapsed: boolean; mobile: boolean }) => {
    const { isCollapsed, mobile } = opts;
    const onNavigate = mobile ? onMobileClose : undefined;
    return (
      <>
        <div className="flex h-14 items-center justify-between gap-2 px-3 border-b">
          {!isCollapsed && (
            <span className="font-semibold text-sm truncate">URM (Marinebio Group)</span>
          )}
          {mobile ? (
            <Button
              variant="ghost"
              size="icon"
              onClick={onMobileClose}
              aria-label="Close menu"
              className="h-8 w-8 ml-auto"
            >
              <X className="h-4 w-4" />
            </Button>
          ) : (
            <Button
              variant="ghost"
              size="icon"
              onClick={toggleSidebar}
              aria-label="Toggle sidebar"
              className="h-8 w-8 ml-auto"
            >
              <Menu className="h-4 w-4" />
            </Button>
          )}
        </div>

        <nav className="flex-1 overflow-y-auto py-2 px-2 scrollbar-thin">
          <ul className="space-y-0.5">
            {TOP_ITEMS.map((item) => (
              <Fragment key={item.href}>
                <NavLink
                  href={item.href}
                  icon={<item.icon className="h-4 w-4 shrink-0" />}
                  label={item.label ?? tNav(item.labelKey)}
                  active={isActive(pathname, item.href)}
                  collapsed={isCollapsed}
                  badge={item.badgeKey ? badges[item.badgeKey] : undefined}
                  badgeText={item.href === '/inbox' ? `${counts.inboxUnread}/${counts.inbound}` : undefined}
                  onNavigate={onNavigate}
                />
                {item.href === '/inbox' && !isCollapsed && (
                  <li>
                    <ul className="mt-0.5 space-y-0.5">
                      {INBOX_SUBITEMS.map((sub) => {
                        const subActive = pathname === '/inbox' && sub.match(searchParams);
                        return (
                          <li key={sub.label}>
                            <Link
                              href={sub.href}
                              onClick={onNavigate}
                              className={cn(
                                'flex items-center gap-2 rounded-md py-1.5 pl-9 pr-2 text-sm transition-colors',
                                subActive
                                  ? 'bg-accent text-accent-foreground font-medium'
                                  : 'text-muted-foreground hover:bg-accent hover:text-foreground',
                              )}
                              aria-current={subActive ? 'page' : undefined}
                            >
                              <span className="flex-1 truncate">{sub.label}</span>
                              {subPairs[sub.countKey][1] > 0 && (
                                <span className="tabular-nums text-xs text-muted-foreground">
                                  {subPairs[sub.countKey][0]}/{subPairs[sub.countKey][1]}
                                </span>
                              )}
                            </Link>
                          </li>
                        );
                      })}
                    </ul>
                  </li>
                )}
              </Fragment>
            ))}
          </ul>

          <Separator className="my-3" />

          {!isCollapsed && (
            <p className="px-2 mb-1 text-[10px] uppercase tracking-wider text-muted-foreground font-medium">
              Directory
            </p>
          )}
          <ul className="space-y-0.5">
            {DIRECTORY_ITEMS.map((d) => {
              const dotCls = PIPELINE_DOT[d.code] ?? FALLBACK_DOT;
              const href = `/${d.code}/parties`;
              const partyCount = counts.parties[d.code] ?? 0;
              return (
                <NavLink
                  key={d.code}
                  href={href}
                  icon={
                    <span
                      className={cn('h-2.5 w-2.5 rounded-full shrink-0', dotCls)}
                      aria-hidden
                    />
                  }
                  label={d.name}
                  active={isActive(pathname, href)}
                  collapsed={isCollapsed}
                  badge={partyCount > 0 ? partyCount : undefined}
                  onNavigate={onNavigate}
                />
              );
            })}
          </ul>

          <Separator className="my-3" />

          {!isCollapsed && (
            <p className="px-2 mb-1 text-[10px] uppercase tracking-wider text-muted-foreground font-medium">
              Pipelines
            </p>
          )}
          <ul className="space-y-0.5">
            {pipelines.map((p) => {
              const dotCls = PIPELINE_DOT[p.code] ?? FALLBACK_DOT;
              const href = `/pipelines/${p.code}`;
              return (
                <NavLink
                  key={p.id}
                  href={href}
                  icon={
                    <span
                      className={cn('h-2.5 w-2.5 rounded-full shrink-0', dotCls)}
                      aria-hidden
                    />
                  }
                  label={p.name}
                  active={isActive(pathname, href)}
                  collapsed={isCollapsed}
                  badge={p.dealCount && p.dealCount > 0 ? p.dealCount : undefined}
                  onNavigate={onNavigate}
                />
              );
            })}
          </ul>
        </nav>

        <div className="border-t py-2 px-2">
          <ul className="space-y-0.5">
            {BOTTOM_ITEMS.map((item) => (
              <NavLink
                key={item.href}
                href={item.href}
                icon={<item.icon className="h-4 w-4 shrink-0" />}
                label={item.label ?? tNav(item.labelKey)}
                active={isActive(pathname, item.href)}
                collapsed={isCollapsed}
                onNavigate={onNavigate}
              />
            ))}
          </ul>
        </div>
      </>
    );
  };

  return (
    <>
      {/* Desktop sidebar (in-flow, collapsible) */}
      <aside
        className={cn(
          'group hidden md:flex h-screen flex-col border-r bg-card text-card-foreground transition-[width] duration-200',
          widthCls,
        )}
        aria-label="Sidebar"
      >
        {renderBody({ isCollapsed: collapsed, mobile: false })}
      </aside>

      {/* Mobile backdrop */}
      <div
        className={cn(
          'fixed inset-0 z-40 bg-black/40 md:hidden transition-opacity duration-200',
          mobileOpen ? 'opacity-100' : 'pointer-events-none opacity-0',
        )}
        aria-hidden
        onClick={onMobileClose}
      />

      {/* Mobile drawer (overlay, always expanded) */}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-50 flex w-72 max-w-[85%] flex-col border-r bg-card text-card-foreground md:hidden transition-transform duration-200 will-change-transform',
          mobileOpen ? 'translate-x-0' : '-translate-x-full',
        )}
        aria-label="Sidebar"
        aria-hidden={!mobileOpen}
      >
        {renderBody({ isCollapsed: false, mobile: true })}
      </aside>
    </>
  );
}

function NavLink({
  href,
  icon,
  label,
  active,
  collapsed,
  badge,
  badgeText,
  onNavigate,
}: {
  href: string;
  icon: React.ReactNode;
  label: string;
  active: boolean;
  collapsed: boolean;
  badge?: number;
  /** Optional expanded-state label inside the pill (e.g. "70/74"); collapsed still shows the number. */
  badgeText?: string;
  onNavigate?: () => void;
}) {
  return (
    <li>
      <Link
        href={href}
        onClick={onNavigate}
        className={cn(
          'relative flex items-center gap-3 rounded-md px-2 py-2 text-sm transition-colors',
          active
            ? 'bg-accent text-accent-foreground font-medium'
            : 'text-muted-foreground hover:bg-accent hover:text-foreground',
        )}
        title={collapsed ? label : undefined}
        aria-current={active ? 'page' : undefined}
      >
        {icon}
        {!collapsed && <span className="truncate flex-1">{label}</span>}
        {badge != null && badge > 0 && (
          <span
            className={cn(
              'inline-flex items-center justify-center rounded-full bg-purple-500 text-white tabular-nums font-medium shrink-0',
              collapsed
                ? 'absolute right-1 top-1 h-4 w-4 text-[10px]'
                : 'h-5 min-w-[20px] px-1.5 text-xs',
            )}
            aria-label={`${badge} pending`}
          >
            {collapsed ? (badge > 99 ? '99+' : badge) : (badgeText ?? badge.toLocaleString())}
          </span>
        )}
      </Link>
    </li>
  );
}

function isActive(pathname: string, href: string): boolean {
  if (href === '/') return pathname === '/';
  return pathname === href || pathname.startsWith(`${href}/`);
}
