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
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { createParty, updateParty, deleteParty } from '@/lib/actions/parties';
import { PARTY_TYPES, type PartyType, type PartyKind } from '@/types/party-type';
import type { PartyDetail, PartyTier } from '@/types/party-detail';

interface Props {
  /** existing party in edit mode; null + initial partyType in create mode */
  mode: 'create' | 'edit';
  initialPartyType: PartyType;
  existing?: PartyDetail | null;
}

const schema = z.object({
  name: z.string().min(1, 'Required').max(200),
  legalName: z.string().max(200).optional().or(z.literal('')),
  // Tracks the canonical PARTY_TYPES list (types/party-type.ts) so new
  // party types never require editing this schema by hand.
  partyType: z.enum(PARTY_TYPES as unknown as [PartyType, ...PartyType[]]),
  partyKind: z.enum(['company', 'organization', 'individual', 'fund', 'government']),
  tier: z.enum(['tier_1', 'tier_2', 'tier_3', 'cold']),
  countryCode: z
    .string()
    .max(2)
    .optional()
    .or(z.literal(''))
    .refine((s) => !s || /^[A-Za-z]{2}$/.test(s), 'Must be 2 letters'),
  region: z.string().max(80).optional().or(z.literal('')),
  city: z.string().max(120).optional().or(z.literal('')),
  website: z
    .string()
    .max(500)
    .optional()
    .or(z.literal(''))
    .refine(
      (s) => !s || /^https?:\/\/.+/.test(s),
      'Must start with http:// or https://',
    ),
  industryTags: z.string().max(500).optional().or(z.literal('')),
  interestTags: z.string().max(500).optional().or(z.literal('')),
  source: z.string().max(120).optional().or(z.literal('')),
  notes: z.string().max(10_000).optional().or(z.literal('')),
});

type FormValues = z.infer<typeof schema>;

const PARTY_KINDS: readonly PartyKind[] = [
  'company',
  'organization',
  'individual',
  'fund',
  'government',
] as const;

const TIERS: readonly PartyTier[] = ['tier_1', 'tier_2', 'tier_3', 'cold'] as const;

function parseTagsInput(raw: string | undefined): string[] {
  if (!raw) return [];
  const seen = new Set<string>();
  const out: string[] = [];
  for (const part of raw.split(',')) {
    const trimmed = part.trim();
    if (trimmed && !seen.has(trimmed)) {
      seen.add(trimmed);
      out.push(trimmed);
    }
  }
  return out;
}

