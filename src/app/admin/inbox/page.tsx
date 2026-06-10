import Link from 'next/link';
import { webAdminClient } from '../web-admin-client';

export const dynamic = 'force-dynamic';

interface Submission {
  id: string; form_type: string; name: string; email: string;
  company: string | null; message: string; status: string; created_at: string;
}

const statusColors: Record<string, string> = {
  new: 'bg-blue-100 text-blue-800',
  read: 'bg-gray-100 text-gray-800',
  replied: 'bg-green-100 text-green-800',
  archived: 'bg-slate-100 text-slate-600',
  spam: 'bg-red-100 text-red-800',
};

async function loadSubmissions(): Promise<Submission[]> {
  const sb = webAdminClient();
  const { data } = await sb
    .schema('web').from('submissions' as never)
    .select('id, form_type, name, email, company, message, status, created_at')
    .order('created_at', { ascending: false }).limit(100);
  return (data ?? []) as Submission[];
}

export default async function AdminInbox() {
  const subs = await loadSubmissions();
  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-900 mb-6">Inbox</h1>
      <div className="space-y-2">
        {subs.map((s) => (
          <Link key={s.id} href={`/admin/inbox/${s.id}`} className="block rounded-lg border border-slate-200 bg-white p-4 hover:shadow-sm transition">
            <div className="flex items-center justify-between">
              <div className="font-medium text-slate-900">{s.name}</div>
              <span className={`text-xs px-2 py-0.5 rounded-full ${statusColors[s.status] ?? 'bg-gray-100'}`}>{s.status}</span>
            </div>
            <div className="text-sm text-slate-500">{s.email}{s.company ? ` - ${s.company}` : ''}</div>
            <div className="text-sm text-slate-600 mt-1 line-clamp-1">{s.message}</div>
            <div className="text-xs text-slate-400 mt-1">{new Date(s.created_at).toLocaleString()}</div>
          </Link>
        ))}
        {!subs.length && <div className="rounded-lg border border-slate-200 bg-white p-8 text-center text-slate-400">No submissions yet</div>}
      </div>
    </div>
  );
}