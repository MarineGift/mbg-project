'use client';

import { useTransition } from 'react';
import { useLocale, useTranslations } from 'next-intl';
import { useRouter } from 'next/navigation';
import { Languages } from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Button } from '@/components/ui/button';
import {
  locales,
  localeCookieName,
  localeDisplayNames,
  type Locale,
} from '@/i18n/routing';

/**
 * Language toggle - updates the cookie + triggers a Server Component re-render via router.refresh().
 */
export function LanguageToggle() {
  const t = useTranslations('common');
  const current = useLocale() as Locale;
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  const setLocale = (next: Locale) => {
    if (next === current) return;
    // cookie valid for 1 year
    document.cookie = `${localeCookieName}=${next}; path=/; max-age=${60 * 60 * 24 * 365}; samesite=lax`;
    startTransition(() => router.refresh());
  };

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          aria-label={t('language')}
          disabled={isPending}
        >
          <Languages className="h-4 w-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuLabel>{t('language')}</DropdownMenuLabel>
        <DropdownMenuSeparator />
        {locales.map((loc) => (
          <DropdownMenuItem
            key={loc}
            onClick={() => setLocale(loc)}
            className={loc === current ? 'font-semibold' : ''}
          >
            {localeDisplayNames[loc]}
            {loc === current && <span className="ml-auto text-xs">✓</span>}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
