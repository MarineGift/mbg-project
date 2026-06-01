'use client';

import { useState, type ReactNode } from 'react';
import { Menu } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { Sidebar } from './sidebar';
import { TopBar } from './topbar';

interface AppShellProps {
  email: string;
  displayName?: string | null;
  children: ReactNode;
}

/**
 * Layout shell for authenticated users only.
 *   - left: Sidebar (desktop in-flow, mobile overlay drawer)
 *   - top: mobile hamburger bar (md:hidden) + desktop TopBar (hidden md:block)
 *   - main: children (page content)
 *
 * email/displayName are received from the Server Component and passed to TopBar.
 */
export function AppShell({ email, displayName, children }: AppShellProps) {
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const tCommon = useTranslations('common');

  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar
        mobileOpen={mobileNavOpen}
        onMobileClose={() => setMobileNavOpen(false)}
      />

      <div className="flex flex-1 flex-col min-w-0">
        {/* Mobile top bar — hamburger opens the drawer (desktop uses TopBar below) */}
        <div className="flex md:hidden items-center gap-2 h-14 px-3 border-b bg-card text-card-foreground shrink-0">
          <button
            type="button"
            onClick={() => setMobileNavOpen(true)}
            aria-label="Open navigation menu"
            className="inline-flex h-9 w-9 items-center justify-center rounded-md hover:bg-accent"
          >
            <Menu className="h-5 w-5" />
          </button>
          <span className="font-semibold text-sm truncate">{tCommon('appName')}</span>
        </div>

        {/* Desktop top bar */}
        <div className="hidden md:block shrink-0">
          <TopBar email={email} displayName={displayName} />
        </div>

        <main className="flex-1 overflow-y-auto scrollbar-thin">
          {children}
        </main>
      </div>
    </div>
  );
}
