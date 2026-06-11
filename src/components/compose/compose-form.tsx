'use client';

// src/components/compose/compose-form.tsx
//
// Standalone compose form (/compose) with:
//   - Recipient picker: type-ahead over registered contacts (name/email);
//     selecting a contact pins contact_id + party_id so the send is fully
//     linked. Free-typing a raw email is still allowed (unlinked send).
//   - Deal selector: once a party is known, its open deals load and the
//     message can be linked to one (auto-selected when exactly one).
//     The DB trigger then logs the email on that deal's Activity timeline.

import { useEffect, useRef, useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useTranslations } from 'next-intl';
import { Building2, Link2, Loader2, Send, X } from 'lucide-react';
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
import { Badge } from '@/components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { sendOutboundManual } from '@/lib/actions/communications';
import {
  searchRecipientContacts,
  listOpenDealsForParty,
  type RecipientContact,
  type OpenDealOption,
} from '@/lib/actions/compose-recipients';
import type { SendingAddressKind } from '@/types/email';
import { AttachmentUploader } from '@/components/email/attachment-uploader';
import type { UploadedAttachment } from '@/lib/actions/upload-attachment';

interface Props {
  /** recipient to pre-fill (optional) */
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

const NO_DEAL = '__none__';

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
  const [attachments, setAttachments] = useState<UploadedAttachment[]>([]);

  // -- recipient linkage state (overrides the URL-provided props once picked) --
  const [linkedContactId, setLinkedContactId] = useState<string | null>(contactId ?? null);
  const [linkedPartyId, setLinkedPartyId] = useState<string | null>(partyId ?? null);
  const [linkedLabel, setLinkedLabel] = useState<string | null>(null);

  // -- type-ahead state --
  const [searchResults, setSearchResults] = useState<RecipientContact[]>([]);
  const [searching, setSearching] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // -- deal selector state --
  const [dealOptions, setDealOptions] = useState<OpenDealOption[]>([]);
  const [selectedDealId, setSelectedDealId] = useState<string>(NO_DEAL);
  const [loadingDeals, setLoadingDeals] = useState(false);

