'use client';
// src/components/parties/enroll-sequence-dialog.tsx

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { enrollParty } from '@/lib/actions/email-sequences';
import type { EmailSequence } from '@/types/phase21b';

interface Contact {
  id:         string;
  full_name:  string;
  email:      string | null;
}

interface Props {
  partyId:    string;
  orgId:      string;
  sequences:  EmailSequence[];
  contacts:   Contact[];
  /** Organization-level HQ email (app.parties.email). When provided, it shows
   *  up as a special "Company HQ email" option in the recipient picker. */
  partyEmail?: string | null;
}

const HQ_OPTION = '__hq';

export function EnrollSequenceDialog({ partyId, orgId, sequences, contacts, partyEmail }: Props) {
  const router = useRouter();
  const [open,        setOpen]        = useState(false);
  const [sequenceId,  setSequenceId]  = useState('');
  const [contactId,   setContactId]   = useState('');
  const [error,       setError]       = useState<string | null>(null);
  const [isPending,   startTransition] = useTransition();

  const activeSequences = sequences.filter(s => s.status === 'active');

  function handleOpen() {
    setSequenceId(activeSequences[0]?.id ?? '');
    // Pick the first sensible recipient by default:
    //   1. first contact that has an email
    //   2. HQ email (if the party has app.parties.email set)
    //   3. the first contact (even without an email, so dialog is not empty)
    const firstContactWithEmail = contacts.find((c) => !!c.email);
    if (firstContactWithEmail) {
      setContactId(firstContactWithEmail.id);
    } else if (partyEmail) {
      setContactId(HQ_OPTION);
    } else {
      setContactId(contacts[0]?.id ?? '');
    }
    setError(null);
    setOpen(true);
  }

  function handleSubmit() {
    if (!sequenceId) { setError('Select a sequence.'); return; }
    setError(null);

    // Map the picker value -> (contactId, recipientEmail) for the server action.
    //   HQ_OPTION      -> contactId=null, recipientEmail=partyEmail
    //   empty string   -> contactId=null, recipientEmail=null (worker resolves)
    //   <contact uuid> -> contactId=<that>, recipientEmail=null (worker resolves)
    let resolvedContactId: string | null = contactId || null;
    let resolvedRecipientEmail: string | null = null;
    if (contactId === HQ_OPTION) {
      resolvedContactId = null;
      resolvedRecipientEmail = partyEmail ?? null;
      if (!resolvedRecipientEmail) {
        setError('No HQ email on file for this party.');
        return;
      }
    }

    startTransition(async () => {
      const result = await enrollParty(
        orgId,
        sequenceId,
        partyId,
        resolvedContactId,
        resolvedRecipientEmail,
      );
      if ('error' in result) {
        setError(result.error);
      } else {
        setOpen(false);
        router.refresh();
      }
    });
  }

  if (!open) {
    return (
      <button
        onClick={handleOpen}
        className="text-xs font-medium text-blue-600 hover:text-blue-800 flex items-center gap-1 border border-blue-200 rounded-lg px-3 py-1.5 hover:bg-blue-50"
      >
        + Enroll in Sequence
      </button>
    );
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-sm mx-4">

        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b">
          <h3 className="text-base font-semibold text-gray-900">Enroll in Sequence</h3>
          <button onClick={() => setOpen(false)} className="text-gray-400 hover:text-gray-600 text-xl leading-none">×</button>
        </div>

        <div className="px-5 py-4 space-y-4">
          {/* Sequence picker */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Sequence <span className="text-red-500">*</span>
            </label>
            {activeSequences.length === 0 ? (
              <p className="text-sm text-gray-400 italic">
                No active sequences. Create one in Settings → Email Sequences.
              </p>
            ) : (
              <select
                value={sequenceId}
                onChange={e => setSequenceId(e.target.value)}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {activeSequences.map(s => (
                  <option key={s.id} value={s.id}>
                    {s.name} ({s.step_count} steps)
                  </option>
                ))}
              </select>
            )}
          </div>

          {/* Contact picker */}
          {(contacts.length > 0 || partyEmail) && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Recipient
              </label>
              <select
                value={contactId}
                onChange={e => setContactId(e.target.value)}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">— No specific contact —</option>
                {contacts.map(c => (
                  <option key={c.id} value={c.id}>
                    {c.full_name}{c.email ? ` (${c.email})` : ' (no email)'}
                  </option>
                ))}
              </select>
              {contactId && contactId !== HQ_OPTION
                && !contacts.find(c => c.id === contactId)?.email && (
                <p className="text-xs text-amber-600 mt-1">
                  ⚠ This contact has no email — steps will be skipped.
                </p>
              )}
            </div>
          )}

          {/* Selected sequence preview */}
          {sequenceId && (() => {
            const seq = activeSequences.find(s => s.id === sequenceId);
            if (!seq) return null;
            return (
              <div className="bg-blue-50 border border-blue-100 rounded-lg p-3 text-xs text-blue-700 space-y-1">
                <div className="font-medium">{seq.name}</div>
                <div>{seq.step_count} step{seq.step_count !== 1 ? 's' : ''} — starts immediately (Day 0)</div>
                {seq.description && <div className="text-blue-500">{seq.description}</div>}
              </div>
            );
          })()}

          {/* Error */}
          {error && (
            <div className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">
              {error}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-2 px-5 py-4 border-t bg-gray-50 rounded-b-xl">
          <button
            onClick={() => setOpen(false)}
            disabled={isPending}
            className="px-4 py-2 text-sm text-gray-600 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={isPending || activeSequences.length === 0}
            className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
          >
            {isPending ? 'Enrolling…' : 'Enroll'}
          </button>
        </div>
      </div>
    </div>
  );
}
