/**
 * components/engagements/engagement-form.tsx
 *
 * Engagement create / edit 통합 폼.
 * party-form.tsx 패턴을 그대로 따름 (RHF + zodResolver, useTransition, Card layout,
 * Delete Dialog, toast).
 *
 * 차이점:
 *   - partyId / partyName이 항상 필요 (engagement는 반드시 party에 속함)
 *   - currentStageId는 edit 모드에서만 노출 (create 시엔 서버가 첫 stage 자동 할당)
 *   - stage 변경은 detail 페이지의 EngagementStageMover에서 별도 처리되므로
 *     edit 폼에서는 의도적으로 stage select를 노출하지 않음 (혼란 방지)
 *
 * 변경 이력:
 *   - 2026-05-12: i18n 키 이름을 ko/en/ja.json의 기존 engagementForm namespace
 *                 키와 일치하게 정렬:
 *                 valueAmount → value, valueCurrency → currency,
 *                 probabilityPct → probability, expectedCloseDate → expectedClose,
 *                 missingParty → partyRequired
 */

'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useTranslations } from 'next-intl';
import { Loader2, Save, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  createEngagement,
  updateEngagement,
  deleteEngagement,
} from '@/lib/actions/engagements';
import type { PartyTypeCode } from '@/types/ai';
import type { EngagementDetail } from '@/types/engagement';

interface Props {
  mode: 'create' | 'edit';
  /** create + edit 모두에서 module 결정용 */
  module: PartyTypeCode;
  /** create 모드 필수, edit 모드에서는 existing.partyId 사용 */
  partyId?: string;
  /** create 모드 표시용. edit 모드에서는 existing.partyName 사용 */
  partyName?: string;
  /** edit 모드에서만 */
  existing?: EngagementDetail | null;
}

const schema = z.object({
  name: z.string().min(1, 'Required').max(200),
  description: z.string().max(5000).optional().or(z.literal('')),
  valueAmount: z
    .string()
    .optional()
    .or(z.literal(''))
    .refine(
      (s) => !s || (!isNaN(Number(s)) && Number(s) >= 0),
      'Must be a non-negative number',
    ),
  valueCurrency: z
    .string()
    .length(3, 'Use 3-letter ISO code (e.g. USD)')
    .toUpperCase(),
  probabilityPct: z
    .string()
    .refine((s) => {
      const n = Number(s);
      return Number.isInteger(n) && n >= 0 && n <= 100;
    }, '0–100 integer'),
  expectedCloseDate: z
    .string()
    .optional()
    .or(z.literal(''))
    .refine(
      (s) => !s || /^\d{4}-\d{2}-\d{2}$/.test(s),
      'Use YYYY-MM-DD format',
    ),
  source: z.string().max(120).optional().or(z.literal('')),
});

type FormValues = z.infer<typeof schema>;

const CURRENCIES = ['USD', 'EUR', 'JPY', 'KRW', 'GBP', 'CNY'] as const;

