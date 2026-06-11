'use client';

// src/components/inbox/deal-reassign-picker.tsx
//
// Compact "Deal" control shown in the inbox thread header. Lets the user
// link this communication (and its auto-logged engagement) to one of the
// party's open deals, or clear the link. Used mainly when the auto-log
// trigger left the message on the company only (0 or 2+ open deals).

import { useEffect, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Link2, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  listOpenDealsForParty,
  type OpenDealOption,
} from '@/lib/actions/compose-recipients';
import { reassignCommunicationDeal } from '@/lib/actions/reassign-communication';

const NO_DEAL = '__none__';

interface Props {
  communicationId: string;
  partyId: string;
  currentDealId: string | null;
}

export function DealReassignPicker({ communicationId, partyId, currentDealId }: Props) {
  const router = useRouter();
  const [options, setOptions] = useState<OpenDealOption[]>([]);
  const [value, setValue] = useState<string>(currentDealId ?? NO_DEAL);
  const [loading, setLoading] = useState(true);
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    listOpenDealsForParty(partyId)
      .then((res) => {
        if (cancelled) return;
        if (res.ok) setOptions(res.deals);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [partyId]);

  const onChange = (next: string) => {
    const prev = value;
    setValue(next);
    startTransition(async () => {
      const res = await reassignCommunicationDeal(
        communicationId,
        next === NO_DEAL ? null : next,
      );
      if (res.ok) {
        toast.success(next === NO_DEAL ? 'Deal link removed.' : 'Linked to deal.');
        router.refresh();
      } else {
        setValue(prev); // revert
        toast.error(res.error ?? 'Failed to update deal link.');
      }
    });
  };

  // If the current deal is no longer among open options (e.g. closed),
  // still show it as the selected value so the user sees the link.
  const showCurrentNotInList =
    currentDealId && !options.some((d) => d.dealId === currentDealId);

  return (
    <div className="flex items-center gap-1.5">
      <Link2 className="h-3.5 w-3.5 text-muted-foreground" />
      {loading ? (
        <span className="text-xs text-muted-foreground flex items-center gap-1">
          <Loader2 className="h-3 w-3 animate-spin" /> deals...
        </span>
      ) : options.length === 0 && !showCurrentNotInList ? (
        <span className="text-xs text-muted-foreground">No open deals</span>
      ) : (
        <Select value={value} onValueChange={onChange} disabled={isPending}>
          <SelectTrigger className="h-7 text-xs w-[200px]">
            <SelectValue placeholder="Link to deal" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value={NO_DEAL}>No deal (company only)</SelectItem>
            {showCurrentNotInList && (
              <SelectItem value={currentDealId as string}>Current deal</SelectItem>
            )}
            {options.map((d) => (
              <SelectItem key={d.dealId} value={d.dealId}>
                {d.dealName}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      )}
      {isPending && <Loader2 className="h-3 w-3 animate-spin text-muted-foreground" />}
    </div>
  );
}
