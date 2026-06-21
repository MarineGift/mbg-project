'use client';
// src/components/settings/sequence-form-dialog.tsx

import { useState, useEffect, useTransition } from 'react';
import { listMailAccountOptions, type MailAccountOption } from '@/lib/actions/mail-account-options';
import { setSequenceFromAccount } from '@/lib/actions/sequence-sender';
import { createSequence, updateSequence } from '@/lib/actions/email-sequences';
import { SequenceSenderPreview } from './sequence-sender-preview';
import type { EmailSequenceWithSteps, StepDraft } from '@/types/phase21b';

interface Props {
  open:       boolean;
  onClose:    () => void;
  orgId:      string;
  initial?:   EmailSequenceWithSteps;
}

const DEFAULT_STEPS: StepDraft[] = [
  { step_order: 0, day_offset: 0, subject: '', body_plain: '' },
  { step_order: 1, day_offset: 3, subject: '', body_plain: '' },
  { step_order: 2, day_offset: 7, subject: '', body_plain: '' },
];

const MERGE_FIELDS = [
  '{{party.name}}', '{{party.countryCode}}', '{{party.website}}',
  '{{contact.fullName}}', '{{contact.firstName}}', '{{contact.email}}',
  '{{my.name}}', '{{my.email}}',
];

export function SequenceFormDialog({ open, onClose, orgId, initial }: Props) {
  const [name,        setName]        = useState(initial?.name        ?? '');
  const [description, setDescription] = useState(initial?.description ?? '');
  const [steps,       setSteps]       = useState<StepDraft[]>(
    initial?.steps.length
      ? initial.steps.map(s => ({ ...s }))
      : DEFAULT_STEPS,
  );
  const [error,       setError]       = useState<string | null>(null);
  const [isPending,   startTransition] = useTransition();

  // Sender (From account) for NEW sequences. Existing sequences use
  // SequenceSenderPreview below (which saves from_account_id inline).
  const [accounts,    setAccounts]    = useState<MailAccountOption[]>([]);
  const [fromId,      setFromId]      = useState<string>(''); // '' = org default account

  useEffect(() => {
    if (initial?.id) return; // edit mode handles the sender via SequenceSenderPreview
    let alive = true;
    (async () => {
      const opt = await listMailAccountOptions();
      if (alive && opt.ok) setAccounts(opt.accounts);
    })();
    return () => { alive = false; };
  }, [initial?.id]);

  if (!open) return null;

  // ── Step helpers ────────────────────────────────────────────
  function addStep() {
    const lastOffset = steps.at(-1)?.day_offset ?? 0;
    setSteps(prev => [
      ...prev,
      { step_order: prev.length, day_offset: lastOffset + 3, subject: '', body_plain: '' },
    ]);
  }

  function removeStep(index: number) {
    setSteps(prev =>
      prev.filter((_, i) => i !== index).map((s, i) => ({ ...s, step_order: i })),
    );
  }

  function updateStep(index: number, field: keyof StepDraft, value: string | number) {
    setSteps(prev =>
      prev.map((s, i) => (i === index ? { ...s, [field]: value } : s)),
    );
  }

  function moveStep(index: number, dir: -1 | 1) {
    const next = index + dir;
    if (next < 0 || next >= steps.length) return;
    setSteps(prev => {
      const arr = [...prev];
      [arr[index], arr[next]] = [arr[next]!, arr[index]!];
      return arr.map((s, i) => ({ ...s, step_order: i }));
    });
  }

  // ── Submit ──────────────────────────────────────────────────
  function handleSubmit() {
    if (!name.trim())         { setError('Sequence name is required.');       return; }
    if (steps.length === 0)   { setError('Add at least one step.');           return; }
    const hasEmpty = steps.some(s => !s.subject.trim() || !s.body_plain.trim());
    if (hasEmpty)             { setError('All steps need a subject and body.'); return; }

    setError(null);
    startTransition(async () => {
      const draft = { name, description, steps };
      const result = initial
        ? await updateSequence(initial.id, draft)
        : await createSequence(orgId, draft);

      if ('error' in result && result.error) {
        setError(result.error);
      } else {
        // New sequence: persist the chosen From account (edit mode saves it inline).
        if (!initial && 'id' in result && result.id) {
          await setSequenceFromAccount(result.id, fromId || null);
        }
        onClose();
      }
    });
  }

  // ── Render ──────────────────────────────────────────────────
  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center bg-black/40 overflow-y-auto py-10">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-2xl mx-4">

        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b">
          <h2 className="text-lg font-semibold text-gray-900">
            {initial ? 'Edit Sequence' : 'New Sequence'}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-xl leading-none">×</button>
        </div>

        <div className="px-6 py-5 space-y-5">

          {/* Name + Description */}
          <div className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Sequence Name <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder="e.g. Cold Outreach — Paper Mills"
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
              <input
                type="text"
                value={description}
                onChange={e => setDescription(e.target.value)}
                placeholder="Optional internal note"
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>

          {/* Sender (From account) for NEW sequences (edit mode uses the preview below) */}
          {!initial?.id && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">From (sender)</label>
              <select
                value={fromId}
                onChange={e => setFromId(e.target.value)}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">Org default account</option>
                {accounts.map(a => (
                  <option key={a.id} value={a.id}>
                    {(a.displayName ? `${a.displayName} (${a.address})` : a.address) + (a.isDefault ? ' (default)' : '')}
                  </option>
                ))}
              </select>
              <p className="mt-1 text-xs text-gray-400">You can change this later when editing the sequence.</p>
            </div>
          )}

          {/* Sender + send-document preview (existing sequences only) */}
          {initial?.id && (
            <SequenceSenderPreview
              sequenceId={initial.id}
              orgId={orgId}
              steps={steps}
            />
          )}

          {/* Steps */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-semibold text-gray-900">
                Steps
                <span className="ml-2 text-xs font-normal text-gray-400">
                  ({steps.length} step{steps.length !== 1 ? 's' : ''})
                </span>
              </h3>
              <button
                onClick={addStep}
                className="text-xs font-medium text-blue-600 hover:text-blue-800 flex items-center gap-1"
              >
                + Add Step
              </button>
            </div>

            <div className="space-y-0">
              {steps.map((step, i) => (
                <div key={i} className="flex gap-0">
                  {/* Timeline line */}
                  <div className="flex flex-col items-center w-8 flex-shrink-0">
                    <div className="w-3 h-3 rounded-full bg-blue-500 mt-5 z-10 flex-shrink-0" />
                    {i < steps.length - 1 && (
                      <div className="w-0.5 flex-1 bg-blue-200 mt-0" />
                    )}
                  </div>

                  {/* Step card */}
                  <div className="flex-1 border border-gray-200 rounded-lg p-4 mb-3 bg-gray-50">
                    <div className="flex items-center justify-between mb-3">
                      {/* Day badge */}
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-semibold text-blue-700 bg-blue-100 px-2 py-0.5 rounded-full">
                          Day
                        </span>
                        <input
                          type="number"
                          min={0}
                          max={365}
                          value={step.day_offset}
                          onChange={e => updateStep(i, 'day_offset', Number(e.target.value))}
                          className="w-16 border border-gray-300 rounded px-2 py-0.5 text-sm text-center focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                        <span className="text-xs text-gray-500">after enrollment</span>
                      </div>
                      {/* Step actions */}
                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => moveStep(i, -1)}
                          disabled={i === 0}
                          className="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30"
                          title="Move up"
                        >↑</button>
                        <button
                          onClick={() => moveStep(i, 1)}
                          disabled={i === steps.length - 1}
                          className="p-1 text-gray-400 hover:text-gray-600 disabled:opacity-30"
                          title="Move down"
                        >↓</button>
                        {steps.length > 1 && (
                          <button
                            onClick={() => removeStep(i)}
                            className="p-1 text-red-400 hover:text-red-600 text-xs font-medium ml-1"
                            title="Remove step"
                          >Remove</button>
                        )}
                      </div>
                    </div>

                    <div className="space-y-2">
                      <input
                        type="text"
                        value={step.subject}
                        onChange={e => updateStep(i, 'subject', e.target.value)}
                        placeholder="Subject line"
                        className="w-full border border-gray-300 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                      <textarea
                        value={step.body_plain}
                        onChange={e => updateStep(i, 'body_plain', e.target.value)}
                        placeholder={`Hi {{contact.firstName}},\n\nI wanted to reach out about...`}
                        rows={4}
                        className="w-full border border-gray-300 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 resize-y font-mono"
                      />
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Merge fields hint */}
            <div className="mt-1 p-3 bg-amber-50 border border-amber-200 rounded-lg">
              <p className="text-xs text-amber-700 font-medium mb-1.5">Available merge fields:</p>
              <div className="flex flex-wrap gap-1.5">
                {MERGE_FIELDS.map(f => (
                  <code key={f} className="text-xs bg-amber-100 text-amber-800 px-1.5 py-0.5 rounded font-mono">
                    {f}
                  </code>
                ))}
              </div>
            </div>
          </div>

          {/* Error */}
          {error && (
            <div className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">
              {error}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-3 px-6 py-4 border-t bg-gray-50 rounded-b-xl">
          <button
            onClick={onClose}
            disabled={isPending}
            className="px-4 py-2 text-sm text-gray-600 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={isPending}
            className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 min-w-[120px]"
          >
            {isPending ? 'Saving…' : initial ? 'Update Sequence' : 'Create Sequence'}
          </button>
        </div>
      </div>
    </div>
  );
}
