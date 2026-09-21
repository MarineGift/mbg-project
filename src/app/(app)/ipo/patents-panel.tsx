// src/app/(app)/ipo/patents-panel.tsx
//
// Patent register (app.patents). Real numbers live only in the DB.
// Material patents with expected_expiration drive v_patent_horizon,
// the L4 gates and the material_patent_min_remaining_years KPI.

'use client';

import { useState } from 'react';
import { upsertPatent, deletePatent, type PatentInput } from './actions';

export type PatentRow = {
  id: string; family_code: string; family_role: string; jurisdiction: string; application_no: string | null;
  patent_no: string | null; title_short: string | null; assignment_status: string; recordation_date: string | null;
  priority_date: string | null; filing_date: string | null; grant_date: string | null; expected_expiration: string | null;
  status: string; is_material: boolean; royalty_weight: number | null; challenge_note: string | null; maintenance_next_due: string | null;
};
export type PublicationRow = {
  id: string; family_code: string | null; title: string; authors: string; venue: string; year: number;
  volume_pages: string | null; doi: string | null; published_on: string | null; key_finding: string | null; ir_use: string | null;
};
export type Horizon = {
  material_count: number; material_foundational: number; material_improvement: number;
  earliest_material_expiration: string | null; latest_material_expiration: string | null;
  min_remaining_years: number | null; weighted_remaining_years: number | null; unrecorded_material_count: number; opposed_count: number;
} | null;

const EMPTY = (programId: string): PatentInput => ({
  id: null, program_id: programId, family_code: '', family_role: 'foundational', jurisdiction: 'KR', application_no: '', patent_no: '',
  title_short: '', assignment_status: 'not_started', recordation_date: '', priority_date: '', filing_date: '', grant_date: '',
  expected_expiration: '', status: 'pending', is_material: true, royalty_weight: '', challenge_note: '', maintenance_next_due: '',
});
const toInput = (r: PatentRow, programId: string): PatentInput => ({
  id: r.id, program_id: programId, family_code: r.family_code, family_role: r.family_role, jurisdiction: r.jurisdiction,
  application_no: r.application_no ?? '', patent_no: r.patent_no ?? '', title_short: r.title_short ?? '', assignment_status: r.assignment_status,
  recordation_date: r.recordation_date ?? '', priority_date: r.priority_date ?? '', filing_date: r.filing_date ?? '', grant_date: r.grant_date ?? '',
  expected_expiration: r.expected_expiration ?? '', status: r.status, is_material: r.is_material,
  royalty_weight: r.royalty_weight == null ? '' : String(r.royalty_weight), challenge_note: r.challenge_note ?? '', maintenance_next_due: r.maintenance_next_due ?? '',
});

const ROLE_CLS: Record<string, string> = { foundational: 'bg-violet-100 text-violet-800', improvement: 'bg-sky-100 text-sky-800', application_specific: 'bg-slate-100 text-slate-700' };
const STATUS_CLS: Record<string, string> = { granted: 'bg-emerald-100 text-emerald-800', pending: 'bg-amber-100 text-amber-800', opposed: 'bg-red-100 text-red-800' };
const yrs = (d: string | null) => d ? ((new Date(d).getTime() - Date.now()) / 31557600000).toFixed(1) : '—';

function Field({ label, children, span }: { label: string; children: React.ReactNode; span?: number }) {
  return <label className={'flex flex-col gap-1 text-xs' + (span ? ` sm:col-span-${span}` : '')}><span className="text-muted-foreground">{label}</span>{children}</label>;
}
const inp = 'h-8 rounded border bg-background px-2 text-sm';

