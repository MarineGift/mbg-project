'use client';

import type { ReactNode } from 'react';
import { Sidebar } from './sidebar';
import { TopBar } from './topbar';

interface AppShellProps {
  email: string;
  displayName?: string | null;
  children: ReactNode;
}

/**
 * Layout shell for authenticated users only.
 *   - left: Sidebar
 *   - top: TopBar
 *   - main: children (page content)
 *
 * email/displayName are received from the Server Component and passed to TopBar.
 */
export function AppShell({ email, displayName, children }: AppShellProps) {
  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar />
      <div className="flex-1 flex flex-col min-w-0">
        <TopBar email={email} displayName={displayName} />
        <main className="flex-1 overflow-y-auto scrollbar-thin">
          {children}
        </main>
      </div>
    </div>
  );
}
