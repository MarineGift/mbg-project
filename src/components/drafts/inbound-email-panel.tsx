'use client';

import { useState } from 'react';
import { ChevronDown, ChevronUp, Mail } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { RelativeTime } from '@/components/common/relative-time';
import type { DraftInboundSummary } from '@/types/draft-detail';
import { cn } from '@/lib/utils';

interface Props {
  inbound: DraftInboundSummary | null;
}

export function InboundEmailPanel({ inbound }: Props) {
  const [expanded, setExpanded] = useState(true);

  if (!inbound) {
    return (
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-sm flex items-center gap-2">
            <Mail className="h-4 w-4 text-muted-foreground" />
            Original Email
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-xs text-muted-foreground">
            No inbound message linked. This may be a manually-created draft.
          </p>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card>
      <CardHeader className="pb-3 flex flex-row items-center justify-between">
        <CardTitle className="text-sm flex items-center gap-2">
          <Mail className="h-4 w-4 text-muted-foreground" />
          Original Email
        </CardTitle>
        <Button
          variant="ghost"
          size="icon"
          className="h-7 w-7"
          onClick={() => setExpanded((v) => !v)}
          aria-label={expanded ? 'Collapse' : 'Expand'}
        >
          {expanded ? (
            <ChevronUp className="h-4 w-4" />
          ) : (
            <ChevronDown className="h-4 w-4" />
          )}
        </Button>
      </CardHeader>
      <CardContent className="space-y-3 text-sm">
        <div className="grid grid-cols-[auto_1fr] gap-x-3 gap-y-1 text-xs">
          <span className="text-muted-foreground">From</span>
          <span className="font-mono truncate">
            {inbound.fromName ? `${inbound.fromName} <${inbound.fromAddress}>` : inbound.fromAddress}
          </span>
          <span className="text-muted-foreground">To</span>
          <span className="font-mono truncate">
            {inbound.toAddresses.join(', ')}
          </span>
          {inbound.ccAddresses.length > 0 && (
            <>
              <span className="text-muted-foreground">Cc</span>
              <span className="font-mono truncate">
                {inbound.ccAddresses.join(', ')}
              </span>
            </>
          )}
          <span className="text-muted-foreground">When</span>
          <RelativeTime date={inbound.occurredAt} live={false} className="font-medium" />
          <span className="text-muted-foreground">Subject</span>
          <span className="font-medium truncate">
            {inbound.subject ?? '(no subject)'}
          </span>
        </div>

        {expanded && inbound.bodyPlain && (
          <div className={cn(
            'mt-3 p-3 rounded-md bg-muted/40 text-sm whitespace-pre-wrap font-mono leading-relaxed max-h-[280px] overflow-y-auto scrollbar-thin',
          )}>
            {inbound.bodyPlain}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
