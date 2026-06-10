import { webAdminClient } from '../web-admin-client';

export const dynamic = 'force-dynamic';

interface OrderRow {
  id: string; email: string | null; total: number | null;
  status: string; created_at: string;
}

async function loadOrders(): Promise<OrderRow[]> {
  const sb = webAdminClient();
  const { data } = await sb
    .schema('web').from('orders' as never)
    .select('id, email, total, status, created_at')
    .order('created_at', { ascending: false }).limit(100);
  return (data ?? []) as OrderRow[];
}

export default async function AdminOrders() {
  const orders = await loadOrders();
  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Orders</h1>
      <div className="rounded-xl border border-slate-200 bg-white overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-slate-500">
            <tr>
              <th className="text-left px-4 py-3 font-medium">Order ID</th>
              <th className="text-left px-4 py-3 font-medium">Email</th>
              <th className="text-right px-4 py-3 font-medium">Total</th>
              <th className="text-left px-4 py-3 font-medium">Status</th>
              <th className="text-left px-4 py-3 font-medium">Date</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((o) => (
              <tr key={o.id} className="border-t border-slate-100">
                <td className="px-4 py-3 font-mono text-xs text-slate-500">{o.id.slice(0, 8)}</td>
                <td className="px-4 py-3 text-slate-700">{o.email ?? '-'}</td>
                <td className="px-4 py-3 text-right text-slate-700">{o.total != null ? `$${Number(o.total).toFixed(2)}` : '-'}</td>
                <td className="px-4 py-3 text-slate-500">{o.status}</td>
                <td className="px-4 py-3 text-slate-400">{new Date(o.created_at).toLocaleDateString()}</td>
              </tr>
            ))}
            {!orders.length && <tr><td colSpan={5} className="px-4 py-8 text-center text-slate-400">No orders yet</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}