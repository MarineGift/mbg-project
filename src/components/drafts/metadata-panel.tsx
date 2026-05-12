'use client';

import { Brain, Coins, Timer } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import type { DraftDetail } from '@/types/draft-detail';

interface Props {
  draft: DraftDetail;
}

export function MetadataPanel({ draft }: Props) {
  const totalCost =
    (draft.classifierRun?.costUsd ?? 0) + (draft.drafterRun?.costUsd ?? 0);
  const totalLatency =
    (draft.classifierRun?.latencyMs ?? 0) + (draft.drafterRun?.latencyMs ?? 0);

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm flex items-center gap-2">
          <Brain className="h-4 w-4 text-muted-foreground" />
          AI Run Metadata
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3 text-sm">
        <div className="grid grid-cols-2 gap-3 text-xs">
          <Stat
            icon={<Coins className="h-3 w-3" />}
            label="Total cost"
            value={`$${totalCost.toFixed(4)}`}
          />
          <Stat
            icon={<Timer className="h-3 w-3" />}
            label="Total latency"
            value={`${totalLatency} ms`}
          />
        </div>

        {draft.classifierRun && (
          <RunSection title="Classifier" run={draft.classifierRun} />
        )}
        {draft.drafterRun && (
          <RunSection title="Reply Drafter" run={draft.drafterRun} />
        )}

        {draft.editDistance != null && (
          <div className="pt-2 border-t">
            <p className="text-xs text-muted-foreground mb-1">Edit distance</p>
            <p className="text-sm font-medium tabular-nums">
              {draft.editDistance}
            </p>
            <p className="text-xs text-muted-foreground mt-0.5">
              Human edits vs. AI original (lower = AI output retained more)
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

function Stat({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div>
      <p className="text-muted-foreground flex items-center gap-1 mb-0.5">
        {icon}
        {label}
      </p>
      <p className="font-medium tabular-nums">{value}</p>
    </div>
  );
}

function RunSection({
  title,
  run,
}: {
  title: string;
  run: import('@/types/draft-detail').DraftRunSummary;
}) {
  return (
    <div className="pt-2 border-t">
      <p className="text-xs font-medium mb-1">{title}</p>
      <div className="grid grid-cols-2 gap-x-3 gap-y-0.5 text-xs">
        <span className="text-muted-foreground">Model</span>
        <span className="font-mono truncate" title={run.modelUsed}>
          {run.modelUsed}
        </span>
        <span className="text-muted-foreground">In / Out</span>
        <span className="tabular-nums">
          {run.inputTokens ?? '—'} / {run.outputTokens ?? '—'}
        </span>
        <span className="text-muted-foreground">Cost</span>
        <span className="tabular-nums">${run.costUsd.toFixed(4)}</span>
        <span className="text-muted-foreground">Latency</span>
        <span className="tabular-nums">{run.latencyMs ?? '—'} ms</span>
      </div>
    </div>
  );
}
