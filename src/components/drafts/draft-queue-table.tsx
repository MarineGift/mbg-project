'use client';

import { useEffect } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { ExternalLink, Pencil } from 'lucide-react';
import { Checkbox } from '@/components/ui/checkbox';
import { ModuleBadge } from '@/components/common/module-badge';
import { StatusBadge } from '@/components/common/status-badge';
import { ConfidenceBar } from '@/components/common/confidence-bar';
import { RiskFlagChip } from '@/components/common/risk-flag-chip';
import { ExpiryCountdown } from './expiry-countdown';
import { useUiStore } from '@/lib/stores/ui-store';
import { cn } from '@/lib/utils';
import type { DraftQueueRow } from '@/types/draft-queue';

interface DraftQueueTableProps {
  rows: readonly DraftQueueRow[];
}

export function DraftQueueTable({ rows }: DraftQueueTableProps) {
  const t = useTranslations('drafts.columns');
  const tPreview = useTranslations('drafts.preview');
  const tCategory = useTranslations('classificationCategory');

  const selected = useUiStore((s) => s.selectedDraftIds);
  const toggle = useUiStore((s) => s.toggleDraftSelection);
  const selectAll = useUiStore((s) => s.selectAllDrafts);
  const clear = useUiStore((s) => s.clearDraftSelection);
  const searchParams = useSearchParams();

  // 페이지 / 필터 변경 시 선택 초기화 (사용자가 잘못된 행을 일괄 액션 대상에 포함하지 않도록)
  useEffect(() => {
    clear();
    // searchParams의 변경 시마다 호출
  }, [searchParams, clear]);

  const visibleIds = rows.map((r) => r.id);
  const allSelected =
    visibleIds.length > 0 && visibleIds.every((id) => selected.has(id));
  const someSelected =
    visibleIds.some((id) => selected.has(id)) && !allSelected;

  const onHeaderCheck = () => {
    if (allSelected) {
      clear();
    } else {
      selectAll(visibleIds);
    }
  };

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead className="border-b-2 bg-muted/60">
          <tr>
            <th className="px-3 py-2 w-10">
              <Checkbox
                checked={
                  allSelected ? true : someSelected ? 'indeterminate' : false
                }
                onCheckedChange={onHeaderCheck}
                aria-label="Select all"
              />
            </th>
            <th className="px-3 py-2 text-left w-24">{t('status')}</th>
            <th className="px-3 py-2 text-left w-24">{t('module')}</th>
            <th className="px-3 py-2 text-left">{t('party')}</th>
            <th className="px-3 py-2 text-left w-32">{t('category')}</th>
            <th className="px-3 py-2 text-left w-32">{t('confidence')}</th>
            <th className="px-3 py-2 text-left w-32">{t('risk')}</th>
            <th className="px-3 py-2 text-left w-28">{t('expires')}</th>
            <th className="px-3 py-2 w-10"></th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr
              key={row.id}
              className={cn(
                'border-b hover:bg-muted/30 transition-colors',
                selected.has(row.id) && 'bg-accent/30',
              )}
            >
              <td className="px-3 py-3 align-top">
                <Checkbox
                  checked={selected.has(row.id)}
                  onCheckedChange={() => toggle(row.id)}
                  aria-label={`Select ${row.subject ?? row.id}`}
                />
              </td>
              <td className="px-3 py-3 align-top">
                <StatusBadge status={row.status} size="sm" />
              </td>
              <td className="px-3 py-3 align-top">
                {row.partyType ? <ModuleBadge module={row.partyType} size="sm" /> : null}
              </td>
              <td className="px-3 py-3 align-top">
                <div className="space-y-0.5 min-w-0">
                  <Link
                    href={`/drafts/${row.id}`}
                    className="font-medium hover:underline truncate block"
                  >
                    {row.partyName ?? tPreview('noParty')}
                  </Link>
                  <p className="text-xs text-muted-foreground truncate">
                    {row.subject ?? row.inboundSubject ?? '(no subject)'}
                  </p>
                  {row.fromAddress && !row.partyName && (
                    <p className="text-xs text-muted-foreground truncate">
                      {tPreview('from')}: {row.fromAddress}
                    </p>
                  )}
                </div>
              </td>
              <td className="px-3 py-3 align-top">
                {row.classificationCategory ? (
                  <span className="text-xs text-muted-foreground">
                    {tCategory(row.classificationCategory)}
                  </span>
                ) : (
                  <span className="text-xs text-muted-foreground">—</span>
                )}
              </td>
              <td className="px-3 py-3 align-top">
                <ConfidenceBar value={row.confidenceScore ?? 0} />
              </td>
              <td className="px-3 py-3 align-top">
                <div className="flex flex-wrap gap-1">
                  {row.riskFlags.slice(0, 2).map((flag) => (
                    <RiskFlagChip key={flag} flag={flag} />
                  ))}
                  {row.riskFlags.length > 2 && (
                    <span className="text-xs text-muted-foreground self-center">
                      +{row.riskFlags.length - 2}
                    </span>
                  )}
                  {row.hasEdits && (
                    <span
                      title="Edited"
                      className="inline-flex items-center text-xs text-blue-600 dark:text-blue-400"
                    >
                      <Pencil className="h-3 w-3" />
                    </span>
                  )}
                </div>
              </td>
              <td className="px-3 py-3 align-top">
                <ExpiryCountdown expiresAt={row.expiresAt} />
              </td>
              <td className="px-3 py-3 align-top text-right">
                <Link
                  href={`/drafts/${row.id}`}
                  className="inline-flex items-center text-muted-foreground hover:text-foreground"
                  aria-label="Open"
                >
                  <ExternalLink className="h-4 w-4" />
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
