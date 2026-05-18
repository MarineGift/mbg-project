'use client';
// src/components/settings/bulk-enroll-dialog.tsx

import { useState, useTransition } from 'react';
import {
  previewBulkEnroll,
  bulkEnrollFiltered,
  type BulkEnrollFilters,
  type BulkEnrollResult,
} from '@/lib/actions/email-sequences';

interface Props {
  open:        boolean;
  onClose:     () => void;
  orgId:       string;
  sequenceId:  string;
  sequenceName: string;
}

const MODULES = [
  { value: '',            label: 'All modules' },
  { value: 'paper_mill',  label: 'Paper Companies' },
  { value: 'investor',    label: 'Investors' },
  { value: 'partner',     label: 'Partners' },
  { value: 'customer',    label: 'Customers' },
  { value: 'filler',      label: 'Filler Suppliers' },
];

const TIERS = [
  { value: 'tier_1', label: 'Tier 1' },
  { value: 'tier_2', label: 'Tier 2' },
  { value: 'tier_3', label: 'Tier 3' },
  { value: 'cold',   label: 'Cold' },
];

const STATUSES = [
  { value: 'active',   label: 'Active only' },
  { value: '',         label: 'Any status' },
];

export function BulkEnrollDialog({ open, onClose, orgId, sequenceId, sequenceName }: Props) {
  const [module,      setModule]      = useState('');
  const [tiers,       setTiers]       = useState<string[]>([]);
  const [status,      setStatus]      = useState('active');
  const [countryCode, setCountryCode] = useState('');
  const [preview,     setPreview]     = useState<BulkEnrollResult | null>(null);
  const [error,       setError]       = useState<string | null>(null);
  const [isPending,   startTransition] = useTransition();
  const [phase,       setPhase]       = useState<'filter' | 'preview' | 'done'>('filter');
  const [doneResult,  setDoneResult]  = useState<BulkEnrollResult | null>(null);

  if (!open) return null;

  function getFilters(): BulkEnrollFilters {
    return {
      module:      module || null,
      tiers:       tiers.length > 0 ? tiers : null,
      status:      status || null,
      countryCode: countryCode.trim().toUpperCase() || null,
    };
  }

  function handleToggleTier(tier: string) {
    setTiers(prev => prev.includes(tier) ? prev.filter(t => t !== tier) : [...prev, tier]);
  }

  function handlePreview() {
    setError(null);
    startTransition(async () => {
      const res = await previewBulkEnroll(orgId, sequenceId, getFilters());
      if ('error' in res) {
        setError(res.error);
        return;
      }
      setPreview(res);
      setPhase('preview');
    });
  }

  function handleEnroll() {
    setError(null);
    startTransition(async () => {
      const res = await bulkEnrollFiltered(orgId, sequenceId, getFilters());
      if ('error' in res) {
        setError(res.error);
        return;
      }
      setDoneResult(res);
      setPhase('done');
    });
  }

  function handleClose() {
    // 리셋 후 닫기
    setModule('');
    setTiers([]);
    setStatus('active');
    setCountryCode('');
    setPreview(null);
    setDoneResult(null);
    setError(null);
    setPhase('filter');
    onClose();
  }

  function handleBackToFilter() {
    setPreview(null);
    setPhase('filter');
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center bg-black/40 overflow-y-auto py-10">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-lg mx-4">

        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Bulk Enroll</h2>
            <p className="text-xs text-gray-500 mt-0.5">Sequence: <span className="font-medium">{sequenceName}</span></p>
          </div>
          <button onClick={handleClose} className="text-gray-400 hover:text-gray-600 text-xl leading-none">×</button>
        </div>

        <div className="px-6 py-5">

          {/* PHASE: filter */}
          {phase === 'filter' && (
            <div className="space-y-4">
              <p className="text-sm text-gray-600">
                Filter parties to enroll. Each party's primary contact (or first contact with email) will receive the sequence.
              </p>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Module</label>
                <select
                  value={module}
                  onChange={e => setModule(e.target.value)}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  {MODULES.map(m => (
                    <option key={m.value} value={m.value}>{m.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Tier (선택 안 하면 전체)</label>
                <div className="flex gap-1.5 flex-wrap">
                  {TIERS.map(t => (
                    <button
                      key={t.value}
                      type="button"
                      onClick={() => handleToggleTier(t.value)}
                      className={
                        `text-xs px-3 py-1.5 rounded-full border transition-colors ` +
                        (tiers.includes(t.value)
                          ? 'bg-blue-100 border-blue-300 text-blue-700 font-medium'
                          : 'bg-white border-gray-300 text-gray-600 hover:border-gray-400')
                      }
                    >
                      {t.label}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
                <select
                  value={status}
                  onChange={e => setStatus(e.target.value)}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  {STATUSES.map(s => (
                    <option key={s.value} value={s.value}>{s.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Country code (예: KR, JP, US)</label>
                <input
                  type="text"
                  value={countryCode}
                  onChange={e => setCountryCode(e.target.value)}
                  placeholder="비워두면 전체"
                  maxLength={2}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 uppercase"
                />
              </div>

              {error && (
                <div className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">
                  {error}
                </div>
              )}
            </div>
          )}

          {/* PHASE: preview */}
          {phase === 'preview' && preview && (
            <div className="space-y-4">
              <p className="text-sm text-gray-600">Preview based on your filters:</p>

              <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Total matching parties</span>
                  <span className="font-semibold text-gray-900">{preview.total_matching}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Already enrolled (skip)</span>
                  <span className="text-gray-500">{preview.skipped_already_enrolled}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">No email contact (skip)</span>
                  <span className="text-gray-500">{preview.skipped_no_email}</span>
                </div>
                <div className="h-px bg-gray-200 my-2" />
                <div className="flex justify-between">
                  <span className="text-sm font-medium text-gray-900">Will enroll</span>
                  <span className="font-semibold text-emerald-600">{preview.enrolled_count}</span>
                </div>
              </div>

              {preview.sample_names && preview.sample_names.length > 0 && (
                <div>
                  <p className="text-xs text-gray-500 mb-1.5">Sample matches:</p>
                  <ul className="text-sm text-gray-700 space-y-0.5">
                    {preview.sample_names.map(n => (
                      <li key={n} className="truncate">• {n}</li>
                    ))}
                    {preview.total_matching > preview.sample_names.length && (
                      <li className="text-gray-400 italic">… and {preview.total_matching - preview.sample_names.length} more</li>
                    )}
                  </ul>
                </div>
              )}

              {error && (
                <div className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">
                  {error}
                </div>
              )}
            </div>
          )}

          {/* PHASE: done */}
          {phase === 'done' && doneResult && (
            <div className="space-y-3 text-center py-6">
              <div className="text-5xl">🎉</div>
              <h3 className="text-lg font-semibold text-gray-900">
                Enrolled {doneResult.enrolled_count} parties
              </h3>
              <p className="text-sm text-gray-600">
                Skipped: {doneResult.skipped_already_enrolled} already enrolled · {doneResult.skipped_no_email} without email
              </p>
              <p className="text-xs text-gray-400 pt-2">
                Sequence starts immediately. Run <strong>▶ Run Now</strong> or wait for the cron.
              </p>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-2 px-6 py-4 border-t bg-gray-50 rounded-b-xl">
          {phase === 'filter' && (
            <>
              <button onClick={handleClose} disabled={isPending}
                className="px-4 py-2 text-sm text-gray-600 bg-white border border-gray-300 rounded-lg hover:bg-gray-50">
                Cancel
              </button>
              <button onClick={handlePreview} disabled={isPending}
                className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50">
                {isPending ? 'Loading…' : 'Preview matches'}
              </button>
            </>
          )}

          {phase === 'preview' && (
            <>
              <button onClick={handleBackToFilter} disabled={isPending}
                className="px-4 py-2 text-sm text-gray-600 bg-white border border-gray-300 rounded-lg hover:bg-gray-50">
                ← Back to filters
              </button>
              <button
                onClick={handleEnroll}
                disabled={isPending || (preview?.enrolled_count ?? 0) === 0}
                className="px-4 py-2 text-sm font-medium text-white bg-emerald-600 rounded-lg hover:bg-emerald-700 disabled:opacity-50"
              >
                {isPending ? 'Enrolling…' : `Enroll ${preview?.enrolled_count ?? 0} parties`}
              </button>
            </>
          )}

          {phase === 'done' && (
            <button onClick={handleClose}
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700">
              Done
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
