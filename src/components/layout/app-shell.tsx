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
 * 인증된 사용자 전용 레이아웃 셸.
 *   - 좌측: Sidebar
 *   - 상단: TopBar
 *   - 메인: children (페이지 컨텐츠)
 *
 * email/displayName은 Server Component에서 받아 TopBar로 전달.
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
