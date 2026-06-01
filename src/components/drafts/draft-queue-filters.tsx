'use client';

import { useRouter, useSearchParams, usePathname } from 'next/navigation';
import { useTransition } from 'react';
import { useTranslations } from 'next-intl';
import { RotateCcw } from 'lucide-react';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import {
  CLASSIFICATION_CATEGORIES,
  type ClassificationCategory,
  type DraftStatus,
  type PartyTypeCode,
} from '@/types/ai';
import type { DraftQueueFilters, DraftQueueSort } from '@/types/draft-queue';

interface DraftQueueFiltersProps {
  filters: DraftQueueFilters;
  sort: DraftQueueSort;
}

const STATUS_OPTIONS: readonly DraftStatus[] = [
  'pending_review',
  'approved',
  'sent',
  'rejected',
  'expired',
  'auto_sent',
] as const;

const MODULE_OPTIONS: readonly PartyTypeCode[] = [
  'investor',
  'paper_mill',
  'partner',
  'customer',
] as const;

const SORT_OPTIONS: readonly DraftQueueSort[] = [
  'urgent',
  'newest',
  'oldest',
  'confidence_high',
  'expiring_soon',
] as const;

const CONFIDENCE_OPTIONS: readonly { value: string; label: string }[] = [
  { value: '0', label: 'any' },
  { value: '0.7', label: '≥ 70%' },
  { value: '0.8', label: '≥ 80%' },
  { value: '0.9', label: '≥ 90%' },
] as const;

export function DraftQueueFilters({
  filters,
  sort,
}: DraftQueueFiltersProps) {
  const t = useTranslations('drafts.filters');
  const tSort = useTranslations('drafts.sort');
  const tStatus = useTranslations('draftStatus');
  const tModules = useTranslations('partyTypes');
  const tCategories = useTranslations('classificationCategory');
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();

  const setParam = (key: string, value: string | null) => {
    const next = new URLSearchParams(searchParams.toString());
    if (value === null || value === '' || value === 'all') {
      next.delete(key);
    } else {
      next.set(key, value);
    }
    // reset to page=1 on filter change
    next.delete('page');
    startTransition(() => {
      router.replace(`${pathname}?${next.toString()}`);
    });
  };

  const reset = () => {
    startTransition(() => {
      router.replace(pathname);
    });
  };

  const isDirty =
    filters.status !== 'pending_review' ||
    filters.partyType !== 'all' ||
    filters.category !== 'all' ||
    filters.minConfidence > 0 ||
    filters.onlyRisky ||
    sort !== 'urgent';

  return (
    <div
      className="flex flex-wrap items-end gap-3 p-4 border-b bg-muted/30"
      aria-busy={isPending}
    >
      {/* Status */}
      <div className="space-y-1 min-w-[140px]">
        <Label className="text-xs text-muted-foreground">{t('status')}</Label>
        <Select
          value={filters.status}
          onValueChange={(v) => setParam('status', v)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('allStatuses')}</SelectItem>
            {STATUS_OPTIONS.map((s) => (
              <SelectItem key={s} value={s}>
                {tStatus(s)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Module */}
      <div className="space-y-1 min-w-[140px]">
        <Label className="text-xs text-muted-foreground">{t('module')}</Label>
        <Select
          value={filters.partyType}
          onValueChange={(v) => setParam('partyType', v)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('allModules')}</SelectItem>
            {MODULE_OPTIONS.map((m) => (
              <SelectItem key={m} value={m}>
                {tModules(m)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Category */}
      <div className="space-y-1 min-w-[160px]">
        <Label className="text-xs text-muted-foreground">{t('category')}</Label>
        <Select
          value={filters.category}
          onValueChange={(v) => setParam('category', v)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('allCategories')}</SelectItem>
            {CLASSIFICATION_CATEGORIES.map((c: ClassificationCategory) => (
              <SelectItem key={c} value={c}>
                {tCategories(c)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Min Confidence */}
      <div className="space-y-1 min-w-[140px]">
        <Label className="text-xs text-muted-foreground">{t('confidence')}</Label>
        <Select
          value={String(filters.minConfidence)}
          onValueChange={(v) => setParam('conf', v === '0' ? null : v)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {CONFIDENCE_OPTIONS.map((opt) => (
              <SelectItem key={opt.value} value={opt.value}>
                {opt.value === '0' ? t('anyConfidence') : opt.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Sort */}
      <div className="space-y-1 min-w-[200px]">
        <Label className="text-xs text-muted-foreground">{t('sort')}</Label>
        <Select
          value={sort}
          onValueChange={(v) => setParam('sort', v === 'urgent' ? null : v)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {SORT_OPTIONS.map((s) => (
              <SelectItem key={s} value={s}>
                {tSort(s === 'confidence_high' ? 'confidenceHigh' : s === 'expiring_soon' ? 'expiringSoon' : s)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {/* Only risky checkbox */}
      <div className="flex items-center gap-2 h-10 pb-0.5">
        <Checkbox
          id="filter-only-risky"
          checked={filters.onlyRisky}
          onCheckedChange={(v) => setParam('risk', v === true ? '1' : null)}
        />
        <Label htmlFor="filter-only-risky" className="cursor-pointer">
          {t('onlyRisky')}
        </Label>
      </div>

      {/* Reset */}
      {isDirty && (
        <Button
          variant="ghost"
          size="sm"
          onClick={reset}
          className="ml-auto"
        >
          <RotateCcw className="h-3.5 w-3.5" />
          {t('reset')}
        </Button>
      )}
    </div>
  );
}