export function PartyForm({ mode, initialPartyType, existing }: Props) {
  const router = useRouter();
  const t = useTranslations('partyForm');
  const tPartyTypes = useTranslations('partyTypes');
  const tPartyKinds = useTranslations('partyKinds');
  const [isPending, startTransition] = useTransition();
  const [showDelete, setShowDelete] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors, isDirty },
    watch,
    setValue,
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: existing
      ? {
          name: existing.name,
          legalName: '',
          partyType: existing.partyType,
          partyKind: 'company',
          tier: existing.tier ?? 'tier_3',
          countryCode: existing.countryCode ?? '',
          region: '',
          city: '',
          website: existing.website ?? '',
          industryTags: existing.industryTags.join(', '),
          interestTags: existing.interestTags.join(', '),
          source: existing.source ?? '',
          notes: existing.notes ?? '',
        }
      : {
          name: '',
          legalName: '',
          partyType: initialPartyType,
          partyKind: 'company',
          tier: 'tier_3',
          countryCode: '',
          region: '',
          city: '',
          website: '',
          industryTags: '',
          interestTags: '',
          source: '',
          notes: '',
        },
  });

  const selectedPartyType = watch('partyType');
  const selectedPartyKind = watch('partyKind');
  const selectedTier = watch('tier');

  const onSubmit = (values: FormValues) => {
    startTransition(async () => {
      const industryTags = parseTagsInput(values.industryTags);
      const interestTags = parseTagsInput(values.interestTags);

      const payload = {
        name: values.name,
        legalName: values.legalName || null,
        partyType: values.partyType,
        partyKind: values.partyKind,
        tier: values.tier,
        countryCode: values.countryCode || null,
        region: values.region || null,
        city: values.city || null,
        website: values.website || null,
        industryTags,
        interestTags,
        source: values.source || null,
        notes: values.notes || null,
      };

      if (mode === 'create') {
        const result = await createParty(payload);
        if (result.ok && result.partyId) {
          toast.success(t('created'));
          router.push(`/${values.partyType}/parties/${result.partyId}`);
        } else {
          toast.error(result.errorMessage ?? t('saveFailed'));
        }
      } else if (existing) {
        const result = await updateParty({ partyId: existing.id, ...payload });
        if (result.ok) {
          toast.success(t('updated'));
          router.push(`/${values.partyType}/parties/${existing.id}`);
        } else {
          toast.error(result.errorMessage ?? t('saveFailed'));
        }
      }
    });
  };

  const onDelete = () => {
    if (!existing) return;
    startTransition(async () => {
      const result = await deleteParty({ partyId: existing.id });
      if (!result.ok) {
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
            {mode === 'create' ? t('createDescription') : t('editDescription')}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Name */}
          <div className="space-y-2">
            <Label htmlFor="party-name">{t('name')} *</Label>
            <Input
              id="party-name"
              {...register('name')}
              disabled={isPending}
              aria-invalid={errors.name ? 'true' : undefined}
            />
            {errors.name && (
              <p className="text-xs text-destructive">{errors.name.message}</p>
            )}
          </div>

          {/* PartyType + PartyKind + Tier */}
          <div className="grid grid-cols-3 gap-3">
            <div className="space-y-2">
              <Label htmlFor="party-type">{t('partyType')} *</Label>
              <Select
                value={selectedPartyType}
                onValueChange={(v) => setValue('partyType', v as PartyType, { shouldDirty: true })}
                disabled={isPending}
              >
                <SelectTrigger id="party-type">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {PARTY_TYPES.map((pt) => (
                    <SelectItem key={pt} value={pt}>
                      {tPartyTypes(pt)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="party-kind">{t('partyKind')}</Label>
              <Select
                value={selectedPartyKind}
                onValueChange={(v) => setValue('partyKind', v as PartyKind, { shouldDirty: true })}
                disabled={isPending}
              >
                <SelectTrigger id="party-kind">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {PARTY_KINDS.map((pk) => (
                    <SelectItem key={pk} value={pk}>
                      {tPartyKinds(pk)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="party-tier">{t('tier')}</Label>
              <Select
                value={selectedTier}
                onValueChange={(v) => setValue('tier', v as PartyTier, { shouldDirty: true })}
                disabled={isPending}
              >
                <SelectTrigger id="party-tier">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {TIERS.map((tier) => (
                    <SelectItem key={tier} value={tier}>
                      {t(`tiers.${tier}`)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Legal name */}
          <div className="space-y-2">
            <Label htmlFor="party-legal">{t('legalName')}</Label>
            <Input
              id="party-legal"
              {...register('legalName')}
              disabled={isPending}
              placeholder={t('legalNamePlaceholder')}
            />
          </div>

          {/* Location grid */}
          <div className="grid grid-cols-3 gap-3">
            <div className="space-y-2">
              <Label htmlFor="party-country">{t('countryCode')}</Label>
              <Input
                id="party-country"
                {...register('countryCode')}
                disabled={isPending}
                placeholder="KR"
                maxLength={2}
                aria-invalid={errors.countryCode ? 'true' : undefined}
              />
              {errors.countryCode && (
                <p className="text-xs text-destructive">{errors.countryCode.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="party-region">{t('region')}</Label>
              <Input id="party-region" {...register('region')} disabled={isPending} />
            </div>
            <div className="space-y-2">
              <Label htmlFor="party-city">{t('city')}</Label>
              <Input id="party-city" {...register('city')} disabled={isPending} />
            </div>
          </div>

          {/* Website */}
          <div className="space-y-2">
            <Label htmlFor="party-website">{t('website')}</Label>
            <Input
              id="party-website"
              {...register('website')}
              disabled={isPending}
              placeholder="https://example.com"
              aria-invalid={errors.website ? 'true' : undefined}
            />
            {errors.website && (
              <p className="text-xs text-destructive">{errors.website.message}</p>
            )}
          </div>

          {/* Industry Tags */}
          <div className="space-y-2">
            <Label htmlFor="party-industry-tags">{t('industryTags')}</Label>
            <Input
              id="party-industry-tags"
              {...register('industryTags')}
              disabled={isPending}
              placeholder={t('industryTagsPlaceholder')}
            />
            <p className="text-xs text-muted-foreground">{t('industryTagsHint')}</p>
          </div>

          {/* Interest Tags */}
          <div className="space-y-2">
            <Label htmlFor="party-interest-tags">{t('interestTags')}</Label>
            <Input
              id="party-interest-tags"
              {...register('interestTags')}
              disabled={isPending}
              placeholder={t('interestTagsPlaceholder')}
            />
            <p className="text-xs text-muted-foreground">{t('interestTagsHint')}</p>
          </div>

          {/* Source */}
          <div className="space-y-2">
            <Label htmlFor="party-source">{t('source')}</Label>
            <Input
              id="party-source"
              {...register('source')}
              disabled={isPending}
              placeholder={t('sourcePlaceholder')}
            />
          </div>

          {/* Notes */}
          <div className="space-y-2">
            <Label htmlFor="party-notes">{t('notes')}</Label>
            <Textarea
              id="party-notes"
              {...register('notes')}
              disabled={isPending}
              rows={5}
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
            <Button
              type="button"
              variant="outline"
              onClick={() => router.back()}
              disabled={isPending}
            >
              {t('cancel')}
            </Button>
            <Button type="submit" disabled={isPending || (mode === 'edit' && !isDirty)}>
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