  const {
    register,
    control,
    handleSubmit,
    setValue,
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

  // Load open deals whenever the linked party changes; auto-select when single.
  useEffect(() => {
    let cancelled = false;
    if (!linkedPartyId) {
      setDealOptions([]);
      setSelectedDealId(NO_DEAL);
      return;
    }
    setLoadingDeals(true);
    listOpenDealsForParty(linkedPartyId)
      .then((res) => {
        if (cancelled) return;
        if (res.ok) {
          setDealOptions(res.deals);
          setSelectedDealId(res.deals.length === 1 ? res.deals[0].dealId : NO_DEAL);
        } else {
          setDealOptions([]);
          setSelectedDealId(NO_DEAL);
        }
      })
      .finally(() => {
        if (!cancelled) setLoadingDeals(false);
      });
    return () => {
      cancelled = true;
    };
  }, [linkedPartyId]);

  // Debounced contact search as the user types into "To".
  const toRegister = register('to');
  const handleToChange = (value: string) => {
    // typing breaks any previous explicit link
    if (linkedContactId || linkedLabel) {
      setLinkedContactId(null);
      setLinkedPartyId(partyId ?? null);
      setLinkedLabel(null);
    }
    if (debounceRef.current) clearTimeout(debounceRef.current);
    const q = value.trim();
    if (q.length < 2) {
      setSearchResults([]);
      setShowResults(false);
      return;
    }
    debounceRef.current = setTimeout(async () => {
      setSearching(true);
      const res = await searchRecipientContacts(q);
      setSearching(false);
      if (res.ok) {
        setSearchResults(res.results);
        setShowResults(res.results.length > 0);
      }
    }, 250);
  };

  const pickContact = (c: RecipientContact) => {
    setValue('to', c.email, { shouldDirty: true, shouldValidate: true });
    setLinkedContactId(c.contactId);
    setLinkedPartyId(c.partyId);
    setLinkedLabel(`${c.fullName}${c.partyName ? ' \u00b7 ' + c.partyName : ''}`);
    setSearchResults([]);
    setShowResults(false);
  };

  const clearLink = () => {
    setLinkedContactId(null);
    setLinkedPartyId(null);
    setLinkedLabel(null);
    setSelectedDealId(NO_DEAL);
  };

  const onSubmit = (values: FormValues) => {
    startTransition(async () => {
      const result = await sendOutboundManual({
        fromKind: values.fromKind,
        to: values.to,
        cc: values.cc || undefined,
        subject: values.subject,
        bodyPlain: values.bodyPlain,
        partyId: linkedPartyId ?? null,
        contactId: linkedContactId ?? null,
        dealId: selectedDealId !== NO_DEAL ? selectedDealId : null,
        inReplyTo: inReplyTo ?? null,
        threadId: threadId ?? null,
        attachments,
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

          {/* To + contact type-ahead */}
          <div className="space-y-2 relative">
            <Label htmlFor="compose-to">{t('to')} *</Label>
            <Input
              id="compose-to"
              type="text"
              autoComplete="off"
              {...toRegister}
              onChange={(e) => {
                void toRegister.onChange(e);
                handleToChange(e.target.value);
              }}
              onFocus={() => setShowResults(searchResults.length > 0)}
              onBlur={() => setTimeout(() => setShowResults(false), 150)}
              disabled={isPending}
              placeholder="Search contacts by name/email, or type an address"
              aria-invalid={errors.to ? 'true' : undefined}
            />
            {showResults && (
              <div className="absolute z-20 left-0 right-0 top-full mt-1 rounded-md border bg-popover shadow-md max-h-64 overflow-y-auto">
                {searchResults.map((c) => (
                  <button
                    key={c.contactId}
                    type="button"
                    className="w-full px-3 py-2 text-left text-sm hover:bg-accent flex flex-col"
                    onMouseDown={(e) => {
                      e.preventDefault();
                      pickContact(c);
                    }}
                  >
                    <span className="font-medium">
                      {c.fullName}
                      {c.title ? (
                        <span className="text-muted-foreground font-normal"> &middot; {c.title}</span>
                      ) : null}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      {c.email}
                      {c.partyName ? ` \u00b7 ${c.partyName}` : ''}
                    </span>
                  </button>
                ))}
              </div>
            )}
            {searching && (
              <p className="text-xs text-muted-foreground flex items-center gap-1">
                <Loader2 className="h-3 w-3 animate-spin" /> Searching contacts...
              </p>
            )}
            {linkedLabel && (
              <div className="flex items-center gap-1.5">
                <Badge variant="secondary" className="text-xs font-normal gap-1">
                  <Building2 className="h-3 w-3" />
                  {linkedLabel}
                </Badge>
                <button
                  type="button"
                  onClick={clearLink}
                  className="text-muted-foreground hover:text-foreground"
                  aria-label="Unlink recipient"
                >
                  <X className="h-3.5 w-3.5" />
                </button>
              </div>
            )}
            {!linkedContactId && !linkedLabel && (
              <p className="text-xs text-muted-foreground">
                Pick a registered contact to log this email on the company and its deal.
              </p>
            )}
            {errors.to && <p className="text-xs text-destructive">{errors.to.message}</p>}
          </div>

          {/* Deal selector (visible once a party is linked) */}
          {linkedPartyId && (
            <div className="space-y-2">
              <Label htmlFor="compose-deal" className="flex items-center gap-1.5">
                <Link2 className="h-3.5 w-3.5" />
                Link to deal
              </Label>
              {loadingDeals ? (
                <p className="text-xs text-muted-foreground flex items-center gap-1">
                  <Loader2 className="h-3 w-3 animate-spin" /> Loading deals...
                </p>
              ) : dealOptions.length === 0 ? (
                <p className="text-xs text-muted-foreground">
                  No open deals for this company. The email is still logged on the company.
                </p>
              ) : (
                <Select value={selectedDealId} onValueChange={setSelectedDealId}>
                  <SelectTrigger id="compose-deal">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value={NO_DEAL}>No deal (log on company only)</SelectItem>
                    {dealOptions.map((d) => (
                      <SelectItem key={d.dealId} value={d.dealId}>
                        {d.dealName}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            </div>
          )}

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
          <div className="space-y-2">
            <Label>Attachments</Label>
            <AttachmentUploader
              attachments={attachments}
              onChange={setAttachments}
              disabled={isPending}
            />
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
