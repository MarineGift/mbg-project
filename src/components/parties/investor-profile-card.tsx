import type { ReactNode } from 'react';
import { Banknote } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import type { InvestorProfile } from '@/types/party-detail';
import { InvestorPriorityEditor } from '@/components/parties/investor-priority-editor';

interface Props {
  profile: InvestorProfile;
  partyName?: string;
  partyId: string;
}

const DASH = <span className="text-muted-foreground">-</span>;

/**
 * One compact field cell: label stacked above value. Cells flow in a responsive
 * grid (2 columns on mobile, 3 on desktop) so values pack together and the card
 * never needs a horizontal scrollbar -- matches PartyInfoCard.
 * `full` makes a field span the whole row (Priority editor, tag lists).
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

function fmtUsd(n: number | null): ReactNode {
  if (n == null) return DASH;
  // compact USD: 1_500_000 -> "$1.5M", 250_000_000 -> "$250M", 2_000_000_000 -> "$2B"
  const abs = Math.abs(n);
  let out: string;
  if (abs >= 1_000_000_000) out = `$${(n / 1_000_000_000).toFixed(1).replace(/\.0$/, '')}B`;
  else if (abs >= 1_000_000) out = `$${(n / 1_000_000).toFixed(1).replace(/\.0$/, '')}M`;
  else if (abs >= 1_000) out = `$${(n / 1_000).toFixed(0)}K`;
  else out = `$${n}`;
  return out;
}

function ticketRange(min: number | null, max: number | null): ReactNode {
  if (min == null && max == null) return DASH;
  if (min != null && max != null) return <>{fmtUsd(min)} – {fmtUsd(max)}</>;
  return min != null ? <>from {fmtUsd(min)}</> : <>up to {fmtUsd(max)}</>;
}

function Tags({ items }: { items: string[] }): ReactNode {
  if (!items || items.length === 0) return DASH;
  return (
    <div className="flex flex-wrap gap-1">
      {items.map((t) => (
        <span
          key={t}
          className="inline-flex items-center rounded-full bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300 px-2 py-0.5 text-xs"
        >
          {t}
        </span>
      ))}
    </div>
  );
}

function Flags({ profile }: { profile: InvestorProfile }): ReactNode {
  const flags: string[] = [];
  if (profile.isLeadInvestor) flags.push('Lead investor');
  if (profile.isStrategic) flags.push('Strategic');
  if (flags.length === 0) return DASH;
  return (
    <div className="flex flex-wrap gap-1">
      {flags.map((f) => (
        <span
          key={f}
          className="inline-flex items-center rounded-full bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-300 px-2 py-0.5 text-xs"
        >
          {f}
        </span>
      ))}
    </div>
  );
}

export function InvestorProfileCard({ profile, partyName, partyId }: Props) {
  const showFundName =
    !!profile.fundName && profile.fundName.trim() !== (partyName ?? '').trim();

  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm flex items-center gap-2">
          <Banknote className="h-4 w-4 text-muted-foreground" />
          Investor Profile
        </CardTitle>
      </CardHeader>
      <CardContent>
        <dl className="grid grid-cols-2 gap-x-6 gap-y-3 lg:grid-cols-3">
          {/* Priority (relevance: who to contact now) with Sector Focus right beside it. */}
          <Field label="Priority">
            <InvestorPriorityEditor partyId={partyId} partyType="investor" value={profile.priority} />
          </Field>
          <Field label="Sector Focus"><Tags items={profile.sectorFocus} /></Field>
          {showFundName && <Field label="Fund Name">{profile.fundName}</Field>}
          <Field label="Type">
            {profile.typeName ? (
              <span className="inline-flex items-center rounded-full bg-indigo-100 text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300 px-2 py-0.5 text-xs font-medium">
                {profile.typeName}
              </span>
            ) : (
              DASH
            )}
          </Field>
          <Field label="Fund Size">{fmtUsd(profile.fundSizeUsd)}</Field>
          <Field label="AUM">{fmtUsd(profile.aumUsd)}</Field>
          <Field label="Vintage Year">{profile.fundVintageYear ?? DASH}</Field>
          <Field label="Ticket Size">{ticketRange(profile.ticketMinUsd, profile.ticketMaxUsd)}</Field>
          <Field label="Flags"><Flags profile={profile} /></Field>
        </dl>
      </CardContent>
    </Card>
  );
}
