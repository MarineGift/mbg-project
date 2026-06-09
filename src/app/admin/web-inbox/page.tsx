// src/app/admin/web-inbox/page.tsx
// Integrated inbox in the CRM. One table for every site's submissions with a
// site filter. Reply UI (Phase 3) opens a composer wired to replyToSubmission.
// Guard this route with your existing CRM auth/RBAC.

import { listSubmissions } from '@/lib/web/inbox';

export const dynamic = 'force-dynamic';

export default async function WebInboxPage(
  { searchParams }: { searchParams: { site?: string; status?: string; q?: string } },
) {
  const rows = await listSubmissions({
    site_id: searchParams.site,
    status: searchParams.status,
    search: searchParams.q,
    limit: 200,
  });

  const counts = rows.reduce<Record<string, number>>((acc, r) => {
    acc[r.site_name] = (acc[r.site_name] ?? 0) + 1;
    return acc;
  }, {});

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold text-slate-800">Web Inbox</h1>
      <p className="mt-1 text-sm text-slate-500">
        {rows.length} submissions across {Object.keys(counts).length} sites
      </p>

      <div className="mt-3 flex flex-wrap gap-2 text-sm">
        {Object.entries(counts).map(([name, n]) => (
          <span key={name} className="rounded-full bg-slate-100 px-3 py-1">
            {name}: {n}
          </span>
        ))}
      </div>

      <div className="mt-6 overflow-x-auto rounded-lg border border-slate-200">
        <table className="w-full text-left text-sm">
          <thead className="bg-slate-50 text-slate-600">
            <tr>
              <th className="px-4 py-2">Site</th>
              <th className="px-4 py-2">Name</th>
              <th className="px-4 py-2">Email</th>
              <th className="px-4 py-2">Interest</th>
              <th className="px-4 py-2">Message</th>
              <th className="px-4 py-2">Status</th>
              <th className="px-4 py-2">When</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.id} className="border-t border-slate-100 align-top hover:bg-slate-50">
                <td className="px-4 py-2 font-medium">{r.site_name}</td>
                <td className="px-4 py-2">{r.name ?? '-'}</td>
                <td className="px-4 py-2 text-slate-600">{r.email ?? '-'}</td>
                <td className="px-4 py-2">{r.interest ?? '-'}</td>
                <td className="max-w-xs truncate px-4 py-2 text-slate-600" title={r.message ?? ''}>
                  {r.message ?? '-'}
                </td>
                <td className="px-4 py-2">
                  <span className={
                    r.status === 'new' ? 'rounded-full bg-emerald-100 px-2 py-0.5 text-emerald-700'
                    : r.status === 'replied' ? 'rounded-full bg-blue-100 px-2 py-0.5 text-blue-700'
                    : 'rounded-full bg-slate-100 px-2 py-0.5 text-slate-600'
                  }>
                    {r.status}
                  </span>
                </td>
                <td className="px-4 py-2 text-slate-500">
                  {new Date(r.created_at).toLocaleString()}
                </td>
              </tr>
            ))}
            {!rows.length && (
              <tr><td colSpan={7} className="px-4 py-8 text-center text-slate-400">No submissions yet.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
