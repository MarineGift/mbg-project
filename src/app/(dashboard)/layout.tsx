import type { ReactNode } from 'react';
import Link from 'next/link';
import { redirect } from 'next/navigation';
import { getUserAndOrg } from '@/lib/supabase/server';
import { signOut } from '@/app/auth/actions';

export const dynamic = 'force-dynamic';

export default async function DashboardLayout({ children }: { children: ReactNode }) {
  let auth;
  try {
    auth = await getUserAndOrg();
  } catch {
    redirect('/login');
  }

  return (
    <div className="grid grid-cols-[220px_1fr] min-h-screen bg-surface-subtle">
      <aside className="flex flex-col bg-surface border-r border-border">
        <div className="px-4 pt-5 pb-3">
          <div className="text-lg font-bold">URM</div>
          <div className="text-xs text-zinc-400 mt-0.5 truncate" title={auth.email}>
            {auth.email}
          </div>
        </div>
        <nav className="grid gap-0.5 px-2 py-2">
          <NavLink href="/drafts">📝 Drafts</NavLink>
          <NavLink href="/communications">📬 Communications</NavLink>
          <NavLink href="/campaigns">📤 Campaigns</NavLink>
        </nav>
        <div className="mt-auto p-2">
          <form action={signOut}>
            <button type="submit" className="btn-secondary btn-sm w-full">
              로그아웃
            </button>
          </form>
        </div>
      </aside>
      <main className="px-8 py-6 overflow-y-auto min-h-screen">{children}</main>
    </div>
  );
}

function NavLink({ href, children }: { href: string; children: ReactNode }) {
  return (
    <Link
      href={href}
      className="block px-3 py-2 text-base text-zinc-700 rounded hover:bg-surface-muted transition-colors"
    >
      {children}
    </Link>
  );
}
