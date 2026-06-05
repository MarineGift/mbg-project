'use client';

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'; // adjust alias if your shadcn path differs
import type { Campaign } from '@/lib/queries/campaigns'; // adjust to your queries path

export const ALL_CAMPAIGNS = '__all__';

type Props = {
  campaigns: Campaign[];
  value: string | null; // campaign id, or ALL_CAMPAIGNS for the board filter
  onChange: (value: string | null) => void;
  /** board filter mode adds an "All campaigns" option; modal mode adds "None" */
  mode?: 'filter' | 'pick';
  placeholder?: string;
  className?: string;
};

export function CampaignSelect({
  campaigns,
  value,
  onChange,
  mode = 'pick',
  placeholder = 'Campaign',
  className,
}: Props) {
  const NONE = mode === 'filter' ? ALL_CAMPAIGNS : '__none__';

  return (
    <Select
      value={value ?? NONE}
      onValueChange={(v) => onChange(v === NONE ? (mode === 'filter' ? ALL_CAMPAIGNS : null) : v)}
    >
      <SelectTrigger className={className}>
        <SelectValue placeholder={placeholder} />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value={NONE}>
          {mode === 'filter' ? '전체 캠페인' : '캠페인 없음'}
        </SelectItem>
        {campaigns.map((c) => (
          <SelectItem key={c.id} value={c.id}>
            <span className="inline-flex items-center gap-2">
              <span
                className="h-2 w-2 rounded-full"
                style={{ backgroundColor: c.color ?? '#94a3b8' }}
              />
              {c.name}
            </span>
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}
