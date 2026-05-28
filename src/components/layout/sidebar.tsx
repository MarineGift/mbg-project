// src/components/layout/sidebar.tsx
//
// Pipeline-centric sidebar.
// PIPELINES section is driven live by app.pipelines (org-scoped via RLS,
// excluding the 'default' technical fallback). A static fallback keeps the
// sidebar rendering even before the fetch resolves -- and if it ever fails.
//
// Preserves existing app integrations:
//   - named export `Sidebar` (consumed by AppShell)
//   - useUiStore: collapse + drafts/inbox/tasks badges
//   - useTranslations('nav') / ('common')
//   - shadcn/ui Button + Separator, cn(), theme tokens
//   - Settings link in the bottom slot, root '/' for Dashboard

'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import {
  Inbox,
  Sparkles,
  CheckSquare,
  Settings as SettingsIcon,
  LayoutDashboard,
  Menu,
  Send,
  CalendarDays,
  Users,
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
  investor:         'bg-module-investor',
  paper_mill:       'bg-module-buyer',
  filler_supplier:  'bg-amber-500',
  crowdfunding:     'bg-rose-500',
  government_grant: 'bg-violet-500',
};
const FALLBACK_DOT = 'bg-zinc-400';

// Static fallback list -- used as the initial state and if the live fetch
// fails. Matches app.pipelines for marinebiogroup (default excluded).
const STATIC_PIPELINES: Pipeline[] = [
  { id: 'static-1', code: 'investor',         name: 'Investors',        sort_order: 1 },
  { id: 'static-2', code: 'paper_mill',       name: 'Paper Mill',       sort_order: 2 },
  { id: 'static-3', code: 'filler_supplier',  name: 'Filler Suppliers', sort_order: 3 },
  { id: 'static-4', code: 'crowdfunding',     name: 'Crowdfunding',     sort_order: 4 },
  { id: 'static-5', code: 'government_grant', name: 'Government Grant', sort_order: 5 },
];

interface NavItem {
  href: string;
  labelKey: string;
  icon: typeof Inbox;
  badgeKey?: 'pendingDraftCount' | 'inboxUnreadCount' | 'openTaskCount';
}

const TOP_ITEMS: readonly NavItem[] = [
  { href: '/',         labelKey: 'dashboard', icon: LayoutDashboard },
  { href: '/drafts',   labelKey: 'drafts',    icon: Sparkles,    badgeKey: 'pendingDraftCount' },
  { href: '/inbox',    labelKey: 'inbox',     icon: Inbox,       badgeKey: 'inboxUnreadCount' },
  { href: '/sent',     labelKey: 'sent',      icon: Send },
  { href: '/tasks',    labelKey: 'tasks',     icon: CheckSquare, badgeKey: 'openTaskCount' },
  { href: '/contacts', labelKey: 'contacts',  icon: Users },
  { href: '/calendar', labelKey: 'calendar',  icon: CalendarDays },
] as const;

const BOTTOM_ITEMS: readonly NavItem[] = [
  { href: '/settings', labelKey: 'settings', icon: SettingsIcon },
] as const;

export function Sidebar() {
  const collapsed = useUiStore((s) => s.sidebarCollapsed);
  const toggleSidebar = useUiStore((s) => s.toggleSidebar);
  const pendingDraftCount = useUiStore((s) => s.pendingDraftCount);
  const inboxUnreadCount = useUiStore((s) => s.inboxUnreadCount);
  const openTaskCount = useUiStore((s) => s.openTaskCount);
  const tNav = useTranslations('nav');
  const tCommon = useTranslations('common');
  const pathname = usePathname();

  const badges = { pendingDraftCount, inboxUnreadCount, openTaskCount };

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
          .select('id, code, name, sort_order, deals(count)')
          .eq('is_active', true)
          .neq('code', 'default')
          .order('sort_order', { ascending: true });
        if (!alive) return;
        if (!error && data) {
          setPipelines(
            (data as unknown as Array<Pipeline & { deals?: Array<{ count: number }> }>).map(
              (p) => ({
                id: p.id,
                code: p.code,
                name: p.name,
                sort_order: p.sort_order,
                dealCount: p.deals && p.deals.length > 0 ? p.deals[0].count : 0,
              })
            )
          );
        }
      } catch (e) {
        // Keep STATIC_PIPELINES as the fallback if anything fails.
        console.warn('[sidebar] live pipelines fetch failed, using static fallback:', e);
      }
    })();
    return () => { alive = false; };
  }, []);

  const widthCls = collapsed ? 'w-16' : 'w-60';

  return (
    <aside
      className={cn(
        'group flex h-screen flex-col border-r bg-card text-card-foreground transition-[width] duration-200',
        widthCls,
      )}
      aria-label="Sidebar"
    >
      <div className="flex h-14 items-center justify-between gap-2 px-3 border-b">
        {!collapsed && (
          <span className="font-semibold text-sm truncate">{tCommon('appName')}</span>
        )}
        <Button
          variant="ghost"
          size="icon"
          onClick={toggleSidebar}
          aria-label="Toggle sidebar"
          className="h-8 w-8 ml-auto"
        >
          <Menu className="h-4 w-4" />
        </Button>
      </div>

      <nav className="flex-1 overflow-y-auto py-2 px-2 scrollbar-thin">
        <ul className="space-y-0.5">
          {TOP_ITEMS.map((item) => (
            <NavLink
              key={item.href}
              href={item.href}
              icon={<item.icon className="h-4 w-4 shrink-0" />}
              label={tNav(item.labelKey)}
              active={isActive(pathname, item.href)}
              collapsed={collapsed}
              badge={item.badgeKey ? badges[item.badgeKey] : undefined}
            />
          ))}
        </ul>

        <Separator className="my-3" />

        {!collapsed && (
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
                collapsed={collapsed}
                badge={p.dealCount && p.dealCount > 0 ? p.dealCount : undefined}
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
              label={tNav(item.labelKey)}
              active={isActive(pathname, item.href)}
              collapsed={collapsed}
            />
          ))}
        </ul>
      </div>
    </aside>
  );
}

function NavLink({
  href,
  icon,
  label,
  active,
  collapsed,
  badge,
}: {
  href: string;
  icon: React.ReactNode;
  label: string;
  active: boolean;
  collapsed: boolean;
  badge?: number;
}) {
  return (
    <li>
      <Link
        href={href}
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
            {badge > 99 ? '99+' : badge}
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
