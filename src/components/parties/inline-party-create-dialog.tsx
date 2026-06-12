'use client';

/**
 * components/parties/inline-party-create-dialog.tsx
 *
 * Reusable "register a new company on the fly" dialog. Creates a party
 * (app.parties) and, optionally, one or more contacts (app.contacts) in a
 * single submit, then hands the new party back to the caller via onCreated().
 *
 * Designed to be version-agnostic about the caller: the deal-create modal
 * (single OR multi-company), directory lists, meeting modals, etc. all just
 * wire onCreated() to "select / attach this party".
 *
 * Reuses the existing server actions (no new server code):
 *   - createParty   from '@/lib/actions/parties'   (accepts every PartyType,
 *                    including government_grant / buyer that the /new route blocks)
 *   - createContact from '@/lib/actions/contacts'   (same payload shape as
 *                    contact-form-dialog.tsx)
 *
 * Strings are hardcoded English to match new-deal-modal.tsx (that flow is not
 * i18n-wrapped). Swap to useTranslations later if desired.
 */

import { useEffect, useTransition } from 'react';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Loader2, Plus, Save, X } from 'lucide-react';
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { createParty } from '@/lib/actions/parties';
import { createContact } from '@/lib/actions/contacts';
import {
  PARTY_TYPES,
  PARTY_KINDS,
  PARTY_TYPE_DISPLAY,
  PARTY_KIND_DISPLAY,
  type PartyType,
  type PartyKind,
} from '@/types/party-type';

/** Shape handed back to the caller (matches the deal modal's PartyResult). */
export interface CreatedParty {
  id: string;
  party_name: string;
  country_code: string | null;
}

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Called once the party (and any contacts) are saved. */
  onCreated: (party: CreatedParty) => void;
  /** Pre-fill the name field (e.g. the text typed into a search box). */
  prefillName?: string;
  /** Default business category (e.g. derived from the current pipeline). */
  defaultPartyType?: PartyType;
}

const contactRowSchema = z.object({
  fullName: z.string().max(160),
  title: z.string().max(120),
  email: z.string().max(255),
  phone: z.string().max(40),
  isPrimary: z.boolean(),
});

const schema = z.object({
  name: z.string().min(1, 'Company name is required').max(200),
  partyType: z.enum([
    'investor',
    'paper_mill',
    'filler_supplier',
    'buyer',
    'customer',
    'partner',
    'government_grant',
    'consultant',
    'crowdfunding_platform',
    'self',
  ]),
  partyKind: z.enum(['company', 'organization', 'individual', 'fund', 'government']),
  countryCode: z
    .string()
    .optional()
    .or(z.literal(''))
    .refine((s) => !s || /^[A-Za-z]{2}$/.test(s), 'Must be a 2-letter code'),
  website: z
    .string()
    .optional()
    .or(z.literal(''))
    .refine((s) => !s || /^https?:\/\/.+/.test(s), 'Must start with http:// or https://'),
  contacts: z.array(contactRowSchema),
});

type FormValues = z.infer<typeof schema>;

const emptyContactRow = {
  fullName: '',
  title: '',
  email: '',
  phone: '',
  isPrimary: false,
};

function buildDefaults(prefillName?: string, defaultPartyType?: PartyType): FormValues {
  return {
    name: prefillName?.trim() ?? '',
    partyType: defaultPartyType ?? 'paper_mill',
    partyKind: 'company',
    countryCode: '',
    website: '',
    contacts: [],
  };
}

