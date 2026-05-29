'use client';
// src/components/settings/email-sequences-client.tsx

import { useState, useTransition } from 'react';
import { archiveSequence, triggerSequenceProcessor, getSequenceForEdit } from '@/lib/actions/email-sequences';
import { SequenceFormDialog } from './sequence-form-dialog';
import { BulkEnrollDialog } from './bulk-enroll-dialog';
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

  function handleRunNow() {
    setRunResult(null);
    startTransition(async () => {
      const res = await triggerSequenceProcessor();
      if ('error' in res) {
        setRunResult(`Error: ${res.error}`);
      } else {
        const sent    = (res.results as { status: string }[]).filter(r => r.status === 'sent').length;
        const skipped = (res.results as { status: string }[]).filter(r => r.status === 'skipped').length;
        const errors  = (res.results as { status: string }[]).filter(r => r.status === 'error').length;
        setRunResult(
          res.processed === 0
            ? 'No sequences due right now.'
            : `Processed ${res.processed}: ✅ ${sent} sent · ⏭ ${skipped} skipped · ❌ ${errors} errors`,
        );
      }
    });
  }

  function handleDialogClose() {
    setDialogOpen(false);
    // 목록 새로고침 (window.location.reload 대신 revalidatePath가 처리함)
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
            onClick={handleRunNow}
            disabled={isPending}
            className="px-3 py-1.5 text-sm text-gray-600 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
            title="Manually trigger processor (sends overdue steps)"
          >
            {isPending ? '⏳ Running…' : '▶ Run Now'}
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
                        onClick={() => setBulkTarget(seq)}
                        className="text-xs text-emerald-600 hover:text-emerald-800 font-medium"
                      >
                        Bulk Enroll
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
    </>
  );
}
