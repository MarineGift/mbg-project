import Link from 'next/link';
import { webAdminClient, getSiteId } from '../web-admin-client';

export const dynamic = 'force-dynamic';

interface PageRow {
  id: string; path: string; title: string; template: string;
  status: string; is_home: boolean; sort_order: number;
}

async function loadPages(): Promise<PageRow[]> {
  const sb = webAdminClient();
  const siteId = await getSiteId();
  if (!siteId) return [];
  const { data } = await sb
    .schema('web').from('pages' as never)
    .select('id, path, title, template, status, is_home, sort_order')
    .eq('site_id', siteId).order('sort_order');
  return (data ?? []) as PageRow[];
}

export default async function AdminPages() {
  const pages = await loadPages();
  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Pages</h1>
      <div className="rounded-xl border border-slate-200 bg-white overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-slate-500">
            <tr>
              <th className="text-left px-4 py-3 font-medium">Title</th>
              <th className="text-left px-4 py-3 font-medium">Path</th>
              <th className="text-left px-4 py-3 font-medium">Template</th>
              <th className="text-left px-4 py-3 font-medium">Status</th>
            </tr>
          </thead>
          <tbody>
            {pages.map((p) => (
              <tr key={p.id} className="border-t border-slate-100">
                <td className="px-4 py-3 font-medium text-slate-900">
                  {p.title}{p.is_home && <span className="ml-2 text-xs text-emerald-600">HOME</span>}
                </td>
                <td className="px-4 py-3 text-slate-500">{p.path}</td>
                <td className="px-4 py-3 text-slate-500">{p.template}</td>
                <td className="px-4 py-3">
                  <span className={p.status === 'published' ? 'text-emerald-600' : 'text-slate-400'}>{p.status}</span>
                </td>
              </tr>
            ))}
            {!pages.length && <tr><td colSpan={4} className="px-4 py-8 text-center text-slate-400">No pages yet</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}