import type { ReactNode } from 'react';
import { Info } from 'lucide-react';
import { format } from 'date-fns';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { PartyTypeBadge } from '@/components/common/party-type-badge';
import type { PartyDetail } from '@/types/party-detail';

interface Props {
  party: PartyDetail;
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

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="flex flex-col gap-0.5 py-2 border-b border-border/50 last:border-0 sm:flex-row sm:items-start sm:gap-4">
      <dt className="text-xs font-medium text-muted-foreground sm:w-40 sm:shrink-0 sm:pt-0.5">
        {label}
      </dt>
      <dd className="text-sm break-words min-w-0 flex-1">{children}</dd>
    </div>
  );
}

const DASH = <span className="text-muted-foreground">-</span>;

export function PartyInfoCard({ party }: Props) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-sm flex items-center gap-2">
          <Info className="h-4 w-4 text-muted-foreground" />
          Basic Information
        </CardTitle>
      </CardHeader>
      <CardContent>
        <dl>
          <Row label="Name">{party.name || DASH}</Row>
          <Row label="Type">
            <PartyTypeBadge partyType={party.partyType} size="sm" />
          </Row>
          <Row label="Status">
            <span className="uppercase tracking-wide text-xs font-medium">
              {party.status}
            </span>
          </Row>
          <Row label="Country">{party.countryCode || DASH}</Row>
          <Row label="Website">
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
          </Row>
          <Row label="Source">{party.source || DASH}</Row>
          <Row label="Interest Tags">
            {party.interestTags.length > 0 ? (
              <div className="flex flex-wrap gap-1">
                {party.interestTags.map((tag) => (
                  <span
                    key={tag}
                    className="inline-flex items-center rounded-full bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300 px-2 py-0.5 text-xs"
                  >
                    {tag}
                  </span>
                ))}
              </div>
            ) : (
              DASH
            )}
          </Row>
          <Row label="Notes">
            {party.notes && party.notes.trim().length > 0 ? (
              <p className="whitespace-pre-wrap leading-relaxed">{party.notes}</p>
            ) : (
              DASH
            )}
          </Row>
          <Row label="Created">{fmtDate(party.createdAt)}</Row>
          <Row label="Updated">{fmtDate(party.updatedAt)}</Row>
          <Row label="Party ID">
            <span className="font-mono text-xs text-muted-foreground break-all">
              {party.id}
            </span>
          </Row>
        </dl>
      </CardContent>
    </Card>
  );
}