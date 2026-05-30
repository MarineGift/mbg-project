'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTranslations } from 'next-intl';
import {
  User, Languages, Bell, Building2, Workflow,
  FileText, Send, History, ShieldCheck,
} from 'lucide-react';
import { cn } from '@/lib/utils';

type NavItem = {
  href:      string;
  icon:      typeof User;
  labelKey?: string;   // i18n
  label?:    string;   // 직접 라벨 (i18n 우회)
};

const NAV_ITEMS: NavItem[] = [
  { href: '/settings/profile',         labelKey: 'profile',       icon: User },
  { href: '/settings/language',        labelKey: 'language',      icon: Languages },
  { href: '/settings/notifications',   labelKey: 'notifications', icon: Bell },
  { href: '/settings/organization',    labelKey: 'organization',  icon: Building2 },
  { href: '/settings/pipelines',       labelKey: 'pipelines',     icon: Workflow },
  // ── Phase 20c / 21b / 21c ──
  { href: '/settings/email-templates', label: 'Email Templates',  icon: FileText },
  { href: '/settings/email-sequences', label: 'Email Sequences',  icon: Send },
  { href: '/settings/email-history',   label: 'Email History',    icon: History },
  { href: '/settings/audit',           label: 'Audit log',        icon: ShieldCheck },
];

export function SettingsNav() {
  const pathname = usePathname();
  const t = useTranslations('settings.nav');

  return (
    <nav className="w-56 shrink-0 border-r bg-card py-3 px-2 hidden md:block">
      <ul className="space-y-0.5">
        {NAV_ITEMS.map((item) => {
          const isActive = pathname.startsWith(item.href);
          const labelText = item.label ?? (item.labelKey ? t(item.labelKey) : '');
          return (
            <li key={item.href}>
              <Link
                href={item.href}
                className={cn(
                  'flex items-center gap-2 rounded-md px-2 py-2 text-sm transition-colors',
                  isActive
                    ? 'bg-accent text-accent-foreground font-medium'
                    : 'text-muted-foreground hover:bg-accent hover:text-foreground',
                )}
                aria-current={isActive ? 'page' : undefined}
              >
                <item.icon className="h-4 w-4 shrink-0" />
                <span>{labelText}</span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
