'use client';

import { useTransition, useState, type ReactNode } from 'react';
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
import { Switch } from '@/components/ui/switch';
import { Separator } from '@/components/ui/separator';
import { TagMultiSelect, type TagOption } from '@/components/parties/tag-multi-select';
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
import {
  createParty,
  updateParty,
  deleteParty,
  updateInvestorProfile,
} from '@/lib/actions/parties';
import { PARTY_TYPES, type PartyType, type PartyKind } from '@/types/party-type';
import type {
  PartyDetail,
  PartyTier,
  PartyStatus,
  InvestorPriority,
  InvestorProfile,
} from '@/types/party-detail';
import type { InvestorTypeOption } from '@/lib/queries/investor-types';
import { COUNTRIES, US_STATES } from '@/lib/constants/countries';

interface Props {
  /** existing party in edit mode; null + initial partyType in create mode */
  mode: 'create' | 'edit';
  initialPartyType: PartyType;
  existing?: PartyDetail | null;
  /** full investor_profile in edit mode (null when none / not an investor) */
  existingProfile?: InvestorProfile | null;
  /** app.investor_types options for the "Investor type" select */
  investorTypeOptions?: InvestorTypeOption[];
  /** canonical tag options for the Industry Tags multi-select */
  industryTagSuggestions?: TagOption[];
  /** canonical tag options for the Interest Tags multi-select */
  interestTagSuggestions?: TagOption[];
  /** canonical sector options for the Sector focus multi-select */
  sectorSuggestions?: TagOption[];
}

const PARTY_STATUSES = [
  'active',
  'paused',
  'closed_won',
  'closed_lost',
  'archived',
] as const;

