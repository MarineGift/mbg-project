import Link from 'next/link';
import { webAdminClient, getSiteId } from './web-admin-client';

export const dynamic = 'force-dynamic';

async function counts() {
  const sb = webAdminClient();
  const siteId = await getSiteId();
  if (!siteId) return { pages: 0, products: 0, orders: 0, newInbox: 0 };

  const [pagesRes, productsRes, ordersRes, inboxRes] = await Promise.all([
    sb.schema('web').from('pages' as never).select('id', { count: 'exact', head: true }).eq('site_id', siteId),
    sb.schema('web').from('products' as never).select('id', { count: 'exact', head: true }).eq('site_id', siteId),
    sb.schema('web').from('orders' as never).select('id', { count: 'exact', head: true }),
    sb.schema('web').from('submissions' as never).select('id', { count: 'exact', head: true }).eq('status', 'new'),
  ]);

  return {
    pages: pagesRes.count ?? 0,
    products: productsRes.count ?? 0,
    orders: ordersRes.count ?? 0,
    newInbox: inboxRes.count ?? 0,
  };
}

export default async function AdminDashboard() {
  const c = await counts();
  const cards = [
    { label: 'Pages', value: c.pages, href: '/admin/pages' },
    { label: 'Products', value: c.products, href: '/admin/products' },
    { label: 'Orders', value: c.orders, href: '/admin/orders' },
    { label: 'New Inquiries', value: c.newInbox, href: '/admin/inbox' },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900 mb-1">Dashboard</h1>
      <p className="text-sm text-slate-500 mb-8">Marinebio Group homepage overview</p>
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {cards.map((card) => (
          <Link key={card.label} href={card.href} className="rounded-xl border border-slate-200 bg-white p-5 hover:shadow-sm transition">
            <div className="text-3xl font-bold text-slate-900">{card.value}</div>
            <div className="text-sm text-slate-500 mt-1">{card.label}</div>
          </Link>
        ))}
      </div>
    </div>
  );
}