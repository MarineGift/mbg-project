import type { ReactNode } from 'react';
import { Info } from 'lucide-react';
import { format } from 'date-fns';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { PartyTypeBadge } from '@/components/common/party-type-badge';
import { ContactMethodBadge } from '@/components/common/contact-method-badge';
import { cn } from '@/lib/utils';
import type { PartyContact, PartyDetail } from '@/types/party-detail';

interface Props {
  party: PartyDetail;
  contacts?: readonly PartyContact[];
}

// US states (+ a few CA provinces) - mirrors the parties list page.
const US_STATES: Record<string, string> = { AL:'Alabama', AK:'Alaska', AZ:'Arizona', AR:'Arkansas', CA:'California', CO:'Colorado', CT:'Connecticut', DE:'Delaware', FL:'Florida', GA:'Georgia', HI:'Hawaii', ID:'Idaho', IL:'Illinois', IN:'Indiana', IA:'Iowa', KS:'Kansas', KY:'Kentucky', LA:'Louisiana', ME:'Maine', MD:'Maryland', MA:'Massachusetts', MI:'Michigan', MN:'Minnesota', MS:'Mississippi', MO:'Missouri', MT:'Montana', NE:'Nebraska', NV:'Nevada', NH:'New Hampshire', NJ:'New Jersey', NM:'New Mexico', NY:'New York', NC:'North Carolina', ND:'North Dakota', OH:'Ohio', OK:'Oklahoma', OR:'Oregon', PA:'Pennsylvania', RI:'Rhode Island', SC:'South Carolina', SD:'South Dakota', TN:'Tennessee', TX:'Texas', UT:'Utah', VT:'Vermont', VA:'Virginia', WA:'Washington', WV:'West Virginia', WI:'Wisconsin', WY:'Wyoming', DC:'District of Columbia', BC:'British Columbia', ON:'Ontario', QC:'Quebec' };

// Common country codes -> full name (fallback: the code itself).
const COUNTRY_NAMES: Record<string, string> = {
  US:'United States', CA:'Canada', GB:'United Kingdom', UK:'United Kingdom',
  DE:'Germany', FR:'France', NL:'Netherlands', CH:'Switzerland', SE:'Sweden',
  ES:'Spain', IT:'Italy', IE:'Ireland', BE:'Belgium', AT:'Austria', FI:'Finland',
  NO:'Norway', DK:'Denmark', PT:'Portugal', PL:'Poland',
  JP:'Japan', CN:'China', KR:'South Korea', IN:'India', ID:'Indonesia',
  VN:'Vietnam', MY:'Malaysia', TW:'Taiwan', TH:'Thailand', SG:'Singapore',
  PH:'Philippines', HK:'Hong Kong',
  IL:'Israel', AE:'United Arab Emirates', SA:'Saudi Arabia', TR:'Turkey',
  BR:'Brazil', MX:'Mexico', AR:'Argentina', CL:'Chile',
  AU:'Australia', NZ:'New Zealand',
  ZA:'South Africa', MA:'Morocco', DZ:'Algeria', NG:'Nigeria', TN:'Tunisia', EG:'Egypt',
};

function countryName(code: string | null | undefined): string | null {
  if (!code) return null;
  return COUNTRY_NAMES[code.toUpperCase()] ?? code;
}

function fmtDate(iso: string | null | undefined): string {
  if (!iso) return '-';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '-';
  return format(d, 'yyyy-MM-dd HH:mm');
}

function isHttpUrl(s: string): boolean {
  return /^https?:\/\//i.test(s);
}

/**
 * One compact field cell: label stacked above value. Cells flow in a responsive
 * grid (2 columns on mobile, 3 on desktop) so short values pack together and
 * fill the row instead of each stretching across the full width.
 * `full` makes a field span the whole row (used for long content like Notes).
 */
function Field({
  label,
  children,
  full,
}: {
  label: string;
  children: ReactNode;
  full?: boolean;
}) {
  return (
    <div
      className={cn(
        'flex flex-col gap-0.5 min-w-0 border-b border-border/40 pb-2',
        full && 'col-span-2 lg:col-span-3',
      )}
    >
      <dt className="text-xs font-medium text-muted-foreground">{label}</dt>
      <dd className="text-sm break-words min-w-0">{children}</dd>
    </div>
  );
}

const DASH = <span className="text-muted-foreground">-</span>;

/** Pick the "representative" contact: primary first, then first with an email, then first. */
function pickRepContact(
  contacts: readonly PartyContact[] | undefined,
): PartyContact | null {
  if (!contacts || contacts.length === 0) return null;
  return (
    contacts.find((c) => c.isPrimary) ??
    contacts.find((c) => !!c.email) ??
    contacts[0] ??
    null
  );
}

export function PartyInfoCard({ party, contacts }: Props) {
  const rep = pickRepContact(contacts);
  const country = countryName(party.countryCode);
  const stateLabel = party.region
    ? (US_STATES[party.region] ?? party.region)
    : null;

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm flex items-center gap-2">
          <Info className="h-4 w-4 text-muted-foreground" />
          Basic Information
        </CardTitle>
      </CardHeader>
      <CardContent>
        <dl className="grid grid-cols-2 gap-x-6 gap-y-3 lg:grid-cols-3">
          <Field label="Name">{party.name || DASH}</Field>
          <Field label="Type">
            <PartyTypeBadge partyType={party.partyType} size="sm" />
          </Field>
          <Field label="Status">
            <span className="uppercase tracking-wide text-xs font-medium">
              {party.status}
            </span>
          </Field>
          <Field label="Country">{country || DASH}</Field>
          <Field label="Location">{party.city || DASH}</Field>
          <Field label="State">{stateLabel || DASH}</Field>
          <Field label="Email">
            {rep?.email ? (
              <a
                href={`mailto:${rep.email}`}
                className="text-blue-600 hover:underline break-all"
              >
                {rep.email}
              </a>
            ) : (
              DASH
            )}
          </Field>
          <Field label="Phone">
            {rep?.phone ? (
              <a href={`tel:${rep.phone}`} className="hover:underline">
                {rep.phone}
              </a>
            ) : (
              DASH
            )}
          </Field>
          <Field label="Website">
            {party.website ? (
              isHttpUrl(party.website) ? (
                <a
                  href={party.website}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:underline break-all"
                >
                  {party.website}
                </a>
              ) : (
                <span className="break-words">{party.website}</span>
              )
            ) : (
              DASH
            )}
          </Field>
          <Field label="Contact method">
            {party.preferredContactMethod ? (
              <ContactMethodBadge
                method={party.preferredContactMethod}
                formUrl={party.contactFormUrl}
              />
            ) : (
              DASH
            )}
          </Field>
          <Field label="Form URL">
            {party.contactFormUrl ? (
              <a
                href={party.contactFormUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 hover:underline break-all"
              >
                {party.contactFormUrl}
              </a>
            ) : (
              DASH
            )}
          </Field>
          <Field label="Source">{party.source || DASH}</Field>
          <Field label="Created">{fmtDate(party.createdAt)}</Field>
          <Field label="Updated">{fmtDate(party.updatedAt)}</Field>
          <Field label="Notes" full>
            {party.notes && party.notes.trim().length > 0 ? (
              <p className="whitespace-pre-wrap leading-relaxed">{party.notes}</p>
            ) : (
              DASH
            )}
          </Field>
        </dl>
      </CardContent>
    </Card>
  );
}