export function EngagementForm({
  mode,
  module,
  partyId,
  partyName,
  existing,
}: Props) {
  const router = useRouter();
  const t = useTranslations('engagementForm');
  const [isPending, startTransition] = useTransition();
  const [showDelete, setShowDelete] = useState(false);

  // create 모드에서 partyId는 페이지가 보장. edit 모드에서는 existing이 보장.
  const effectivePartyId = existing?.partyId ?? partyId;
  const effectivePartyName = existing?.partyName ?? partyName ?? '';

  const {
    register,
    handleSubmit,
    formState: { errors, isDirty },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: existing
      ? {
          name: existing.name,
          description: existing.description ?? '',
          valueAmount:
            existing.valueAmount != null ? String(existing.valueAmount) : '',
          valueCurrency: existing.valueCurrency || 'USD',
          probabilityPct: String(existing.probabilityPct ?? 0),
          expectedCloseDate: existing.expectedCloseDate ?? '',
          source: existing.source ?? '',
        }
      : {
          name: '',
          description: '',
          valueAmount: '',
          valueCurrency: 'USD',
          probabilityPct: '0',
          expectedCloseDate: '',
          source: '',
        },
  });

  const onSubmit = (values: FormValues) => {
    if (!effectivePartyId) {
      toast.error(t('partyRequired'));
      return;
    }

    startTransition(async () => {
      const payload = {
        partyId: effectivePartyId,
        module,
        name: values.name.trim(),
        description: values.description?.trim() || null,
        valueAmount: values.valueAmount ? Number(values.valueAmount) : null,
        valueCurrency: values.valueCurrency.toUpperCase(),
        probabilityPct: Number(values.probabilityPct),
        expectedCloseDate: values.expectedCloseDate || null,
        source: values.source?.trim() || null,
      };

      if (mode === 'create') {
        const result = await createEngagement(payload);
        if (result.ok && result.engagementId) {
          toast.success(t('created'));
          router.push(`/engagements/${result.engagementId}`);
        } else {
          toast.error(result.errorMessage ?? t('saveFailed'));
        }
      } else if (existing) {
        const result = await updateEngagement({
          engagementId: existing.id,
          ...payload,
        });
        if (result.ok) {
          toast.success(t('updated'));
          router.push(`/engagements/${existing.id}`);
        } else {
          toast.error(result.errorMessage ?? t('saveFailed'));
        }
      }
    });
  };

  const onDelete = () => {
    if (!existing) return;
    startTransition(async () => {
      const result = await deleteEngagement({ engagementId: existing.id });
      if (result.ok) {
        toast.success(t('deleted'));
        // delete 후 party 상세 페이지로 이동
        router.push(`/${existing.partyModule}/parties/${existing.partyId}`);
      } else {
        toast.error(result.errorMessage ?? t('deleteFailed'));
        setShowDelete(false);
      }
    });
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <Card>
        <CardHeader>
          <CardTitle>
            {mode === 'create' ? t('createTitle') : t('editTitle')}
          </CardTitle>
          <CardDescription>
            {mode === 'create'
              ? t('createDescription', { party: effectivePartyName })
              : t('editDescription', { party: effectivePartyName })}
          </CardDescription>
        </CardHeader>

        <CardContent className="space-y-4">
          {/* Name */}
          <div className="space-y-2">
            <Label htmlFor="eng-name">{t('name')} *</Label>
            <Input
              id="eng-name"
              {...register('name')}
              disabled={isPending}
              placeholder={t('namePlaceholder')}
              aria-invalid={errors.name ? 'true' : undefined}
            />
            {errors.name && (
              <p className="text-xs text-destructive">{errors.name.message}</p>
            )}
          </div>

          {/* Description */}
          <div className="space-y-2">
            <Label htmlFor="eng-description">{t('description')}</Label>
            <Textarea
              id="eng-description"
              {...register('description')}
              disabled={isPending}
              rows={3}
              placeholder={t('descriptionPlaceholder')}
            />
          </div>

          {/* Value / Currency / Probability — 3-column grid */}
          <div className="grid grid-cols-3 gap-3">
            <div className="space-y-2 col-span-2">
              <Label htmlFor="eng-value">{t('value')}</Label>
              <Input
                id="eng-value"
                type="number"
                step="any"
                min="0"
                {...register('valueAmount')}
                disabled={isPending}
                placeholder="0"
                aria-invalid={errors.valueAmount ? 'true' : undefined}
              />
              {errors.valueAmount && (
                <p className="text-xs text-destructive">
                  {errors.valueAmount.message}
                </p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="eng-currency">{t('currency')}</Label>
              <select
                id="eng-currency"
                {...register('valueCurrency')}
                disabled={isPending}
                className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
              >
                {CURRENCIES.map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
              {errors.valueCurrency && (
                <p className="text-xs text-destructive">
                  {errors.valueCurrency.message}
                </p>
              )}
            </div>
          </div>

          {/* Probability + Expected close date */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="eng-probability">{t('probability')}</Label>
              <Input
                id="eng-probability"
                type="number"
                min="0"
                max="100"
                step="1"
                {...register('probabilityPct')}
                disabled={isPending}
                aria-invalid={errors.probabilityPct ? 'true' : undefined}
              />
              {errors.probabilityPct ? (
                <p className="text-xs text-destructive">
                  {errors.probabilityPct.message}
                </p>
              ) : (
                <p className="text-xs text-muted-foreground">
                  {t('probabilityHint')}
                </p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="eng-close">{t('expectedClose')}</Label>
              <Input
                id="eng-close"
                type="date"
                {...register('expectedCloseDate')}
                disabled={isPending}
                aria-invalid={errors.expectedCloseDate ? 'true' : undefined}
              />
              {errors.expectedCloseDate && (
                <p className="text-xs text-destructive">
                  {errors.expectedCloseDate.message}
                </p>
              )}
            </div>
          </div>

          {/* Source */}
          <div className="space-y-2">
            <Label htmlFor="eng-source">{t('source')}</Label>
            <Input
              id="eng-source"
              {...register('source')}
              disabled={isPending}
              placeholder={t('sourcePlaceholder')}
            />
          </div>

          {/* edit 모드 정보 (stage / status는 별도 페이지에서 변경) */}
          {mode === 'edit' && existing && (
            <div className="rounded-md border border-dashed border-muted-foreground/30 bg-muted/20 p-3 text-xs text-muted-foreground space-y-1">
              <p>{t('stageNote')}</p>
              {existing.currentStageName && (
                <p>
                  <span className="font-medium">{t('currentStage')}:</span>{' '}
                  {existing.currentStageName}
                </p>
              )}
              <p>
                <span className="font-medium">{t('currentStatus')}:</span>{' '}
                {existing.status}
              </p>
            </div>
          )}
        </CardContent>

        <CardFooter className="flex justify-between">
          {mode === 'edit' && (
            <Button
              type="button"
              variant="destructive"
              onClick={() => setShowDelete(true)}
              disabled={isPending}
            >
              <Trash2 className="h-4 w-4" />
              {t('delete')}
            </Button>
          )}
          <div className="flex gap-2 ml-auto">
            <Button
              type="button"
              variant="outline"
              onClick={() => router.back()}
              disabled={isPending}
            >
              {t('cancel')}
            </Button>
            <Button
              type="submit"
              disabled={isPending || (mode === 'edit' && !isDirty)}
            >
              {isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Save className="h-4 w-4" />
              )}
              {mode === 'create' ? t('create') : t('save')}
            </Button>
          </div>
        </CardFooter>
      </Card>

      {/* Delete confirmation */}
      {existing && (
        <Dialog open={showDelete} onOpenChange={setShowDelete}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>{t('deleteConfirmTitle')}</DialogTitle>
              <DialogDescription>
                {t('deleteConfirmDescription', { name: existing.name })}
              </DialogDescription>
            </DialogHeader>
            <DialogFooter>
              <Button
                variant="outline"
                onClick={() => setShowDelete(false)}
                disabled={isPending}
              >
                {t('cancel')}
              </Button>
              <Button
                variant="destructive"
                onClick={onDelete}
                disabled={isPending}
              >
                {isPending ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : (
                  <Trash2 className="h-4 w-4" />
                )}
                {t('deleteConfirm')}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </form>
  );
}
