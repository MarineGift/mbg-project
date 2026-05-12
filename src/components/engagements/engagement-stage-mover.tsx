'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Loader2, ArrowRight } from 'lucide-react';
import { toast } from 'sonner';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import { moveEngagementStage } from '@/lib/actions/engagements';
import type { EngagementDetail } from '@/types/engagement';

interface Props {
  engagement: EngagementDetail;
}

export function EngagementStageMover({ engagement }: Props) {
  const router = useRouter();
  const t = useTranslations('engagements.detail.mover');
  const [isPending, startTransition] = useTransition();
  const [selectedStageId, setSelectedStageId] = useState<string | null>(
    engagement.currentStageId,
  );

  const isDisabled =
    engagement.availableStages.length === 0 ||
    engagement.status === 'archived';

  const handleMove = () => {
    if (!selectedStageId || selectedStageId === engagement.currentStageId) return;
    startTransition(async () => {
      const result = await moveEngagementStage({
        engagementId: engagement.id,
        toStageId: selectedStageId,
      });
      if (result.ok) {
        toast.success(t('moveSucceeded'));
        router.refresh();
      } else {
        toast.error(result.errorMessage ?? t('moveFailed'));
      }
    });
  };

  if (isDisabled) {
    return null;
  }

  const changed = selectedStageId !== engagement.currentStageId;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm">{t('title')}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-2">
        <Select
          value={selectedStageId ?? undefined}
          onValueChange={(v) => setSelectedStageId(v)}
          disabled={isPending}
        >
          <SelectTrigger>
            <SelectValue placeholder={t('selectStage')} />
          </SelectTrigger>
          <SelectContent>
            {engagement.availableStages.map((stage) => (
              <SelectItem key={stage.id} value={stage.id}>
                {stage.name}
                {stage.isWon && ' 🏆'}
                {stage.isLost && ' ✕'}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        {changed && (
          <Button
            onClick={handleMove}
            disabled={isPending}
            size="sm"
            className="w-full"
          >
            {isPending ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <ArrowRight className="h-4 w-4" />
            )}
            {t('move')}
          </Button>
        )}
      </CardContent>
    </Card>
  );
}
