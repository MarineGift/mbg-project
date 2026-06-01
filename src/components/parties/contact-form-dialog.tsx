'use client';

import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useTranslations } from 'next-intl';
import { Loader2, Save } from 'lucide-react';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Textarea } from '@/components/ui/textarea';
import { createContact, updateContact } from '@/lib/actions/contacts';
import type { PartyContact } from '@/types/party-detail';

interface Props {
  partyId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** the existing contact when in edit mode */
  existing?: PartyContact | null;
}

const schema = z.object({
  fullName: z.string().min(1, 'Required').max(160),
  title: z.string().max(120).optional().or(z.literal('')),
  email: z.string().email('Invalid email').max(255).optional().or(z.literal('')),
  phone: z.string().max(40).optional().or(z.literal('')),
  isPrimary: z.boolean().default(false),
  notes: z.string().max(2000).optional().or(z.literal('')),
});

type FormValues = z.infer<typeof schema>;

export function ContactFormDialog({ partyId, open, onOpenChange, existing }: Props) {
  const router = useRouter();
  const t = useTranslations('contactForm');
  const [isPending, startTransition] = useTransition();

  const {
    register,
    handleSubmit,
    formState: { errors, isDirty },
    setValue,
    watch,
    reset,
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: existing
      ? {
          fullName: existing.fullName ?? '',
          title: existing.jobTitle ?? '',
          email: existing.email ?? '',
          phone: existing.phone ?? '',
          isPrimary: existing.isPrimary,
          notes: '',
        }
      : {
          fullName: '',
          title: '',
          email: '',
          phone: '',
          isPrimary: false,
          notes: '',
        },
  });

  const isPrimary = watch('isPrimary');

  const onSubmit = (values: FormValues) => {
    startTransition(async () => {
      const payload = {
        partyId,
        fullName: values.fullName,
        title: values.title || undefined,
        email: values.email || undefined,
        phone: values.phone || undefined,
        isPrimary: values.isPrimary,
        notes: values.notes || undefined,
        decisionRole: 'unknown' as const,
      };

      const result = existing
        ? await updateContact({ contactId: existing.id, ...payload })
        : await createContact(payload);

      if (result.ok) {
        toast.success(existing ? t('updated') : t('created'));
        onOpenChange(false);
        reset();
        router.refresh();
      } else {
        toast.error(result.errorMessage ?? t('saveFailed'));
      }
    });
  };

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!isPending) onOpenChange(v); }}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {existing ? t('editTitle') : t('createTitle')}
          </DialogTitle>
          <DialogDescription>
            {existing ? t('editDescription') : t('createDescription')}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-3" noValidate>
          <div className="space-y-2">
            <Label htmlFor="contact-name">{t('fullName')} *</Label>
            <Input
              id="contact-name"
              {...register('fullName')}
              disabled={isPending}
              autoFocus
              aria-invalid={errors.fullName ? 'true' : undefined}
            />
            {errors.fullName && (
              <p className="text-xs text-destructive">{errors.fullName.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="contact-title">{t('title')}</Label>
            <Input
              id="contact-title"
              {...register('title')}
              disabled={isPending}
              placeholder="CEO, Procurement Manager..."
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="contact-email">{t('email')}</Label>
              <Input
                id="contact-email"
                type="email"
                {...register('email')}
                disabled={isPending}
                aria-invalid={errors.email ? 'true' : undefined}
              />
              {errors.email && (
                <p className="text-xs text-destructive">{errors.email.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="contact-phone">{t('phone')}</Label>
              <Input id="contact-phone" {...register('phone')} disabled={isPending} />
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Checkbox
              id="contact-primary"
              checked={isPrimary}
              onCheckedChange={(v) => setValue('isPrimary', v === true, { shouldDirty: true })}
            />
            <Label htmlFor="contact-primary" className="cursor-pointer">
              {t('isPrimary')}
            </Label>
          </div>

          <div className="space-y-2">
            <Label htmlFor="contact-notes">{t('notes')}</Label>
            <Textarea
              id="contact-notes"
              {...register('notes')}
              disabled={isPending}
              rows={2}
            />
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={isPending}
            >
              {t('cancel')}
            </Button>
            <Button type="submit" disabled={isPending || (Boolean(existing) && !isDirty)}>
              {isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
              {existing ? t('save') : t('create')}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
