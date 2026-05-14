'use client';

/**
 * components/inbox/inbox-filters.tsx
 *
 * Inbox 목록 페이지 상단 필터 바.
 * URL searchParams 기반 상태 관리.
 *
 * 변경 이력:
 *   - 2026-05-12 (1차): CHANNELS 배열을 DB enum 9개와 일치 (slack/other 제거).
 *   - 2026-05-12 (2차): UI 호환을 위해 11개로 확장 (slack, other 재포함).
 *   - 2026-05-12 (3차): DB enum과 완전 일치 (12개) — webform 추가.
 *                       정확한 소문자 + DB enum/i18n 키와 일치하는 케이스 사용.
 *                       대문자나 라벨 형식 ('Email', 'In person' 등) 사용 금지.
 */

import { useRouter, usePathname, useSearchParams } from 'next/navigation';
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
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import type {
  CommunicationChannel,
  CommunicationDirection,
  InboxFilters,
} from '@/types/inbox';

interface Props {
  filters: InboxFilters;
}

const CHANNELS: readonly CommunicationChannel[] = [
  'email',
  'phone',
  'sms',
  'linkedin',
  'kakaotalk',
  'wechat',
  'whatsapp',
  'in_person',
  'video_call',
  'webform',
  'slack',
  'other',
] as const;

const DIRECTIONS: readonly CommunicationDirection[] = [
  'inbound',
  'outbound',
] as const;

export function InboxFiltersBar({ filters }: Props) {
  const t = useTranslations('inbox.filters');
  const tChannel = useTranslations('inbox.channels');
  const tDirection = useTranslations('inbox.directions');
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
    filters.channel !== 'all' ||
    filters.direction !== 'all' ||
    filters.hasDraft ||
    filters.query.length > 0 ||
    filters.partyId !== null;

  return (
    <div
      className="flex flex-wrap items-end gap-3 px-4 py-3 border-b bg-muted/30"
      aria-busy={isPending}
    >
      <div className="space-y-1 min-w-[140px]">
        <Label className="text-xs text-muted-foreground">{t('channel')}</Label>
        <Select
          value={filters.channel}
          onValueChange={(v) => setParam('channel', v)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('allChannels')}</SelectItem>
            {CHANNELS.map((c) => (
              <SelectItem key={c} value={c}>
                {tChannel(c)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="space-y-1 min-w-[140px]">
        <Label className="text-xs text-muted-foreground">{t('direction')}</Label>
        <Select
          value={filters.direction}
          onValueChange={(v) => setParam('direction', v)}
        >
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">{t('allDirections')}</SelectItem>
            {DIRECTIONS.map((d) => (
              <SelectItem key={d} value={d}>
                {tDirection(d)}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <div className="flex items-center gap-2 h-10 pb-0.5">
        <Checkbox
          id="inbox-has-draft"
          checked={filters.hasDraft}
          onCheckedChange={(v) => setParam('hasDraft', v === true ? '1' : null)}
        />
        <Label htmlFor="inbox-has-draft" className="cursor-pointer">
          {t('hasDraft')}
        </Label>
      </div>

      {isDirty && (
        <Button variant="ghost" size="sm" onClick={reset} className="ml-auto">
          <RotateCcw className="h-3.5 w-3.5" />
          {t('reset')}
        </Button>
      )}
    </div>
  );
}