export function PatentsPanel({ patents, horizon, programId, publications = [] }: { patents: PatentRow[]; horizon: Horizon; programId: string; publications?: PublicationRow[] }) {
  const [form, setForm] = useState<PatentInput | null>(null);
  const [msg, setMsg] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const set = (k: keyof PatentInput, v: string | boolean) => setForm((f) => (f ? { ...f, [k]: v } : f));

  const save = async () => {
    if (!form) return; setBusy(true);
    const r = await upsertPatent(form); setBusy(false);
    setMsg(r.ok ? 'Saved' : r.error); if (r.ok) setForm(null);
  };
  const remove = async (id: string) => {
    if (!confirm('Delete this patent record?')) return;
    setBusy(true); const r = await deletePatent(id); setBusy(false); setMsg(r.ok ? 'Deleted' : r.error);
  };

  return (
    <div className="flex flex-col gap-4">
      <section className="rounded-md border p-4">
        <h2 className="mb-2 text-sm font-semibold">Patent horizon (material only)</h2>
        {!horizon || horizon.material_count === 0 ? (
          <p className="text-xs text-muted-foreground">No material patents yet. Add the FCC families below; L4 gates and the patent-life KPI derive from them.</p>
        ) : (
          <dl className="grid grid-cols-2 gap-x-4 gap-y-1 text-sm sm:grid-cols-4">
            <dt className="text-muted-foreground">Material patents</dt><dd className="font-medium">{horizon.material_count} <span className="text-xs text-muted-foreground">({horizon.material_foundational} foundational · {horizon.material_improvement} improvement/other)</span></dd>
            <dt className="text-muted-foreground">Min. remaining life</dt><dd className={'font-medium ' + ((horizon.min_remaining_years ?? 99) < 10 ? 'text-amber-700' : '')}>{horizon.min_remaining_years ?? '—'} yrs</dd>
            <dt className="text-muted-foreground">Earliest expiration</dt><dd className="font-medium">{horizon.earliest_material_expiration ?? '—'}</dd>
            <dt className="text-muted-foreground">Latest expiration</dt><dd className="font-medium">{horizon.latest_material_expiration ?? '—'}</dd>
            <dt className="text-muted-foreground">Weighted life</dt><dd className="font-medium">{horizon.weighted_remaining_years ?? '— (set royalty_weight on every material patent)'}</dd>
            <dt className="text-muted-foreground">Unrecorded material</dt><dd className={'font-medium ' + (horizon.unrecorded_material_count > 0 ? 'text-red-600' : '')}>{horizon.unrecorded_material_count}</dd>
            <dt className="text-muted-foreground">Opposed</dt><dd className="font-medium">{horizon.opposed_count}</dd>
          </dl>
        )}
      </section>

      <section className="rounded-md border p-4">
        <div className="mb-2 flex items-center gap-3">
          <h2 className="text-sm font-semibold">Patent register</h2>
          <span className="text-xs text-muted-foreground">{patents.length} records</span>
          <button type="button" className="ml-auto rounded bg-foreground px-3 py-1 text-xs text-background" onClick={() => { setForm(EMPTY(programId)); setMsg(null); }}>+ Add patent</button>
          {msg && <span className="text-xs text-muted-foreground">{msg}</span>}
        </div>

        {form && (
          <form className="mb-4 grid gap-2 rounded-md border bg-muted/30 p-3 sm:grid-cols-4" onSubmit={(e) => { e.preventDefault(); void save(); }}>
            <Field label="Family code"><input required className={inp} value={form.family_code} onChange={(e) => set('family_code', e.target.value)} placeholder="FCC-BASE / FCC-UPG-01" /></Field>
            <Field label="Family role"><select className={inp} value={form.family_role} onChange={(e) => set('family_role', e.target.value)}><option value="foundational">foundational</option><option value="improvement">improvement</option><option value="application_specific">application_specific</option></select></Field>
            <Field label="Jurisdiction"><input required className={inp} value={form.jurisdiction} onChange={(e) => set('jurisdiction', e.target.value)} placeholder="KR / US / EP / JP" /></Field>
            <Field label="Status"><select className={inp} value={form.status} onChange={(e) => set('status', e.target.value)}>{['pending', 'granted', 'opposed', 'lapsed', 'expired', 'abandoned'].map((s) => <option key={s} value={s}>{s}</option>)}</select></Field>
            <Field label="Application no."><input className={inp} value={form.application_no} onChange={(e) => set('application_no', e.target.value)} /></Field>
            <Field label="Patent no."><input className={inp} value={form.patent_no} onChange={(e) => set('patent_no', e.target.value)} /></Field>
            <Field label="Short title" span={2}><input className={inp} value={form.title_short} onChange={(e) => set('title_short', e.target.value)} /></Field>
            <Field label="Priority date"><input type="date" className={inp} value={form.priority_date} onChange={(e) => set('priority_date', e.target.value)} /></Field>
            <Field label="Filing date"><input type="date" className={inp} value={form.filing_date} onChange={(e) => set('filing_date', e.target.value)} /></Field>
            <Field label="Grant date"><input type="date" className={inp} value={form.grant_date} onChange={(e) => set('grant_date', e.target.value)} /></Field>
            <Field label="Expected expiration"><input type="date" className={inp} value={form.expected_expiration} onChange={(e) => set('expected_expiration', e.target.value)} /></Field>
            <Field label="Assignment to MBG Inc."><select className={inp} value={form.assignment_status} onChange={(e) => set('assignment_status', e.target.value)}>{['not_started', 'executed', 'recorded', 'not_required'].map((s) => <option key={s} value={s}>{s}</option>)}</select></Field>
            <Field label="Recordation date"><input type="date" className={inp} value={form.recordation_date} onChange={(e) => set('recordation_date', e.target.value)} /></Field>
            <Field label="Maintenance next due"><input type="date" className={inp} value={form.maintenance_next_due} onChange={(e) => set('maintenance_next_due', e.target.value)} /></Field>
            <Field label="Royalty weight (optional)"><input type="number" step="any" min="0" className={inp} value={form.royalty_weight} onChange={(e) => set('royalty_weight', e.target.value)} /></Field>
            <Field label="Challenge / opposition note" span={3}><input className={inp} value={form.challenge_note} onChange={(e) => set('challenge_note', e.target.value)} placeholder="EPO TPO filed 2026-08-13; JP opposition due 2026-10-27" /></Field>
            <label className="flex items-center gap-2 self-end text-xs"><input type="checkbox" checked={form.is_material} onChange={(e) => set('is_material', e.target.checked)} /> Material (covers the licensed process)</label>
            <div className="flex items-center gap-2 sm:col-span-4">
              <button type="submit" disabled={busy} className="rounded bg-foreground px-3 py-1 text-xs text-background disabled:opacity-50">{form.id ? 'Update' : 'Save'}</button>
              <button type="button" className="rounded border px-3 py-1 text-xs" onClick={() => setForm(null)}>Cancel</button>
            </div>
          </form>
        )}

        {patents.length === 0 ? <p className="text-xs text-muted-foreground">Empty.</p> : (
          <div className="overflow-x-auto">
            <table className="w-full text-xs">
              <thead className="text-muted-foreground"><tr>
                <th className="text-left">Family</th><th>Role</th><th>Jur.</th><th className="text-left">Application / Patent</th><th>Status</th><th>Expires</th><th>Left</th><th>Assignment</th><th>Material</th><th>Weight</th><th></th>
              </tr></thead>
              <tbody>{patents.map((p) => (
                <tr key={p.id} className="border-t">
                  <td className="py-1">{p.family_code}{p.title_short && <div className="text-[11px] text-muted-foreground">{p.title_short}</div>}</td>
                  <td className="text-center"><span className={'rounded px-1.5 ' + (ROLE_CLS[p.family_role] ?? '')}>{p.family_role}</span></td>
                  <td className="text-center">{p.jurisdiction}</td>
                  <td>{p.application_no ?? '—'}{p.patent_no && <> / <b>{p.patent_no}</b></>}{p.challenge_note && <div className="text-[11px] text-amber-700">{p.challenge_note}</div>}</td>
                  <td className="text-center"><span className={'rounded px-1.5 ' + (STATUS_CLS[p.status] ?? 'bg-muted')}>{p.status}</span></td>
                  <td className="text-center">{p.expected_expiration ?? '—'}</td>
                  <td className="text-center">{yrs(p.expected_expiration)}</td>
                  <td className={'text-center ' + (p.is_material && p.assignment_status !== 'recorded' && p.assignment_status !== 'not_required' ? 'text-red-600' : '')}>{p.assignment_status}{p.recordation_date && <div className="text-[11px] text-muted-foreground">{p.recordation_date}</div>}</td>
                  <td className="text-center">{p.is_material ? '●' : ''}</td>
                  <td className="text-center">{p.royalty_weight ?? '—'}</td>
                  <td className="whitespace-nowrap text-right">
                    <button type="button" className="rounded border px-2 py-0.5" onClick={() => { setForm(toInput(p, programId)); setMsg(null); }}>Edit</button>
                    <button type="button" className="ml-1 rounded border px-2 py-0.5 text-red-700" onClick={() => void remove(p.id)}>Del</button>
                  </td>
                </tr>
              ))}</tbody>
            </table>
          </div>
        )}
        <p className="mt-2 text-xs text-muted-foreground">Investors should see foundational and improvement families separately; the remaining life of the oldest foundational patent alone misstates the IP position.</p>
      </section>

      <section className="rounded-md border p-4">
        <h2 className="mb-2 text-sm font-semibold">Peer-reviewed publications <span className="ml-2 text-xs font-normal text-muted-foreground">{publications.length} papers · entered via SQL (public data)</span></h2>
        {publications.length === 0 ? <p className="text-xs text-muted-foreground">None yet.</p> : (
          <ul className="flex flex-col gap-3">
            {publications.map((pub) => (
              <li key={pub.id} className="border-t pt-2 text-sm first:border-t-0 first:pt-0">
                <div className="font-medium">{pub.title}</div>
                <div className="text-xs text-muted-foreground">
                  {pub.authors} · <i>{pub.venue}</i> {pub.year}{pub.volume_pages && <>, {pub.volume_pages}</>}
                  {pub.doi && <> · <a className="underline" href={`https://doi.org/${pub.doi}`} target="_blank" rel="noreferrer">doi:{pub.doi}</a></>}
                  {pub.family_code && <> · <span className="rounded bg-muted px-1">{pub.family_code}</span></>}
                </div>
                {pub.key_finding && <p className="mt-1 text-xs">{pub.key_finding}</p>}
                {pub.ir_use && <p className="mt-1 text-xs text-muted-foreground">Use: {pub.ir_use}</p>}
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
