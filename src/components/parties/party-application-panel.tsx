// src/components/parties/party-application-panel.tsx
// Party detail: application / inquiry forms for this party.
//   - lists existing application_forms with progress
//   - "New from template": pick a form_type -> POST /api/applications/from-template
//     which generates canonical fields and auto-binds answer_library variants
//   - each form links to the /applications/[formId] editor (Copy next mode lives there)

'use client';

import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { toast } from 'sonner';
import { ClipboardList, Plus, ExternalLink, Loader2 } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import {
  TEMPLATE_FORM_TYPES,
  type TemplateFormType,
} from '@/lib/applications/canonical-templates';

type ViewRow = {
  form_id: string;
  form_url: string;
  form_status: string;
  form_type: string | null;
  deadline: string | null;
  submission_method: string | null;
  field_id: string | null;
  field_state: string | null;
  is_copied: boolean | null;
};

type FormSummary = {
  formId: string;
  formUrl: string;
  status: string;
  formType: string;
  deadline: string | null;
  total: number;
  ok: number;
  copied: number;
};

interface Props {
  partyId: string;
  partyType: string;
  contactMethod: string | null;
  contactFormUrl: string | null;
}

const STATUS_COLORS: Record<string, string> = {
  not_started: 'bg-muted text-muted-foreground',
  drafting: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300',
  ready: 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
  submitted:
    'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300',
  decided: 'bg-slate-200 text-slate-700 dark:bg-slate-800 dark:text-slate-300',
};

export function PartyApplicationPanel({
  partyId,
  partyType,
  contactMethod,
  contactFormUrl,
}: Props) {
  const router = useRouter();
  const [forms, setForms] = useState<FormSummary[] | null>(null);
  const [creating, setCreating] = useState(false);
  const [showNew, setShowNew] = useState(false);

  // sensible default: mills get contact_inquiry, everyone else an application
  const defaultType: TemplateFormType =
    partyType === 'paper_mill' || partyType === 'filler_supplier'
      ? 'contact_inquiry'
      : 'application';
  const [formType, setFormType] = useState<TemplateFormType>(defaultType);
  const [formUrl, setFormUrl] = useState(contactFormUrl ?? '');

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch(`/api/applications?party_id=${partyId}`);
        if (!res.ok) throw new Error(await res.text());
        const rows = (await res.json()) as ViewRow[];
        if (cancelled) return;
        const byForm = new Map<string, FormSummary>();
        for (const r of rows) {
          let f = byForm.get(r.form_id);
          if (!f) {
            f = {
              formId: r.form_id,
              formUrl: r.form_url,
              status: r.form_status,
              formType: r.form_type ?? 'application',
              deadline: r.deadline,
              total: 0,
              ok: 0,
              copied: 0,
            };
            byForm.set(r.form_id, f);
          }
          if (r.field_id) {
            f.total += 1;
            if (r.field_state === 'ok') f.ok += 1;
            if (r.is_copied) f.copied += 1;
          }
        }
        setForms(Array.from(byForm.values()));
      } catch (err) {
        console.error('[party-application-panel] fetch failed:', err);
        if (!cancelled) setForms([]);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [partyId]);

  const createFromTemplate = async () => {
    if (!formUrl.trim()) {
      toast.error('Form URL is required');
      return;
    }
    setCreating(true);
    try {
      const res = await fetch('/api/applications/from-template', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          party_id: partyId,
          form_type: formType,
          form_url: formUrl.trim(),
          submission_method: contactMethod === 'portal' ? 'portal' : 'web_form',
        }),
      });
      const data = (await res.json()) as {
        form_id?: string;
        fields?: number;
        bound?: number;
        unbound_keys?: string[];
        error?: string;
      };
      if (!res.ok || !data.form_id) throw new Error(data.error ?? 'failed');
      toast.success(
        `Form created: ${data.fields ?? 0} fields, ${data.bound ?? 0} answers bound`,
      );
      if ((data.unbound_keys ?? []).length > 0) {
        toast.warning(`No library answer for: ${data.unbound_keys!.join(', ')}`);
      }
      router.push(`/applications/${data.form_id}`);
    } catch (err) {
      console.error(err);
      toast.error('Failed to create the application form');
      setCreating(false);
    }
  };

  const sorted = useMemo(
    () =>
      (forms ?? []).sort((a, b) => {
        if (!a.deadline && !b.deadline) return 0;
        if (!a.deadline) return 1;
        if (!b.deadline) return -1;
        return a.deadline.localeCompare(b.deadline);
      }),
    [forms],
  );

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm flex items-center justify-between gap-2">
          <span className="inline-flex items-center gap-2">
            <ClipboardList className="h-4 w-4 text-muted-foreground" />
            Applications &amp; Forms
          </span>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setShowNew((v) => !v)}
            disabled={creating}
          >
            <Plus className="h-3.5 w-3.5" />
            New from template
          </Button>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        {showNew && (
          <div className="rounded-md border p-3 space-y-2 bg-muted/30">
            <div className="flex flex-wrap items-center gap-2">
              <select
                value={formType}
                onChange={(e) => setFormType(e.target.value as TemplateFormType)}
                className="rounded-md border px-2 py-1.5 text-sm bg-background"
                disabled={creating}
              >
                {TEMPLATE_FORM_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </select>
              <input
                type="url"
                value={formUrl}
                onChange={(e) => setFormUrl(e.target.value)}
                placeholder="https://... (application form URL)"
                className="flex-1 min-w-[220px] rounded-md border px-2 py-1.5 text-sm bg-background"
                disabled={creating}
              />
              <Button size="sm" onClick={() => void createFromTemplate()} disabled={creating}>
                {creating && <Loader2 className="h-3.5 w-3.5 animate-spin" />}
                Generate
              </Button>
            </div>
            <p className="text-xs text-muted-foreground">
              Generates the standard question set for this form type and binds the
              best-length answer from the library to each field.
            </p>
          </div>
        )}

        {forms === null ? (
          <p className="text-sm text-muted-foreground">Loading…</p>
        ) : sorted.length === 0 ? (
          <p className="text-sm text-muted-foreground">
            No application forms yet
            {contactMethod === 'web_form' || contactMethod === 'portal'
              ? ' — this party accepts submissions via a form, create one from a template above.'
              : '.'}
          </p>
        ) : (
          <ul className="space-y-2">
            {sorted.map((f) => (
              <li
                key={f.formId}
                className="flex flex-wrap items-center gap-x-3 gap-y-1 rounded-md border px-3 py-2"
              >
                <span
                  className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                    STATUS_COLORS[f.status] ?? 'bg-muted text-muted-foreground'
                  }`}
                >
                  {f.status.replace(/_/g, ' ')}
                </span>
                <span className="text-xs text-muted-foreground capitalize">
                  {f.formType.replace(/_/g, ' ')}
                </span>
                {f.deadline && (
                  <span className="text-xs text-muted-foreground">
                    deadline {f.deadline}
                  </span>
                )}
                <span className="text-xs text-muted-foreground">
                  {f.ok}/{f.total} ok · {f.copied}/{f.total} copied
                </span>
                <span className="ml-auto inline-flex items-center gap-2">
                  <a
                    href={f.formUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-muted-foreground hover:text-foreground"
                    title={f.formUrl}
                  >
                    <ExternalLink className="h-3.5 w-3.5" />
                  </a>
                  <Button asChild variant="outline" size="sm">
                    <Link href={`/applications/${f.formId}`}>Open application</Link>
                  </Button>
                </span>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}