const schema = z.object({
  name: z.string().min(1, 'Required').max(200),
  legalName: z.string().max(200).optional().or(z.literal('')),
  partyType: z.enum(PARTY_TYPES as unknown as [PartyType, ...PartyType[]]),
  partyKind: z.enum(['company', 'organization', 'individual', 'fund', 'government']),
  tier: z.enum(['tier_1', 'tier_2', 'tier_3', 'cold']),
  status: z.enum(PARTY_STATUSES),
  // Investor priority lives on app.investor_profile; 'none' means unset (null).
  priority: z.enum(['none', 'high', 'medium', 'low']),
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
    .refine((s) => !s || /^https?:\/\/.+/.test(s), 'Must start with http:// or https://'),
  industryTags: z.string().max(500).optional().or(z.literal('')),
  interestTags: z.string().max(500).optional().or(z.literal('')),
  source: z.string().max(120).optional().or(z.literal('')),
  preferredContactMethod: z
    .enum(['email', 'web_form', 'portal', 'phone', 'other'])
    .optional()
    .or(z.literal('')),
  contactFormUrl: z
    .string()
    .max(500)
    .optional()
    .or(z.literal(''))
    .refine((s) => !s || /^https?:\/\/.+/.test(s), 'Must start with http:// or https://'),
  notes: z.string().max(10_000).optional().or(z.literal('')),
  // Org-level contact info: HQ email + single-line street address.
  email: z
    .string()
    .max(320)
    .optional()
    .or(z.literal(''))
    .refine((s) => !s || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s), 'Must be a valid email'),
  streetAddress: z.string().max(300).optional().or(z.literal('')),
  introKo: z.string().max(10_000).optional().or(z.literal('')),
  introEn: z.string().max(10_000).optional().or(z.literal('')),
  // ---- investor profile (only persisted for investor parties) ----
  investorType: z.string().max(64).optional().or(z.literal('')),
  fundName: z.string().max(200).optional().or(z.literal('')),
  fundSizeUsd: z.string().max(40).optional().or(z.literal('')),
  aumUsd: z.string().max(40).optional().or(z.literal('')),
  fundVintageYear: z.string().max(8).optional().or(z.literal('')),
  ticketMinUsd: z.string().max(40).optional().or(z.literal('')),
  ticketMaxUsd: z.string().max(40).optional().or(z.literal('')),
  sectorFocus: z.string().max(500).optional().or(z.literal('')),
  geographicFocus: z.string().max(500).optional().or(z.literal('')),
  isLeadInvestor: z.boolean(),
  isStrategic: z.boolean(),
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

const STATUS_LABELS: Record<PartyStatus, string> = {
  active: 'Active',
  paused: 'Paused',
  closed_won: 'Closed — won',
  closed_lost: 'Closed — lost',
  archived: 'Archived',
};

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

/** Parse a USD amount; accepts plain numbers, commas, and K/M/B suffixes. */
function parseUsd(raw: string | undefined): number | null {
  if (!raw) return null;
  const s = raw.trim().replace(/[$,\s]/g, '');
  if (!s) return null;
  const m = /^(-?\d+(?:\.\d+)?)([kKmMbB]?)$/.exec(s);
  if (!m || m[1] === undefined) {
    const n = Number(s);
    return Number.isFinite(n) ? Math.round(n) : null;
  }
  let n = parseFloat(m[1]);
  const suf = (m[2] ?? '').toLowerCase();
  if (suf === 'k') n *= 1_000;
  else if (suf === 'm') n *= 1_000_000;
  else if (suf === 'b') n *= 1_000_000_000;
  return Number.isFinite(n) ? Math.round(n) : null;
}

function parseYear(raw: string | undefined): number | null {
  if (!raw) return null;
  const n = parseInt(raw.trim(), 10);
  return Number.isFinite(n) && n >= 1800 && n <= 2200 ? n : null;
}

function numToStr(n: number | null | undefined): string {
  return n == null ? '' : String(n);
}

/** Small uppercase section heading, consistent with the detail cards. */
function SectionLabel({ children }: { children: ReactNode }) {
  return (
    <h3 className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
      {children}
    </h3>
  );
}

export function PartyForm({
  mode,
  initialPartyType,
  existing,
  existingProfile,
  investorTypeOptions = [],
  industryTagSuggestions = [],
  interestTagSuggestions = [],
  sectorSuggestions = [],
}: Props) {
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
          status: existing.status ?? 'active',
          priority: existingProfile?.priority ?? 'none',
          countryCode: existing.countryCode ?? '',
          region:
            existing.region ??
            ((existing.countryCode ?? '') === 'US' ? 'Texas' : ''),
          city: existing.city ?? '',
          website: existing.website ?? '',
          industryTags: existing.industryTags.join(', '),
          interestTags: existing.interestTags.join(', '),
          source: existing.source ?? '',
          preferredContactMethod: (existing.preferredContactMethod ??
            '') as FormValues['preferredContactMethod'],
          contactFormUrl: existing.contactFormUrl ?? '',
          notes: existing.notes ?? '',
          email: existing.email ?? '',
          streetAddress: existing.streetAddress ?? '',
          introKo: existing.introKo ?? '',
          introEn: existing.introEn ?? '',
          investorType: existingProfile?.typeCode ?? '',
          fundName: existingProfile?.fundName ?? '',
          fundSizeUsd: numToStr(existingProfile?.fundSizeUsd),
          aumUsd: numToStr(existingProfile?.aumUsd),
          fundVintageYear: numToStr(existingProfile?.fundVintageYear),
          ticketMinUsd: numToStr(existingProfile?.ticketMinUsd),
          ticketMaxUsd: numToStr(existingProfile?.ticketMaxUsd),
          sectorFocus: (existingProfile?.sectorFocus ?? []).join(', '),
          geographicFocus: (existingProfile?.geographicFocus ?? []).join(', '),
          isLeadInvestor: existingProfile?.isLeadInvestor ?? false,
          isStrategic: existingProfile?.isStrategic ?? false,
        }
      : {
          name: '',
          legalName: '',
          partyType: initialPartyType,
          partyKind: 'company',
          tier: 'tier_3',
          status: 'active',
          priority: 'none',
          countryCode: 'US',
          region: 'Texas',
          city: '',
          website: '',
          industryTags: '',
          interestTags: '',
          source: '',
          preferredContactMethod: '',
          contactFormUrl: '',
          notes: '',
          email: '',
          streetAddress: '',
          introKo: '',
          introEn: '',
          investorType: '',
          fundName: '',
          fundSizeUsd: '',
          aumUsd: '',
          fundVintageYear: '',
          ticketMinUsd: '',
          ticketMaxUsd: '',
          sectorFocus: '',
          geographicFocus: '',
          isLeadInvestor: false,
          isStrategic: false,
        },
  });

  const selectedPartyType = watch('partyType');
  const selectedPartyKind = watch('partyKind');
  const selectedTier = watch('tier');
  const selectedStatus = watch('status');
  const selectedCountry = watch('countryCode');
  const selectedRegion = watch('region');
  const selectedPriority = watch('priority');
  const selectedInvestorType = watch('investorType');
  const isLead = watch('isLeadInvestor');
  const isStrategic = watch('isStrategic');
  const isInvestor = selectedPartyType === 'investor';
  const isUS = selectedCountry === 'US';

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
        status: values.status,
        countryCode: values.countryCode || null,
        region: values.region || null,
        city: values.city || null,
        website: values.website || null,
        industryTags,
        interestTags,
        source: values.source || null,
        preferredContactMethod: values.preferredContactMethod || null,
        contactFormUrl: values.contactFormUrl || null,
        notes: values.notes || null,
        introKo: values.introKo || null,
        introEn: values.introEn || null,
        email: values.email || null,
        streetAddress: values.streetAddress || null,
      };

      // Full investor profile lives on app.investor_profile (its own action).
      const persistProfile = async (partyId: string) => {
        if (values.partyType !== 'investor') return;
        const res = await updateInvestorProfile({
          partyId,
          partyType: values.partyType,
          priority: values.priority === 'none' ? null : values.priority,
          investorTypeCode: values.investorType || null,
          fundName: values.fundName || null,
          fundSizeUsd: parseUsd(values.fundSizeUsd),
          aumUsd: parseUsd(values.aumUsd),
          fundVintageYear: parseYear(values.fundVintageYear),
          ticketMinUsd: parseUsd(values.ticketMinUsd),
          ticketMaxUsd: parseUsd(values.ticketMaxUsd),
          sectorFocus: parseTagsInput(values.sectorFocus),
          geographicFocus: parseTagsInput(values.geographicFocus),
          isLeadInvestor: values.isLeadInvestor,
          isStrategic: values.isStrategic,
        });
        if (!res.ok) toast.error(res.errorMessage ?? t('saveFailed'));
      };

      if (mode === 'create') {
        const result = await createParty(payload);
        if (result.ok && result.partyId) {
          await persistProfile(result.partyId);
          toast.success(t('created'));
          router.push(`/${values.partyType}/parties/${result.partyId}`);
        } else {
          toast.error(result.errorMessage ?? t('saveFailed'));
        }
      } else if (existing) {
        const result = await updateParty({ partyId: existing.id, ...payload });
        if (result.ok) {
          await persistProfile(existing.id);
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

        <CardContent className="space-y-8">
          {/* ===================== Basic information ===================== */}
          <section className="space-y-4">
            <SectionLabel>Basic information</SectionLabel>

            <div className="grid grid-cols-1 gap-x-6 gap-y-4 md:grid-cols-2">
              {/* Name / Legal name / Status -- one responsive row */}
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3 md:col-span-2">
              <div className="space-y-2">
                <Label htmlFor="party-name">{t('name')} *</Label>
                <Input
                  id="party-name"
                  {...register('name')}
                  disabled={isPending}
                  aria-invalid={errors.name ? 'true' : undefined}
                />
                {errors.name && <p className="text-xs text-destructive">{errors.name.message}</p>}
              </div>
              <div className="space-y-2">
                <Label htmlFor="party-legal">{t('legalName')}</Label>
                <Input
                  id="party-legal"
                  {...register('legalName')}
                  disabled={isPending}
                  placeholder={t('legalNamePlaceholder')}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="party-status">Status</Label>
                <Select
                  value={selectedStatus}
                  onValueChange={(v) => setValue('status', v as PartyStatus, { shouldDirty: true })}
                  disabled={isPending}
                >
                  <SelectTrigger id="party-status">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {PARTY_STATUSES.map((s) => (
                      <SelectItem key={s} value={s}>
                        {STATUS_LABELS[s]}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              </div>

              {/* Type / Entity type / Tier */}
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-3 md:col-span-2">
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

              {/* Website / Email / Source -- one responsive row */}
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3 md:col-span-2">
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

              {/* Email (org-level / HQ) */}
              <div className="space-y-2">
                <Label htmlFor="party-email">Email</Label>
                <Input
                  id="party-email"
                  type="email"
                  {...register('email')}
                  disabled={isPending}
                  placeholder="info@example.com"
                  aria-invalid={errors.email ? 'true' : undefined}
                />
                {errors.email && (
                  <p className="text-xs text-destructive">{errors.email.message}</p>
                )}
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

              {/* Contact method (migration_027) */}
              <div className="space-y-2">
                <Label htmlFor="party-contact-method">Contact method</Label>
                <select
                  id="party-contact-method"
                  {...register('preferredContactMethod')}
                  disabled={isPending}
                  className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm shadow-sm"
                >
                  <option value="">- unknown -</option>
                  <option value="email">Email</option>
                  <option value="web_form">Web form</option>
                  <option value="portal">Portal (login required)</option>
                  <option value="phone">Phone</option>
                  <option value="other">Other</option>
                </select>
              </div>

              {/* Application / contact form URL (required for web_form and portal) */}
              <div className="space-y-2">
                <Label htmlFor="party-contact-form-url">Form URL</Label>
                <Input
                  id="party-contact-form-url"
                  {...register('contactFormUrl')}
                  disabled={isPending}
                  placeholder="https://..."
                />
                {errors.contactFormUrl && (
                  <p className="text-xs text-destructive">
                    {errors.contactFormUrl.message}
                  </p>
                )}
              </div>
              </div>
            </div>
          </section>

          <Separator />

          {/* ===================== Introduction ===================== */}
          <section className="space-y-4">
            <SectionLabel>Introduction</SectionLabel>
            <div className="grid grid-cols-1 gap-x-6 gap-y-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="party-intro-ko">{t('introKo')}</Label>
                <Textarea
                  id="party-intro-ko"
                  {...register('introKo')}
                  disabled={isPending}
                  rows={6}
                  placeholder={t('introKoPlaceholder')}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="party-intro-en">{t('introEn')}</Label>
                <Textarea
                  id="party-intro-en"
                  {...register('introEn')}
                  disabled={isPending}
                  rows={6}
                  placeholder={t('introEnPlaceholder')}
                />
              </div>
              <p className="text-xs text-muted-foreground md:col-span-2">{t('introHint')}</p>
            </div>
          </section>

          <Separator />

          {/* ===================== Notes ===================== */}
          <section className="space-y-2">
            <SectionLabel>{t('notes')}</SectionLabel>
            <Textarea id="party-notes" {...register('notes')} disabled={isPending} rows={5} />
          </section>

          <Separator />

          {/* ===================== Location ===================== */}
          <section className="space-y-4">
            <SectionLabel>Location</SectionLabel>
            {/* Street address (single line, full width) */}
            <div className="space-y-2">
              <Label htmlFor="party-street-address">Street address</Label>
              <Input
                id="party-street-address"
                {...register('streetAddress')}
                disabled={isPending}
                placeholder="123 Main St, Suite 400"
                aria-invalid={errors.streetAddress ? 'true' : undefined}
              />
              {errors.streetAddress && (
                <p className="text-xs text-destructive">{errors.streetAddress.message}</p>
              )}
            </div>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
              <div className="space-y-2">
                <Label htmlFor="party-country">Country</Label>
                <Select
                  value={selectedCountry || '__none'}
                  onValueChange={(v) => {
                    const code = v === '__none' ? '' : v;
                    setValue('countryCode', code, { shouldDirty: true });
                    if (code === 'US' && !watch('region')) {
                      setValue('region', 'Texas', { shouldDirty: true });
                    }
                  }}
                  disabled={isPending}
                >
                  <SelectTrigger id="party-country">
                    <SelectValue placeholder="Select a country" />
                  </SelectTrigger>
                  <SelectContent className="max-h-72">
                    <SelectItem value="US">United States (US)</SelectItem>
                    <SelectItem value="__none">(none)</SelectItem>
                    {COUNTRIES.filter((c) => c.code !== 'US').map((c) => (
                      <SelectItem key={c.code} value={c.code}>
                        {c.name} ({c.code})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.countryCode && (
                  <p className="text-xs text-destructive">{errors.countryCode.message}</p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="party-region">{isUS ? 'State' : t('region')}</Label>
                {isUS ? (
                  <Select
                    value={selectedRegion || '__none'}
                    onValueChange={(v) =>
                      setValue('region', v === '__none' ? '' : v, { shouldDirty: true })
                    }
                    disabled={isPending}
                  >
                    <SelectTrigger id="party-region">
                      <SelectValue placeholder="Select a state" />
                    </SelectTrigger>
                    <SelectContent className="max-h-72">
                      <SelectItem value="__none">(none)</SelectItem>
                      {US_STATES.map((s) => (
                        <SelectItem key={s} value={s}>
                          {s}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                ) : (
                  <Input id="party-region" {...register('region')} disabled={isPending} />
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="party-city">{t('city')}</Label>
                <Input id="party-city" {...register('city')} disabled={isPending} />
              </div>
            </div>
          </section>

          <Separator />

          {/* ===================== Tags ===================== */}
          <section className="space-y-4">
            <SectionLabel>Tags</SectionLabel>
            {/* Industry Tags removed (2026-07-04): duplicated Sector focus and
                was not persisted since D6-5e. */}
            <div className="grid grid-cols-1 gap-x-6 gap-y-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="party-interest-tags">{t('interestTags')}</Label>
                <TagMultiSelect
                  inputId="party-interest-tags"
                  value={watch('interestTags') ?? ''}
                  onChange={(v) => setValue('interestTags', v, { shouldDirty: true })}
                  suggestions={interestTagSuggestions}
                  disabled={isPending}
                  placeholder={t('interestTagsPlaceholder')}
                />
                <p className="text-xs text-muted-foreground">{t('interestTagsHint')}</p>
              </div>
              {isInvestor && (
                <div className="space-y-2">
                  <Label htmlFor="party-sector-focus">Sector focus</Label>
                  <TagMultiSelect
                    inputId="party-sector-focus"
                    value={watch('sectorFocus') ?? ''}
                    onChange={(v) => setValue('sectorFocus', v, { shouldDirty: true })}
                    suggestions={sectorSuggestions}
                    disabled={isPending}
                    placeholder="Select or add sectors..."
                  />
                  <p className="text-xs text-muted-foreground">
                    Normalized sectors only. Pick from the list, or type to add a new one.
                  </p>
                </div>
              )}
            </div>
          </section>

          {/* ===================== Investor profile ===================== */}
          {isInvestor && (
            <>
              <Separator />
              <section className="space-y-4">
                <SectionLabel>Investor profile</SectionLabel>
                <div className="grid grid-cols-1 gap-x-6 gap-y-4 md:grid-cols-2">
                  {/* Priority */}
                  <div className="space-y-2">
                    <Label htmlFor="party-priority">{t('priority')}</Label>
                    <Select
                      value={selectedPriority}
                      onValueChange={(v) =>
                        setValue('priority', v as FormValues['priority'], { shouldDirty: true })
                      }
                      disabled={isPending}
                    >
                      <SelectTrigger id="party-priority">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="none">{t('priorities.none')}</SelectItem>
                        <SelectItem value="high">{t('priorities.high')}</SelectItem>
                        <SelectItem value="medium">{t('priorities.medium')}</SelectItem>
                        <SelectItem value="low">{t('priorities.low')}</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  {/* Investor type */}
                  <div className="space-y-2">
                    <Label htmlFor="party-investor-type">Investor type</Label>
                    <Select
                      value={selectedInvestorType || '__none'}
                      onValueChange={(v) =>
                        setValue('investorType', v === '__none' ? '' : v, { shouldDirty: true })
                      }
                      disabled={isPending}
                    >
                      <SelectTrigger id="party-investor-type">
                        <SelectValue placeholder="Select a type" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="__none">— Not set —</SelectItem>
                        {investorTypeOptions.map((opt) => (
                          <SelectItem key={opt.code} value={opt.code}>
                            {opt.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  {/* Fund name */}
                  <div className="space-y-2">
                    <Label htmlFor="party-fund-name">Fund name</Label>
                    <Input id="party-fund-name" {...register('fundName')} disabled={isPending} />
                  </div>

                  {/* Vintage year */}
                  <div className="space-y-2">
                    <Label htmlFor="party-vintage">Vintage year</Label>
                    <Input
                      id="party-vintage"
                      {...register('fundVintageYear')}
                      disabled={isPending}
                      inputMode="numeric"
                      placeholder="2009"
                    />
                  </div>

                  {/* Fund size */}
                  <div className="space-y-2">
                    <Label htmlFor="party-fund-size">Fund size (USD)</Label>
                    <Input
                      id="party-fund-size"
                      {...register('fundSizeUsd')}
                      disabled={isPending}
                      inputMode="numeric"
                      placeholder="e.g. 150M or 150000000"
                    />
                  </div>

                  {/* AUM */}
                  <div className="space-y-2">
                    <Label htmlFor="party-aum">AUM (USD)</Label>
                    <Input
                      id="party-aum"
                      {...register('aumUsd')}
                      disabled={isPending}
                      inputMode="numeric"
                      placeholder="e.g. 150M or 150000000"
                    />
                  </div>

                  {/* Ticket min / max */}
                  <div className="space-y-2">
                    <Label htmlFor="party-ticket-min">Ticket min (USD)</Label>
                    <Input
                      id="party-ticket-min"
                      {...register('ticketMinUsd')}
                      disabled={isPending}
                      inputMode="numeric"
                      placeholder="e.g. 1M"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="party-ticket-max">Ticket max (USD)</Label>
                    <Input
                      id="party-ticket-max"
                      {...register('ticketMaxUsd')}
                      disabled={isPending}
                      inputMode="numeric"
                      placeholder="e.g. 10M"
                    />
                  </div>


                  {/* Lead / Strategic toggles */}
                  <div className="flex items-center justify-between rounded-md border px-3 py-2">
                    <Label htmlFor="party-lead" className="cursor-pointer">
                      Lead investor
                    </Label>
                    <Switch
                      id="party-lead"
                      checked={isLead}
                      onCheckedChange={(v) => setValue('isLeadInvestor', v, { shouldDirty: true })}
                      disabled={isPending}
                    />
                  </div>
                  <div className="flex items-center justify-between rounded-md border px-3 py-2">
                    <Label htmlFor="party-strategic" className="cursor-pointer">
                      Strategic investor
                    </Label>
                    <Switch
                      id="party-strategic"
                      checked={isStrategic}
                      onCheckedChange={(v) => setValue('isStrategic', v, { shouldDirty: true })}
                      disabled={isPending}
                    />
                  </div>
                </div>
              </section>
            </>
          )}


        </CardContent>

        <CardFooter className="sticky bottom-0 z-10 flex items-center justify-between gap-2 border-t bg-card px-6 py-4">
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
          <div className="ml-auto flex gap-2">
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
              <Button variant="outline" onClick={() => setShowDelete(false)} disabled={isPending}>
                {t('cancel')}
              </Button>
              <Button variant="destructive" onClick={onDelete} disabled={isPending}>
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
