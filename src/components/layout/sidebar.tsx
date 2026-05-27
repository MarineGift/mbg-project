'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTranslations } from 'next-intl';
import {
  Inbox,
  Sparkles,
  Users,
  Briefcase,
  CheckSquare,
  Settings as SettingsIcon,
  LayoutDashboard,
  Menu, Send
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Separator } from '@/components/ui/separator';
import { cn } from '@/lib/utils';
import { useUiStore } from '@/lib/stores/ui-store';
import type { PartyTypeCode } from '@/types/ai';

/**
 * Sidebar — 좌측 네비게이션.
 *
 * 구조:
 *   - 상단: 앱 로고 + 토글 버튼
 *   - 메인: 핵심 페이지 (대시보드, 수신함, AI 초안, 할 일)
 *   - 모듈 섹션: 4개 priority 모듈 (Q1 결정 — investor/buyer/partner/customer만 활성)
 *   - 하단: 설정
 */

const PHASE_1_ACTIVE_MODULES: readonly PartyTypeCode[] = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
  'filler_supplier',
] as const;

interface NavItem {
  href: string;
  labelKey: string;
  icon: typeof Inbox;
}

const TOP_ITEMS: readonly NavItem[] = [
  { href: '/', labelKey: 'dashboard', icon: LayoutDashboard },
  { href: '/drafts', labelKey: 'drafts', icon: Sparkles },
  { href: '/inbox', labelKey: 'inbox', icon: Inbox },
  { href: '/sent', labelKey: 'sent', icon: Send },
  { href: '/tasks', labelKey: 'tasks', icon: CheckSquare },
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
  const tModules = useTranslations('modules');
  const tCommon = useTranslations('common');
  const pathname = usePathname();

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
          <span className="font-semibold text-sm truncate">
            {tCommon('appName')}
          </span>
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
              badge={item.href === '/drafts' ? pendingDraftCount : item.href === '/inbox' ? inboxUnreadCount : item.href === '/tasks' ? openTaskCount : undefined}
            />
          ))}
        </ul>

        <Separator className="my-3" />

        {!collapsed && (
          <p className="px-2 mb-1 text-[10px] uppercase tracking-wider text-muted-foreground font-medium">
            {tNav('parties')}
          </p>
        )}
        <ul className="space-y-0.5">
          {PHASE_1_ACTIVE_MODULES.map((mod) => (
            <NavLink
              key={mod}
              href={`/${mod}/parties`}
              icon={<ModuleDot module={mod} />}
              label={tModules(mod)}
              active={pathname.startsWith(`/${mod}/`)}
              collapsed={collapsed}
            />
          ))}
        </ul>

        <Separator className="my-3" />

        {!collapsed && (
          <p className="px-2 mb-1 text-[10px] uppercase tracking-wider text-muted-foreground font-medium">
            {tNav('engagements')}
          </p>
        )}
        <ul className="space-y-0.5">
          {PHASE_1_ACTIVE_MODULES.map((mod) => (
            <NavLink
              key={`eng-${mod}`}
              href={`/${mod}/engagements`}
              icon={<Briefcase className="h-4 w-4 shrink-0" />}
              label={`${tModules(mod)}`}
              active={pathname === `/${mod}/engagements`}
              collapsed={collapsed}
            />
          ))}
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
          'flex items-center gap-3 rounded-md px-2 py-2 text-sm transition-colors',
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

function ModuleDot({ module }: { module: PartyTypeCode }) {
  const cls: Record<PartyTypeCode, string> = {
  investor: 'bg-module-investor',
  paper_mill: 'bg-module-buyer',
  partner: 'bg-module-partner',
  customer: 'bg-module-customer',
  buyer: 'bg-module-buyer',
  government_grant: 'bg-gray-500',
  filler_supplier: 'bg-amber-500',  // 충전제(광물성) — amber 톤. 추후 tailwind config에 bg-module-filler 추가 가능
};
  return (
    <span
      className={cn('h-2.5 w-2.5 rounded-full shrink-0', cls[module])}
      aria-hidden
    />
  );
}

function isActive(pathname: string, href: string): boolean {
  if (href === '/') return pathname === '/';
  return pathname === href || pathname.startsWith(`${href}/`);
}