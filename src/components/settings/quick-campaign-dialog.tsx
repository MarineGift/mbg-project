'use client';
// src/components/settings/quick-campaign-dialog.tsx

import { useState, useEffect, useTransition } from 'react';
import {
  fetchActiveTemplates,
  previewCampaignFilter,
  createCampaignFromTemplate,
  type BulkEnrollFilters,
  type CampaignTemplate,
  type CampaignPreview,
  type CampaignResult,
} from '@/lib/actions/email-sequences';

interface Props {
  open:    boolean;
  onClose: () => void;
  orgId:   string;
}

const MODULES = [
  { value: '',            label: 'All modules' },
  { value: 'paper_mill',  label: 'Paper Mills' },
  { value: 'investor',    label: 'Investors' },
  { value: 'partner',     label: 'Partners' },
  { value: 'customer',    label: 'Customers' },
  { value: 'filler_supplier',      label: 'Filler Suppliers' },
];

const TIERS = [
  { value: 'tier_1', label: 'Tier 1' },
  { value: 'tier_2', label: 'Tier 2' },
  { value: 'tier_3', label: 'Tier 3' },
  { value: 'cold',   label: 'Cold' },
];

type Phase = 'select' | 'preview' | 'done';

function fmtDate(d: Date) {
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

export function QuickCampaignDialog({ open, onClose, orgId }: Props) {
  const [templates,   setTemplates]   = useState<CampaignTemplate[]>([]);
  const [templateId,  setTemplateId]  = useState('');
  const [campaignName, setCampaignName] = useState('');
  const [module,      setModule]      = useState('');
  const [tiers,       setTiers]       = useState<string[]>([]);
  const [countryCode, setCountryCode] = useState('');
  const [industryTag, setIndustryTag] = useState('');
  const [nameContains, setNameContains] = useState('');
  const [autoSend,    setAutoSend]    = useState(true);
  const [preview,     setPreview]     = useState<CampaignPreview | null>(null);
  const [result,      setResult]      = useState<CampaignResult | null>(null);
  const [phase,       setPhase]       = useState<Phase>('select');
  const [error,       setError]       = useState<string | null>(null);
  const [isPending,   startTransition] = useTransition();
  const [loadingTpls, setLoadingTpls] = useState(false);

  useEffect(() => {
    if (!open) return;
    setLoadingTpls(true);
    fetchActiveTemplates(orgId)
      .then(t => setTemplates(t))
      .catch(e => setError(String(e)))
      .finally(() => setLoadingTpls(false));
  }, [open, orgId]);

  if (!open) return null;

  const selectedTpl = templates.find(t => t.id === templateId);

  function getFilters(): BulkEnrollFilters {
    return {
      module:       module || null,
      tiers:        tiers.length > 0 ? tiers : null,
      status:       'active',
      countryCode:  countryCode.trim().toUpperCase() || null,
      industryTag:  industryTag.trim() || null,
      nameContains: nameContains.trim() || null,
    };
  }

  function handleToggleTier(t: string) {
    setTiers(prev => prev.includes(t) ? prev.filter(x => x !== t) : [...prev, t]);
  }

  function handleTemplateChange(id: string) {
    setTemplateId(id);
    const tpl = templates.find(t => t.id === id);
    if (tpl && !campaignName) {
      setCampaignName(`${tpl.name} · ${fmtDate(new Date())}`);
    }
  }

  function handlePreview() {
    if (!templateId) { setError('Pick a template.'); return; }
    if (!campaignName.trim()) { setError('Campaign name required.'); return; }
    setError(null);
    startTransition(async () => {
      const res = await previewCampaignFilter(orgId, getFilters());
      if ('error' in res) { setError(res.error); return; }
      setPreview(res);
      setPhase('preview');
    });
  }

  function handleSend() {
    setError(null);
    startTransition(async () => {
      const res = await createCampaignFromTemplate(
        orgId, templateId, campaignName.trim(), getFilters(), autoSend
      );
      if ('error' in res) { setError(res.error); return; }
      setResult(res);
      setPhase('done');
    });
  }

  function handleClose() {
    setTemplateId(''); setCampaignName(''); setModule(''); setTiers([]);
    setCountryCode(''); setIndustryTag(''); setNameContains('');
    setPreview(null); setResult(null);
    setPhase('select'); setError(null);
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center bg-black/40 overflow-y-auto py-8">
      <div className="bg-white rounded-xl shadow-2xl w-full max-w-xl mx-4">

        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b">
          <h2 className="text-lg font-semibold text-gray-900">
            🚀 Send Campaign from Template
          </h2>
          <button onClick={handleClose} className="text-gray-400 hover:text-gray-600 text-xl">×</button>
        </div>

        <div className="px-6 py-5">

          {/* PHASE 1: Select template + filters */}
          {phase === 'select' && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Template <span className="text-red-500">*</span>
                </label>
                {loadingTpls ? (
                  <p className="text-sm text-gray-400">Loading templates…</p>
                ) : templates.length === 0 ? (
                  <p className="text-sm text-amber-600">
                    No active templates. Create one in Settings → Email Templates.
                  </p>
                ) : (
                  <select
                    value={templateId}
                    onChange={e => handleTemplateChange(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="">— Select a template —</option>
                    {templates.map(t => (
                      <option key={t.id} value={t.id}>
                        {t.category ? `[${t.category}] ` : ''}{t.name}
                      </option>
                    ))}
                  </select>
                )}
                {selectedTpl && (
                  <div className="mt-2 bg-blue-50 border border-blue-100 rounded p-3 text-xs space-y-1">
                    <div className="font-medium text-blue-900">Preview:</div>
                    <div className="text-blue-800"><strong>Subject:</strong> {selectedTpl.subject}</div>
                    <div className="text-blue-700 whitespace-pre-wrap line-clamp-4">{selectedTpl.body_plain}</div>
                  </div>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Campaign Name</label>
                <input
                  type="text"
                  value={campaignName}
                  onChange={e => setCampaignName(e.target.value)}
                  placeholder="e.g. Cold Outreach Q2 2026"
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div className="h-px bg-gray-200" />

              <div className="text-sm font-semibold text-gray-900">Filter recipients</div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">Module</label>
                  <select
                    value={module}
                    onChange={e => setModule(e.target.value)}
                    className="w-full border border-gray-300 rounded-lg px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {MODULES.map(m => <option key={m.value} value={m.value}>{m.label}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">Country (2-letter)</label>
                  <input
                    type="text"
                    value={countryCode}
                    onChange={e => setCountryCode(e.target.value)}
                    placeholder="all"
                    maxLength={2}
                    className="w-full border border-gray-300 rounded-lg px-2 py-1.5 text-sm uppercase focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">Industry tag contains</label>
                  <input
                    type="text"
                    value={industryTag}
                    onChange={e => setIndustryTag(e.target.value)}
                    placeholder="e.g. tissue, packaging"
                    className="w-full border border-gray-300 rounded-lg px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-700 mb-1">Name contains</label>
                  <input
                    type="text"
                    value={nameContains}
                    onChange={e => setNameContains(e.target.value)}
                    placeholder="e.g. [TEST]"
                    className="w-full border border-gray-300 rounded-lg px-2 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-700 mb-1.5">Tier</label>
                <div className="flex gap-1.5 flex-wrap">
                  {TIERS.map(t => (
                    <button
                      key={t.value}
                      type="button"
                      onClick={() => handleToggleTier(t.value)}
                      className={
                        `text-xs px-3 py-1 rounded-full border transition-colors ` +
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

              <label className="flex items-center gap-2 text-sm text-gray-700 cursor-pointer">
                <input
                  type="checkbox"
                  checked={autoSend}
                  onChange={e => setAutoSend(e.target.checked)}
                  className="rounded"
                />
                Send immediately after enrollment (otherwise queued for next cron)
              </label>

              {error && (
                <div className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">
                  {error}
                </div>
              )}
            </div>
          )}

          {/* PHASE 2: Preview */}
          {phase === 'preview' && preview && (
            <div className="space-y-4">
              <p className="text-sm text-gray-600">Confirm campaign details:</p>

              <div className="bg-blue-50 border border-blue-100 rounded-lg p-3 text-sm space-y-1">
                <div><strong>Template:</strong> {selectedTpl?.name}</div>
                <div><strong>Campaign:</strong> {campaignName}</div>
              </div>

              <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 space-y-2">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600">Total matching parties</span>
                  <span className="font-semibold">{preview.total_matching}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">No email contact (skip)</span>
                  <span className="text-gray-500">{preview.no_email}</span>
                </div>
                <div className="h-px bg-gray-200 my-2" />
                <div className="flex justify-between">
                  <span className="text-sm font-medium">Will send to</span>
                  <span className="font-semibold text-emerald-600">{preview!.with_email}</span>
                </div>
              </div>

              {preview.sample_names?.length > 0 && (
                <div>
                  <p className="text-xs text-gray-500 mb-1.5">Sample matches:</p>
                  <ul className="text-sm text-gray-700 space-y-0.5">
                    {preview.sample_names.map(n => <li key={n} className="truncate">• {n}</li>)}
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

          {/* PHASE 3: Done */}
          {phase === 'done' && result && (
            <div className="space-y-3 text-center py-6">
              <div className="text-5xl">🚀</div>
              <h3 className="text-lg font-semibold text-gray-900">
                Campaign Launched
              </h3>
              <p className="text-sm text-gray-600">
                Enrolled <strong>{result.enrolled_count}</strong> parties
                {autoSend && ' · sending now'}
              </p>
              <p className="text-xs text-gray-400">
                Track results in <strong>Settings → Email History</strong>
              </p>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex justify-end gap-2 px-6 py-4 border-t bg-gray-50 rounded-b-xl">
          {phase === 'select' && (
            <>
              <button onClick={handleClose}
                className="px-4 py-2 text-sm text-gray-600 bg-white border border-gray-300 rounded-lg hover:bg-gray-50">Cancel</button>
              <button onClick={handlePreview} disabled={isPending || !templateId}
                className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50">
                {isPending ? 'Loading…' : 'Preview matches'}
              </button>
            </>
          )}
          {phase === 'preview' && (
            <>
              <button onClick={() => setPhase('select')} disabled={isPending}
                className="px-4 py-2 text-sm text-gray-600 bg-white border border-gray-300 rounded-lg hover:bg-gray-50">← Back</button>
              <button
                onClick={handleSend}
                disabled={isPending || preview!.with_email === 0}
                className="px-4 py-2 text-sm font-medium text-white bg-emerald-600 rounded-lg hover:bg-emerald-700 disabled:opacity-50"
              >
                {isPending ? 'Launching…' : `Launch — Send to ${preview!.with_email}`}
              </button>
            </>
          )}
          {phase === 'done' && (
            <button onClick={handleClose}
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700">Done</button>
          )}
        </div>
      </div>
    </div>
  );
}
