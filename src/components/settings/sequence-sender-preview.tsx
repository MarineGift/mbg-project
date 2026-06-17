'use client';
// src/components/settings/sequence-sender-preview.tsx
//
// Sender selection + send-document preview for a sequence, embedded in the
// edit dialog. The From dropdown reuses listMailAccountOptions (the same
// app.inbound_mailboxes accounts the compose/reply dialog lists) and saves to
// email_sequences.from_account_id immediately. Preview renders each step with
// sample data + the org signature, exactly the document that would be sent.

import { useEffect, useState, useTransition } from 'react';
import {
  listMailAccountOptions,
  type MailAccountOption,
} from '@/lib/actions/mail-account-options';
import {
  getSequenceFromAccountId,
  setSequenceFromAccount,
  previewSequenceStep,
} from '@/lib/actions/sequence-sender';

interface StepLike {
  day_offset: number;
  subject: string;
  body_plain: string;
}

interface Props {
  sequenceId: string;
  orgId: string;
  steps: StepLike[];
}

export function SequenceSenderPreview({ sequenceId, orgId, steps }: Props) {
  const [accounts, setAccounts] = useState<MailAccountOption[]>([]);
  const [fromId, setFromId] = useState<string>(''); // '' = org default account
  const [savedMsg, setSavedMsg] = useState<string | null>(null);
  const [, startSave] = useTransition();

  const [previewIdx, setPreviewIdx] = useState<number | null>(null);
  const [preview, setPreview] = useState<{ subject: string; html: string } | null>(null);
  const [loadingPreview, setLoadingPreview] = useState(false);

  useEffect(() => {
    let alive = true;
    (async () => {
      const opt = await listMailAccountOptions();
      if (alive && opt.ok) setAccounts(opt.accounts);
      const cur = await getSequenceFromAccountId(sequenceId);
      if (alive && 'accountId' in cur && cur.accountId) setFromId(cur.accountId);
    })();
    return () => {
      alive = false;
    };
  }, [sequenceId]);

  function onChangeFrom(value: string) {
    setFromId(value);
    setSavedMsg(null);
    startSave(async () => {
      const r = await setSequenceFromAccount(sequenceId, value || null);
      setSavedMsg('error' in r ? `Save failed: ${r.error}` : 'Saved');
    });
  }

  async function showPreview(i: number) {
    setPreviewIdx(i);
    setLoadingPreview(true);
    setPreview(null);
    const s = steps[i];
    const r = await previewSequenceStep({
      orgId,
      subject: s?.subject ?? '',
      bodyPlain: s?.body_plain ?? '',
    });
    setLoadingPreview(false);
    setPreview(
      'error' in r ? { subject: 'Preview error', html: escapeHtml(r.error) } : r,
    );
  }

  const defaultAccount = accounts.find((a) => a.isDefault) ?? null;

  return (
    <div className="rounded-lg border border-gray-200 p-4 bg-white space-y-4">
      <h3 className="text-sm font-semibold text-gray-900">Sender &amp; Preview</h3>

      {/* From account */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          From (sender)
        </label>
        <select
          value={fromId}
          onChange={(e) => onChangeFrom(e.target.value)}
          className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="">
            {defaultAccount
              ? `Default — ${accountLabel(defaultAccount)}`
              : 'Default account'}
          </option>
          {accounts.map((a) => (
            <option key={a.id} value={a.id}>
              {accountLabel(a)}
              {a.isDefault ? ' (default)' : ''}
            </option>
          ))}
        </select>
        <p className="mt-1 text-xs text-gray-400">
          Saved automatically. Empty = the org default account. Replies return to
          the chosen address.
        </p>
        {savedMsg && (
          <p
            className={`mt-1 text-xs ${
              savedMsg.startsWith('Save failed') ? 'text-red-600' : 'text-green-600'
            }`}
          >
            {savedMsg}
          </p>
        )}
      </div>

      {/* Preview controls */}
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-1">
          Preview the document that gets sent
        </label>
        <div className="flex flex-wrap gap-1.5">
          {steps.map((s, i) => (
            <button
              key={i}
              type="button"
              onClick={() => showPreview(i)}
              className={`text-xs font-medium px-2 py-1 rounded border ${
                previewIdx === i
                  ? 'bg-blue-600 text-white border-blue-600'
                  : 'bg-white text-blue-600 border-blue-200 hover:bg-blue-50'
              }`}
            >
              Preview Day {s.day_offset}
            </button>
          ))}
        </div>
        <p className="mt-1 text-xs text-gray-400">
          Rendered with sample data (Alex Kim / Acme Ventures) plus your default
          signature.
        </p>
      </div>

      {/* Preview output */}
      {previewIdx !== null && (
        <div className="rounded-lg border border-gray-200 bg-gray-50 overflow-hidden">
          <div className="px-3 py-2 border-b border-gray-200 bg-white">
            <div className="text-[11px] uppercase tracking-wide text-gray-400">
              Subject
            </div>
            <div className="text-sm font-medium text-gray-900">
              {loadingPreview ? 'Rendering…' : preview?.subject || '(empty)'}
            </div>
          </div>
          <div className="p-3 max-h-80 overflow-y-auto text-sm text-gray-800 bg-white">
            {loadingPreview ? (
              <span className="text-gray-400">Rendering…</span>
            ) : (
              <div
                className="prose prose-sm max-w-none"
                // preview only; content is our own template + signature
                dangerouslySetInnerHTML={{ __html: preview?.html ?? '' }}
              />
            )}
          </div>
        </div>
      )}
    </div>
  );
}

function accountLabel(a: MailAccountOption): string {
  return a.displayName ? `${a.displayName} <${a.address}>` : a.address;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}
