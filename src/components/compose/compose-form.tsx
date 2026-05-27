'use client';

import { useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useTranslations } from 'next-intl';
import { Loader2, Send } from 'lucide-react';
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
} from '@/components/ui/select';import { sendOutboundManual } from '@/lib/actions/communications';
import type { SendingAddressKind } from '@/types/email';

interface Props {
  /** 미리 채울 수신자 (선택) */
  defaultTo?: string;
  defaultSubject?: string;
  defaultBody?: string;
  partyId?: string | null;
  contactId?: string | null;
  inReplyTo?: string | null;
  threadId?: string | null;
}


// D6-7c-1: From kind selector options
// Display labels are user-facing; actual email is resolved server-side from env.MAIL_<KIND>_*.
const SENDER_OPTIONS: Array<{ kind: SendingAddressKind; label: string }> = [
  { kind: 'shared',   label: 'Marinebio Group <contact@marinebiogroup.com>' },
  { kind: 'role',     label: 'CEO <ceo@marinebiogroup.com>' },
  { kind: 'personal', label: 'YunYoung Heo <yunyoung.heo@marinebiogroup.com>' },
];
const schema = z.object({
  fromKind: z.enum(['personal', 'role', 'shared']).default('shared'),
  to: z.string().email('Invalid email').max(255),
  cc: z.string().max(2000).optional().or(z.literal('')),
  subject: z.string().min(1, 'Required').max(500),
  bodyPlain: z.string().min(1, 'Required').max(50_000),
});

type FormValues = z.infer<typeof schema>;

export function ComposeForm({
  defaultTo,
  defaultSubject,
  defaultBody,
  partyId,
  contactId,
  inReplyTo,
  threadId,
}: Props) {
  const router = useRouter();
  const t = useTranslations('compose');
  const [isPending, startTransition] = useTransition();

  const {
    register,
    control,
    handleSubmit,
    formState: { errors, isDirty },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      fromKind: 'shared',
      to: defaultTo ?? '',
      cc: '',
      subject: defaultSubject ?? '',
      bodyPlain: defaultBody ?? '',
    },
  });

  const onSubmit = (values: FormValues) => {
    startTransition(async () => {
      const result = await sendOutboundManual({
        fromKind: values.fromKind,
        to: values.to,
        cc: values.cc || undefined,
        subject: values.subject,
        bodyPlain: values.bodyPlain,
        partyId: partyId ?? null,
        contactId: contactId ?? null,
        inReplyTo: inReplyTo ?? null,
        threadId: threadId ?? null,
      });
      if (result.ok && result.communicationId) {
        toast.success(t('sent'));
        router.push(`/inbox/${result.communicationId}`);
      } else if (result.errorCode === 'send_failed') {
        toast.error(t('sendFailed') + ': ' + (result.errorMessage ?? ''));
      } else {
        toast.error(result.errorMessage ?? t('sendFailed'));
      }
    });
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <Card>
        <CardHeader>
          <CardTitle>{t('title')}</CardTitle>
          <CardDescription>{t('description')}</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
                    {/* D6-7c-1 JSX: From kind selector */}
          <div className="space-y-2">
            <Label htmlFor="fromKind">From</Label>
            <Controller
              control={control}
              name="fromKind"
              render={({ field }) => (
                <Select onValueChange={field.onChange} value={field.value}>
                  <SelectTrigger id="fromKind">
                    <SelectValue placeholder="Select sender" />
                  </SelectTrigger>
                  <SelectContent>
                    {SENDER_OPTIONS.map((opt) => (
                      <SelectItem key={opt.kind} value={opt.kind}>
                        {opt.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="compose-to">{t('to')} *</Label>
            <Input
              id="compose-to"
              type="email"
              {...register('to')}
              disabled={isPending}
              placeholder="recipient@example.com"
              aria-invalid={errors.to ? 'true' : undefined}
            />
            {errors.to && <p className="text-xs text-destructive">{errors.to.message}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="compose-cc">{t('cc')}</Label>
            <Input
              id="compose-cc"
              {...register('cc')}
              disabled={isPending}
              placeholder={t('ccPlaceholder')}
            />
            <p className="text-xs text-muted-foreground">{t('ccHint')}</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="compose-subject">{t('subject')} *</Label>
            <Input
              id="compose-subject"
              {...register('subject')}
              disabled={isPending}
              aria-invalid={errors.subject ? 'true' : undefined}
            />
            {errors.subject && (
              <p className="text-xs text-destructive">{errors.subject.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="compose-body">{t('body')} *</Label>
            <Textarea
              id="compose-body"
              {...register('bodyPlain')}
              disabled={isPending}
              rows={14}
              className="font-mono"
              aria-invalid={errors.bodyPlain ? 'true' : undefined}
            />
            {errors.bodyPlain && (
              <p className="text-xs text-destructive">{errors.bodyPlain.message}</p>
            )}
          </div>
        </CardContent>
        <CardFooter className="flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={() => router.back()} disabled={isPending}>
            {t('cancel')}
          </Button>
          <Button type="submit" disabled={isPending || !isDirty}>
            {isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
            {t('send')}
          </Button>
        </CardFooter>
      </Card>
    </form>
  );
}
