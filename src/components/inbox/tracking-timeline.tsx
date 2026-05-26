// src/components/inbox/tracking-timeline.tsx
'use client';

import { Eye, MousePointer, ExternalLink } from 'lucide-react';
import { formatDistanceToNow, format } from 'date-fns';
import type { EmailTrackingEvent } from '@/types/phase21';

interface TrackingTimelineProps {
  events: EmailTrackingEvent[];
}

export function TrackingTimeline({ events }: TrackingTimelineProps) {
  if (!events.length) {
    return (
      <p className="text-sm text-muted-foreground py-2">
        No opens or clicks recorded yet.
      </p>
    );
  }

  return (
    <ul className="space-y-3">
      {events.map((ev) => (
        <li key={ev.id} className="flex items-start gap-2.5 text-sm">
          <span
            className={`mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full ${
              ev.event_type === 'open'
                ? 'bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400'
                : 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400'
            }`}
          >
            {ev.event_type === 'open' ? (
              <Eye className="h-3.5 w-3.5" />
            ) : (
              <MousePointer className="h-3.5 w-3.5" />
            )}
          </span>

          <div className="min-w-0 flex-1">
            <p className="font-medium capitalize">{ev.event_type}</p>

            {ev.url && ev.event_type === 'click' && (
              <a
                href={ev.url}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground truncate max-w-xs mt-0.5"
              >
                <ExternalLink className="h-3 w-3 shrink-0" />
                <span className="truncate">{ev.url}</span>
              </a>
            )}

            <p
              className="text-xs text-muted-foreground mt-0.5"
              title={format(new Date(ev.created_at), 'PPpp')}
            >
              {formatDistanceToNow(new Date(ev.created_at), { addSuffix: true })}
            </p>
          </div>
        </li>
      ))}
    </ul>
  );
}
