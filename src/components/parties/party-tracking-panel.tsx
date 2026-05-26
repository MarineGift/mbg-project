// src/components/parties/party-tracking-panel.tsx
// Drop this into the party detail page (below Notes / Meetings section)
// Usage: <PartyTrackingPanel partyId={party.id} />

import { fetchTrackingForParty, fetchTrackingEvents } from '@/lib/queries/email-tracking';
import { TrackingBadge } from '@/components/inbox/tracking-badge';
import { TrackingTimeline } from '@/components/inbox/tracking-timeline';
import { formatDistanceToNow } from 'date-fns';
import { Mail } from 'lucide-react';

interface PartyTrackingPanelProps {
  partyId: string;
}

export async function PartyTrackingPanel({ partyId }: PartyTrackingPanelProps) {
  const records = await fetchTrackingForParty(partyId);

  if (!records.length) return null;

  return (
    <section className="space-y-4">
      <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">
        Email Tracking
      </h3>

      <div className="space-y-3">
        {records.map(async (rec) => {
          const events = await fetchTrackingEvents(rec.id);
          return (
            <div
              key={rec.id}
              className="rounded-lg border bg-card p-4 space-y-3"
            >
              {/* Header */}
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-start gap-2 min-w-0">
                  <Mail className="mt-0.5 h-4 w-4 shrink-0 text-muted-foreground" />
                  <div className="min-w-0">
                    <p className="text-sm font-medium truncate">
                      {rec.subject ?? '(no subject)'}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      To: {rec.sent_to} ·{' '}
                      {formatDistanceToNow(new Date(rec.sent_at), {
                        addSuffix: true,
                      })}
                    </p>
                  </div>
                </div>
                <TrackingBadge
                  openCount={rec.open_count}
                  clickCount={rec.click_count}
                  firstOpenedAt={rec.first_opened_at}
                />
              </div>

              {/* Event timeline */}
              {events.length > 0 && (
                <div className="border-t pt-3">
                  <TrackingTimeline events={events} />
                </div>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}
