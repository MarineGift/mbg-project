import { webAdminClient, getSiteId } from '../web-admin-client';

export const dynamic = 'force-dynamic';

interface ProductRow {
  id: string; name: string; slug: string;
  base_price: number | null; status: string; category: string | null;
}

async function loadProducts(): Promise<ProductRow[]> {
  const sb = webAdminClient();
  const siteId = await getSiteId();
  if (!siteId) return [];
  const { data } = await sb
    .schema('web').from('products' as never)
    .select('id, name, slug, base_price, status, category')
    .eq('site_id', siteId).order('name');
  return (data ?? []) as ProductRow[];
}

export default async function AdminProducts() {
  const products = await loadProducts();
  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Products</h1>
      <div className="rounded-xl border border-slate-200 bg-white overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-slate-500">
            <tr>
              <th className="text-left px-4 py-3 font-medium">Name</th>
              <th className="text-left px-4 py-3 font-medium">Category</th>
              <th className="text-right px-4 py-3 font-medium">Price</th>
              <th className="text-left px-4 py-3 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {products.map((p) => (
              <tr key={p.id} className="border-t border-slate-100">
                <td className="px-4 py-3 font-medium text-slate-900">{p.name}</td>
                <td className="px-4 py-3 text-slate-500">{p.category ?? '-'}</td>
                <td className="px-4 py-3 text-right text-slate-700">{p.base_price != null ? `$${Number(p.base_price).toFixed(2)}` : '-'}</td>
                <td className="px-4 py-3">
                  <span className={p.status === 'active' ? 'text-emerald-600' : 'text-slate-400'}>{p.status}</span>
                </td>
              </tr>
            ))}
            {!products.length && <tr><td colSpan={4} className="px-4 py-8 text-center text-slate-400">No products yet</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}