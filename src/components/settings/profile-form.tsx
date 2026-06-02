'use client';

import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useTranslations } from 'next-intl';
import { Loader2, Save } from 'lucide-react';
import { toast } from 'sonner';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { updateUserProfile } from '@/lib/actions/profile';
import type { UserProfile } from '@/lib/queries/user-profile';
import { SUPPORTED_TIMEZONES, DEFAULT_TIMEZONE } from '@/lib/constants/timezones';

interface Props {
  profile: UserProfile;
}

const schema = z.object({
  fullName: z.string().min(1, 'Required').max(120),
  displayName: z.string().max(60).optional().or(z.literal('')),
  sendingEmail: z.string().email('Invalid email').max(255).optional().or(z.literal('')),
  timezone: z.string().min(1),
});

type FormValues = z.infer<typeof schema>;

export function ProfileForm({ profile }: Props) {
  const t = useTranslations('settings.profile');
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  const {
    register,
    handleSubmit,
    formState: { errors, isDirty },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      fullName: profile.fullName,
      displayName: profile.displayName ?? '',
      sendingEmail: profile.sendingEmail ?? '',
      timezone: profile.timezone || DEFAULT_TIMEZONE,
    },
  });

  const onSubmit = (values: FormValues) => {
    startTransition(async () => {
      const result = await updateUserProfile({
        fullName: values.fullName,
        displayName: values.displayName || null,
        sendingEmail: values.sendingEmail || null,
        timezone: values.timezone,
      });
      if (result.ok) {
        toast.success(t('saved'));
        router.refresh();
      } else {
        toast.error(result.errorMessage ?? 'Save failed');
      }
    });
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>{t('title')}</CardTitle>
        <CardDescription>{t('description')}</CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
          <div className="space-y-2">
            <Label>{t('emailLabel')}</Label>
            <Input type="email" value={profile.email} readOnly disabled />
            <p className="text-xs text-muted-foreground">{t('emailHint')}</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="full-name">{t('fullName')}</Label>
            <Input
              id="full-name"
              {...register('fullName')}
              disabled={isPending}
              aria-invalid={errors.fullName ? 'true' : undefined}
            />
            {errors.fullName && (
              <p className="text-xs text-destructive">{errors.fullName.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="display-name">{t('displayName')}</Label>
            <Input
              id="display-name"
              placeholder={profile.fullName}
              {...register('displayName')}
              disabled={isPending}
              aria-invalid={errors.displayName ? 'true' : undefined}
            />
            <p className="text-xs text-muted-foreground">{t('displayNameHint')}</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="sending-email">{t('sendingEmail')}</Label>
            <Input
              id="sending-email"
              type="email"
              placeholder={profile.email}
              {...register('sendingEmail')}
              disabled={isPending}
              aria-invalid={errors.sendingEmail ? 'true' : undefined}
            />
            {errors.sendingEmail && (
              <p className="text-xs text-destructive">{errors.sendingEmail.message}</p>
            )}
            <p className="text-xs text-muted-foreground">{t('sendingEmailHint')}</p>
          </div>

          {/* Timezone (English literals: no i18n keys yet) */}
          <div className="space-y-2">
            <Label htmlFor="timezone">Timezone</Label>
            <select
              id="timezone"
              {...register('timezone')}
              disabled={isPending}
              className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
            >
              {SUPPORTED_TIMEZONES.map((tz) => (
                <option key={tz.value} value={tz.value}>
                  {tz.label}
                </option>
              ))}
            </select>
            <p className="text-xs text-muted-foreground">
              Times in the Sent list and message details are shown in this timezone.
            </p>
          </div>

          <Button type="submit" disabled={!isDirty || isPending}>
            {isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
            {t('save')}
          </Button>
        </form>
      </CardContent>
    </Card>
  );
}
