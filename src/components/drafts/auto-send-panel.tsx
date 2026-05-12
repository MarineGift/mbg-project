'use client';

import { CheckCircle2, XCircle, Zap } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import type { DraftAutoSendInfo } from '@/types/draft-detail';
import { cn } from '@/lib/utils';

interface Props {
  autoSend: DraftAutoSendInfo;
}

export function AutoSendPanel({ autoSend }: Props) {
  const eligible = autoSend.eligible;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm flex items-center gap-2">
          <Zap className="h-4 w-4 text-muted-foreground" />
          Auto-Send Evaluation
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3 text-sm">
        <div className="flex items-center gap-2">
          {eligible ? (
            <>
              <CheckCircle2 className="h-4 w-4 text-emerald-600" />
              <span className="font-medium">Eligible for auto-send</span>
            </>
          ) : (
            <>
              <XCircle className="h-4 w-4 text-muted-foreground" />
              <span className="font-medium">Held for human review</span>
            </>
          )}
        </div>

        {!eligible && autoSend.blockedReasons.length > 0 && (
          <div>
            <p className="text-xs text-muted-foreground mb-1">Blocked reasons</p>
            <ul className="space-y-1">
              {autoSend.blockedReasons.map((reason) => (
                <li
                  key={reason}
                  className="text-xs flex items-start gap-1.5 text-destructive"
                >
                  <XCircle className="h-3 w-3 mt-0.5 shrink-0" />
                  <span className="font-mono">{reason}</span>
                </li>
              ))}
            </ul>
          </div>
        )}

        {autoSend.rule && (
          <div className="pt-2 border-t">
            <p className="text-xs text-muted-foreground mb-1">Rule applied</p>
            <div className="grid grid-cols-2 gap-x-3 gap-y-0.5 text-xs">
              <span className="text-muted-foreground">Category</span>
              <span className="font-mono">
                {autoSend.rule.classificationCategory}
              </span>
              <span className="text-muted-foreground">Min confidence</span>
              <span className="tabular-nums">
                {(autoSend.rule.minConfidence * 100).toFixed(0)}%
              </span>
              <span className="text-muted-foreground">Active</span>
              <span
                className={cn(
                  autoSend.rule.isActive ? 'text-emerald-600' : 'text-muted-foreground',
                )}
              >
                {autoSend.rule.isActive ? 'Yes' : 'No'}
              </span>
              {autoSend.rule.isBlocked && (
                <>
                  <span className="text-muted-foreground">Kill switch</span>
                  <span className="text-destructive">
                    {autoSend.rule.blockReason ?? 'blocked'}
                  </span>
                </>
              )}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
