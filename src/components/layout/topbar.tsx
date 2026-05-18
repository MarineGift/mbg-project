'use client';

import { Search } from 'lucide-react';
import { TopbarSearchInput } from './topbar-search-input';
import { useTranslations } from 'next-intl';
import { Input } from '@/components/ui/input';
import { LanguageToggle } from './language-toggle';
import { UserMenu } from './user-menu';

interface TopBarProps {
  email: string;
  displayName?: string | null;
}

export function TopBar({ email, displayName }: TopBarProps) {
  const t = useTranslations('common');

  return (
    <header className="flex h-14 items-center gap-3 border-b bg-background px-4 sticky top-0 z-30">
      <div className="relative flex-1 max-w-md">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          type="search"
          placeholder={t('search_placeholder')}
          className="pl-9"
          aria-label={t('search')}
        />
      </div>

      <div className="flex items-center gap-1 ml-auto">
        <LanguageToggle />
        <UserMenu email={email} displayName={displayName} />
      </div>
    </header>
  );
}
