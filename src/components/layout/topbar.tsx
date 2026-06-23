'use client';

import Link from 'next/link';
import { CalendarDays, CalendarCheck } from 'lucide-react';
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
        <Link href="/today" aria-label="Today" className="inline-flex h-9 items-center gap-1.5 rounded-md px-2 text-sm font-medium hover:bg-accent">
          <CalendarCheck className="h-5 w-5" />
          <span className="hidden sm:inline">Today</span>
        </Link>
        <Link href="/calendar" aria-label="Calendar" className="inline-flex h-9 items-center gap-1.5 rounded-md px-2 text-sm font-medium hover:bg-accent">
          <CalendarDays className="h-5 w-5" />
          <span className="hidden sm:inline">Calendar</span>
        </Link>
        <LanguageToggle />
        <UserMenu email={email} displayName={displayName} />
      </div>
    </header>
  );
}
