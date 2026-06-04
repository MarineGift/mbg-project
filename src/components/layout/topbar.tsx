'use client';

import { LanguageToggle } from './language-toggle';
import { UserMenu } from './user-menu';

interface TopBarProps {
  email: string;
  displayName?: string | null;
}

export function TopBar({ email, displayName }: TopBarProps) {
  return (
    <header className="flex h-14 items-center gap-3 border-b bg-background px-4 sticky top-0 z-30">
      <div className="flex items-center gap-1 ml-auto">
        <LanguageToggle />
        <UserMenu email={email} displayName={displayName} />
      </div>
    </header>
  );
}
