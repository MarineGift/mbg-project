import { requireAuthOrRedirect } from '@/lib/auth';
import Link from 'next/link';

export const dynamic = 'force-dynamic';

const NAV = [
  { href: '/admin', label: 'Dashboard' },
  { href: '/admin/pages', label: 'Pages' },
  { href: '/admin/products', label: 'Products' },
  { href: '/admin/orders', label: 'Orders' },
  { href: '/admin/inbox', label: 'Inbox' },
  { href: '/admin/campaigns', label: 'Campaigns' },
];

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  await requireAuthOrRedirect();

  return (
    <div className="min-h-screen bg-slate-50">
      <div className="flex">
        <aside className="w-56 min-h-screen border-r border-slate-200 bg-white">
          <div className="px-5 py-5 border-b border-slate-200">
            <Link href="/admin" className="font-bold text-slate-900">MBG Admin</Link>
            <p className="text-xs text-slate-400 mt-0.5">Homepage CMS</p>
          </div>
          <nav className="p-3 space-y-1">
            {NAV.map((n) => (
              <Link key={n.href} href={n.href} className="block rounded-md px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 hover:text-slate-900">
                {n.label}
              </Link>
            ))}
          </nav>
          <div className="p-3 mt-4 border-t border-slate-200">
            <Link href="/" className="block rounded-md px-3 py-2 text-sm text-slate-500 hover:bg-slate-100">View Site</Link>
          </div>
        </aside>
        <main className="flex-1 p-8">{children}</main>
      </div>
    </div>
  );
}