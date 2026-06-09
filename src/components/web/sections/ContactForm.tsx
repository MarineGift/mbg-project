'use client';
// src/components/web/sections/ContactForm.tsx
// Config-driven lead form. Which fields show and the interest options come
// from section.config, so every site reuses one component. Submissions land
// in web.submissions (the integrated admin inbox).

import { useState, useTransition } from 'react';
import type { SectionProps } from '../SectionRenderer';
import { submitForm } from '../actions';

interface ContactConfig {
  title?: string;
  fields?: string[];           // subset of name,email,company,phone,interest,message
  interests?: string[];
  form_type?: string;
}

const LABELS: Record<string, string> = {
  name: 'Name', email: 'Email', company: 'Company',
  phone: 'Phone', message: 'Message',
};

export function ContactForm({ section, site, page }: SectionProps) {
  const cfg = section.config as ContactConfig;
  const fields = cfg.fields ?? ['name', 'email', 'message'];
  const [vals, setVals] = useState<Record<string, string>>({});
  const [hp, setHp] = useState('');
  const [done, setDone] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [pending, start] = useTransition();

  const set = (k: string, v: string) => setVals((s) => ({ ...s, [k]: v }));

  const onSubmit = () => {
    setErr(null);
    start(async () => {
      const res = await submitForm({
        site_id: site.id,
        page_id: page.id,
        form_type: cfg.form_type ?? 'contact',
        name: vals.name,
        email: vals.email,
        phone: vals.phone,
        company: vals.company,
        interest: vals.interest,
        message: vals.message,
        data: vals,
        _hp: hp,
      });
      if (res.ok) setDone(true);
      else setErr(res.error ?? 'Something went wrong');
    });
  };

  if (done) {
    return (
      <section id="contact" className="mx-auto max-w-xl px-6 py-20 text-center">
        <h2 className="text-2xl font-bold text-slate-800">Thank you</h2>
        <p className="mt-3 text-slate-600">
          Your message has been received. We will be in touch shortly.
        </p>
      </section>
    );
  }

  return (
    <section id="contact" className="mx-auto max-w-xl px-6 py-20">
      {cfg.title && (
        <h2 className="mb-8 text-center text-3xl font-bold text-slate-800">
          {cfg.title}
        </h2>
      )}
      <div className="space-y-4">
        {/* honeypot */}
        <input
          type="text" tabIndex={-1} autoComplete="off"
          value={hp} onChange={(e) => setHp(e.target.value)}
          className="hidden" aria-hidden="true"
        />

        {fields.filter((f) => f !== 'interest' && f !== 'message').map((f) => (
          <div key={f}>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              {LABELS[f] ?? f}
            </label>
            <input
              type={f === 'email' ? 'email' : 'text'}
              value={vals[f] ?? ''}
              onChange={(e) => set(f, e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 focus:border-[var(--site-accent)] focus:outline-none"
            />
          </div>
        ))}

        {fields.includes('interest') && (
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              Area of Interest
            </label>
            <select
              value={vals.interest ?? ''}
              onChange={(e) => set('interest', e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2"
            >
              <option value="">Select your interest</option>
              {(cfg.interests ?? []).map((o) => (
                <option key={o} value={o}>{o}</option>
              ))}
            </select>
          </div>
        )}

        {fields.includes('message') && (
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              Message
            </label>
            <textarea
              rows={5} maxLength={500}
              value={vals.message ?? ''}
              onChange={(e) => set('message', e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 focus:border-[var(--site-accent)] focus:outline-none"
            />
          </div>
        )}

        {err && <p className="text-sm text-red-600">{err}</p>}

        <button
          onClick={onSubmit}
          disabled={pending}
          className="w-full rounded-lg px-4 py-3 font-semibold text-white disabled:opacity-60"
          style={{ background: 'var(--site-primary)' }}
        >
          {pending ? 'Sending...' : 'Send Message'}
        </button>
      </div>
    </section>
  );
}
