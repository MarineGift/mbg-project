'use client';

import { useTranslations } from 'next-intl';
import { ShieldAlert, ShieldCheck } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { ConfidenceBar } from '@/components/common/confidence-bar';
import { RiskFlagChip } from '@/components/common/risk-flag-chip';
import type { DraftDetail } from '@/types/draft-detail';

interface Props {
  draft: DraftDetail;
}

export function ClassificationPanel({ draft }: Props) {
  const tCat = useTranslations('classificationCategory');
  const tCommon = useTranslations('common');

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm flex items-center gap-2">
          {draft.requiresHumanApproval ? (
            <ShieldAlert className="h-4 w-4 text-destructive" />
          ) : (
            <ShieldCheck className="h-4 w-4 text-emerald-600" />
          )}
          AI Classification
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div>
            <p className="text-xs text-muted-foreground mb-1">Category</p>
            <p className="font-medium">
              {draft.classificationCategory
                ? tCat(draft.classificationCategory)
                : '—'}
            </p>
          </div>
          <div>
            <p className="text-xs text-muted-foreground mb-1">Confidence</p>
            <ConfidenceBar
              value={draft.confidenceScore ?? 0}
              showLabel
              className="w-full"
            />
          </div>
        </div>

        {draft.riskFlags.length > 0 && (
          <div>
            <p className="text-xs text-muted-foreground mb-1">Risk flags</p>
            <div className="flex flex-wrap gap-1">
              {draft.riskFlags.map((flag) => (
                <RiskFlagChip key={flag} flag={flag} />
              ))}
            </div>
          </div>
        )}

        {draft.rationale && (
          <div>
            <p className="text-xs text-muted-foreground mb-1">Rationale</p>
            <p className="text-sm leading-relaxed whitespace-pre-wrap">
              {draft.rationale}
            </p>
          </div>
        )}

        {draft.requiresHumanApproval && (
          <p className="text-xs text-destructive flex items-start gap-1 mt-2">
            <ShieldAlert className="h-3 w-3 mt-0.5 shrink-0" />
            <span>Human review required (AI flagged this draft for verification)</span>
          </p>
        )}

        {/* avoid unused warning */}
        <span hidden>{tCommon('loading')}</span>
      </CardContent>
    </Card>
  );
}
