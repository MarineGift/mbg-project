'use client';

import { useTransition, useState } from 'react';
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
import type { ModuleType } from '@/types/ai';
import type { EngagementDetail } from '@/types/engagement';

interface Props {
  mode: 'create' | 'edit';
  /** create 모드면 partyId/module 필수 */
  partyId?: string;
  partyName?: string;
  module: ModuleType;
  existing?: EngagementDetail | null;
}

const schema = z.object({
  name: z.string().min(1, 'Required').max(200),
  description: z.string().max(5000).optional().or(z.literal('')),
  valueAmount: z.string().optional().or(z.literal('')),
  valueCurrency: z.string().length(3).default('USD'),
  probabilityPct: z.string().optional().or(z.literal('')),
  expectedCloseDate: z.string().optional().or(z.literal('')),
  source: z.string().max(120).optional().or(z.literal('')),
});

type FormValues = z.infer<typeof schema>;

export function EngagementForm({ mode, partyId, partyName, module, existing }: Props) {
  const router = useRouter();
  const t = useTranslations('engagementForm');
  const [isPending, startTransition] = useTransition();
  const [showDelete, setShowDelete] = useState(false);

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
          valueAmount: existing.valueAmount?.toString() ?? '',
          valueCurrency: existing.valueCurrency,
          probabilityPct: String(existing.probabilityPct),
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
    if (mode === 'create' && !partyId) {
      toast.error(t('partyRequired'));
      return;
    }

    startTransition(async () => {
      const valueAmount = values.valueAmount?.trim()
        ? Number(values.valueAmount)
        : null;
      const probabilityPct = values.probabilityPct?.trim()
        ? Math.max(0, Math.min(100, Math.floor(Number(values.probabilityPct))))
        : 0;

      const payload = {
        partyId: existing?.partyId ?? partyId!,
        module,
        name: values.name,
        description: values.description || null,
        valueAmount,
        valueCurrency: values.valueCurrency || 'USD',
        probabilityPct,
        expectedCloseDate: values.expectedCloseDate || null,
        source: values.source || null,
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
        router.push(`/${module}/engagements`);
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
          <CardTitle>{mode === 'create' ? t('createTitle') : t('editTitle')}</CardTitle>
          <CardDescription>
            {mode === 'create' && partyName
              ? t('createDescription', { party: partyName })
              : mode === 'edit' && existing
                ? t('editDescription', { party: existing.partyName })
                : t('createDescriptionGeneric')}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
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

          <div className="space-y-2">
            <Label htmlFor="eng-description">{t('description')}</Label>
            <Textarea
              id="eng-description"
              {...register('description')}
              disabled={isPending}
              rows={3}
            />
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="space-y-2 col-span-2">
              <Label htmlFor="eng-value">{t('value')}</Label>
              <Input
                id="eng-value"
                type="number"
                step="0.01"
                {...register('valueAmount')}
                disabled={isPending}
                placeholder="0.00"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="eng-currency">{t('currency')}</Label>
              <Input
                id="eng-currency"
                {...register('valueCurrency')}
                disabled={isPending}
                maxLength={3}
                placeholder="USD"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="eng-prob">{t('probability')}</Label>
              <Input
                id="eng-prob"
                type="number"
                min="0"
                max="100"
                {...register('probabilityPct')}
                disabled={isPending}
                placeholder="0"
              />
              <p className="text-xs text-muted-foreground">{t('probabilityHint')}</p>
            </div>
            <div className="space-y-2">
              <Label htmlFor="eng-close">{t('expectedClose')}</Label>
              <Input
                id="eng-close"
                type="date"
                {...register('expectedCloseDate')}
                disabled={isPending}
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="eng-source">{t('source')}</Label>
            <Input
              id="eng-source"
              {...register('source')}
              disabled={isPending}
              placeholder={t('sourcePlaceholder')}
            />
          </div>
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
            <Button type="button" variant="outline" onClick={() => router.back()} disabled={isPending}>
              {t('cancel')}
            </Button>
            <Button type="submit" disabled={isPending || (mode === 'edit' && !isDirty)}>
              {isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
              {mode === 'create' ? t('create') : t('save')}
            </Button>
          </div>
        </CardFooter>
      </Card>

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
              <Button variant="outline" onClick={() => setShowDelete(false)} disabled={isPending}>
                {t('cancel')}
              </Button>
              <Button variant="destructive" onClick={onDelete} disabled={isPending}>
                {isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
                {t('deleteConfirm')}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}
    </form>
  );
}
