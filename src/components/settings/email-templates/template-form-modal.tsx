'use client';

import { useState, useEffect, useTransition } from 'react';
import type { EmailTemplate } from '@/lib/queries/email-templates';
import {
  createEmailTemplate,
  updateEmailTemplate,
  type TemplateInput,
} from '@/lib/actions/email-templates';

const MODULES = ['investor', 'paper_mill', 'partner', 'customer', 'filler_supplier'] as const;
type ModuleValue = (typeof MODULES)[number] | '';

const STAGE_OPTIONS: Record<string, { code: string; label: string }[]> = {
  investor: [
    { code: 'cold_outreach', label: 'Cold outreach' },
    { code: 'reply_received', label: 'Reply received' },
    { code: 'first_meeting', label: 'First meeting' },
    { code: 'due_diligence', label: 'Due diligence' },
    { code: 'followup_meeting', label: 'Follow-up meeting' },
    { code: 'term_sheet', label: 'Term sheet' },
    { code: 'contract', label: 'Contract' },
  ],
  paper_mill: [
    { code: 'lead', label: 'Lead' },
    { code: 'qualified', label: 'Qualified' },
    { code: 'sample_sent', label: 'Sample sent' },
    { code: 'trial_eval', label: 'Trial / Eval' },
    { code: 'quotation', label: 'Quotation' },
    { code: 'negotiation', label: 'Negotiation' },
    { code: 'won', label: 'Won' },
  ],
  filler_supplier: [
    { code: 'prospect', label: 'Prospect' },
    { code: 'contacted', label: 'Contacted' },
    { code: 'nda', label: 'NDA' },
    { code: 'lab_test', label: 'Lab test' },
    { code: 'evaluation', label: 'Evaluation' },
    { code: 'pilot', label: 'Pilot' },
    { code: 'royalty', label: 'Royalty Agreement' },
    { code: 'mass_production', label: 'Mass Production' },
  ],
};

interface Props {
  open: boolean;
  editing: EmailTemplate | null;
  onClose: () => void;
  onSaved: (template: EmailTemplate) => void;
}

export function TemplateFormModal({ open, editing, onClose, onSaved }: Props) {
  const [name, setName] = useState('');
  const [category, setCategory] = useState('');
  const [subject, setSubject] = useState('');
  const [bodyPlain, setBodyPlain] = useState('');
  const [bodyHtml, setBodyHtml] = useState('');
  const [moduleVal, setModuleVal] = useState<ModuleValue>('');
  const [stageVal, setStageVal] = useState('');
  const [isActive, setIsActive] = useState(true);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    if (!open) return;
    if (editing) {
      setName(editing.name);
      setCategory(editing.category ?? '');
      setSubject(editing.subject);
      setBodyPlain(editing.bodyPlain);
      setBodyHtml(editing.bodyHtml ?? '');
      setModuleVal((editing.module as ModuleValue) ?? '');
      setStageVal(editing.stageCode ?? '');
      setIsActive(editing.isActive);
    } else {
      setName('');
      setCategory('');
      setSubject('');
      setBodyPlain('');
      setBodyHtml('');
      setModuleVal('');
      setStageVal('');
      setIsActive(true);
    }
    setErrorMsg(null);
  }, [open, editing]);

  if (!open) return null;

  function handleSubmit() {
    setErrorMsg(null);
    const payload: TemplateInput = {
      name,
      category: category || null,
      subject,
      bodyPlain,
      bodyHtml: bodyHtml || null,
      module: (moduleVal || null) as TemplateInput['module'],
      stage_code: stageVal || null,
      isActive,
    };

    startTransition(async () => {
      const result = editing
        ? await updateEmailTemplate(editing.id, payload)
        : await createEmailTemplate(payload);

      if (!result.ok) {
        setErrorMsg(result.errorMessage);
        return;
      }

      const nowIso = new Date().toISOString();
      const saved: EmailTemplate = {
        id: result.data.id,
        organizationId: editing?.organizationId ?? '',
        name: name.trim(),
        category: category.trim() || null,
        subject: subject.trim(),
        bodyPlain,
        bodyHtml: bodyHtml.trim() || null,
        module: moduleVal || null,
        stageCode: stageVal || null,
        isActive,
        createdBy: editing?.createdBy ?? null,
        createdAt: editing?.createdAt ?? nowIso,
        updatedAt: nowIso,
      };
      onSaved(saved);
    });
  }

  const placeholderBody =
    'Hi {{contact_name}},\n\nI noticed that {{party_name}} ...\n\nBest regards';

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onClick={onClose}
    >
      <div
        className="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-lg bg-white shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="border-b border-gray-200 px-6 py-4">
          <h2 className="text-lg font-semibold text-gray-900">
            {editing ? 'Edit template' : 'Create template'}
          </h2>
        </div>

        <div className="space-y-4 px-6 py-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">Name *</label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              placeholder="e.g. Initial outreach"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Party type</label>
              <select
                value={moduleVal}
                onChange={(e) => { setModuleVal(e.target.value as ModuleValue); setStageVal(""); }}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              >
                <option value="">(none)</option>
                {MODULES.map((m) => (
                  <option key={m} value={m}>
                    {m}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Stage</label>
              <select
                value={stageVal}
                onChange={(e) => setStageVal(e.target.value)}
                disabled={!moduleVal || !STAGE_OPTIONS[moduleVal]}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 disabled:bg-gray-100 disabled:opacity-60"
              >
                <option value="">(none)</option>
                {(STAGE_OPTIONS[moduleVal] ?? []).map((st) => (
                  <option key={st.code} value={st.code}>
                    {st.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Category</label>
              <input
                type="text"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                placeholder="e.g. outreach, follow-up"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Subject *</label>
            <input
              type="text"
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              placeholder="e.g. Hello {{contact_name}}"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Body (plain text) *
            </label>
            <textarea
              value={bodyPlain}
              onChange={(e) => setBodyPlain(e.target.value)}
              rows={8}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 text-sm shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              placeholder={placeholderBody}
            />
            <p className="mt-1 text-xs text-gray-500">
              Use{' '}
              <code className="rounded bg-gray-100 px-1 py-0.5">
                {'{{contact_name}}'}
              </code>
              ,{' '}
              <code className="rounded bg-gray-100 px-1 py-0.5">
                {'{{party_name}}'}
              </code>{' '}
              etc. as placeholders.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">
              Body HTML (optional)
            </label>
            <textarea
              value={bodyHtml}
              onChange={(e) => setBodyHtml(e.target.value)}
              rows={4}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 font-mono text-xs shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
              placeholder="<p>Hi {{contact_name}},</p>..."
            />
          </div>

          <div className="flex items-center">
            <input
              type="checkbox"
              id="email-template-active"
              checked={isActive}
              onChange={(e) => setIsActive(e.target.checked)}
              className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <label
              htmlFor="email-template-active"
              className="ml-2 text-sm text-gray-700"
            >
              Active (available for use in sequences)
            </label>
          </div>

          {errorMsg && (
            <div className="rounded-md bg-red-50 p-3 text-sm text-red-800">
              {errorMsg}
            </div>
          )}
        </div>

        <div className="flex justify-end gap-2 border-t border-gray-200 bg-gray-50 px-6 py-3">
          <button
            type="button"
            onClick={onClose}
            disabled={isPending}
            className="rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={handleSubmit}
            disabled={isPending}
            className="rounded-md bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {isPending ? 'Saving...' : 'Save'}
          </button>
        </div>
      </div>
    </div>
  );
}