export function InlinePartyCreateDialog({
  open,
  onOpenChange,
  onCreated,
  prefillName,
  defaultPartyType,
}: Props) {
  const [isPending, startTransition] = useTransition();

  const {
    register,
    handleSubmit,
    formState: { errors },
    watch,
    setValue,
    reset,
    control,
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: buildDefaults(prefillName, defaultPartyType),
  });

  const { fields, append, remove } = useFieldArray({ control, name: 'contacts' });

  // Re-seed the form whenever the dialog is (re)opened so a fresh search term
  // or pipeline-derived type is reflected. Mirrors new-deal-modal's reset pattern.
  useEffect(() => {
    if (open) {
      reset(buildDefaults(prefillName, defaultPartyType));
    }
  }, [open, prefillName, defaultPartyType, reset]);

  const selectedPartyType = watch('partyType');
  const selectedPartyKind = watch('partyKind');
  const contactRows = watch('contacts');

  const onSubmit = (values: FormValues) => {
    startTransition(async () => {
      const countryCode = values.countryCode ? values.countryCode.toUpperCase() : null;

      const result = await createParty({
        name: values.name.trim(),
        partyType: values.partyType,
        partyKind: values.partyKind,
        countryCode,
        website: values.website || null,
      });

      if (!result.ok || !result.partyId) {
        toast.error(result.errorMessage ?? 'Failed to create company');
        return;
      }

      const partyId = result.partyId;

      // Save any filled-in contact rows. A contact failure does not undo the
      // party (it already exists); surface a warning and continue.
      const rows = values.contacts.filter((c) => c.fullName.trim().length > 0);
      let contactFailures = 0;
      for (const c of rows) {
        const res = await createContact({
          partyId,
          fullName: c.fullName.trim(),
          title: c.title || undefined,
          email: c.email || undefined,
          phone: c.phone || undefined,
          isPrimary: c.isPrimary,
          decisionRole: 'unknown' as const,
        });
        if (!res.ok) contactFailures += 1;
      }

      if (contactFailures > 0) {
        toast.warning(
          `Company created, but ${contactFailures} contact(s) could not be saved.`,
        );
      } else {
        toast.success('Company registered');
      }

      onCreated({
        id: partyId,
        party_name: values.name.trim(),
        country_code: countryCode,
      });
      reset(buildDefaults());
      onOpenChange(false);
    });
  };

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        if (!isPending) onOpenChange(v);
      }}
    >
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>Register new company</DialogTitle>
          <DialogDescription>
            Create a company that isn&apos;t in the directory yet, then use it right away.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit(onSubmit)} className="space-y-4" noValidate>
          {/* Name */}
          <div className="space-y-2">
            <Label htmlFor="ipc-name">Company name *</Label>
            <Input
              id="ipc-name"
              {...register('name')}
              disabled={isPending}
              autoFocus
              aria-invalid={errors.name ? 'true' : undefined}
            />
            {errors.name && (
              <p className="text-xs text-destructive">{errors.name.message}</p>
            )}
          </div>

          {/* Type + Kind */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="ipc-type">Type *</Label>
              <Select
                value={selectedPartyType}
                onValueChange={(v) =>
                  setValue('partyType', v as PartyType, { shouldDirty: true })
                }
                disabled={isPending}
              >
                <SelectTrigger id="ipc-type">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {PARTY_TYPES.map((pt) => (
                    <SelectItem key={pt} value={pt}>
                      {PARTY_TYPE_DISPLAY[pt].en}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="ipc-kind">Entity</Label>
              <Select
                value={selectedPartyKind}
                onValueChange={(v) =>
                  setValue('partyKind', v as PartyKind, { shouldDirty: true })
                }
                disabled={isPending}
              >
                <SelectTrigger id="ipc-kind">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {PARTY_KINDS.map((pk) => (
                    <SelectItem key={pk} value={pk}>
                      {PARTY_KIND_DISPLAY[pk].en}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Country + Website */}
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="ipc-country">Country</Label>
              <Input
                id="ipc-country"
                {...register('countryCode')}
                disabled={isPending}
                placeholder="US"
                maxLength={2}
                aria-invalid={errors.countryCode ? 'true' : undefined}
              />
              {errors.countryCode && (
                <p className="text-xs text-destructive">{errors.countryCode.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="ipc-website">Website</Label>
              <Input
                id="ipc-website"
                {...register('website')}
                disabled={isPending}
                placeholder="https://example.com"
                aria-invalid={errors.website ? 'true' : undefined}
              />
              {errors.website && (
                <p className="text-xs text-destructive">{errors.website.message}</p>
              )}
            </div>
          </div>

          {/* Contacts (optional, repeatable) */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label>Contacts</Label>
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="gap-1"
                onClick={() => append({ ...emptyContactRow })}
                disabled={isPending}
              >
                <Plus className="h-3.5 w-3.5" />
                <span className="text-xs">Add contact</span>
              </Button>
            </div>

            {fields.length === 0 ? (
              <p className="text-xs text-muted-foreground italic">
                No contacts yet. Add one if you have a point of contact.
              </p>
            ) : (
              <div className="space-y-3">
                {fields.map((field, idx) => (
                  <div key={field.id} className="rounded-md border p-3 space-y-2">
                    <div className="flex items-center gap-2">
                      <Input
                        {...register(`contacts.${idx}.fullName` as const)}
                        disabled={isPending}
                        placeholder="Full name"
                        className="flex-1"
                      />
                      <button
                        type="button"
                        onClick={() => remove(idx)}
                        disabled={isPending}
                        aria-label="Remove contact"
                        className="text-muted-foreground hover:text-destructive disabled:opacity-50"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </div>
                    <div className="grid grid-cols-2 gap-2">
                      <Input
                        {...register(`contacts.${idx}.title` as const)}
                        disabled={isPending}
                        placeholder="Title (e.g. Program Officer)"
                      />
                      <Input
                        {...register(`contacts.${idx}.phone` as const)}
                        disabled={isPending}
                        placeholder="Phone"
                      />
                    </div>
                    <Input
                      type="email"
                      {...register(`contacts.${idx}.email` as const)}
                      disabled={isPending}
                      placeholder="Email"
                    />
                    <label className="flex items-center gap-2 text-sm">
                      <Checkbox
                        checked={contactRows?.[idx]?.isPrimary ?? false}
                        onCheckedChange={(v) =>
                          setValue(`contacts.${idx}.isPrimary`, v === true, {
                            shouldDirty: true,
                          })
                        }
                        disabled={isPending}
                      />
                      <span className="cursor-pointer">Primary contact</span>
                    </label>
                  </div>
                ))}
              </div>
            )}
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={isPending}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={isPending}>
              {isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Save className="h-4 w-4" />
              )}
              Register &amp; use
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
