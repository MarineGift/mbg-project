'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { User, Languages, Bell, Building2 } from 'lucide-react';
import { cn } from '@/lib/utils';

const NAV_ITEMS = [
  { href: '/settings/profile', labelKey: 'profile', icon: User },
  { href: '/settings/language', labelKey: 'language', icon: Languages },
  { href: '/settings/notifications', labelKey: 'notifications', icon: Bell },
  { href: '/settings/organization', labelKey: 'organization', icon: Building2 },
] as const;

export function SettingsNav() {
  const pathname = usePathname();
  const t = useTranslations('settings.nav');

  return (
    <nav className="w-56 shrink-0 border-r bg-card py-3 px-2 hidden md:block">
      <ul className="space-y-0.5">
        {NAV_ITEMS.map((item) => {
          const isActive = pathname.startsWith(item.href);
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
                <span>{t(item.labelKey)}</span>
              </Link>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
