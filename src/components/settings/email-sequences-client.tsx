'use client';
// src/components/settings/email-sequences-client.tsx

import { useState, useTransition } from 'react';
import { archiveSequence, triggerSequenceProcessor, getSequenceForEdit, duplicateSequence } from '@/lib/actions/email-sequences';
import { SequenceFormDialog } from './sequence-form-dialog';
import { BulkEnrollDialog } from './bulk-enroll-dialog';
import { SequenceOpensDialog } from './sequence-opens-dialog';
import type { EmailSequence, EmailSequenceWithSteps } from '@/types/phase21b';

const STATUS_COLORS: Record<string, string> = {
  active: 'bg-emerald-100 text-emerald-700',
  paused: 'bg-amber-100 text-amber-700',
};

interface Props {
  sequences: EmailSequence[];
  orgId:     string;
}

export function EmailSequencesClient({ sequences: initial, orgId }: Props) {
  const [sequences,     setSequences]     = useState(initial);
  const [dialogOpen,    setDialogOpen]    = useState(false);
  const [editTarget,    setEditTarget]    = useState<EmailSequenceWithSteps | undefined>();
  const [runResult,     setRunResult]     = useState<string | null>(null);
  const [bulkTarget,    setBulkTarget]    = useState<EmailSequence | null>(null);
  const [opensTarget,   setOpensTarget]   = useState<EmailSequence | null>(null);
  const [runningSeqId,  setRunningSeqId]  = useState<string | null>(null);
  const [isPending,     startTransition]  = useTransition();

  function handleCreate() {
    setEditTarget(undefined);
    setDialogOpen(true);
  }

  async function handleEdit(seq: EmailSequence) {
    const result = await getSequenceForEdit(seq.id);
    if ('data' in result && result.data) {
      setEditTarget(result.data as EmailSequenceWithSteps);
      setDialogOpen(true);
    }
  }

  function handleArchive(seqId: string) {
    if (!confirm('Archive this sequence? Active enrollments will continue to completion.')) return;
    startTransition(async () => {
      await archiveSequence(seqId);
      setSequences(prev => prev.filter(s => s.id !== seqId));
    });
  }

  function handleDuplicate(seq: EmailSequence) {
    setRunResult(null);
    startTransition(async () => {
      const res = await duplicateSequence(orgId, seq.id);
      if ('error' in res) {
        setRunResult(`Duplicate failed: ${res.error}`);
      } else {
        setSequences(prev => [
          ...prev,
          {
            ...seq,
            id: res.id,
            name: `${seq.name} (copy)`,
            active_enrollments: 0,
            total_sends: 0,
            created_at: new Date().toISOString(),
          },
        ]);
        setRunResult(`Duplicated "${seq.name}" -> "${seq.name} (copy)". Enroll the test party on the copy, then Run Now.`);
      }
    });
  }

  function runProcessor(seqId?: string) {
    setRunResult(null);
    setRunningSeqId(seqId ?? 'all');
    startTransition(async () => {
      const res = await triggerSequenceProcessor(seqId ?? null);
      setRunningSeqId(null);
      if ('error' in res) {
        setRunResult(`Error: ${res.error}`);
      } else {
        setRunResult(
          res.processed === 0
            ? 'Nothing due right now.'
            : `Processed ${res.processed}: ✅ ${res.sent} sent · ⏭ ${res.skipped} skipped · ❌ ${res.failed} failed`,
        );
      }
    });
  }

  function handleDialogClose() {
    setDialogOpen(false);
    // refresh the list (revalidatePath handles it instead of window.location.reload)
  }

  return (
    <>
      {/* Toolbar */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <h1 className="text-xl font-semibold text-gray-900">Email Sequences</h1>
          <span className="text-sm text-gray-400">
            {sequences.length} sequence{sequences.length !== 1 ? 's' : ''}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => runProcessor()}
            disabled={isPending}
            className="px-3 py-1.5 text-sm text-gray-600 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
            title="Run every sequence's due steps now (same as the cron)"
          >
            {runningSeqId === 'all' ? '⏳ Running…' : '▶ Run All'}
          </button>
          <button
            onClick={handleCreate}
            className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700"
          >
            + New Sequence
          </button>
        </div>
      </div>

      {/* Run result banner */}
      {runResult && (
        <div className="mb-4 px-4 py-2 bg-gray-100 border border-gray-200 rounded-lg text-sm text-gray-700">
          {runResult}
          <button onClick={() => setRunResult(null)} className="ml-3 text-gray-400 hover:text-gray-600">✕</button>
        </div>
      )}

      {/* Sequences table */}
      {sequences.length === 0 ? (
        <div className="text-center py-16 text-gray-400">
          <div className="text-4xl mb-3">📬</div>
          <p className="font-medium">No sequences yet</p>
          <p className="text-sm mt-1">Create one to automate your follow-up cadence.</p>
        </div>
      ) : (
        <div className="rounded-xl border border-gray-200 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-xs text-gray-500 uppercase tracking-wider">
              <tr>
                <th className="px-4 py-3 text-left font-medium">Sequence</th>
                <th className="px-4 py-3 text-left font-medium">Status</th>
                <th className="px-4 py-3 text-right font-medium">Steps</th>
                <th className="px-4 py-3 text-right font-medium">Active</th>
                <th className="px-4 py-3 text-right font-medium">Total Sent</th>
                <th className="px-4 py-3 text-right font-medium">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {sequences.map(seq => (
                <tr key={seq.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3">
                    <div className="font-medium text-gray-900">{seq.name}</div>
                    {seq.description && (
                      <div className="text-xs text-gray-400 mt-0.5 truncate max-w-xs">
                        {seq.description}
                      </div>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${STATUS_COLORS[seq.status] ?? 'bg-gray-100 text-gray-600'}`}>
                      {seq.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-right text-gray-600">{seq.step_count}</td>
                  <td className="px-4 py-3 text-right">
                    {seq.active_enrollments > 0 ? (
                      <span className="text-emerald-600 font-medium">{seq.active_enrollments}</span>
                    ) : (
                      <span className="text-gray-400">—</span>
                    )}
                  </td>
                  <td className="px-4 py-3 text-right text-gray-600">{seq.total_sends}</td>
                  <td className="px-4 py-3 text-right">
                    <div className="flex items-center justify-end gap-2">
                      <button
                        onClick={() => runProcessor(seq.id)}
                        disabled={isPending}
                        className="text-xs text-purple-600 hover:text-purple-800 font-medium disabled:opacity-50"
                        title="Send this sequence's due steps now"
                      >
                        {runningSeqId === seq.id ? 'Running…' : 'Run Now'}
                      </button>
                      <button
                        onClick={() => setOpensTarget(seq)}
                        className="text-xs text-indigo-600 hover:text-indigo-800 font-medium"
                        title="See who opened this sequence's emails"
                      >
                        Opens
                      </button>
                      <button
                        onClick={() => setBulkTarget(seq)}
                        className="text-xs text-emerald-600 hover:text-emerald-800 font-medium"
                      >
                        Bulk Enroll
                      </button>
                      <button
                        onClick={() => handleDuplicate(seq)}
                        disabled={isPending}
                        className="text-gray-400 hover:text-blue-600 disabled:opacity-50"
                        title="Duplicate - clone name, steps, and sender into a new sequence"
                        aria-label="Duplicate sequence"
                      >
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
                          <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1" />
                        </svg>
                      </button>
                      <button
                        onClick={() => handleEdit(seq)}
                        className="text-xs text-blue-600 hover:text-blue-800 font-medium"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleArchive(seq.id)}
                        disabled={isPending}
                        className="text-xs text-gray-400 hover:text-red-500 font-medium disabled:opacity-50"
                      >
                        Archive
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Create / Edit Dialog */}
      <SequenceFormDialog
        key={`${dialogOpen ? 'open' : 'closed'}-${editTarget?.id ?? 'new'}`}
        open={dialogOpen}
        onClose={handleDialogClose}
        orgId={orgId}
        initial={editTarget}
      />

      {/* Bulk Enroll Dialog */}
      {bulkTarget && (
        <BulkEnrollDialog
          open={true}
          onClose={() => setBulkTarget(null)}
          orgId={orgId}
          sequenceId={bulkTarget.id}
          sequenceName={bulkTarget.name}
        />
      )}
      {/* Read-receipts (opens) Dialog */}
      {opensTarget && (
        <SequenceOpensDialog
          open={true}
          onClose={() => setOpensTarget(null)}
          sequenceId={opensTarget.id}
          sequenceName={opensTarget.name}
        />
      )}
    </>
  );
}
